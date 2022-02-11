---
layout: post
title: Apache OpenWhisk, Eclipse Che and OpenShift / MiniShift
author: Florent Benoit
description: >-
  In this blog post, we’ll demonstrate how to use the serverless capabilities of
  Apache OpenWhisk by writing actions within Eclipse Che.
date: '2018-01-12T14:03:47.244Z'
categories: []
keywords: []
slug: >-
  /@florent.benoit/apache-openwhisk-eclipse-che-and-openshift-minishift
---

![](https://cdn-images-1.medium.com/max/800/1*9kUKM1qnsM8n53Ue6uSyUw.png)

In this blog post, we’ll demonstrate how to use the serverless capabilities of Apache OpenWhisk by writing actions within Eclipse Che.

[**Apache OpenWhisk is a serverless, open source cloud platform**  
_An open source platform for serverless, event-driven code at any scale. We handle the infrastructure & servers so you…_openwhisk.incubator.apache.org](https://openwhisk.incubator.apache.org/ "https://openwhisk.incubator.apache.org/")[](https://openwhisk.incubator.apache.org/)

There are several ways to deploy Apache OpenWhisk. I’ve followed the MiniShift setup which deploys both Eclipse Che and Apache OpenWhisk on top of MiniShift. It’s easy to setup and to reproduce.

### Setup of Apache OpenWhisk

Here is the installation guide for Apache OpenWhisk on MiniShift

[**projectodd/incubator-openwhisk-deploy-kube**  
_incubator-openwhisk-deploy-kube - This project can be used to deploy Apache OpenWhisk to a Kubernetes cluster_github.com](https://github.com/projectodd/incubator-openwhisk-deploy-kube/blob/simplify-deployment-openshift/resources/README.md#oc-minishift "https://github.com/projectodd/incubator-openwhisk-deploy-kube/blob/simplify-deployment-openshift/resources/README.md#oc-minishift")[](https://github.com/projectodd/incubator-openwhisk-deploy-kube/blob/simplify-deployment-openshift/resources/README.md#oc-minishift)

Note: do not forget to launch this command after MiniShift startup (else pods won’t start correctly)

```
$ minishift ssh -- sudo ip link set docker0 promisc on
```

We can check OpenWhisk is running by using the following command (it can take time as there are a lot of docker images to download)

$ oc logs -f controller-0 | grep "invoker status changed"  
\[2018-01-05T10:05:29.844Z\] \[INFO\] \[#sid\_121\] \[InvokerPool\] invoker status changed to 0 -> UnHealthy  
\[2018-01-05T10:06:30.243Z\] \[INFO\] \[#sid\_121\] \[InvokerPool\] invoker status changed to 0 -> Healthy

We can check actions as well. We’re using `-i` flag as the HTTP certificate is self signed.

The `wsk` binary can be downloaded from [https://github.com/apache/incubator-openwhisk-cli/releases](https://github.com/apache/incubator-openwhisk-cli/releases)

The CLI will be installed as well in the workspace’s image of Eclipse Che, so there is no extra download step.

$ wsk -i list

Entities in namespace: **default  
packages  
**/whisk.system/combinators                                              shared  
/whisk.system/utils                                                    shared  
/whisk.system/websocket                                                shared  
/whisk.system/github                                                   shared  
/whisk.system/watson-speechToText                                      shared  
/whisk.system/weather                                                  shared  
/whisk.system/watson-translator                                        shared  
/whisk.system/slack                                                    shared  
/whisk.system/samples                                                  shared  
/whisk.system/watson-textToSpeech                                      shared

**actions**

/whisk.system/samples/curl                                             private nodejs:6  
/whisk.system/utils/head                                               private nodejs:6  
/whisk.system/utils/echo                                               private nodejs:6  
/whisk.system/utils/date                                               private nodejs:6  
/whisk.system/samples/greeting                                         private nodejs:6  
/whisk.system/watson-speechToText/speechToText                         private nodejs:6  
/whisk.system/combinators/retry                                        private nodejs:6  
/whisk.system/utils/sort                                               private nodejs:6  
/whisk.system/utils/cat                                                private nodejs:6  
/whisk.system/combinators/forwarder                                    private nodejs:6  
/whisk.system/utils/hosturl                                            private nodejs:6  
/whisk.system/utils/namespace                                          private nodejs:6  
/whisk.system/watson-translator/translator                             private nodejs:6  
/whisk.system/combinators/eca                                          private nodejs:6  
/whisk.system/combinators/trycatch                                     private nodejs:6  
/whisk.system/utils/smash                                              private nodejs:6  
/whisk.system/samples/wordCount                                        private nodejs:6  
/whisk.system/samples/helloWorld                                       private nodejs:6  
/whisk.system/github/webhook                                           private nodejs:6  
/whisk.system/utils/split                                              private nodejs:6  
/whisk.system/watson-translator/languageId                             private nodejs:6  
/whisk.system/watson-textToSpeech/textToSpeech                         private nodejs:6  
/whisk.system/websocket/send                                           private nodejs:6  
/whisk.system/slack/post                                               private nodejs:6  
/whisk.system/weather/forecast                                         private nodejs:6

**triggers**

**rules**

### Setup of Eclipse Che

Using shell scripts, we can deploy easily Eclipse Che on top of MiniShift.

[**eclipse/che**  
_che - Eclipse Che: Next-generation Eclipse IDE. Open source workspace server and cloud IDE._github.com](https://github.com/eclipse/che/blob/master/dockerfiles/init/modules/openshift/files/scripts/deploy_che.sh "https://github.com/eclipse/che/blob/master/dockerfiles/init/modules/openshift/files/scripts/deploy_che.sh")[](https://github.com/eclipse/che/blob/master/dockerfiles/init/modules/openshift/files/scripts/deploy_che.sh)

Let’s run `./deploy_che.sh` script from the previous link.

Now we have two MiniShift projects, `openwhisk` with all Apache OpenWhisk deployments and `eclipse-che` with Eclipse Che images running.

Eclipse Che can be reached at [http://che-eclipse-che.192.168.64.5.nip.io/dashboard](http://che-eclipse-che.192.168.64.5.nip.io/dashboard) on my current setup. (the link is displayed at the end of the run of the sh script)

![](https://cdn-images-1.medium.com/max/800/1*MvjCGP94kzRBRDVsqtCtVA.png)

Let’s create a workspace by using the following docker image: `florentbenoit/centos_openwhisk` This image integrates Java, NodeJS and Python runtime but also OpenShift client `(oc)`and OpenWhisk client `(wsk)`

Once the workspace is created, let’s import a maven Java project so we will be able to create a Java action with OpenWhisk. The project source code is at [https://github.com/benoitf/openwhisk-action](https://github.com/benoitf/openwhisk-action)

[**benoitf/openwhisk-action**  
_Contribute to openwhisk-action development by creating an account on GitHub._github.com](https://github.com/benoitf/openwhisk-action "https://github.com/benoitf/openwhisk-action")[](https://github.com/benoitf/openwhisk-action)

Let’s build the maven project:

![](https://cdn-images-1.medium.com/max/800/1*8ak-embtGh0s7EZNqrIh3w.gif)

In the target folder, the jar file was generated.

Now, let’s connect Eclipse Che to OpenWhisk.

First, we login from the Che terminal to MiniShift (192.168.64.5 being the IP that is displayed by using `$ minishift ip` command)

_$ oc login_ [_https://192.168.64.5:8443_](https://192.168.64)_  
(we use developer/developer as login and password)_

Authentication required for [https://192.168.64.5:8443](https://192.168.64.5:8443) (openshift)  
Username: developer  
Password:  
Login successful.

You have access to the following projects and can switch between them with 'oc  
project <projectname>':

```bash
eclipse-che
    myproject
    openwhisk
  \* workspacewdsw9iop4nubfh7m
```

Using project "workspacewdsw9iop4nubfh7m".

We need to get data from OpenWhisk, so we enter the command `oc project openwhisk`

$ oc project openwhisk  
Now using project "openwhisk" on server "[https://192.168.64.5:8443](https://192.168.64.5:8443)".

Then we’re able to configure OpenWhisk client

```bash
$ AUTH_SECRET=$(oc get secret openwhisk -o yaml | grep "system:" | awk '{print $2}' | base64 --decode)$ wsk property set --auth $AUTH_SECRET --apihost $(oc get route/openwhisk --template={{ "{{ .spec.host " }}}})
```

then we can build the action from the JAR file

$ cd target/  
$ wsk -i action create helloJava openwhisk-action-1.0-SNAPSHOT.jar --main Hello  
$ wsk -i action invoke --result helloJava --param name "Eclipse Che"

so we were able to write an action from Eclipse Che, create it in OpenWhisk and invoke it by providing “Eclipse Che” parameter.

\[user@workspacewdsw9iop4nubfh7m target\]$ wsk -i action invoke --result helloJava --param name "Eclipse Che"  
{  
    "greeting": "Hello Eclipse Che!"  
}  
\[user@workspacewdsw9iop4nubfh7m target\]$ wsk -i action invoke --result helloJava --param name "Eclipse Che test"  
{  
    "greeting": "Hello Eclipse Che test!"  
}

![](https://cdn-images-1.medium.com/max/800/1*5KCftW_aMynTi6hYxHFnUw.gif)

As always please let us know your thoughts by connecting with us on twitter @eclipse\_che or by filing issues in the Che GitHub repo at [https://github.com/eclipse/che](https://github.com/eclipse/che)