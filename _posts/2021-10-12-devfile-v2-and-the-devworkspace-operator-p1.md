---
title: Devfile v2 and the DevWorkspace Operator - Part 1
layout: post
author: Mario Loriedo
description: >-
  How to enable the DevWorkspace engine and what it means from a user point of view
categories: []
keywords: ['devfile', 'devworkpace']
slug: /@mario.loriedo/devfile-v2-and-the-devworkspace-operator-p1
---

![Locally trusted certs]({{ site.url }}{{ site.baseurl }}/assets/img/devfile-v2-and-the-devworkspace-operator-part1/che-workspace-engines.png)

With version [7.28 of Che](https://github.com/eclipse/che/releases/tag/7.28.0) we have introduced a workspace engine, [the DevWorkspace Operator](https://github.com/devfile/devworkspace-operator), that supports v2 of the Devfile specification. Although the default engine is still the che-server we plan to replace it with the DevWorkspace in the next few months.

Switching to the DevWorkspace engine has some important consequences. Notably on the authentication subsystem that will be lighter and more flexible, on the workspaces network managed by a central gateway powered by [Traefik](https://github.com/traefik/traefik) and simpler configuration options for Che administrators.  

This is the first of a series of three articles reviewing the changes introduced with the DevWorkspace. Here we will discuss the changes from the point of view of a Che user. The second part will be about the point of view of a Che administrator. The last part will be dedicated to the DevWorkspace Operator.

## How to enable the DevWorkspace Operator 
Che default workspace engine is the che-server. The DevWorkspace engine needs to be explicitly enabled. The following [chectl](https://github.com/che-incubator/chectl) command deploys Che on OpenShift configured with the DevWorkspace Operator as workspace engine:

```bash
chectl server:deploy --installer=olm -p openshift \
                     --workspace-engine=dev-workspace
```

The command above works for other Kubernetes distributions too (`-p openshift` should be replaced) but, after chectl has completed, the CheCluster CustomResource requires a patch:

```bash
# For vanilla Kubernetes only
kubectl patch checluster/eclipse-che --type=merge -n eclipse-che \ 
           --patch '{"spec": {"server": { "customCheProperties": {"CHE_INFRA_KUBERNETES_ENABLE__UNSUPPORTED__K8S": "true"}}}}' 
```

## Changes from a Che user perspective

### New Devfile spec (v2.1)

Here is an example of v2.1 Devfile:
```yaml
schemaVersion: 2.1.0
metadata:
  name: python-hello-world
attributes:
  che-theia.eclipse.org/sidecar-policy: USE_DEV_CONTAINER
components:
  - name: python
    container:
      image: quay.io/devfile/base-developer-image:ubi8-7bd4fe3
      volumeMounts:
        - name: venv
          path: /home/user/.venv
      memoryLimit: 512Mi
      mountSources: true
  - name: venv
    volume:
      size: 1G
```

The Devfile specification has gone through the release of v2. Here are a few notable changes:
- It is compatible with the specification of a Kubernetes API. The DevWorkspace CRD is an extension of the Kubernetes API and it’s generated from the Devfile specification.
- It removes [chePlugin and cheEditor component types](https://github.com/eclipse/che/issues/18669).
- It introduces the volume component type.
- Events and parent are two new components types.
- Besides Che it’s used by the OpenShift Developer Console, `odo` and the [Devfile Docker plugin](https://github.com/devfile/devfile-docker-plugin). 

The documentation for Devfile v2.1 is [https://devfile.io/docs/devfile/2.1.0/](https://devfile.io/docs/devfile/2.1.0/user-guide/index.html) and a migration to v2 guide 

### A new way to specify the editor and its plugins
As mentioned above, version 2 of the Devfile, doesn’t include cheEditor and chePlugins component types anymore. 

The recommended way to specify the editor of a workspace is to include the file `.che/che-editor.yaml` at the root of the workspace git repository:
```yaml
id: eclipse/che-theia                 # mandatory
registryUrl: https://my-registry.com  # optional
override:                             # optional
  containers:
    - name: theia-ide
      memoryLimit: 1280Mi
```

The recommended way to specify a che-theia plugin in a workspace is to include the file `.vscode/extensions.json` at the root of the workspace git repository:
```json
{
    "recommendations": [
      "ms-python.python"
    ]
}
```
 
It is also possible to define a Che editor and its plugins inline in a Devfile attributes. But that’s not recommended. More informations can be found at [https://github.com/eclipse/che/issues/18669](https://github.com/eclipse/che/issues/18669).

### The Devfile should live at the root of the git repo, not in a registry
The recommended place to publish the Devfile is within the project source code. Along with the files that we have just seen above to specify che-theia plugins and the editor:

```
  |--- devfile.yaml
  |___ .che
         |___ che-editor.yaml
         |___ che-theia-plugins.yaml
  |___ .vsocode
         |___ extensions.json
```

The Devfile should be versioned and its version should be synchronized with the version of the source code. Having the Devfile at the root of a repository makes it possible to use a simple factory link to the repository to start the workspace.

Versioning the Devfile with the source code has two consequences: 
- the `project` section of a Devfile can be omitted: it’s implicitly set to the git repo where the Devfile lives
- Che source code examples include a Devfile at their root (those Devfiles used to be published in the Devfile registry)  

### Only one running workspace per user
A user cannot have more than one running workspace at the time. This limitation is related to the persistent volume strategy (“common”) that is used by Che. The same Volume is mounted by every workspace of the same user. This is implemented using Pods `volumeMounts.subPath` property and guarantee that the number of Volumes mounted by Che matches the number of user.

## Current limitations and Timeline

Although most of the work has been completed, Che with the DevWorkspace enabled is not ready for production yet. Here is a list of open issues:
- [An admin should be able to specify secrets or config maps that need to be provisioned on each user's namespace #20501](https://github.com/eclipse/che/issues/20501)
- [Support custom certificates for git hosts for devworkspaces #20528](https://github.com/eclipse/che/issues/20528)
- [Support Pod tolerations for DevWorkspace Pods devfile/devworkspace-operator#614](https://github.com/devfile/devworkspace-operator/issues/614)
- [Che with Devworkspaces should be able to use Dex as identity provider on OIDC enabled k8s #20362](https://github.com/eclipse/che/issues/20362)
- [Create v2 devfiles for Getting Started samples](https://github.com/eclipse/che/issues/19341)
- [Support overriding Che Theia plugins preferences and sidecar through .che/che-theia-plugins.yaml](https://github.com/eclipse/che/issues/20596)
- [Adapt Che-Theia Activity Tracker extension to DevWorkspace mode (idling)](https://github.com/eclipse/che/issues/20460)

The complete list of issues and the due date can be tracked on the [GitHub milestone](https://github.com/eclipse/che/milestone/140).  

## Conclusion

In this post we have described how to enable the DevWorkspace engine and reviewed the changes from the point of view of a user of Che.

In the second part of this series we are going to look at the changes from an administrator point of view:
- It’s possible to deploy only one Che instance per Kubernetes cluster
- Devfiles are not in the registry anymore
- Keycloak is not required anymore and Che users has to be Kubernetes users
- Simpler configuration: namespace, persistent volumes, network
- Use of external routes not supported
- Metrics

The third part of this series will be about the DevWorkspace Operator:
- Extending the Kubernetes API to provision Development Environments
- Relationship between the DevWorkspace CRD and the Devfile v2
- Relationship between the DevWorkspace Operator and the OpenShift WebTerminal
- Comparison between the DevWorkspace controller and the che-server:
	- single tenant
	- no knowledge of IDEs and their extensions
- DevWorkspaceTemplate and Plugins
- Auto-mounting Secrets and ConfigMaps

