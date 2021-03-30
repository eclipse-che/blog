---
layout: post
title: 'Java 9 — Part 1: Using Java 9 in Eclipse Che'
author: Florent Benoit
description: In this post I’ll explain how you can run Java 9 workspaces in Eclipse Che.
categories: []
keywords: []
slug: /@florent.benoit/java-9-part-1-using-java-9-in-eclipse-che
---

![](https://cdn-images-1.medium.com/max/800/1*0ij42CnBwH2OdQaeg0ftAA.png)
undefined

In this post I’ll explain how you can run Java 9 workspaces in Eclipse Che.

**Background**

Eclipse Che uses the Eclipse JDT (Java Development Tools) to do all the Java language services in the IDE (code completion, refactoring, etc...). Now that Eclipse Che is moving towards using only LSP (Language Server Protocol) implementations it’s easier to maintain these language services, and there is a clear separation between the `IDE` part and the `language` part.

With Che 5.x, we had a JDT instance running on the server side. It was a custom JDT patched to get rid of all the UI that we couldn’t use in the browser-based Che IDE.

With Che 6 (usable now but due to GA in January 2018) we now have a JDT instance packaged as part of `jdt.ls` language server protocol implementation.

[**eclipse/eclipse.jdt.ls**  
_eclipse.jdt.ls - Java language server_github.com](https://github.com/eclipse/eclipse.jdt.ls "https://github.com/eclipse/eclipse.jdt.ls")[](https://github.com/eclipse/eclipse.jdt.ls)

You may know already that the `eclipse.jdt.ls` was developed by Red Hat and is also used for the Java extension on VS Code.

[**Language Support for Java(TM) by Red Hat - Visual Studio Marketplace**  
_Extension for Visual Studio Code - Language Support for Java(TM) for Visual Studio Code provided by Red Hat_marketplace.visualstudio.com](https://marketplace.visualstudio.com/items?itemName=redhat.java "https://marketplace.visualstudio.com/items?itemName=redhat.java")[](https://marketplace.visualstudio.com/items?itemName=redhat.java)

It means that all improvements, bugfixes, etc. that are done inside `jdt.ls` are then shared for many products — the true meaning of Christmas (and community)!

However, in Eclipse Che there are a few things for Java that aren’t part of the Language Server Protocol — these Che-specific items have been built into the Che `jdt.ls` project: [https://github.com/eclipse/che-ls-jdt](https://github.com/eclipse/che-ls-jdt)

Now that we had a language server compliant with Java 9 we needed to enable it in Che. For now this work is only available through a feature branch named `5730_Java_ls_poc`in the Che repo. So I needed to build this branch and then create Docker images for it so that others (like you) that want to try it don’t need to checkout or build a branch!

You can skip the next section if you only want to run your workspace and aren’t interested in rebuilding Che (it’s not necessary to).

**Building Che Server Docker Images**

After successfully building the branch I can also make the Che server Java 9 compliant.

We could use Alpine Linux with Java 9 to have a small image but there is no OpenJDK9/Alpine yet. And it’s probably not going to happen soon based on the following issue.

[**Create 9-alpine · Issue #100 · docker-library/openjdk**  
_Can we get a JDK 9 on alpine 3.5?_github.com](https://github.com/docker-library/openjdk/issues/100 "https://github.com/docker-library/openjdk/issues/100")[](https://github.com/docker-library/openjdk/issues/100)

As part of experimenting with stuff, let’s use Eclipse OpenJ9 — a JVM under the Eclipse Foundation (obviously we’re fans of the Foundation).

[**OpenJ9**  
_Eclipse OpenJ9 is a high performance, scalable, Java virtual machine (JVM) implementation that represents hundreds of…_www.eclipse.org](https://www.eclipse.org/openj9/ "https://www.eclipse.org/openj9/")[](https://www.eclipse.org/openj9/)

AdoptOpenJDK provides a Docker image we can use:`adoptopenjdk/openjdk9-openj9`

[https://hub.docker.com/r/adoptopenjdk/openjdk8-openj9/](https://hub.docker.com/r/adoptopenjdk/openjdk8-openj9/)

I’ve used the following Dockerfile to build the Che image.

[**eclipse/che**  
_che - Eclipse Che: Next-generation Eclipse IDE. Open source workspace server and cloud IDE._github.com](https://github.com/eclipse/che/blob/6901e5360949468dae6bcbc16ec25e57d13f5c91/dockerfiles/che/Dockerfile.openj9 "https://github.com/eclipse/che/blob/6901e5360949468dae6bcbc16ec25e57d13f5c91/dockerfiles/che/Dockerfile.openj9")[](https://github.com/eclipse/che/blob/6901e5360949468dae6bcbc16ec25e57d13f5c91/dockerfiles/che/Dockerfile.openj9)

In the end, I’ve successfully build the server image from the `jdt.ls` branch named `florentbenoit/che-server:jdtls` and it’s based on the OpenJ9 `adoptopenjdk/openjdk9-openj9` Docker image. I’ve also published the image so everyone can use it.

**Using Java 9 in my Workspace**

Let’s start Eclipse Che. I’m using `/tmp/jdtls` as folder to store the data.

$ docker run -it --rm -v /var/run/docker.sock:/var/run/docker.sock -v /tmp/jdtls:/data florentbenoit/che:jdtls start --fast

The output should look like:

INFO: Proxy: HTTP\_PROXY=, HTTPS\_PROXY=, NO\_PROXY=\*.local, 169.254/16  
INFO: (che cli): jdtls - using docker 17.11.0-ce / docker4mac  
INFO: (che config): Generating che configuration...  
INFO: (che config): Customizing docker-compose for running in a container  
INFO: (che start): Starting containers...  
INFO: (che start): Services booting...  
INFO: (che start): Server logs at "docker logs -f che"  
INFO: (che start): Booted and reachable  
INFO: (che start): Ver: jdtls  
INFO: (che start): Use: [http://localhost:8080](http://localhost:8080)  
INFO: (che start): API: http://localhost:8080/swagger

We can check that the server is running Java 9:

$ docker logs 2>&1 che | grep "JVM "  
\- JVM Version:           9-internal+0-adhoc.jenkins.openjdk  
\- JVM Vendor:            Eclipse OpenJ9

Great, let’s connect to [http://localhost:8080](http://localhost:8080) and create a new workspace.

Since this is all new work, we’ll need to create a custom Che workspace with Java 9 installed — luckily that’s not hard! I’ve published a `florentbenoit/ubuntu_jdk9` Docker image containing OpenJDK9 on top of the `ubuntu:17.10` Docker image. It also includes maven.

![](https://cdn-images-1.medium.com/max/800/1*3-5AQ1wfiSBkR7ngZi2h2g.png)
undefined

Check that the image is set to `florentbenoit/ubuntu_jdk9.`

Also, be sure that the Java LSP agent is enabled, if it’s not you won’t get any of the language server features like code completion, etc…

You can show the config of the workspace and it should include the agent `org.eclipse.che.ls.java` (line 28 below)

![](https://cdn-images-1.medium.com/max/800/1*gjAw6gkwDYudDvUKvcLPjQ.png)
undefined

When the correct Docker image is set and the Java LS agent is defined, we can start the workspace.

![](https://cdn-images-1.medium.com/max/800/1*lrOK-v6wStCp7dlT_dkKHg.png)
![](https://cdn-images-1.medium.com/max/800/1*NoVT59PVuDSp5_eOCisojQ.png)

Let’s import a maven project from [https://github.com/benoitf/jdtls-maven-example](https://github.com/benoitf/jdtls-maven-example)

[**benoitf/jdtls-maven-example**  
_jdtls-maven-example - Java9 + maven + jdt.ls example_github.com](https://github.com/benoitf/jdtls-maven-example "https://github.com/benoitf/jdtls-maven-example")[](https://github.com/benoitf/jdtls-maven-example)

After the project is imported, you can then try to type Java 9 code. You should have code completion and javadoc for Java 9 features.

![](https://cdn-images-1.medium.com/max/800/1*H2VsxhKLgzWKZgnHX60tkg.gif)

Voilà! You can use Java 9 inside your projects now!

In the next post we’ll look at how to compile and run the Che project (as a contributor) with Java 9.

As always please let us know your thoughts by connecting with us on twitter @eclipse\_che or by filing issues in the Che GitHub repo at [https://github.com/eclipse/che](https://github.com/eclipse/che)