---
published: true
title: 'Advanced NestJS: Dynamic Providers'
tags: NestJS, Node.js, TypeScript
path: '/articles/advanced-nestjs-dymaic-providers'
date: '2019-08-17'
description: 'Learn how to use dynamic providers with NestJS!'
dev_to_path: 'https://dev.to/nestjs/advanced-nestjs-dynamic-providers-1ee'
---

_Livio is a member of the NestJS core team and creator of the @nestjs/terminus integration_

## Intro

**Dependency Injection** (short _DI_) is a powerful technique to build a loosely coupled architecture in a testable manner. In NestJS an item which is part of the DI context is called _provider_. A provider consists of two main parts, a value, and a unique token. In NestJS you can request the value of a _provider_ by its token. This is most apparent when using the following snippet.

```typescript
import { NestFactory } from '@nestjs/core';
import { Module } from '@nestjs/common';

@Module({
  providers: [
    {
      provide: 'PORT',
      useValue: 3000,
    },
  ],
})
export class AppModule {}

async function bootstrap() {
  const app = await NestFactory.createApplicationContext(AppModule);

  const port = app.get('PORT');
  console.log(port); // Prints: 3000
}
bootstrap();
```

The `AppModule` consists of one provider with the token `PORT`.

- We bootstrap our application by calling `NestFactory.createApplicationContext` (this method does the same as `NestFactory.create` but does not initiate an HTTP instance).
- Later on, we request the value of our provider with `app.get('PORT')`. This will return `3000` as specified in our provider.

Fair enough. But what if you do not know what you will provide to the user? What if you need to compute the providers during runtime?

This article goes into a technique which we use often for various NestJS integrations. This technique will allow you to build highly dynamic NestJS applications and still make use of the advantages of DI.

## What are we trying to achieve

To see use cases of dynamic providers we will use a simple but useful example. We want to have a parameter decorator called `Logger` which takes an optional `prefix` as `string`. This decorator will inject a `LoggerService`, which prepends the given `prefix` to every log message.

So the final implementation will look like this:

```typescript
@Injectable()
export class AppService {
  constructor(@Logger('AppService') private logger: LoggerService) {}

  getHello() {
    this.logger.log('Hello World'); // Prints: '[AppService] Hello World'
    return 'Hello World';
  }
}
```

## Setup a NestJS application

We will make use of the NestJS CLI to get started quickly. If you have not installed it, use the following command:

```bash
npm i -g @nestjs/cli
```

Now run the following command in your terminal of choice to bootstrap your Nest application.

```bash
nest new logger-app && cd logger-app
```

## Logger service

Let's start off with our `LoggerService`. This service will get injected later when we use our `@Logger()` decorator. Our basic requirements for this service are:

- A method which can log messages to stdout
- A method which can set the prefix of each instance

Once again we will use the NestJS CLI to bootstrap our module and service.

```bash
nest generate module Logger
nest generate service Logger
```

To satisfy our requirements we build this minimal `LoggerService`.

```typescript
// src/logger/logger.service.ts

import { Injectable, Scope } from '@nestjs/common';

@Injectable({
  scope: Scope.TRANSIENT,
})
export class LoggerService {
  private prefix?: string;

  log(message: string) {
    let formattedMessage = message;

    if (this.prefix) {
      formattedMessage = `[${this.prefix}] ${message}`;
    }

    console.log(formattedMessage);
  }

  setPrefix(prefix: string) {
    this.prefix = prefix;
  }
}
```

First of all, you may have realized that the `@Injectable()` decorator uses the scope option with `Scope.TRANSIENT`. This basically means every time the `LoggerService` gets injected in our application, it will create a new instance of the class. This is mandatory due to the `prefix` attribute. We do not want to have a single instance of the `LoggerService` and constantly override the `prefix` option.

Other than that, the `LoggerService` should be self-explanatory.

Now we only have to export our service in the `LoggerModule`, so we can use it in `AppModule`.

```typescript
// src/logger/logger.module.ts

import { Module } from '@nestjs/common';
import { LoggerService } from './logger.service';

@Module({
  providers: [LoggerService],
  exports: [LoggerService],
})
export class LoggerModule {}
```

Let's see if it works in our `AppService`.

```typescript
// src/app.service.ts

import { Injectable } from '@nestjs/common';
import { LoggerService } from './logger/logger.service';

@Injectable()
export class AppService {
  constructor(private readonly logger: LoggerService) {
    this.logger.setPrefix('AppService');
  }
  getHello(): string {
    this.logger.log('Hello World');
    return 'Hello World!';
  }
}
```

Seems fine - let's start the application with `npm run start` and request the website with `curl http://localhost:3000/` or open up `http://localhost:3000` in your browser of choice.

If everything is set up correctly we will receive the following log output.

```
[AppService] Hello World
```

That is cool. Though, we are lazy, aren't we? We do not want to explicitly write `this.logger.setPrefix('AppService')` in the constructor of our services? Something like `@Logger('AppService')` before our `logger`-parameter would be way less verbose and we would not have to define a constructor every time we want to use our logger.

## Logger Decorator

For our example, we do not need to exactly know how decorators work in TypeScript. All you need to know is that functions can be handled as a decorator.

Lets quickly create our decorator manually.

