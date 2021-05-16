---
published: true
title: 'Use Stencil with GatsbyJS'
tags: stencil, gatsbyjs, ssr, webcomponents
path: '/articles/use-stencil-with-gatsbyjs'
date: '2021-05-16'
description: 'Use a Stencil based web components library together with GatsbyJS'
cover_image: 'https://dev-to-uploads.s3.amazonaws.com/uploads/articles/tlqsil8dyb8p02ob3oi8.png'
---

_Livio is a member of the NestJS core team and creator of the @nestjs/terminus integration._

[Stencil](https://stenciljs.com/) is one of my favorite frameworks and _in my opinion_ combines the best of both the Angular and React worlds. Though not only that! Stencil is _just_ a toolchain for building your Web Components - **that run in every major browser**.

Unfortunately, there is a caveat with Web Components:
They only run with JavaScript and do not work with SSR.

Whilst that is true - if you've built your Web Components library with Stencil - you have are covered by their amazing SSR integration!

Let's have a look at how we were able to run our Design Systems UI library with GatsbyJS! With this article, I won't go into details on how you set up a Stencil project. So make sure you understand the fundamentals of Stencil already.

> **[Check out the final repository here](https://github.com/BrunnerLivio/stencil-gatsbyjs-starter-repo)**

## Setup the Project

I am going to assume in this article that you have already set up a Stencil project. In my case, this project is called `@my-company/webcomponents`.

In order to replicate my setup, execute the following commands. We will end up with a simple mono-repository. Though if you want to keep things separated - that would work too!

```bash
# ✅ Create the project folder
mkdir stencil-gatsbyjs
cd stencil-gatsbyjs
npm init -y

# ✅ Setup Git (optional)

mkdir packages
cd packages

# ✅ Setup Stencil
# Select "components"
# Choose name "webcomponents" or whatever name you want
npm init stencil

# ✅ Setup GatsbyJS
# Choose name "docs" or whatever name you want
# "Yes" to everything else
npm init gatsby

# ✅ Setup Lerna (optional)
cd ..
npx lerna init
npx lerna bootstrap
```

My folder structure now looks like this:

```bash
$ tree -I node_modules
.
├── lerna.json
├── package.json
└── packages
    ├── docs
    │   ├── README.md
    │   ├── gatsby-config.js
    │   ├── package.json
    │   ├── src
    │   │   ├── images
    │   │   │   └── icon.png
    │   │   └── pages
    │   │       ├── 404.js
    │   │       └── index.js
    │   └── yarn.lock
    └── webcomponents
        ├── LICENSE
        ├── package.json
        ├── readme.md
        ├── src
        │   ├── components
        │   │   └── my-component
        │   │       ├── my-component.css
        │   │       ├── my-component.e2e.ts
        │   │       ├── my-component.spec.ts
        │   │       ├── my-component.tsx
        │   │       └── readme.md
        │   ├── components.d.ts
        │   ├── index.html
        │   ├── index.ts
        │   └── utils
        │       ├── utils.spec.ts
        │       └── utils.ts
        ├── stencil.config.ts
        └── tsconfig.json

10 directories, 24 files
```

## Enable SSR with Stencil

Once we have set up the fundamental project, let's make sure we have added the [_hydrate app_](https://stenciljs.com/docs/hydrate-app) functionality inside our Stencil project.

The hydrate app is a bundle of your same components but compiled so they can be hydrated on a NodeJS server, and generate HTML.

In order to enable it, simply go to your `stencil.config.ts` file and add the following line inside the `outputTargets`-array.

`packages/webcomponents/stencil.config.ts`

```typescript
{
  type: 'dist-hydrate-script';
}
```

This will generate a new folder called `hydrate` after running `npm run build`. We will need to use that folder later!

Don't forget to update your `.gitignore`-file to exclude the `hydrate` folder.

```bash
$ cd packages/webcomponents
$ echo "hydrate" >> .gitignore
```

As well as updating your `package.json`-file.

`packages/webcomponents/package.json`

```diff
- "name": "webcomponents",
+ "name": "@my-company/webcomponents",
  "files": [
    "dist/",
    "loader/",
+   "hydrate/"
  ],
```

As the last step, let's link our library so we can use it locally later.

```bash
$ npm link
# Go back to the project root folder
$ cd ../../
```

## Use your Stencil components with GatsbyJS

With the previous step, we have enabled SSR with Stencil. Basically, we now have access to the `hydrate` folder which exposes the `renderToString` function. This function basically prerenders the web components into plain old HTML which will be hydrated once JavaScript is loaded.

In order to make use of this function, we have to add it into our `gatsby-node.js`.

```bash
$ cd packages/docs
$ touch gatsby-node.js
$ touch gatsby-browser.js

# We are going to use that package later
$ npm install --save glob
```

> The code is inspired by https://github.com/jonearley/gatsby-plugin-stencil. Personally, I prefer the following enhanced version, since it allows you to add multiple Stencil packages, as well as provide better error handling. I have created a PR against the gatsby-plugin-stencil repository with the changes. So hopefully, you will be able to simply consume this as a Gatsby plugin soon https://github.com/jonearley/gatsby-plugin-stencil/pull/3 (posted @ 16. May 2021)

`packages/docs/gatsby-node.js`

```javascript
const util = require('util');
const glob = util.promisify(require('glob'));
const fs = require('fs');

const readFile = util.promisify(fs.readFile);
const writeFile = util.promisify(fs.writeFile);

/*
  Server-side render Stencil web components
*/
exports.onPostBuild = async ({ reporter }) => {
  // Make sure to edit the following lines
  const pluginOptions = {
    module: ['@my-company/webcomponents'],
    renderToStringOptions: {},
  };

  let packages = pluginOptions.module;
  if (!Array.isArray(pluginOptions.module)) {
    packages = [pluginOptions.module];
  }

  const files = await glob('public/**/*.html', { nodir: true });

  const renderToStringOptions = pluginOptions.renderToStringOptions ? pluginOptions.renderToStringOptions : {};

  async function preRenderPage(file, hydrate, pkg) {
    try {
      const page = await readFile(file, 'utf-8');
      const { html, diagnostics = [] } = await hydrate.renderToString(page, renderToStringOptions);

      diagnostics.forEach(diagnostic =>
        reporter.error(`error pre-rendering file: ${file} with ${pkg}. ${JSON.stringify(diagnostic, null, '  ')}`),
      );

      await writeFile(file, html);
    } catch (e) {
      reporter.error(`error pre-rendering file: ${file} with ${pkg}. ${e.message}`);
    }
  }

  async function preRenderPackage(pkg) {
    const hydrate = require(`${pkg}/hydrate`);
    await Promise.all(files.map(file => preRenderPage(file, hydrate, pkg)));
    reporter.info(`pre-rendered ${pkg}`);
  }

  return Promise.all(packages.map(preRenderPackage));
};
```

In a nutshell, this script will be executed in "post build" (so after the HTML, CSS, and JS files have been generated). We simply go through every HTML file and execute Stencils `renderToString` function and save the contents.

Now we just need to add a few lines to our `gatsby-browser.js`.

`packages/docs/gatsby-browser.js`

```javascript
const { defineCustomElements } = require('@my-company/webcomponents/loader');
defineCustomElements();
```

Now we can start using our web component inside our pages.

`packages/docs/src/pages/index.js`

```diff
const IndexPage = () => {
  return (
    <main style={pageStyles}>
      <title>Home Page</title>
      <h1 style={headingStyles}>
        Congratulations
+       <my-component
+         first="Albus"
+         middle="Percival Wulfric Brian"
+         last="Dumbledore"
+       />
        <br />
```

Done! 🎉
Let's link our Webcomponents library with the docs and build the site.

```bash
$ npm link @my-company/webcomponents
$ npm run build
# Start a simple HTTP server on port 8000 from the "public" folder
$ npx servor public index.html 8000

# Open up your site on http://localhost:8000
```

You should now see the following site. Note the _"Hello, World! I'm Albus Percival Wulfric Brian Dumbledore"_ is being rendered by our Webcomponent!

![Gatsby website rendering our webcomponent](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/s80zf3nztbqveo7eev2v.png)

## Inspect the output

In order to double-check the SSR we can try disabling JavaScript and the website should render the same. In Chrome, `Open up Dev Tools` -> `CMD + SHIFT + P` or `CTRL + SHIFT + P` -> `Disable JavaScript` -> `Reload the page`.

You still see the _"Hello World! I'm Albus..."_? Great! The Webcomponent still renders with JavaScript disabled.

So what did Stencils `renderToString` actually do? Well let's have a look at the diff of the built `index.html` file we just generated from the `npm run build`.

As first stricking difference we see in the `<head>`-tag that Stencil has added the CSS of our web component:

```diff
   <head>
     <meta charset="utf-8" />
     <meta http-equiv="x-ua-compatible" content="ie=edge" />
@@ -8,6 +8,12 @@
       content="width=device-width, initial-scale=1, shrink-to-fit=no"
     />
     <meta name="generator" content="Gatsby 3.5.0" />
+    <style sty-id="sc-my-component">
+      /*!@:host*/
+      .sc-my-component-h {
+        display: block;
+      }
+    </style>
```

Also inside the HTML of our Webcomponent has been rendered with the correct text (removed comments and unnecessary attributes for readability).

```diff
<h1 style="margin-top: 0; margin-bottom: 64px; max-width: 320px">Congratulations
      <my-component
        first="Albus"
        middle="Percival Wulfric Brian"
        last="Dumbledore"
-      ></my-component>
+       class="sc-my-component-h hydrated">
+         <div class="sc-my-component">
+           Hello, World! I'm Albus Percival Wulfric Brian Dumbledore
+         </div>
+       </my-component>
```

So basically the `renderToString` function takes care of the first render - which allows us to use the WebComponents even without JavaScript.

## Add TypeScript support within GatsbyJS

In case you are using GatsbyJS with Typescript, adding support to your Stencil Webcomponents is fairly straightforward.

Create a new folder called `types` inside the `packages/docs/`-folder

```bash
$ cd packages/docs
$ mkdir types && cd types
$ touch wc.d.ts
```

and add the following code inside the `types/wc.d.ts` file

`packages/docs/types/wc.d.ts`

```typescript
// This is a workaround to include type-safe stencil web components
// with TSX https://github.com/ionic-team/stencil/issues/1636
import { JSX as LocalJSX } from '@my-company/webcomponents';
import { DetailedHTMLProps, HTMLAttributes } from 'react';

type StencilProps<T> = {
  [P in keyof T]?: Omit<T[P], 'ref'> | HTMLAttributes<T>;
};

type ReactProps<T> = {
  [P in keyof T]?: DetailedHTMLProps<HTMLAttributes<T[P]>, T[P]>;
};

type StencilToReact<T = LocalJSX.IntrinsicElements, U = HTMLElementTagNameMap> = StencilProps<T> & ReactProps<U>;

declare global {
  // eslint-disable-next-line @typescript-eslint/no-namespace
  export namespace JSX {
    interface IntrinsicElements extends StencilToReact {}
  }
}
```

Load the type definition file within your `tsconfig.json`

`packages/docs/tsconfig.json`

```diff
{
  "compilerOptions": {
+   "typeRoots": ["./types", "node_modules/@types"],
+   "paths": {
+     "*": ["types/*"]
+   }
  },
  "include": [
+   "./types/*"
  ]
}
```

Now we keep our types up to date. The `wc.d.ts` file import the types of your Webcomponents library (in our case `@my-company/webcomponents`) and converts them to "React compatible" JSX type definitions.

## Use `@stencil/react-output-target` with GatsbyJS

In case you are using [`@stencil/react-output-target`](https://www.npmjs.com/package/@stencil/react-output-target)
to wrap your Webcomponents within React components in order to have a more "native" feel, follow this chapter.

Feel free to skip this chapter in case you are fine using the raw Webcomponents.
**Beware though, [React and Webcomponents comes with some limitations](https://custom-elements-everywhere.com/#react) which are fixed by `@stencil/react-output-target`.**
So personally, I can only recommend this plugin for your Stencil application.

### Setup the React package

Skip this chapter in case you have already setup your React package.

Run the following commands in your shell of choice.

```bash
cd packages/

# Install the React output target
cd webcomponents
npm install --save-dev @stencil/react-output-target
cd ../

# Setup the React project
mkdir -p react/src
cd react
touch .gitignore
touch package.json
touch rollup.config.js
```

Inside your `stencil.config.ts` add the following lines to configure the
React output target.

`packages/webcomponents/stencil.config.ts`

```diff
  import { Config } from '@stencil/core';
+ import { reactOutputTarget } from '@stencil/react-output-target';

export const config: Config = {
  namespace: 'webcomponents',
  outputTargets: [
+   reactOutputTarget({
+     componentCorePackage: 'component-library',
+     proxiesFile: '../react/src/components.ts',
+   }),
```

Once we run the build command again within the Stencil project, we should now see
new files generated in the `packages/react/`-project.

```bash
$ cd packages/webcomponents
$ npm run build
```

Let's clean that up as well!

`packages/react/.gitignore`

```
# compiled output
/dist

# dependencies
/node_modules


# misc
npm-debug.log
yarn-error.log
testem.log
/typings

# System Files
.DS_Store
Thumbs.db

/src
!/src/typings.d.ts
dist-transpiled
```

Now we just need to setup our `package.json`.

`packages/react/package.json`

```json
{
  "name": "@my-company/react",
  "version": "1.0.0",
  "description": "",
  "keywords": [],
  "author": "",
  "license": "ISC",
  "files": ["dist/"],
  "main": "dist/index.js",
  "module": "dist/index.js",
  "esmodule": "dist/index.js",
  "types": "dist/index.d.ts",
  "source": "src/index.ts",
  "scripts": {
    "build": "npm run clean && npm run compile",
    "clean": "rimraf dist && rimraf dist-transpiled",
    "compile": "npm run tsc && rollup -c",
    "tsc": "tsc -p ."
  },
  "peerDependencies": {
    "react": ">=16.8.6",
    "react-dom": ">=16.8.6"
  },
  "devDependencies": {
    "@types/node": "^12.12.38",
    "@types/react": "^16.9.27",
    "@types/react-dom": "^16.9.7",
    "@rollup/plugin-node-resolve": "^8.1.0",
    "react": "^16.13.1",
    "react-dom": "^16.13.1",
    "react-scripts": "^3.4.1",
    "rollup": "^2.26.4",
    "rollup-plugin-sourcemaps": "^0.6.2",
    "typescript": "^3.7.5",
    "rimraf": "^3.0.2"
  }
}
```

and install the dependencies with

```bash
$ npm link @my-company/webcomponents
$ npm install
```

### Bundle your React package

Personally, I like to use Rollup for bundling my libraries. Though feel free to use
whatever tool you want to use. **Make sure you produce a `CommonJS` output bundle
so that it works all fine with GatsbyJS**

Inside your `rollup.config.js` add the following configuration

`packages/react/rollup.config.js`

```javascript
import resolve from '@rollup/plugin-node-resolve';
import sourcemaps from 'rollup-plugin-sourcemaps';

export default {
  input: {
    index: 'dist-transpiled/index',
  },
  output: [
    {
      dir: 'dist/',
      entryFileNames: '[name].esm.js',
      chunkFileNames: '[name]-[hash].esm.js',
      format: 'es',
      sourcemap: true,
    },
    {
      dir: 'dist/',
      format: 'commonjs',
      preferConst: true,
      sourcemap: true,
    },
  ],
  external: id => !/^(\.|\/)/.test(id),
  plugins: [resolve(), sourcemaps()],
};
```

Also, add a `tsconfig.json` which transpiles our TypeScript files
before we bundle it with Rollup.

`packages/react/tsconfig.json`

```json
{
  "compilerOptions": {
    "strict": true,
    "allowUnreachableCode": false,
    "allowSyntheticDefaultImports": true,
    "declaration": true,
    "emitDecoratorMetadata": true,
    "experimentalDecorators": true,
    "esModuleInterop": true,
    "lib": ["dom", "es2015"],
    "importHelpers": true,
    "module": "es2015",
    "moduleResolution": "node",
    "noImplicitAny": true,
    "noImplicitReturns": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "outDir": "dist-transpiled",
    "declarationDir": "dist/types",
    "removeComments": false,
    "inlineSources": true,
    "sourceMap": true,
    "jsx": "react",
    "target": "es2017"
  },
  "include": ["src/**/*.ts", "src/**/*.tsx"],
  "compileOnSave": false,
  "buildOnSave": false
}
```

By running the build command of the React package we are generating
a new `dist`-bundle

```bash
$ cd packages/react
$ npm run build
```

Voilà! We now successfully added a React integration!
Let's link that one up so we can use it within our Gatbsy application.

```bash
$ cd packages/react
$ npm link
```

### Use the React package with Gatsby

First of all we need to make sure both libraries are linked.

```bash
npm link @my-company/webcomponents @my-company/react
```

As a next step, we can refactor our previously used Webcomponent inside the `pages/index.js` file

`packages/docs/src/pages/index.js`

```diff
+ import { MyComponent } from "@my-company/react";

 const IndexPage = () => {
  return (
    <main style={pageStyles}>
      <title>Home Page</title>
      <h1 style={headingStyles}>
        Congratulations
-       <my-component
+       <MyComponent
          first="Albus"
          middle="Percival Wulfric Brian"
          last="Dumbledore"
        />
        <br />
```

and that is it! We can now run and build the website as we
used to.

## Conclusion

In this article, we examined why I personally love Stencil.
This framework is so much more than "just Webcomponents". For myself,
as a UI library maintainer it so rewarding to offer components which are framework
independent, yet can be integrated into frameworks such as React to have a more natural
developer experience.

Not only that - you can go above and beyond by enabling SSR. The TypeScript support
for users of a Stencil UI library is just phenomenal.

The cherry on top - which we, unfortunately, did not have a look at in this article - is
the automated markdown documentation of each component.
These Markdown files can now easily be integrated into your Gatsby documentation!

> **[Check out the final repository here](https://github.com/BrunnerLivio/stencil-gatsbyjs-starter-repo)**
