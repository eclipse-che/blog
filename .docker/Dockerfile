#
# Copyright (c) 2023 Red Hat, Inc.
# This program and the accompanying materials are made
# available under the terms of the Eclipse Public License 2.0
# which is available at https://www.eclipse.org/legal/epl-2.0/
#
# SPDX-License-Identifier: EPL-2.0
#

# Brab vale
FROM docker.io/library/golang:1.17.5-alpine3.15 as vale-builder
WORKDIR /vale
ARG VALE_VERSION=2.13.0
RUN wget -qO- https://github.com/errata-ai/vale/archive/v${VALE_VERSION}.tar.gz | tar --strip-components=1 -zxvf - \
    &&  export ARCH="$(uname -m)" \
    &&  if [[ ${ARCH} == "x86_64" ]]; \
    then export ARCH="amd64"; \
    elif [[ ${ARCH} == "aarch64" ]]; \
    then export ARCH="arm64"; \
    fi \
    &&  GOOS=linux GOARCH=${ARCH} CGO_ENABLED=0 go build -tags closed -ldflags "-X main.date=`date -u +%Y-%m-%dT%H:%M:%SZ` -X main.version=${VALE_VERSION}" -o bin/vale ./cmd/vale \
    &&  /vale/bin/vale --version

# use UBI image
FROM quay.io/devfile/universal-developer-image:latest

COPY --from=vale-builder /vale/bin/vale /usr/local/bin/vale
RUN mkdir -p $HOME/.vale/styles && \
    cd $HOME/.vale/styles && \
    curl -sSL -o ./RedHat.zip https://github.com/redhat-documentation/vale-at-red-hat/releases/latest/download/RedHat.zip && \
    curl -sSL -o ./CheDocs.zip https://github.com/eclipse-che/che-docs-vale-style/releases/latest/download/CheDocs.zip && \
    unzip ./RedHat.zip && rm ./RedHat.zip && \
    unzip ./CheDocs.zip && rm ./CheDocs.zip
COPY --chown=user:0 .docker/.vale.ini $HOME/.vale.ini

# The following commands require root
USER 0

# Install a recent version of ruby
ENV RUBY_VERSION 3.1.2
RUN dnf -y update && \
    dnf -y install rbenv ruby-build sqlite && \
    dnf -y clean all --enablerepo='*' && \
    rbenv install $RUBY_VERSION && \
    rbenv global $RUBY_VERSION && \
    echo 'eval "$(rbenv init - bash)"' >> $HOME/.bashrc && \
    echo 'eval "$(rbenv init - sh)"' > /etc/profile.d/rbenv.sh

ENV PATH="${HOME}/.rbenv/shims:${PATH}" ENV="/etc/profile"

# Install jekyll
RUN gem install jekyll

# Set bundle config
RUN bundle config --global path $HOME/.bundle/vendor && \
    chgrp -R 0 $HOME/.bundle && chmod -R g=u $HOME/.bundle && \
    chgrp -R 0 $HOME/.local && chmod -R g=u $HOME/.local && \
    chgrp -R 0 $HOME/.rbenv && chmod -R g=u $HOME/.rbenv

USER 10001
