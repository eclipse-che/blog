# Copyright (c) 2021 Red Hat, Inc.
# This program and the accompanying materials are made
# available under the terms of the Eclipse Public License 2.0
# which is available at https://www.eclipse.org/legal/epl-2.0/
#
# SPDX-License-Identifier: EPL-2.0
#
# Contributors:
#   Red Hat, Inc. - initial implementation
#

FROM registry.fedoraproject.org/fedora-minimal:35

LABEL description="Tools to build Eclipse Che blog: Jekyll AsciiDoc" \
    io.k8s.description="Tools to build Eclipse Che blog: Jekyll AsciiDoc" \
    io.k8s.display-name="Che-blog tools" \
    license="Eclipse Public License - v 2.0" \
    MAINTAINERS="Eclipse Che Blog Team" \
    maintainer="Eclipse Che Blog Team" \
    name="eclipse-che-blog" \
    source="https://github.com/eclipse-che/blog/Dockerfile" \
    summary="Tools to build Eclipse Che blog" \
    URL="quay.io/eclipse/che-blog" \
    vendor="Eclipse Che Blog Team" \
    version="2021.12"

RUN microdnf install -y rubygem-jekyll-asciidoc && microdnf clean all
