---
title: Devfile v2 and IDE plug-ins
layout: post
author: Florent Benoit
description: >-
  How are IDE plug-ins handled with devfile v2
categories: []
keywords: ['devfile', 'ide', 'plug-ins']
slug: /@florent.benoit/devfile-v2-and-ide-plug-ins
---

### Definition

Devfile has been incubated by Eclipse Che project providing [devfile v1 specification](https://redhat-developer.github.io/devfile/).

To allow other projects to use a common definition, devfile has moved out of Eclipse Che. It has its own definition at [https://devfile.io](https://devfile.io) with current [v2.1.0 specification](https://docs.devfile.io/devfile/2.1.0/user-guide/api-reference.html).

Devfile v1 were handled by Eclipse Che Server workspace engine using Java/Kubernetes API. There is a new engine for devfile v2 called DevWorkspace Controller. The source code is at: [https://github.com/devfile/devworkspace-operator](https://github.com/devfile/devworkspace-operator).

DevWorkspaces are custom kubernetes resources and can be created/listed/deleted using kubernetes tools like `kubectl`.

A DevWorkspace is a workspace using the new engine and supporting devfile V2 definition.

### Milestones

Devfile v2 support in Eclipse Che can be followed by milestones.

*   [Milestone 1](https://github.com/eclipse/che/milestone/136) introduced the first support of devfile v2 (start a basic workspace)
*   [Milestone 2](https://github.com/eclipse/che/milestone/139) just landed in Eclipse Che 7.32.0 with the support of Theia plug-ins for DevWorkspaces
*   [Milestone 3](https://github.com/eclipse/che/milestone/140) is the next target, including Kubernetes support and more.

### How to test ?

The support of devfile v2/DevWorkspaces is optional and need to be opt-in.  

When the support is enabled, both devfile v1 and v2 are supported. You can still work with your previous workspaces and devfile v1.

* If the `devfile.yaml` has `apiVersion 1.0.0`, it will use che server workspace engine to deploy this devfile.
* If the `devfile.yaml` has `schemaVersion 2.0.0` (or greater like `2.1.0`), it will use the DevWorkspace controller to deploy this devfile.

⚠️ DevWorkspaces requires OpenShift as platform until Milestone 3 is reached (no support of plain Kubernetes yet)

ℹ️ Enabling DevWorkspace is also defaulting installation to use single-host deployment. So no need to install certificates on your computer.

To enable DevWorkspaces, use a custom spec object for Che Operator:  

Creates a file in your `${HOME}` folder for example `${HOME}/enable-devfilev2.yaml` with the following content:

```yaml
spec:  
  devWorkspace:  
    enable: true
```

Install Eclipse Che (latest stable ≥7.32 or next channel) with chectl:
```bash
$ chectl update next # (or stable)  
$ chectl server:deploy --che-operator-cr-patch-yaml=${HOME}/enable-devfilev2.yaml
```

Then, search for the Dashboard link in the chectl output:
```
✔ Eclipse Che 7.33.0-SNAPSHOT has been successfully deployed.  
  ✔ Documentation        : [https://www.eclipse.org/che/docs/](https://www.eclipse.org/che/docs/)  
  ✔ -------------------------------------------------------------  
  ✔ Users Dashboard      : https://che-eclipse-che.my-che.com/  
  ✔ -------------------------------------------------------------  
```  

Opening the Dashboard page will display the new getting started:

![Getting Started]({{ site.url }}{{ site.baseurl }}/assets/img/devfile-v2-and-ide-plugins/dashboard-getting-started.png)

Clicking on a sample will use a devfile v2 and the DevWorkspace engine.

ℹ️ [Installation guide is also available in Che documentation](https://www.eclipse.org/che/docs/che-7/installation-guide/enabling-dev-workspace-engine/)

### Updating from devfile v1

While the syntax between v1 and v2 yaml definition is close, there is a major change in the DevWorkspace definition: the IDE plug-ins are no longer part of the devfile.

It brings more clarity: for example, it was possible to specify a java plug-in but if the editor was not Eclipse Theia then there was no Java plug-in in the resulting workspace. Also when using other tools that don’t provide IDE like [odo](https://developers.redhat.com/products/odo/overview), when consuming the devfile definition, these plug-ins were not available.

Another change in the lifecycle of a workspace is that the project clone operation is done by the DevWorkspace engine. So whatever editor is picked-up, project is always cloned in `/projects/<your-project>` location after the workspace is started (no matter if there is an editor/IDE or not)

### Plug-ins definition

#### IDE preferences

While IDE plug-ins are no longer part of the devfile.yaml, instead or reinventing how to specify a plug-in for IDE, the idea was to leverage existing plug-in definition of the IDEs.

Example: VS Code has `.vscode/extensions.json` file where plug-ins can be recommended.

Eclipse Che will use this input by adding these VS Code extensions to the DevWorkspace.

Specifying

```json
{  
  "recommendations": [
    "redhat.java"  
  ]  
}
```

in `.vscode/extensions.json` will automatically install `redhat/java` VS Code extension in the Eclipse Che workspace.

Note: if the specified set of extensions IDs are not available in the Eclipse Che plug-in registry, it won’t fail but the extensions won’t be available.

Current plug-ins are available at registry at [https://eclipse-che.github.io/che-plugin-registry/main/v3/plugins/](https://eclipse-che.github.io/che-plugin-registry/main/v3/plugins/) which is updated on every commit on the main branch of the plug-in registry.

#### Custom definition

Relying on `.vscode/extensions.json` is great but sometimes some specific settings could be provided in addition to that file.

Here comes the `.che/che-theia-plugins.yaml` optional file.

For example, overriding some container settings like the memoryLimit for the `redhat.java` plug-in.

```yaml
- id: redhat/java  
  override:  
    sidecar:  
      memoryLimit: 2Gi
```

#### Inlining

Sometimes it may not be possible to add the `.vscode/extensions.json` or the `.che/che-theia-plugins.yaml` files inside the repository.

Inlining the content of these files in the `devfile.yaml` file is somehow possible using the following syntax of the devfile:
```yaml
schemaVersion: 2.1.0  
metadata:  
  name: my-example  
attributes:  
  .vscode/extensions.json: |  
    {  
      "recommendations": [  
        "redhat.java"  
      ]  
    }
```

To inline `.che/che-theia-plugins.yaml` :
```yaml

schemaVersion: 2.1.0  
metadata:  
  name: my-example  
attributes:  
  .che/che-theia-plugins.yaml: |  
    - id: redhat/java
```


### Workflow of handling IDE plug-ins with workspaces

![devfile v2 workflow]({{ site.url }}{{ site.baseurl }}/assets/img/devfile-v2-and-ide-plugins/devfile2-workflow.png)

### New Features for plug-ins

While there is big change by excluding the IDE plug-ins from the devfile, each editor can bring new features more easily, as each editor is handling the DevWorkspace templates update based on some definition of files (like optional `.vscode/extensions.json`or `.che/che-theia-plugins.yaml` files)

#### Deploy plug-ins in existing containers

By default, in Eclipse Che and when using Eclipse Theia editor, IDE plug-ins are deployed either in the Che-Theia container (when it only requires nodejs runtime) or through a new sidecar container (for example for Java, Go, Python, Php, etc.)

Now, there is a new attribute of the devfile specific to Che-Theia:
```yaml
attributes:  
  che-theia.eclipse.org/sidecar-policy: USE_DEV_CONTAINER
```

In that case, all plugins requiring a sidecar will be deployed in the `user defined container` and not bring any sidecar container.

Example:

If a repository contains these two files:

1. `devfile.yaml` with the following content:
```yaml
schemaVersion: 2.1.0  
metadata:  
  name: my-example  
attributes:  
  che-theia.eclipse.org/sidecar-policy: USE_DEV_CONTAINER
components:  
  - name: tools  
    container:  
      image: registry.access.redhat.com/ubi8/openjdk-11  
      command: ['tail']  
      args: ['-f', '/dev/null']
```
2. And the file `.vscode/extensions.json` containing
```json
{  
   "recommendations":[
      "redhat.java"  
   ]  
}
```

The plug-in `redhat.java` will be started inside the tools container and not bring another sidecar container.

It also means that all dependencies required by the plug-ins need to be there else the VS Code java extension may fail to start.

#### Prebuilt DevWorkspace templates

Today, the flow is the following with devfile v1: user pickup a getting started, then dashboard fetches the devfile then plug-in broker will analyze the devfile.yaml and fetch content from linked plug-in registries, parse the meta.yaml of these plug-ins to find sidecar definition, and then at the end some containers are added.

With devfile v2, there is still these kind of steps where a lot of yaml/json files are fetched, analyzed to result at the end in a set of DevWorkspace templates.

The Che-Theia library allows to generate a single yaml file with all the analysis being done offline.

npx @eclipse-che/che-theia-devworkspace-handler --devfile-url:[https://github.com/che-samples/spring-petclinic/tree/devfilev2](https://github.com/che-samples/spring-petclinic/tree/devfilev2) --output-file:$(pwd)/all-in-one.yaml

Then this file can be used directly by `kubectl` :

`kubectl apply -f all-in-one.yaml -n my-namespace`

These templates can be stored in the devfile registry so Eclipse Che dashboard could directly use this content instead of processing at every click the full analysis.

### Plug-in registry changes

For the workspaces using devfile v1, Eclipse Che server fetches meta.yaml files from the plug-in registry. There are some limitations, for example defining plug-in preferences is only possible if there is a sidecar being defined, etc.

With DevWorkspaces, the plug-in registry export now the content provided in different formats. It still export meta.yaml but it also expose devfile.yaml files for Eclipse Che editors definition and for some plug-ins that are not IDE plug-ins like che-machine-exec (library to be able connect to a specific container in a workspace/pod).

Also the Che-Theia IDE plug-ins are now exposed by their che-theia-plugin.yaml fragment.

Every Che-Theia plug-in fragment is generated from the [che-theia-plugins.yaml file](https://github.com/eclipse-che/che-plugin-registry/blob/main/che-theia-plugins.yaml).

An hosted version of the che-plugin-registry is available after each commit at [https://eclipse-che.github.io/che-plugin-registry/main](https://eclipse-che.github.io/che-plugin-registry/main)

Corresponding definition for`redhat/java` IDE plug-in is available at:

[https://eclipse-che.github.io/che-plugin-registry/main/v3/plugins/redhat/java/latest/che-theia-plugin.yaml](https://eclipse-che.github.io/che-plugin-registry/main/v3/plugins/redhat/java/latest/che-theia-plugin.yaml)

It references the dependencies of this IDE plug-in and the preferences (so .vsix are not grouped directly in the meta.yaml file)

```yaml
preferences:  
  java.server.launchMode: Standard  
dependencies:  
  - vscjava/vscode-java-debug  
  - vscjava/vscode-java-test
```

### Eclipse Che Devfile registry changes

The index of the devfile registry is providing a list of devfiles to use. But now, with devfile V2 as some other optional files may be required, it’s better to reference a repository rather than a devfile.yaml

New links are available in the devfile registry. The `v2` links are links to either repositories or devfiles.

example of index of the devfile-registry:

```json
{
  "displayName": "Java Spring Boot",
  "icon": "/images/springboot.svg",
  "links": {
    "v2": "https://github.com/che-samples/java-spring-petclinic/tree/devfilev2",
    "self": "/devfiles/java-web-spring/devfile.yaml"
  }
}
```

By enabling DevWorkspaces on Eclipse Che and if there are some v2 links in the devfile registry, the dashboard will only display Devfile v2 getting started (no devfile v1 getting started). Each of these samples will use the new DevWorkspace engine.

![Getting Started]({{ site.url }}{{ site.baseurl }}/assets/img/devfile-v2-and-ide-plugins/dashboard-getting-started.png)

There is ongoing work to merge Che Devfile registry and [Community Devfile registry](https://registry.devfile.io) endorsed by [devfile organization](https://github.com/devfile/registry).
