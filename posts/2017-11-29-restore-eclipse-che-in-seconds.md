---
layout: post
title: Restore Eclipse Che in Seconds
author: Florent Benoit
description: Quickly save/restore the state of Eclipse Che using Docker checkpoints.
categories: []
keywords: []
slug: /@florent.benoit/restore-eclipse-che-in-seconds
---

Docker 1.13 added a **checkpoint** feature. It is still considered an experimental feature but it allows you to create a checkpoint for your running container. This checkpoint can be used later when starting a new container. If the container takes some time to start (to execute the initial command like starting the app server and deploying the application, etc…), it’s very helpful. Eclipse Che is delivered as a docker container with Tomcat deploying the WAR file when starting the container so it’s the perfect candidate to try this experimental feature.

[**docker checkpoint**  
_Description Manage checkpoints API 1.25+ The client and daemon API must both be at least 1.25 to use this command. Use…_docs.docker.com](https://docs.docker.com/engine/reference/commandline/checkpoint/ "https://docs.docker.com/engine/reference/commandline/checkpoint/")[](https://docs.docker.com/engine/reference/commandline/checkpoint/)

Basically the steps are:

1.  Create a checkpoint of a running container (which stops the container).
2.  Start a new container from this checkpoint (container is restored).

Note that when the checkpoint is created, the current container is stopped.

All this requires `[**criu**](http://www.criu.org)` to be installed. _(pronounced kree-oo, IPA: /krɪʊ/, Russian: криу from their home page)_

[**Docker**  
_This article describes the status of CRIU integration with Docker, and how to use it. Naturally, Docker wants to manage…_criu.org](https://criu.org/Docker "https://criu.org/Docker")[](https://criu.org/Docker)

### **TL;DR**

The Che server container is ready in one second when using checkpoint.

### Experimenting with Eclipse Che

When starting Eclipse Che with the CLI, it can take few seconds to boot the workspace master. If you need to start/stop the container several times, it could be interesting to restore the state of Eclipse Che instead of trying to start a new container each time. This is what we’ll focus on.

At first, I’ve tried to create a checkpoint with Docker for Mac. The issue is that `criu` is not installed inside the Docker VM.

[**1.13 experimental: checkpoint/restore not working · Issue #1059 · docker/for-mac**  
_Docker 1.13 adds experimental support for checkpoint/restore, using CRIU (https://criu.org), see Docker Checkpoint …_github.com](https://github.com/docker/for-mac/issues/1059 "https://github.com/docker/for-mac/issues/1059")[](https://github.com/docker/for-mac/issues/1059)

I could have tried [https://hub.docker.com/r/boucher/criu-for-mac/](https://hub.docker.com/r/boucher/criu-for-mac/) but I just switched to a Ubuntu VM and installed `criu`. `(sudo apt-get install criu)`

First, check that you’re running experimental mode for Docker. You can configure it in _/etc/docker/daemon.json_ file on Linux or via the preferences for Docker on Mac and Windows.

You can also check this using the command line with`docker version`. In the `server` part, it should contain **experimental/true**.

Here is my command line output:

root@ubuntu:~# docker version

Client:  
Version:      1.13.1  
API version:  1.26  
Go version:   go1.8.3  
Git commit:   092cba3  
Built:        Thu Oct 12 22:34:44 2017  
OS/Arch:      linux/amd64

Server:  
Version:      1.13.1  
API version:  1.26 (minimum version 1.12)  
Go version:   go1.8.3  
Git commit:   092cba3  
Built:        Thu Oct 12 22:34:44 2017  
OS/Arch:      linux/amd64  
**Experimental: true**

Then we start Eclipse Che with the CLI

$ docker run -it — rm -v /var/run/docker.sock:/var/run/docker.sock -v /tmp/data:/data eclipse/che start

And try to create a checkpoint…

$ docker checkpoint create — checkpoint-dir=/tmp container-hash checkpoint-name

… but it may fail:

(01.291696) sk unix: Dumping external sockets  
(01.291700) sk unix:  Dumping extern: ino 0x9b6d peer\_ino 0xa10d family    1 type    1 state  1 name /var/run/docker.sock  
(01.291709) sk unix:  Dumped extern: id 0x86 ino 0x9b6d peer 0 type 2 state 10 name 21 bytes  
(01.291714) sk unix:  Ext stream not supported: ino 0x9b6d peer\_ino 0xa10d family    1 type    1 state  1 name **/var/run/docker.sock**  
(01.291716) Error (criu/sk-unix.c:715): sk unix: Can't dump half of stream unix connection.

It seems the checkpoint command is not aware on how to handle`/var/run/docker.sock.`

Eclipse Che is using `/var/run/docker.sock` to start sibling containers for the workspace and it’s causing trouble. So let’s avoid this socket and we’ll use a TCP connection for Docker instead.

This time use the`-e DOCKER_HOST=tcp://192.168.1.27:2375` flag instead of `/var/run/docker.sock.` The IP address is the internal IP of the VM on your LAN.

### Launch + Creating the Checkpoint

This time we’ll launch the server image directly instead of via the Che CLI (to avoid the use of `/var/run/docker.sock` problem). We provide the CHE\_IP to use Eclipse Che from other IPs and the name of container we set to `che-server.` Finally, we expose `8080` port to the system `8080` port.

$ docker run — name che-server -e CHE\_HOME=/home/user/che -e CHE\_LOGS\_DIR=/logs -e CHE\_IP=192.168.1.27 -e DOCKER\_HOST=tcp://192.168.1.27:2375 -p 8080:8080 -v /tmp/data:/data -v /tmp/logs:/logs eclipse/che-server

When Eclipse Che is booted, we commit the current container state to a new image (as we’ve deployed the WAR files and boot app server of Eclipse Che)

$ docker commit che-server che-new-server-image  
sha256:71b1b4255fe5bb4bb8e94cfcace01c5599bd4994958c6a1fe73665d0e77b553b

then we perform the checkpoint. We use a specific checkpoint directory (using`--checkpoint-dir)`so we can easily find it later when resuming.

$ docker checkpoint create —-checkpoint-dir=/tmp che-server my-own-checkpoint

When this completes successfully you should see the following in the console:

my-own-checkpoint

If it fails, you’ll get a `dump.log` file that you can inspect. Unfortunately the output isn’t very straightforward :-/

If it works then the `che-server`container should be stopped.

$ docker ps  
CONTAINER ID IMAGE COMMAND CREATED STATUS PORTS NAMES

### Resuming Eclipse Che

Now that Eclipse Che is no longer running, we’ll create a new container for resuming it. This new container will be named `che-server-clone`

\# docker create — name che-server-clone -e CHE\_IP=192.168.1.27 -e DOCKER\_MACHINE\_HOST=192.168.1.27 -e DOCKER\_HOST=tcp://192.168.1.27:2375 -p 8080:8080 -v /tmp/data:/data -v /tmp/logs:/logs che-new-server-image

59849772c723b9688505580c7ee6a41b2c4e72cb212cf46db8a0117341f0fe23

A new container is created, and hash is displayed as output. At this time, we still have no container running.

$ docker ps  
CONTAINER ID IMAGE COMMAND CREATED STATUS PORTS NAMES

Now, it’s time to start the container from the checkpoint. We specify the checkpoint directory `(--checkpoint-dir)`to use and the name of the checkpoint to use `(--checkpoint)`

$  date;docker start --checkpoint-dir=/tmp --checkpoint my-own-checkpoint che-server-clone;date  
Mon Nov 13 14:55:08 CET 2017  
Mon Nov 13 14:55:09 CET 2017

And voilà, the Eclipse Che server was recovered in one second and ready to answer connections if I connect on `8080` port.

![](https://cdn-images-1.medium.com/max/800/1*8r0TnlsGrcJm5VIjkjXWug.gif)

As a side note, the size used by the checkpoint was in my case almost 0.5GB

$ du -s -h /tmp/my-own-checkpoint/  
488M /tmp/my-own-checkpoint/

### Conclusion

We’ve been able to demonstrate that Eclipse Che can benefit from the checkpoint/restore feature by starting a new instance of Eclipse Che in one second!

As Eclipse Che is using Docker (OpenShift / k8s is another option) for deploying the workspaces, it would be interesting to see if it’s also possible to start workspace agent containers using checkpointing. It would mean that you could pause/resume Eclipse Che and a running workspace in one second.

Anyone care to try?