---
published: false
draft: true
title: 'Why we chose WebComponents for our Design System'
path: '/articles/why-we-chose-webcomponents-for-our-design-system'
date: '2022-04-20'
description: 'I believe Web Components has its place and here is why'
cover_image: 'https://res.cloudinary.com/practicaldev/image/fetch/s--4TmXd8CQ--/c_imagga_scale,f_auto,fl_progressive,h_420,q_auto,w_1000/https://dev-to-uploads.s3.amazonaws.com/uploads/articles/ohbqnh96p1k2bdflohox.png'
---


I have worked on a UI library for an internal Design System at a large-scale company (10'000+ employees). I want to walk through my thought process why I have been advocating for Web Components.

## Context

I was asked to help creating an Angular-based UI Kit which contains our commonly used components such as inputs, buttons and so on.
Early on I questioned this decision. The rational behind it was that most product teams were using Angular.

Though as I later found out, that was not necessarily true. In Switzerland, where I am located, it's true that most teams were using Angular (probably because it felt more natural to C# developers which was the dominating backend language). Though the more I was trying to do "market research" (=reaching out to teams within the company) I have realized that in e.g. Spain, Poland and the US _React_ was clearly dominant. Whereas in Asian countries Vue was the goto frontend framework. We also worked with external companies which sometimes used completely different frameworks. I came to realisation that basically every framework you can imagine was still in use -- from Backbone.js to Svelte.

So for me creating a UI library with Angular wouldn't cut the vision I had; **I want one UI Kit which can be consumed within the company. No matter if or what framework you use.**

## What the heck are Web Components?

For a long time I honestly did not understand what "Web Components" are. To this day I still believe "Web Components" is just a marketing term or _"Syntax Sugar"_
for different sets to HTML specifications.

Let me break the specifications down for you:

|                 |                                                                                                                                                              |
| :-------------- | :----------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Custom Elements | The Custom Elements specification lays the foundation for designing and using new types of DOM elements.                                                     |
| Shadow DOM      | The shadow DOM specification defines how to use encapsulated style and markup in web components.                                                             |
| ES Modules      | The ES Modules specification defines the inclusion and reuse of JS documents in a standards based, modular, performant way.                                  |
| HTML Template   | The HTML template element specification defines how to declare fragments of markup that go unused at page load, but can be instantiated later on at runtime. |

> The table above was taken from [webcomponents.org](https://www.webcomponents.org/introduction)

So in a nutshell Web Components is a term to bundle up all of those specifications.

## Why Web Components

Now that we understand what Web Components are I want to dissect how that can serve us given the context I was in.

### Shadow DOM and Custom Properties


![Image description](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/dusm23u3y6cysscc8zhj.png)

Shadow DOM essentially encapsulates CSS and HTML. The reason why this is **really** useful is because you have more control what is considered public and private API of a component.

To explain it further, let's have a look at how _probably_ most folks used UI libraries like [Bootstrap](https://getbootstrap.com/docs/3.4/css/) back in the _good ol' days_.

Usually you'd copy/paste a HTML block and sometimes also import some JavaScript whenever you want to use a component. Often times you'd also customize the HTML with additional CSS code to make it look more according to your branding.

Now imagine Bootstrap would introduce some changes in its CSS of a component. Since anyone has full access to overwrite any CSS of a Bootstrap component, ugprading to the latest Bootstrap version may lead to some nasty side-effects. **There is no control from Bootstraps side how the components will be used and modified.**

For a library like Bootstrap this may not be a big deal, though with a Design Systems UI library you want to consolidate the components as much as possible and only allow certain things to change.

Now with Shadow DOM and the [Custom Properties](https://developer.mozilla.org/en-US/docs/Web/CSS/Using_CSS_custom_properties) specifications you can fully encapsulate the HTML and CSS of a component, but still allow customization to be made via Custom CSS Properties. So this means your components API is much more explicit and not everything is just _public_.

This gives much more sanity to library authors of UI Kits and also allows to use [SemVer](https://semver.org/lang/de/) in a much more sane manner since you know exactly when a components API is considered broken (e.g. removing a custom property). This makes an upgrade of your library much more predictable (given they did not pierce through the Shadow DOM).


### Framework Agnosticity

One of our biggest struggles was serving teams with very varying tech stacks. Whilst it is a very feasible and good option to just use vanilla HTML, CSS and JS without Web Components for your UI Kit, I believe the developer experience will suffer. On top of that you won't be able to prevent using private component APIs as mentioned above or.

Generally speaking, Web Components are quite well supported for most frameworks.

There is one big caveat though; React v18 does not support handling rich data or handling events of Web Components.

![React 18 WC support](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/3qap49xsqtye0jcomo02.PNG)


> Source: [custom-elements-everywhere.com](https://custom-elements-everywhere.com/)


With React v19 this should be resolved, but this is at the time of this writing not stable for
production use.

So apart from React you should be able to use Web Components (including Preact) -- [though I'll go into more details later in this article how you can workaround that limitation](#framework-bindings) as well as support JSX as first-class citizen.

## Downsides of Web Components and how to workaround it

Writing a Web Component with Vanilla JS-only is cumbersome. A lot of code needs to be added in order to do the simplest things which you'd normally expect in frameworks like Vue, Angular or React.

It is in a developers nature to simply reduce redundant code and abstract low-level interfaces. Unfortunately, this will most likely lead in a sort-of _Frankenstein-framework_  which most probably is not even half as good as other already existing frameworks and might not even be documented. Therefore I came to the conclusion; **Web Components do not replace your frontend framework**

Fortunately, there are some amazing libraries and frameworks already out there. For instance:

- [Lit](https://lit.dev/)
- [Stencil](https://stenciljs.com/)
- [Hybrids](https://github.com/hybridsjs/hybrids)
- [Slim.JS](https://slimjs.com/#/welcome)

These frameworks off course have some major differences in philosophies, implementation and style. **For us, the one we chose is [Stencil](https://stenciljs.com/)**.

## Stencil

> Stencil is a toolchain for building reusable, scalable Design Systems. Generate small, blazing fast, and 100% standards based Web Components that run in every browser.

Stencil has some really great features and philosophies I subscribe to. One of its most compelling features for me is that it is essentially just a "toolchain" which generates Web Components with minimal runtime code.

### Compiler

This is fundamentally different to runtime frameworks like Angular, Vue or React where these libraries have their own runtime code which needs to be shipped to a browser. Stencil on the other hand **compiles** the Web Component for you with all its necessary functionality during build time which leads to a smaller
bundle size.

### TypeScript

This is opinionated but I absolutely love that Stencil fully embraces TypeScript. It embraces it so far that it even uses TypeScript reflection API to auto-generate Markdown documentation for you. For instance, all your events and props will get automatically documentened with the proper typing.
This is really useful because if you build a UI Kit the documentation is absolutely detremental. While it
does not completely remove the need for documentation, at least you don't need to document the component
atanomy.

In my opinion, a Stencil component takes best of both the Angular and React world; phenomenal TypeScript support as well as TSX.


```typescript
import { Component, Prop, h } from '@stencil/core';

@Component({
  tag: 'my-first-component',
})
export class MyComponent {

  // Indicate that name should be a public property on the component
  @Prop() name: string;

  render() {
    return (
      <p>
        My name is {this.name}
      </p>
    );
  }
}
```
> Example of a Stencil Component


### Framework Bindings

As I mentioned Web Components have some limitations with React. Though Stencil actually [provides Framework
Bindings](https://stenciljs.com/docs/overview) which essentially wrap a Web Component with the target frameworks Component API.

So for instance if you use the React Framework binding, it will automatically generate a React component with all the Props & Events and connect these internally with the Web Component. This is possible because Stencil heavily uses the TypeScript reflection API to auto-generate these integrations.

<!-- TODO: Image-->

This also enables an awesome developer experience. Your Web Component will almost become indistinguishable to _native_ React components.

```jsx
// Without using framework bindings
function MyComponent() {
    return <ui-kit-component></ui-kit-component>
}

// With using framework bindings
import { UiKitComponent } from '@my-ui-kit/react';

function MyComponent() {
    return <UiKitComponent />
}
```

## Conclusion

For us Web Components with Stencil have worked out great so far. In addition, with the Framework Bindings we can give a natural developer experience for React, Angular and Vue developers. Thanks to Shadow DOM and Custom Properties there is now a much clearer interface what is considered public and private functionality of
a component. This aids especially the users of the library so they are less likely to shoot themselves in the foot
by over-customizing the UI-Kit components.

Instead of building multiple UI Kits in Angular, Vue or React, we can just simply have one-source-of-truths and target whatever framework we'd like.


## Further Readings

There is so much more to explore when it comes to Design System. Here are some additional posts I've made which you might find interesting.

- [Create an icon web front for your Design System](https://www.brunnerliv.io/articles/icon-web-font)
- [Use Stencil with GatsbyJS](https://www.brunnerliv.io/articles/use-stencil-with-gatsbyjs)
- [Design Tokens @ WebZürich (YouTube)](https://www.youtube.com/watch?v=yq_APtAkgD8&t=3053s)