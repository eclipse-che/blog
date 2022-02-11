---
layout: post
title: How to quickly deploy a VS Code extension on Eclipse Che
author: Florent Benoit
description: Introduction
categories: []
keywords: []
slug: >-
  /@florent.benoit/how-to-quickly-deploy-a-vs-code-extension-on-eclipse-che
---

#### Introduction

Eclipse Che is supporting VS Code extensions in its IDE.

Each workspace can have its own set of plug-ins. This definition of plug-ins is stored inside a `devfile.yaml`file containing as well the list of projects to clone.

From the dashboard, there is a list of plug-ins that can be enabled on a given workspace.

![](https://cdn-images-1.medium.com/max/800/1*AljynvaP6VGvLx1hr4UdwA.png)

When a plug-in is enabled, a new entry is added in the `devfile.yaml` file.

For example, enabling AsciiDoc plug-in is adding the following snippet in my devfile.

![](https://cdn-images-1.medium.com/max/800/1*JDXduFwsoaxMokw49VxXpA.png)


It’s easy but what if the plug-in that I want to try is not in the default Eclipse Che plug-in registry ?

Here come multiple ideas. One of them is to fork the current plug-in-registry repository, rebuild the docker image, deploy it and use this registry. It’s very powerful for ‘in-house’ use-cases, etc but it might be a big effort at first.

#### Setup configuration

Let’s try to make it very simple by just using Github and its [gist](https://gist.github.com/) service.

Go on [https://gist.github.com/](https://gist.github.com/) and create a README.md file saying for example that : `Try Bracket Pair Colorizer extension in Eclipse Che`

It’s because I want to try [https://marketplace.visualstudio.com/items?itemName=CoenraadS.bracket-pair-colorizer](https://marketplace.visualstudio.com/items?itemName=CoenraadS.bracket-pair-colorizer) with its 3M of downloads !

![](https://cdn-images-1.medium.com/max/800/1*K9B6-Ivap24YRGPvlEXYkg.png)
![](https://cdn-images-1.medium.com/max/800/1*o9fowXf0ylqqqSZacNRa0w.png)

And click on `Create secret gist` button

![](https://cdn-images-1.medium.com/max/800/1*p2f_G6UbZ_MXvjY2NtbWdQ.png)

You might not know, but behind a gist, there is a git repository. Let’s clone this repository by using the URL from the navbar.

Git clone command will look like:

```bash
$ git clone https://gist.github.com/<github-username>/<very-long-id>
```                      

In my case it was
```bash
git clone https://gist.github.com/benoitf/85c60c8c439177ac50141d527729b9d9                                                                                                                                                
Cloning into '85c60c8c439177ac50141d527729b9d9'...  
remote: Enumerating objects: 3, done.  
remote: Counting objects: 100% (3/3), done.  
remote: Total 3 (delta 0), reused 0 (delta 0), pack-reused 0  
Unpacking objects: 100% (3/3), done.
```

then we enter into this cloned directory

```bash
$ cd 85c60c8c439177ac50141d527729b9d9
```

#### Create the devfile and plug-ins definition

First, download the plug-in from the VS Code marketplace [https://marketplace.visualstudio.com/items?itemName=CoenraadS.bracket-pair-colorizer](https://marketplace.visualstudio.com/items?itemName=CoenraadS.bracket-pair-colorizer) or from its github page [https://github.com/CoenraadS/BracketPair/releases](https://github.com/CoenraadS/BracketPair/releases) and store the file in the cloned directory

Then, we need to add a definition of this plug-in through a yaml file.

Let’s create this file in the cloned directory
<script src="https://gist.github.com/benoitf/04e840a453e46f243c07c2254d68ea0a.js"></script>

Two remarks there:

*   This extension seems to only require nodejs runtime so in the yaml definition I didn’t specified a custom runtime image.
*   I’m using {{REPOSITORY}} in URL to later compute this link to avoid to search the public URL of the file for now.

note: in the `spec` section, we can specify a custom runtime image, memory limit and some extra volumes, but for the use-case of this simple extension, it was not required.

```yaml
spec:  
  containers:  
    - image: "quay.io/eclipse/che-sidecar-java:8-0cfbacb"  
      name: vscode-java  
      memoryLimit: "1500Mi"  
      volumes:  
      - mountPath: "/home/theia/.m2"  
        name: m2
```

So, `plugin.vsix`file is there, `plugin.yaml` file is there and we only need our workspace definition: `devfile.yaml`

<script src="https://gist.github.com/benoitf/2bce0908836d8dce9171016eafb334f9.js"></script>

You could have taken any other devfile definition., the only important information from this devfile are the lines

```yaml
components:  
  - type: chePlugin  
    reference: "{{REPOSITORY}}/plugin.yaml"
```

It means that we’ll add a custom plug-in using an external reference vs just an id pointing to a definition inside the default plug-in registry.

To sum up, we have 4 files in the current git directory:

```bash
$ ls -la  
.git  
CoenraadS.bracket-pair-colorizer-1.0.61.vsix  
README.md  
devfile.yaml  
plugin.yaml
```

We will need to commit the files to our repository, but before, we will add a pre-commit hook to update `{{ "{{ REPOSITORY " }}}}` variable to the public external raw gist link.

```bash
# download this script  
$ curl -s https://gist.githubusercontent.com/benoitf/e1dd101a6ae157e7e498453dbf683137/raw/2c332278c5a8018b6669da661bbdc6fa10dfb872/pre-commit.sh > .git/hooks/pre-commit

# make it executable  
$ chmod u+x .git/hooks/pre-commit
```

Pre-commit hook is in place, it’s time to commit our files
```bash
$ git add \*
```

![](https://cdn-images-1.medium.com/max/800/1*0FbflRWYdDICdYwAfPYRGA.png)

…commit the files…

```bash
$ git commit -m "Initial Commit for the test of our extension" .                                                                                                                      

[master 98dd370] Initial Commit for the test of our extension  
 3 files changed, 61 insertions(+)  
 create mode 100644 CoenraadS.bracket-pair-colorizer-1.0.61.vsix  
 create mode 100644 devfile.yaml  
 create mode 100644 plugin.yaml
```

… and push the files to the main branch

```bash
$ git push origin 
```

By going back to the gist website, we can see that all links have been updated with the correct public URL.

![](https://cdn-images-1.medium.com/max/800/1*jUjdaNPgGRmZSeEe44fqYg.png)

Now it’s time to experiment our devfile by entering the command to check that online !

```bash
$ open "https://che.openshift.io/f/?url=$(git config --get remote.origin.url)/raw/devfile.yaml"
```

or if you only want the link

```bash
$ echo "https://che.openshift.io/f/?url=$(git config --get remote.origin.url)/raw/devfile.yaml"
```

I can now code with nice brackets :-)

![](https://cdn-images-1.medium.com/max/800/1*T0IcGezki-m-bHM8DB3V7A.gif)