```bash
touch src/logger/logger.decorator.ts
```

We are just going to reuse the `@Inject()` decorator from `@nestjs/common`.

```typescript
// src/logger/logger.decorator.ts

import { Inject } from '@nestjs/common';

export const prefixesForLoggers: string[] = new Array<string>();

export function Logger(prefix: string = '') {
  if (!prefixesForLoggers.includes(prefix)) {
    prefixesForLoggers.push(prefix);
  }
  return Inject(`LoggerService${prefix}`);
}
```

You can think of `@Logger('AppService')` as nothing more than an alias for `@Inject('LoggerServiceAppService')`. The only special thing we have added is the `prefixesForLoggers` array. We will make use of this array later. This array just stores all the prefixes we are going to need.

But wait, our Nest application does not know anything about a `LoggerServiceAppService` token. So let's create this token using dynamic providers and our newly created `prefixesForLoggers` array.

## Dynamic providers

In this chapter, we want to have a look at dynamically generating providers.
We want to

- create a provider for each prefix
  - each of these providers must have a token like this `'LoggerService' + prefix`
  - each provider must call `LoggerService.setPrefix(prefix)` upon its instantiation

To implement these requirements we create a new file.

```bash
touch src/logger/logger.providers.ts
```

Copy & paste the following code into your editor.

```typescript
// src/logger/logger.provider.ts

import { prefixesForLoggers } from './logger.decorator';
import { Provider } from '@nestjs/common';
import { LoggerService } from './logger.service';

function loggerFactory(logger: LoggerService, prefix: string) {
  if (prefix) {
    logger.setPrefix(prefix);
  }
  return logger;
}

function createLoggerProvider(prefix: string): Provider<LoggerService> {
  return {
    provide: `LoggerService${prefix}`,
    useFactory: logger => loggerFactory(logger, prefix),
    inject: [LoggerService],
  };
}

export function createLoggerProviders(): Array<Provider<LoggerService>> {
  return prefixesForLoggers.map(prefix => createLoggerProvider(prefix));
}
```

The `createLoggerProviders`-function creates an array of providers for each prefix set by the `@Logger()` decorator. Thanks to the `useFactory` functionality of NestJS we can run a the `LoggerService.setPrefix()` method before the provider gets created.

All we need to do now is to add these logger providers to our `LoggerModule`.

```typescript
// src/logger/logger.module.ts

import { Module } from '@nestjs/common';
import { LoggerService } from './logger.service';
import { createLoggerProviders } from './logger.providers';

const loggerProviders = createLoggerProviders();

@Module({
  providers: [LoggerService, ...loggerProviders],
  exports: [LoggerService, ...loggerProviders],
})
export class LoggerModule {}
```

As simple as that. Wait no, that does not work? Because of JavaScript, man. Let me explain: `createLoggerProviders` will get called immediately once the file is loaded, right? At that point in time, the `prefixesForLoggers` array will be empty inside `logger.decorator.ts`, because the `@Logger()` decorator was not called.

So how do we bypass that? The holy words are [_Dynamic Module_](https://docs.nestjs.com/modules#dynamic-modules). Dynamic modules allow us to create the module settings (which are usually given as parameter of the `@Module`-decorator) via a method. This method will get called after the `@Logger` decorator calls and therefore `prefixForLoggers` array will contain all the values.

If you want to learn more about why this works, you may wanna check out this [video about the JavaScript event loop](https://www.youtube.com/watch?v=8aGhZQkoFbQ)

Therefore we have to rewrite the `LoggerModule` to a _Dynamic Module_.

```typescript
// src/logger/logger.module.ts

import { DynamicModule } from '@nestjs/common';
import { LoggerService } from './logger.service';
import { createLoggerProviders } from './logger.providers';

export class LoggerModule {
  static forRoot(): DynamicModule {
    const prefixedLoggerProviders = createLoggerProviders();
    return {
      module: LoggerModule,
      providers: [LoggerService, ...prefixedLoggerProviders],
      exports: [LoggerService, ...prefixedLoggerProviders],
    };
  }
}
```

Do not forget to update the import array in `app.module.ts`

```typescript
// src/logger/app.module.ts

@Module({
  controllers: [AppController],
  providers: [AppService],
  imports: [LoggerModule.forRoot()],
})
export class AppModule {}
```

...and that's it! Let's see if it works when we update the `app.service.ts`

```typescript
// src/app.service.ts

@Injectable()
export class AppService {
  constructor(@Logger('AppService') private logger: LoggerService) {}

  getHello() {
    this.logger.log('Hello World'); // Prints: '[AppService] Hello World'
    return 'Hello World';
  }
}
```

Calling `http://localhost:3000` will give us the following log

```
[AppService] Hello World
```

Yey, we did it!

## Conclusion

We have touched on numerous advanced parts of NestJS. We have seen how we can create simple decorators, dynamic modules and dynamic providers. You can do impressive stuff with it in a clean and testable way.

As mentioned we have used the exact same patterns for the internals of `@nestjs/typeorm` and `@nestjs/mongoose`. In the Mongoose integration, for example, we used a very similar approach for generating injectable providers for each model.

You can find the code in this [Github repostiory](https://github.com/BrunnerLivio/logger-app). I have also refactored smaller functionalities and added unit tests, so you can use this code in production.
