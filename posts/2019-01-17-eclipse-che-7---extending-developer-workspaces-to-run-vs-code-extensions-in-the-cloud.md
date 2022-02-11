---
layout: post
title: Eclipse Che 7 — Extending developer workspaces to run VS Code extensions in the cloud
author: Florent Benoit
description: >-
  A plug-in model added to Eclipse Theia to support VS Code extensions and run
  them in cloud developer workspaces with Eclipse Che.
categories: []
keywords: []
slug: >-
 /@florent.benoit/eclipse-che-7-extending-developer-workspaces-to-run-vs-code-extensions-in-the-cloud
---

Over the last month, the Eclipse Che community has been adopting Eclipse Theia as the default web IDE provided with Che developer workspaces. We’ve enriched the Eclipse Theia with a plug-in model to provide VS Code extension compatibility. This blog post explain why we decided to add the plug-in model to Eclipse Theia and what are the benefits when it’s used with Eclipse Che developer workspaces .

![](https://cdn-images-1.medium.com/max/800/0*lQP7_HqXIafdcecV.jpg)

In [Eclipse Che](https://www.eclipse.org/che) 6, it is possible to develop and plug-ins on top of the GWT IDE but it is not possible to load them at runtime without stopping/recompiling and then reloading the IDE.

### The Requirements

A lot of people wanted to improve that extensibility model. For the upcoming version of [Eclipse Che](http://eclipse.org/che), Che 7, we ended up with the following requirements:

![](https://cdn-images-1.medium.com/max/800/1*G2fjiJG3NWqw8hPWJgVDfg.png)

1.  Plug-ins should be loaded at runtime easily and it should not involve any compilation step at that time. Plug-in should be already compiled and IDE should only load the code.

![](https://cdn-images-1.medium.com/max/800/1*vUEntDKhbofTukMqGgyKkg.png)

2\. A plug-in shouldn’t break the whole IDE if it is not well written. For example if I load a broken plug-in, I should still be able to use the current IDE

![](https://cdn-images-1.medium.com/max/800/1*rNDJzvEAo17bvtMVjEdQ0g.png)

3\. In [Eclipse Che](http://eclipse.org/che), we wanted to guarantee that any plug-in shouldn’t block the main functions of the IDE like opening a file or typing. It could allow to identify if it’s the main product that has issue or if it’s due to a specific plug-in. Also, if two plug-ins are relying on the same dependency but in different versions it shouldn’t be a problem as well, each plug-in using its own dependency.

### Existing IDE

![](https://cdn-images-1.medium.com/max/800/1*DAEuLnhX-i4Xy0rbuQfLiQ.png)

The current IDE (Eclipse Che 6) requires to recompile the whole IDE when a new plug-in is added. Some experiments were made to use [JS-Interop](http://www.gwtproject.org/doc/latest/DevGuideCodingBasicsJsInterop.html) to dynamically load JavaScript plug-ins. But we need to take into consideration that many people dislike GWT, by saying it’s a technology of the past.

The API provided is a low-level API. It’s a great API but as you can change everything you can also break everything. And it is difficult to know each entry point.

### Alternative

[Eclipse Theia](https://www.eclipse.org/theia) has been considered to be the alternative IDE in [Eclipse Che](http://eclipse.org/che). This IDE can be embedded and used in [Eclipse Che](http://eclipse.org/che) as it’s a web based IDE and use modern technologies like [React](https://reactjs.org/) and is written in [TypeScript](https://www.typescriptlang.org/). This IDE had only a single extension model: Theia extension.

The problem is that this extension model was mainly designed to develop customs IDE so it has issues for our requirements:

![](https://cdn-images-1.medium.com/max/800/1*RkQfX6SQfxESxkNPdcBXaw.png)

With Eclipse Theia extensions, once a new Theia extension is added, the whole IDE is recompiled. If an extension is not so clean, you may broke the full IDE. It’s a problem when you want to allow users to add custom plug-ins.  
Let’s imagine you open a Che workspace and you see a blank page due to a compilation failure instead of the IDE…

![](https://cdn-images-1.medium.com/max/800/1*iL2dsirgV1lc9hnEv4uE3g.png)

Extensions are retrieved from npmjs repository. It’s nice but npmjs has tons of libraries and when you install an extension, it will download all dependencies again and again. If you’ve many dependencies, it may break. You might want to use a local repository easily as well.

![](https://cdn-images-1.medium.com/max/800/1*v9Q4xIot0okskDI8IfXmPw.png)

Theia extensions allow to customize the whole IDE but as for the GWT IDE in Eclipse Che 6, extensions may easily break the full IDE.

![](https://cdn-images-1.medium.com/max/800/1*WGG-1miS8yq1iguGoDip4w.png)

It’s very nice when you are advanced users or power users but when you want to write your first extension, you’ve to master [inversify](http://inversify.io/) and dependency injection and also you need to know which class is doing what and which interface you need to implement.

![](https://cdn-images-1.medium.com/max/800/1*eapMvHtrxK92E9wYh9CV-A.png)

So this extension model was not matching the requirements. At Red Hat, we decided to bring another extensibility model into Eclipse Theia: the Theia plug-ins

### Theia plug-ins

This new extensibility model has been integrated into Eclipse Theia upstream.

Here are key aspects of Theia plug-ins:

![](https://cdn-images-1.medium.com/max/800/1*hgD983O-549v2IzMMmx-SA.png)

Plug-ins can be loaded at any time at the runtime without having to restart/refresh the IDE.

![](https://cdn-images-1.medium.com/max/800/1*5Gyw2iLfSa-bIdwoVS5czQ.png)

Eclipse Theia plug-ins are packaged into `.theia` files and contain all the runtime code for the plug-ins. No need to download anything else when you load this plug-in at runtime.

![](https://cdn-images-1.medium.com/max/800/1*9l4NrkIGBqwvCR1ibEOUtQ.png)

You might want to bring a dependency injection framework into your plug-in but it’s up to you. The model is as simple as importing only once namespace `@theia/plugin` (through npmjs package `@theia/plugin`) and you can get all stuff from this entry point with code completion on this object. Then you implement the lifecycle of your plug-in by implementing `start`and `stop` functions.

#### Sample code of a theia plug-in

![](https://cdn-images-1.medium.com/max/800/1*zY8tCWOmX4YpUF5M0DtfOw.png)

It is a protocol. It means that we can run plug-ins anywhere. Some plug-ins can run in worker threads of the browser (they are called frontend plug-ins) or it can run on server side on separate processes (backend plug-ins). It’s easy to handle other kind of namespace, including VS Code extensions.

![](https://cdn-images-1.medium.com/max/800/1*N7ch7PdCcOkKtcknz-5jkQ.png)
![](https://cdn-images-1.medium.com/max/800/1*HbPE-preYemMYHCBHeSX9g.png)

It’s backward compliant. As plug-in model is provided through a TypeScript declaration file, even if the implementation of this model is entirely rewritten or if code refactoring is done on many Eclipse Theia classes, the model stay unchanged.

![](https://cdn-images-1.medium.com/max/800/1*hKt1gsZTkWN0glPnJKfu4w.png)

As it’s a high level API, you may not be able to break the whole IDE but you may not do what you want in the way you want but surely there are many possibilities.

#### Container Ready

![](https://cdn-images-1.medium.com/max/800/1*n5Acsc2XWmy9RJVy6vSWQw.png)

Eclipse Che is using containers for the tooling. Theia plug-ins are written in TypeScript/Javascript and it works well. But sometimes, plug-ins writers need some dependencies that are not only pure `npmjs` dependencies. For example if people write a Language Server for Java, this plug-in will probably require java. So it might implies that the container that runs Eclipse Theia should have java already installed on it.

This is why in Eclipse Che, it’s possible to run each Eclipse Theia plug-in in its own container, allowing to use any system dependency from this plug-in.

![](https://cdn-images-1.medium.com/max/800/1*jWMXjumXc-n3dH2UvTyDug.png)

By default all plug-ins are executed as separate processes in the Theia container.

### VS Code Extensions

![](https://cdn-images-1.medium.com/max/600/1*kPPtr8GFjknmji2-pTECEQ.png)

Eclipse Theia Plug-in protocol being extensible, support of VS Code API is being added inside Eclipse Theia. It allows to have some VS Code extensions running inside Eclipse Theia.

For example it’s possible to use SonarLint VS Code extension from VS Code marketplace

![](https://cdn-images-1.medium.com/max/800/0*gZ8B07jSd6On5t--)
![](https://cdn-images-1.medium.com/max/800/1*BCuitm8DmPZIR8zqm5bVrA.gif)
![](https://cdn-images-1.medium.com/max/800/0*PHuAGo4Blrt99k_q)

### Try Eclipse Che 7 Now!

Want to give a try to the new version of Eclipse Che 7? Try the following:

**Click on** the following factory URL : [https://che.openshift.io/f?id=factoryvbwekkducozn3jsn](https://che.openshift.io/f?id=factoryvbwekkducozn3jsn)

**Or Create your account** on [che.openshift.io](https://che.openshift.io), **create a new workspace** and select “Che 7” stack.

![](https://cdn-images-1.medium.com/max/800/1*PChYzMeZ55Q7dJ4c3A1WSA.png)

You can also test that **locally**, by installing the latest version of Eclipse Che: [Quick Start with Eclipse Che](http://www.eclipse.org/che/docs/#getting-started).

### Want to learn more?

Blog post about Eclipse Che 7:

*   Read the [blog post serie about Eclipse Che 7](https://medium.com/p/64d79b75ca02).

### Get Involved!

[Quick Start with Eclipse Che](http://www.eclipse.org/che/docs/#getting-started).

Join the community:

*   **Support**: You can ask questions, report bugs, and request features using [GitHub issues](https://github.com/eclipse/che/issues).
*   **Public Chat**: Join the public [eclipse-che](https://mattermost.eclipse.org/eclipse/channels/eclipse-che) Mattermost channel to discuss with community and contributors.
*   **Weekly Meetings**: Join us in our [Che community meeting](https://github.com/eclipse/che/wiki/Che-Dev-Meetings) every second monday.
*   **Mailing list**: che-dev@eclipse.org