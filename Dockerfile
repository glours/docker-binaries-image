#syntax=docker/dockerfile:1.3-labs

FROM alpine AS curl
RUN apk add --no-cache \
    curl

FROM curl AS cli
ARG CLI_VERSION=20.10.17
RUN <<EOT ash
    curl -fL https://download.docker.com/linux/static/stable/$(uname -m)/docker-${CLI_VERSION}.tgz | tar zxf - --strip-components 1 docker/docker
    chmod +x /docker
EOT

FROM curl AS buildx-plugin
ARG TARGETARCH
ARG BUILDX_VERSION=v0.9.1
RUN <<EOT ash
    curl -fLo /docker-buildx https://github.com/docker/buildx/releases/download/${BUILDX_VERSION}/buildx-${BUILDX_VERSION}.linux-${TARGETARCH}
    chmod +x /docker-buildx
EOT

FROM curl AS compose-cli
ARG TARGETARCH
ARG CLOUD_CLI_VERSION=v1.0.29
RUN <<EOT ash
    curl -fLo /docker https://github.com/docker/compose-cli/releases/download/${CLOUD_CLI_VERSION}/docker-linux-${TARGETARCH}
    chmod +x /docker
EOT
ARG GO_COMPOSE_VERSION=v2.10.2
RUN <<EOT ash
    curl -fLo /docker-compose https://github.com/docker/compose/releases/download/${GO_COMPOSE_VERSION}/docker-compose-linux-$(uname -m)
    chmod +x /docker-compose
EOT

FROM curl AS scan-plugin
ARG SCAN_VERSION=v0.19.0
RUN <<EOT ash
    curl -fLo /docker-scan https://github.com/docker/scan-cli-plugin/releases/download/${SCAN_VERSION}/docker-scan_linux_amd64
    chmod +x /docker-scan
EOT

FROM scratch AS common
COPY --from=cli            /docker         /usr/local/bin/com.docker.cli
COPY --from=compose-cli    /docker         /usr/local/bin/docker
COPY --from=compose-cli    /docker-compose /usr/lib/docker/cli-plugins/docker-compose
COPY --from=buildx-plugin  /docker-buildx  /usr/lib/docker/cli-plugins/docker-buildx
COPY --from=scan-plugin     /docker-scan    /usr/lib/docker/cli-plugins/docker-scan

FROM common AS docker-amd64

FROM common AS docker-arm64

FROM docker-${TARGETARCH} AS docker
