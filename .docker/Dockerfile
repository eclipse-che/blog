#
# Copyright (c) 2021 Red Hat, Inc.
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

# use jekyll image
FROM docker.io/jekyll/jekyll:4.2.2
COPY --from=vale-builder /vale/bin/vale /usr/local/bin/vale
RUN mkdir -p /home/jekyll/.vale/styles
WORKDIR /home/jekyll/.vale/styles
RUN wget -qO- https://github.com/redhat-documentation/vale-at-red-hat/releases/latest/download/RedHat.zip | unzip -
RUN wget -qO-  https://github.com/eclipse-che/che-docs-vale-style/releases/latest/download/CheDocs.zip | unzip -
COPY --chown=jekyll:jekyll .docker/.vale.ini /home/jekyll/.vale.ini
COPY --chown=jekyll:jekyll Gemfile .
COPY --chown=jekyll:jekyll Gemfile.lock .
RUN bundle install
COPY --chown=0:0 .docker/entrypoint.sh /
RUN chgrp -R 0 /home && chmod -R g=u /etc/passwd /etc/group /home && chmod +x /entrypoint.sh && usermod --shell /bin/bash jekyll

USER 1000
WORKDIR /projects
ENV HOME=/home/jekyll
ENV USER_NAME=jekyll
ENTRYPOINT [ "/entrypoint.sh" ]
CMD ["tail", "-f", "/dev/null"]
