---
layout: post
title: "Using mkcert to Locally Trust Eclipse Che TLS Certificates"
date: '2021-01-07T10:01:30.817Z'
description: >-
  In this blog post we are going to see how we can use mkcert, an awesome
  command line tool, to generate a locally trusted certificate for…
categories: []
keywords: []
slug: >-
  /@mario.loriedo/using-mkcert-to-locally-trust-eclipse-che-tls-certificates-ffaafe76e5d0
---

![](https://cdn-images-1.medium.com/max/800/1*bo14UIis0Dz-7i_aLr3MFg.png)

In this blog post we are going to see how we can use [mkcert](https://mkcert.dev/), an awesome command line tool, to generate a locally trusted certificate and use it for Che.

### The problem with untrusted TLS certificates

When Eclipse Che TLS certificates are not trusted on a browser we are forced to ask [users to locally import Che CA certificate](https://www.eclipse.org/che/docs/che-7/installation-guide/installing-che-on-minikube/#importing-certificates-to-browsers_che).

Adding the URL among the browser exceptions is not enough. Even in single-host mode (when Che uses one unique domain for every endpoint) a fully trusted TLS certificate is required to use [the service worker API](https://developer.mozilla.org/en-US/docs/Web/API/Service_Worker_API) [required by the IDE](https://github.com/eclipse/che/issues/18566) running in the browser.

Locally importing a CA certificate is a repetitive and error prone manual task. That can be frustrating for users that deploy Che often (like me 😅). The good news is that it can be avoided if Che is deployed with a certificate that is already trusted by the browser. We are going to see how in the next paragraphs.

### Install a local CA (one time operation)

If we want to generate valid TLS certificates to use for Che endpoints, the first thing we need is a locally trusted Certificate Authority. That is actually what [mkcert](https://mkcert.dev/) is good for.

> mkcert is a simple tool for making locally-trusted development certificates. It requires no configuration.

Instructions to install mkcert are in the GitHub repository [README file](https://github.com/FiloSottile/mkcert#installation). Once installed, the following command generates a CA certificate:

```bash
$ mkcert -install   
Using the local CA at “/Users/mariolet/Library/Application Support/mkcert” ✨  
The local CA is already installed in the system trust store! 👍  
The local CA is already installed in the Firefox trust store! 👍
```

After running this command I have a local CA certificate at `~/Library/Application Support/mkcert/rootCA.pem` that is trusted by my system and by my browser. This is a one time operation as I can use this same CA to sign TLS certificates for different Che instance, even on different clusters.

### Generate a locally trusted Che TLS certificate

With a local CA installed it’s now possible to generate locally trusted TLS certificates for any domain. The command line tool `openssl` could be used for that but `mkcert` makes the operation much easier. For example the following command generates a locally trusted certificate for any subdomain of example.com:

```bash
mkcert \*.example.com
```

#### Generate a certificate for minikube

Che URL on [minikube](https://www.eclipse.org/che/docs/che-7/installation-guide/installing-che-on-minikube/#importing-certificates-to-browsers_installing-che-on-minikube) looks like

```
https://che-<namespace>.<minikube-external-IP>.nip.io
```

To generates a certificate for such URL, we can use the following `mkcert` command:

```bash
$ mkcert “\*.$(minikube ip).nip.io”  
Created a new certificate valid for the following names 📜  
 — “\*.192.168.64.19.nip.io”

Reminder: X.509 wildcards only go one level deep, so this won’t match a.b.192.168.64.19.nip.io ℹ️

The certificate is at “./\_wildcard.192.168.64.19.nip.io.pem” and the key at “./\_wildcard.192.168.64.19.nip.io-key.pem” ✅

It will expire on 29 March 2023 🗓
```

That’s it. We have just generated a TLS certificate that works for Che endpoints (and for any `minikube` ingress), that is valid until 2023 and that will be trusted by our local browser.

Note that if `minikube` IP changes (if the cluster gets recreated for example) we should generate a new certificate.

### Deploy Che

If it doesn’t already exist we should create the namespace where Che will be deployed:

```bash
$ kubectl create namespace che  
namespace/che created
```

To configure Che to use the certificate generated above we should create a [Kubernetes tls secret](https://kubernetes.io/docs/concepts/configuration/secret/#tls-secrets) named **`che-tls`**:

```bash
$ kubectl create secret tls che-tls \\  
               --namespace che \\  
               --key ./\_wildcard.$(minikube ip).nip.io-key.pem \\  
               --cert ./\_wildcard.$(minikube ip).nip.io.pem  
secret/che-tls created
```
To configure Che to trust the certificates signed by our local CA we should create a Kubernetes ConfigMap:

```bash
CA\_CERT=~/Library/Application\\ Support/mkcert/rootCA.pem  
kubectl create configmap custom-certs \\  
              --namespace=che \\  
              --from-file="${CA\_CERT}"

kubectl label configmap custom-certs \\  
           app.kubernetes.io/part-of=che.eclipse.org \\  
           app.kubernetes.io/component=ca-bundle \\  
           --namespace=che
```

Now it’s just a matter of using _chectl_ to deploy Che in the same namespace:

```bash
$ chectl server:deploy -p minikube -n che
```