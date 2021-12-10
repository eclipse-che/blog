#!/usr/bin/env sh
#
# Copyright (c) 2021 Red Hat, Inc.
# This program and the accompanying materials are made
# available under the terms of the Eclipse Public License 2.0
# which is available at https://www.eclipse.org/legal/epl-2.0/
#
# SPDX-License-Identifier: EPL-2.0
#

# Detect available runner
if command -v podman > /dev/null
  then RUNNER=podman
elif command -v docker > /dev/null
  then RUNNER=docker
else echo "No installation of podman or docker found in the PATH" ; exit 1
fi

# Fail on errors and display commands
set -ex

# Use local image if it exists
IMAGE=eclipse-che-blog
podman image exists ${IMAGE} || IMAGE=quay.io/eclipse/eclipse-che-blog
export IMAGE

${RUNNER} run --rm -ti \
  --name eclipse-che-blog \
  -v "$PWD:/projects:z" -w /projects \
  -p 4000:4000 -p 35729:35729 \
  "${IMAGE}" \
  jekyll serve --incremental --watch  --host 0.0.0.0 --livereload --livereload-port 35729
