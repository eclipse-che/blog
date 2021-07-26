---
title: Back up and Restore Eclipse Che Installation
layout: post
author: Mykola Morhun
description: >-
  How to create backups and do recovery of Eclipse Che
categories: []
keywords: ['backup', 'back up', 'restore']
slug: /@mmorhun/backup-restore-che-installation
---

### Introduction

Any application that runs in production should be backed up regularly.
Even if the application runs inside Kubernetes or Openshift cluster.
To back up an application in a Kubernetes or Openshift cluster, cluster admin should back up all the resources and definitions that the application owns and uses.
It could be pretty easy in case when the application is, for example, a deployment with attached volume.
But what if the application has a lot of objects to back up?
In such case the task becomes much more complicated and will require from the admin understanding on how the components of the application work and interact with each other.
Or... just back up the whole cluster, however, such approach has a lot of overhead.

To address the backup / restore problem in [Eclipse Che](https://www.eclipse.org/che/), backup / restore feature was implemented.
With it, cluster admin doesn't have to be aware of Eclipse Che internals in order to create a backup or do recovery of Che.
Eclipse Che (Eclipse Che operator to be more precise) can create backups and restore the installation even if Che cluster was completely deleted!
(Che operator should be available, though).

Let me show you how easy the process of backing up and restoring Che is now.
But first, let's talk about backup servers a bit.

### Internal vs external backup server

When all data for backup is gathered into a snapshot, then it is encrypted and sent to a backup server.
The backup server should be set up beforehand and be accessible from within the cluster.
This step requires choosing the backup server type and manual configuration of it.

To make life a bit easier, Eclipse Che can automatically set up and configure a backup server in the same cluster.
Such approach requires no additional configuration as everything is automated, but the main downside of it is that backups are stored in the same cluster and even the same namespace as Eclipse Che.

Note, for production use, it is recommended to set up a backup server outside of the cluster.

### How to back up and restore Che using chectl

#### Creating backups

To create a backup of Eclipse Che with [chectl](https://github.com/che-incubator/chectl#chectl) one should run:
```bash
$ chectl server:backup
```
The command above will create a backup snapshot and send it to the configured backup server.
But if no backup server is configured, Che operator will deploy internal backup server and configure itself to use the server by default.

To use an external backup server (or switch to another one), its URL and backups repository password should be provided, for example:
```bash
$ checlt server:backup -r rest:my-backups.domain.net:1234/che-backups -p encryption-password
```
After execution of the command above, a new backup will be created and sent to the specified backup server.
Also, it will configure Che to use that backup server by default, so for the next backups just `chectl server:backup` will be enough.

Note, instead of using `-p` flag, it is possible to set `BACKUP_REPOSITORY_PASSWORD` environment variable.
Note, losing repository password means losing all the data stored in it as the password is used to decrypt the repository content.

#### Supported types of backup servers

Eclipse Che uses an external tool called [restic](https://restic.net/) to manage backup snapshots.
`restic` stores backup snapshots in a backup repository, where each snapshot is identified by a hash.
It also can connect to different kinds of servers that provide data storage capabilities.

As of now, Eclipse Che supports the following types of backup servers:
* `REST`
* `AWS S3` and API compatible
* `SFTP`

[`REST` backup server](https://github.com/restic/rest-server#rest-server) is a dedicated server that's specially designed to be used with `restic`.
It supports optional authentication by username and password:
```bash
$ export REST_SERVER_USERNAME=user
$ export REST_SERVER_PASSWORD=password
$ chectl server:backup -r rest:http://backups.my-domain.net:1234/che -p encryption-password
```
Internal backup server is of type `REST`.

`AWS S3` storage and all API compatible implementations can be used as a backup server.
Requires setting `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` environment variables.
Example:
``` bash
$ export AWS_ACCESS_KEY_ID=BZK8W5****
$ export AWS_SECRET_ACCESS_KEY=JKTa9TKoL*****dH6U+kP
$ chectl server:backup -r s3:s3.amazonaws.com/che-bucket -p password
```

`SFTP` storage.
It requires providing SSH key for passwordless login.
That could be done by providing the path to the file with the SSH key or the key itself (choose one):
```bash
$ export SSH_KEY_FILE=/home/user/.ssh/sftp.key
$ # export SSH_KEY=-----BEGIN RSA PRIVATE KEY-----*****
$ chectl server:backup sftp:user@my-host.net:1234//srv/static/che-backups
```

#### Restoring Che installation form a backup

To restore Eclipse Che installation, simply run:
```bash
$ chectl server:restore
```
It will download the latest backup snapshot from the configured backup server and restore all Eclipse Che data from it.
If needed, it will even deploy a new Che cluster and apply data from the backup snapshot.

But what if we created a dozen of backups and want to restore not from the latest backup available on the backup server, but an older one?
It is possible!
Just add backup snapshot ID with `-f`  flag to the restore command:
```bash
$ chectl server:restore -s f801da5c
```
Where to get snapshot IDs?
There are two ways.
Snapshot ID is printed when a backup command executed:
```bash
Backup snapshot ID: f801da5c
```
Another way is to use `restic` tool:
```bash
$ restic -r rest:my-backups.domain.net:1234/che-backups snapshots
```

Also, it is possible to use differnet backup server to restore from.
Just provide a backup server URL and repository password with needed credentials.
For example:
```bash
$ chectl server:restore -r sftp:cheuser@my-sftp.domain.net:/srv/data/che-backups/ -p encryption-password --ssh-key-file=~/.ssh/che-sftp.key
```
Note, that the command above will change default backup server, so the next backup will be sent there unless another configuration provided.

### How to back up and restore Che via custom resources objects

#### Concept

If someone doesn't want to use `chectl` or want to have more control over the backup and restore process, it is possible to control backup and restore processes by directly managing backup related custom resources (CRs).
There are 3 types of CRs:
* `CheBackupServerConfiguration` that holds information about a backup server and references to the secrets with credentials.
* `CheClusterBackup` requests a new backup and also points to an instance of `CheBackupServerConfiguration` to where the backup snapshot should be sent.
* `CheClusterRestore` requests a new restore and holds reference to `CheBackupServerConfiguration` from where the backup snapshot should be downloaded.

Please note, that only creation of `CheClusterBackup` and `CheClusterRestore` instances triggers backup and restore processes correspondingly.
Any editing of these resources has no effect.

Under the hood, `chectl` deals with the described CRs in order to create a backup or trigger a restore process.

#### Configuring a backup server

Before backing up or restoring Che installation, at least one backup server configuration should be created.
Also, all secrets that are referenced from the CR must exist.
Then, the configuration might be referenced from backup and/or restore CR.

Example backup server configuration for AWS S3 storage:
```yaml
apiVersion: org.eclipse.che/v1
kind: CheBackupServerConfiguration
metadata:
  name: backup-server-configuration
spec:
  awss3:
    repositoryPath: che-bucket
    repositoryPasswordSecretRef: aws-backup-encryption-password-secret
    awsAccessKeySecretRef: aws-user-credentials-secret
```
Both secrets `aws-backup-encryption-password-secret` with `repo-password` key and `aws-user-credentials-secret` with `awsAccessKeyId` and `awsSecretAccessKey` keys must exist.

As it was described above, under `spec` section only `rest`, `awss3` and `sftp` is allowed.
CR definitions have self-explanatory fields and it will be easy to create a backup server configuration.
But note, that each subsection mutually excludes the others.
However, it is allowed to create as many backup server configurations as needed.

#### Backing up

To create a new backup, a new CR of `CheClusterBackup` type should be created:
```yaml
apiVersion: org.eclipse.che/v1
kind: CheClusterBackup
metadata:
  name: eclipse-che-backup
spec:
  backupServerConfigRef: backup-server-configuration
```
Right after the CR creation a new backup process will be started.
To monitor backup process state, one should look at `status` section of the created CR:
```bash
$ kubectl get CheClusterBackup eclipse-che-backup -n eclipse-che -o yaml | grep -A 5 ^status
```
The output of the command above looks like:
```yaml
status:
  message: 'Backup is in progress. Start time: <timestamp>'
  stage: Collecting Che installation data
  state: InProgress
```
where
* `message` shows overall human readable status or an error message.
* `stage` displays human readable current phase of backup process
* `state` indicates the overall state of the backup. Only `InProgress`, `Succeeded` and `Failed` allowed.

When the process finishes successfully, the `status` section will contain `snapshotId` field that could be used when restoring.
The CR might be deleted after backup is finished.

If one need to request internal backup server and create a backup, `CheClusterBackup` with `useInternalBackupServer` property set to `true` should be created:
```yaml
apiVersion: org.eclipse.che/v1
kind: CheClusterBackup
metadata:
  name: eclipse-che-backup
spec:
  useInternalBackupServer: true
```
Note, it will create an instance of `CheBackupServerConfiguration` and corresponding secrets automatically.

#### Restoring

To restore from a backup snapshot, a new CR of `CheClusterRestore` type should be created:
```yaml
apiVersion: org.eclipse.che/v1
kind: CheClusterRestore
metadata:
  name: eclipse-che-restore
spec:
  backupServerConfigRef: backup-server-configuration
```

By default the latest snapshot is taken.
However, it is possible to restore from a specific snapshot by adding `snapshotId` field under `spec` section.

To monitor the restore state, one may read status of the corresponding CR:
```bash
$ kubectl get CheClusterRestore eclipse-che-restore -n eclipse-che -o yaml | grep -A 5 ^status
```
Once the restore finishes, the CR can be deleted.

### Limitations

As of now, there are two major limitations with backup and restore:
* Backing up of user's projects inside workspaces hasn't been implemented yet. So, all not committed changes will not be restored.
* Backup snapshots are bind to the specific cluster, so it is not possible to restore snapshot on another cluster in general case. This is because Che binds to some cluster ID's.

Other than that, back up and restore is a user friendly and straightforward process now.
