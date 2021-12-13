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

Devfiles v1 were handled by Eclipse Che Server workspace engine using Java/Kubernetes API. There is a new engine for v2 Devfiles called DevWorkspace Controller. The source code is at: [https://github.com/devfile/devworkspace-operator](https://github.com/devfile/devworkspace-operator).

DevWorkspaces are custom Kubernetes resources and can be created/listed/deleted using any Kubernetes client like `kubectl`.

A DevWorkspace is a workspace using the new engine and supporting Devfile v2 definition.

### Milestones

Devfile v2 support in Eclipse Che can be followed by milestones.

*   [Milestone 1](https://github.com/eclipse/che/milestone/136) introduced the first support of Devfile v2 (start a basic workspace)
*   [Milestone 2](https://github.com/eclipse/che/milestone/139) just landed in Eclipse Che 7.32.0 with the support of Theia plug-ins for DevWorkspaces
*   [End Game](https://github.com/eclipse/che/issues/20830) is the End Game issue.

### How to test ?

The support of Devfile v2/DevWorkspaces is optional and need to be opt-in.  

When the support is enabled, both Devfile v1 and v2 are supported. You can still work with your previous workspaces and Devfile v1.

* If the `devfile.yaml` has `apiVersion 1.0.0`, it will use Che server workspace engine to deploy this Devfile.
* If the `devfile.yaml` has `schemaVersion 2.0.0` (or greater like `2.1.0`), it will use the DevWorkspace controller to deploy this Devfile.

⚠️ DevWorkspaces requires OpenShift as platform until Milestone 3 is reached (vanilla Kubernetes is not supported yet)

ℹ️ When DevWorkspace is enabled, single-host deployment is enforced. As a consequence, when the Che host certificate is untrusted, there is no need to locally install it.

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

Clicking on a sample will use a Devfile v2 and the DevWorkspace engine.

ℹ️ [The installation guide is also available in Eclipse Che documentation](https://www.eclipse.org/che/docs/che-7/installation-guide/enabling-dev-workspace-engine/)

### Updating from Devfile v1

While the syntax between v1 and v2 yaml definition is close, there is a major change in the DevWorkspace definition: the IDE plug-ins are no longer part of the Devfile.

It brings more clarity: for example, it was possible to include a java plug-in but it was unclear that it required the Eclipse Theia editor and that it would not work with other supported editors. Also, when the Devfile was consumed by other tools like [odo](https://developers.redhat.com/products/odo/overview) that don't have the notion of plugin or editor, those components were ignored.

Another change in the lifecycle of a workspace is that the project clone operation is done by the DevWorkspace engine. So whatever Che editor is picked-up, the project will always be cloned in `/projects/<your-project>` location after the workspace start (no matter if there is an editor/IDE or not).

### Plug-ins definition

#### IDE preferences

While IDE plug-ins are no longer part of the `devfile.yaml`, instead or reinventing a new file format to specify an IDE plugins, the idea was to leverage the already existing definition files.

For example VS Code has `.vscode/extensions.json` file where plug-ins can be recommended.

Eclipse Che now supports this file format and, when it founds one and the editor is Eclipse Theia, it will add the corresponding VS Code extensions to the DevWorkspace.

Specifying

```json
{  
  "recommendations": [
    "redhat.java"  
  ]  
}
```

in `.vscode/extensions.json` will automatically install `redhat/java` VS Code extension in the Eclipse Che workspace.

Note: if the specified set of extensions IDs are not available in the Eclipse Che plug-in registry, the workspace creation won’t fail but the extensions won’t be included.

The list of the VS Code extension that can be included in a Che Theia workspace are available on the online registry at [https://eclipse-che.github.io/che-plugin-registry/main/v3/plugins/](https://eclipse-che.github.io/che-plugin-registry/main/v3/plugins/). The registry is continuously updated when PRs get merged on Che plugin registry main branch.

#### Custom definition

Relying on `.vscode/extensions.json` is great but, to run a VS Code extension as a Kubernetes workload, may require some extra specifications that are not part of this file format.

Here comes the `.che/che-theia-plugins.yaml` optional file.

For example, overriding some container settings like the memoryLimit for the `redhat.java` plug-in.

```yaml
- id: redhat/java  
  override:  
    sidecar:  
      memoryLimit: 2Gi
```

#### Inlining

Sometimes it may not be possible to include the files `.vscode/extensions.json` or the `.che/che-theia-plugins.yaml` in the git repository.

Inlining the content of these files in the `devfile.yaml` file is somehow possible using the following syntax of the Devfile:
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

Although excluding the IDE plug-ins from the Devfile specification represents a big change, each editor can now bring new features more easily. Each editor can directly update a workspace using `DevWorkspaceTemplate` objects based on its configuration files (like optional `.vscode/extensions.json` or `.che/che-theia-plugins.yaml` files).

#### Deploy plug-ins in existing containers

By default, in Eclipse Che and when using Eclipse Theia editor, IDE plug-ins were deployed either in the Che-Theia container (when it only requires nodejs runtime) or through a new sidecar container (for example for Java, Go, Python, Php, etc.)

In that case, all plugins requiring a sidecar will be deployed in the `user defined container` and not in their specific sidecar container.

Example:

If a repository contains these two files:

1. `devfile.yaml` with the following content:
```yaml
schemaVersion: 2.1.0  
metadata:  
  name: my-example  
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

The plug-in `redhat.java` will be started inside the tools container and in its own sidecar container.

For this to work the tools container should include the plug pre-requisites otherwise the VS Code java extension will fail to start.

To disable this behaviour, use the following attribute:

```yaml
attributes:  
  che-theia.eclipse.org/sidecar-policy: mergeImage
```

#### Prebuilt DevWorkspace templates

With Devfile v1 the flow was the following: a user selects a getting started example, the Dashboard fetches the Devfile, the plug-in broker analyzes the `devfile.yaml` fetches the content from linked plug-in registries, parses the `meta.yaml` of these plug-ins, extracts the sidecar containers definitions and, finally, adds some containers to the workspace definition.

With Devfile v2, these steps with a lot of yaml/json transformations are still present but the output result is a set of DevWorkspace templates that will be applied on the Kubernetes cluster.

Those DevWorkspace templates can be generated at build time rather than at runtime. The Che-Theia library, with a Devfile provided as input (the optional `.vscode/extensions.json` and `.che/che-theia-plugins.yaml` files), generates a yaml file that includes the definition of the DevWorkspace templates.

npx @eclipse-che/che-theia-devworkspace-handler --devfile-url:[https://github.com/che-samples/spring-petclinic/tree/devfilev2](https://github.com/che-samples/spring-petclinic/tree/devfilev2) --output-file:$(pwd)/all-in-one.yaml

Then this file can be used directly by `kubectl` :

`kubectl apply -f all-in-one.yaml -n my-namespace`

These templates can be included in the Devfile registry and the Eclipse Che Dashboard will apply them directly instead of processing the original Devfile at every workspace start.

### Plug-in registry changes

For workspaces using Devfile v1, Eclipse Che server fetches a `meta.yaml` files from the plug-in registry. There are some limitations, for example defining plug-in preferences is only possible if there is a sidecar being defined, etc.

With DevWorkspaces, the plug-in registry export now the content provided in different formats. It still exports `meta.yaml` files but it also exposes `devfile.yaml` files for Eclipse Che editors definition and for some plug-ins that are not IDE plug-ins like che-machine-exec (library to be able connect to a specific container in a workspace/pod).

Also the Che-Theia IDE plug-ins are now exposed by their `che-theia-plugin.yaml` fragment.

Every Che-Theia plug-in fragment is generated from the [che-theia-plugins.yaml file](https://github.com/eclipse-che/che-plugin-registry/blob/main/che-theia-plugins.yaml).

An hosted version of the che-plugin-registry is available after each commit at [https://eclipse-che.github.io/che-plugin-registry/main](https://eclipse-che.github.io/che-plugin-registry/main)

Corresponding definition for`redhat/java` IDE plug-in is available at:

[https://eclipse-che.github.io/che-plugin-registry/main/v3/plugins/redhat/java/latest/che-theia-plugin.yaml](https://eclipse-che.github.io/che-plugin-registry/main/v3/plugins/redhat/java/latest/che-theia-plugin.yaml)

It references the dependencies of this IDE plug-in and its preferences (whereas with `meta.yaml` the notion of dependency didn't exist and all the required `.vsix` had to be specified in the file)

```yaml
preferences:  
  java.server.launchMode: Standard  
dependencies:  
  - vscjava/vscode-java-debug  
  - vscjava/vscode-java-test
```

### Eclipse Che Devfile registry changes

The index of the Devfile registry is providing a list of Devfiles to use. But now, Devfile v2 as some other optional files may be required, it’s better to reference a repository rather than a single `devfile.yaml`.

New links are available in the Devfile registry. The `v2` links are links to either repositories or devfiles.

Here is an example of a minimal index of a Devfile registry:

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

If the DevWorkspaces is enabled and there are some v2 links in the Devfile registry, only Devfile v2 getting started will be shown on the Dashboard (Devfile v1 getting started will be hidden). Each of these samples will use the new DevWorkspace engine.

![Getting Started]({{ site.url }}{{ site.baseurl }}/assets/img/devfile-v2-and-ide-plugins/dashboard-getting-started.png)

In addition to those changes, there is an ongoing effort to merge Che Devfile registry and [community Devfile registry](https://registry.devfile.io). This work is part of the [Devfile project](https://github.com/devfile/registry) that is planned to become [a CNCF sandbox project](https://github.com/devfile/api/issues/426).
