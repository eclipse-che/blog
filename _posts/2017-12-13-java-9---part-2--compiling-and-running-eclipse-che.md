---
layout: post
title: 'Java 9 — Part 2: Compiling and Running Eclipse Che'
description: >-
  In part 1 we got Java 9 working with our workspaces, now let’s see how we
  compile and run it with Java 9!
categories: []
keywords: []
slug: /@florent.benoit/java-9-part-2-compiling-and-running-eclipse-che
---

![](https://cdn-images-1.medium.com/max/800/1*Zv5KXdAW988QNEeyKlB83A.jpeg)

In the first post, I described what needed to be done to make Che workspaces run Java 9 (which means getting the Che server to run Java 9 too).

Now I want to explain what had to be done so contributors to the Che project could compile and run with Java 9.

The latest Eclipse Che stable release (v5) was designed and built on top of Java 8. So when a new version of the JDK, Java 9, was released we had to ensure that Eclipse Che could be built and run on top of Java 9 as well.

Eclipse Che uses many dependencies and in order to be compliant with Java 9 all dependencies need to be compliant as well. So making Eclipse Che compliant with Java 9 required a lot of updates.

### Compiling Eclipse Che with Java 9

**Maven and Java 9**

We had numerous failures when we first tried to build Eclipse Che with Java 9. Eclipse Che uses maven to build the project but when trying to build it most of the existing maven plugins were not ready to use Java 9 so we had to wait for those plugins to be updated.

Plus, as an Eclipse project when we update a component we have to file a CQ ([Contribution Questionnaire](https://wiki.eclipse.org/Development_Resources/Contribution_Questionnaire#Third_Party_Libraries)) for each one. With 20+ plugins to update it meant getting approval for each one.

[**Update plugins · eclipse/che-parent@d18be1d**  
_Change-Id: I90667d9a0a4d64294c10ac647b1cb176c3811fa1 Signed-off-by: Florent BENOIT_github.com](https://github.com/eclipse/che-parent/commit/d18be1d93dc4e1a5dbda7747c6012a6bc8c03907 "https://github.com/eclipse/che-parent/commit/d18be1d93dc4e1a5dbda7747c6012a6bc8c03907")[](https://github.com/eclipse/che-parent/commit/d18be1d93dc4e1a5dbda7747c6012a6bc8c03907)

After those plugins were updated, we still had issues around some Java components. Most of the failures were linked to the fact that in Java 9 the system class loader is no longer a `URLClassLoader` and many components assumed that and performed a cast to `URLClassLoader` …which would fail.

**JDK Reflection / Internal Classes**

The easiest problem to solve was with JDK reflection. We had some methods that performed internal introspection of JDK classes but these methods were not used anymore so instead of trying to fix them we simply removed them!

[**ai Remove unused SystemInfo attributes (cpu, freeMemory, totalMemory) by benoitf · Pull Request #6946…**  
_What does this PR do? In Java9, relying on "internal fields" of classes is not permitted by default. Only public…_github.com](https://github.com/eclipse/che/pull/6946 "https://github.com/eclipse/che/pull/6946")[](https://github.com/eclipse/che/pull/6946)

**JDK and** `**tools.jar**`

Until Java 9, when you required classes provided by `tools.jar` you had to add a system dependency in your pom.xml by using the path to the `tools.jar` file:

<dependency>  
  <groupId>sun.jdt</groupId>  
  <artifactId>tools</artifactId>  
  <scope>system</scope>  
  <systemPath>${java.home}/../lib/tools.jar</systemPath  
</dependency>

With Java 9, `tools.jar` is no longer there (modularity!) and classes are available with the JVM so we instead added this dependency in a maven profile that is only enabled if the Java version is lower than Java 9.

<profile>  
  <id>java8-tools</id>  
  <activation>  
    <jdk>(,1.9)</jdk>  
  </activation>  
  <dependencies>  
    <dependency>  
      <groupId>sun.jdt</groupId>  
      <artifactId>tools</artifactId>  
      <scope>system</scope>  
      <systemPath>${java.home}/../lib/tools.jar</systemPath>  
    </dependency>  
  </dependencies>  
</profile>

**Compiling?**

At that point when we tried to compile Eclipse Che by disabling all unit tests and checks it _almost_ worked. All the modules were marked `_“build success”_` until the last module that tried to build GWT app which…failed…oh no!

**GWT and Java9**

This meant we had to upgrade to GWT 2.8.2 to get Java 9 compliance. Note that you still have to use Java 8 language features, but GWT 2.8.2 allows you to use a Java 9 runtime.

[**GWT Project**  
_The 2.4 General Availability release of GWT contains new App Engine tools for Android, incremental RPC tooling, Apps…_www.gwtproject.org](http://www.gwtproject.org/release-notes.html#Release_Notes_2_8_2 "http://www.gwtproject.org/release-notes.html#Release_Notes_2_8_2")[](http://www.gwtproject.org/release-notes.html#Release_Notes_2_8_2)

After all these compiling dependencies updates it was finally possible to build Eclipse Che with Java9!

But we really wanted to have unit tests working as well! ;-)

**Che and Unit Tests with Java9**

We were using Mockito 1.x in Eclipse Che but to get Java 9 support we needed Mockito 2.10. This meant converting all existing tests to Mockito 2.x. This was quite a bit of work because some of classes which were deprecated in 1.x were removed in 2.x while other methods (like `any()`) handle `null` differently.

Last but not least, we were using a maven artifact named `mockito-all` and this artifact is no longer supported on 2.x so we had to remove it everywhere it was used (many, many places…).

Now tests could be launched but some failures were still reported on EclipseLink and Apache Lucene — the versions that we were using of those were not compliant with Java 9.

After upgrading EclipseLink to 2.7.0, and Lucene to 7.0.1 the issues were solved. For Lucene we’d previously used version 5.2.1 so it was a big update to move to 7.0.1.

**GWT Mockito  
**As before the last unit tests that needed fixing were related to the GWT Mockito tests. Specifically, there was an issue with `classloaders`

```
Caused by: java.lang.IllegalAccessError: class jdk.internal.reflect.ConstructorAccessorImpl loaded by com/google/gwtmockito/GwtMockitoTestRunner$GwtMockitoClassLoader cannot access jdk/internal/reflect superclass jdk.internal.reflect.MagicAccessorImpl	at java.base/java.lang.ClassLoader.defineClass1(Native Method)	at java.base/java.lang.ClassLoader.defineClass(ClassLoader.java:1007)	at java.base/java.lang.ClassLoader.defineClass(ClassLoader.java:868)	at javassist.Loader.findClass(Loader.java:377)	at com.google.gwtmockito.GwtMockitoTestRunner$GwtMockitoClassLoader.findClass(GwtMockitoTestRunner.java:421)
```

A pull request was merged but we have not yet released.

[**Make jdk.internal.reflect package being loaded by the standard classloader by benoitf · Pull…**  
_It avoids error like Caused by: java.lang.IllegalAccessError: class jdk.internal.reflect.ConstructorAccessorImpl loaded…_github.com](https://github.com/google/gwtmockito/pull/73 "https://github.com/google/gwtmockito/pull/73")[](https://github.com/google/gwtmockito/pull/73)

With all the updates and patches we finally had Eclipse Che compiling with all unit tests when using Java 9 (my tests were with Oracle JDK on macOS)

```
java version "9.0.1"Java(TM) SE Runtime Environment (build 9.0.1+11)Java HotSpot(TM) 64-Bit Server VM (build 9.0.1+11, mixed mode)
```

### Running

OK great — Eclipse Che was compiling, tests were working, but could we launch Che with Java 9?

Quick answer…no :-(

Eclipse Che uses APIs provided in the `javax` namespace (`javax.activation` and `javax.xml.bind`). With Java 9, all packages that are not in the`java` namespace are not exposed by default.

So we had to enable extra modules when using Java 9 or higher:

JAVA\_OPTS="$JAVA\_OPTS --add-modules java.activation --add-modules java.xml.bind"

You may notice that the name of the modules are just `java.xxx` not `javax.xxx` — that’s not a typo, `java.activation` provides the `javax.activation` package at runtime.

With that flag Eclipse Che was finally able to start!

But there was a big stack trace in Tomcat saying that the `logging.properties` file was not found. This file was found in `java.home/lib` folder previously but in Java 9 it’s moved to the `conf` folder.

So we needed a Tomcat version change that included that fix.

[**Tomcat - Dev - svn commit: r1809831 - in /tomcat/tc8.5.x/trunk: ./ java/org/apache/juli…**  
_svn commit: r1809831 - in /tomcat/tc8.5.x/trunk: ./ java/org/apache/juli/ClassLoaderLogManager.java webapps/docs…_tomcat.10.x6.nabble.com](http://tomcat.10.x6.nabble.com/svn-commit-r1809831-in-tomcat-tc8-5-x-trunk-java-org-apache-juli-ClassLoaderLogManager-java-webapps-l-td5067695.html "http://tomcat.10.x6.nabble.com/svn-commit-r1809831-in-tomcat-tc8-5-x-trunk-java-org-apache-juli-ClassLoaderLogManager-java-webapps-l-td5067695.html")[](http://tomcat.10.x6.nabble.com/svn-commit-r1809831-in-tomcat-tc8-5-x-trunk-java-org-apache-juli-ClassLoaderLogManager-java-webapps-l-td5067695.html)

By using Tomcat 8.5.23 we could move forward.

Finally!

**Eclipse Che is Now Compiling and Running with Java 9!**

As always please let us know your thoughts by connecting with us on twitter @eclipse\_che or by filing issues in the Che GitHub repo at [https://github.com/eclipse/che](https://github.com/eclipse/che)