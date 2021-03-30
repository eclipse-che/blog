---
layout: post
title: 'Discover Che 7: devfile'
author: Florent Benoit
description: Developer environments as code
categories: []
keywords: []
slug: /@florent.benoit/discover-che-7-devfile
---

[In a previous blog post](https://che.eclipse.org/discover-eclipse-che-7-7515e74a99ca), we’ve experimented ready-to-use workspaces and how to write/run/debug code easily.

But when we are open a ready-to-use workspace, it seems that there is some magic:

*   The runtime already has language tooling
*   There is code completion with pre-installed plug-ins for the given language
*   The project is already cloned into the workspace, and we have commands to build, debug and manipulate the runtime

In this blog post, we’ll discover what drives this workspace magic: the devfile.

#### Definition

A devfile defines the configuration of the workspace, which is the developer’s environment. This definition is portable - we can create any number of identical workspaces from the same devfile. Anyone can share a devfile and everyone using this devfile will get the same workspace including projects, tooling, commands, etc…

![](https://cdn-images-1.medium.com/max/800/0*o_SxIc5VuMqc0BtS.png)

#### Explore

To make exploration easier, we’ll use the hosted Eclipse Che service (version 7) run by Red Hat at [https://che.openshift.io](https://che.openshift.io).

For our example, let’s start with a pre-built workspace Stack: From the user dashboard, click on Stacks in the left nav bar.

![](https://cdn-images-1.medium.com/max/800/1*edyrQNdKqzpJC9jhh3MQLA.png)

Now click on Python stack:

![](https://cdn-images-1.medium.com/max/800/1*8rOhOHjaU4cdimuJXeGjlA.png)

The raw configuration section shows the devfile content:

![](https://cdn-images-1.medium.com/max/800/1*rYww8WAOL7YbRjhNzFwWxQ.png)
undefined

### Deconstructing the devfile

#### Metadata

`metadata.generateName` is used for the workspace prefix name. When a user creates a workspace from the devfile, their workspace name will be named `python-<random-4-digits-id>`. By using instead of `generateName metadata.name` there will be no prefix so workspace names will all use only that name, however, if a single user tries to create a second workspace from the same devile, they’ll get an error notifying them that they can’t create another workspace because one with that name already exists.

#### Projects

Describes the projects to clone into the workspace. The `type` field can be `git` or `zip`. In this case, we’re using git so we specify the repository URL (there can be multiple URLs to clone in multiple projects).

projects:  
 -  
  name: python-hello-world  
  source:  
   type: git  
   location: '[https://github.com/che-samples/python-hello-world.git'](https://github.com/che-samples/python-hello-world.git%27)

Alternatively, when using the `zip` type you can link to a zip file containing the project source code.

#### Components

This example devfile uses two kind of components: a Che plug-in and a docker image.

\-  
  type: **chePlugin**  
  id: ms-python/python/latest  
  memoryLimit: 512Mi  
 -  
  type: **dockerimage**  
  alias: python  
  image: 'quay.io/eclipse/che-python-3.6:nightly'  
  memoryLimit: 512Mi  
  mountSources: true

The `cheplugin` type is used for plugins in the Eclipse Che plug-in registry. The `id` field includes the vendor name, name and version divided by slashes. In this case, `latest` is an alias to the latest stable definition of the plug-in. This Che Plug-in is a VS Code extension that is instantiated in a sidecar container with its own code and dependencies. This is held outside the source code container so that it doesn’t “pollute” the behaviour of the project itself.

The `dockerimage` type is used to generate the runtime container. In this case that includes everything in the `che-python-3.6` nightly container build. The `alias` is what will be used to identify this container when we want commands executed in it (we’ll cover that in the next section). Setting the `mountSources` flag to `true` will make the projects source code available inside this container. Typically in the`/projects` folder. If you make it `false` then there will be no folder that uses attached storage (this is fine for certain use cases like teaching examples where code changes don’t need to be retained after the course unit is completed).

`memoryLimit` can be given in either case to change the default memory allocation.

#### Commands

Commands defined in the devfile will be available in the IDE.

commands:  
\-  
  name: run  
  actions:  
   -  
    type: exec  
    component: python  
    command: python hello-world.py  
    workdir: '${CHE\_PROJECTS\_ROOT}/python-hello-world'

In this example a new `run` command is defined. It is executing the `hello-world.py` source file with the python interpreter. The working directory is set with the `workdir` line.

The `component: python` line tells Che to execute this command in the container with the `python` alias (we defined that in the section above).

Variables can be used in commands like `${CHE_PROJECTS_ROOT}` to specify the folder where the source code is mounted in the container.

#### Experiment with devfiles for yourself

You can click on different stacks from the Che user dashboard and see the associated devfile — this is a great way to discover more examples.

Read about the full devfile schema at [https://redhat-developer.github.io/devfile/devfile](https://redhat-developer.github.io/devfile/devfile)

### Get Involved!

[Quick Start with Eclipse Che](http://www.eclipse.org/che/docs/#getting-started).

Join the community:

*   **Support**: You can ask questions, report bugs, and request features using [GitHub issues](https://github.com/eclipse/che/issues).
*   **Public Chat**: Join the public [eclipse-che](https://mattermost.eclipse.org/eclipse/channels/eclipse-che) Mattermost channel to discuss with community and contributors.
*   **Weekly Meetings**: Join us in our [Che community meeting](https://github.com/eclipse/che/wiki/Che-Dev-Meetings) every second monday.
*   **Mailing list**: che-dev@eclipse.org