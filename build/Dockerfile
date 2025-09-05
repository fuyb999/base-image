ARG IMAGE_BASE="nvidia/cuda:11.8.0-base-ubuntu22.04"

# Caddy build
FROM ghcr.io/ai-dock/base-image:v2-cpu-22.04 AS caddybuilder

# Caddy build
FROM ubuntu:22.04 AS caddybuilder2

ENV PATH=/opt/go/bin:$PATH
ENV GOROOT=/opt/go

# Update mirror
RUN sed -i -E 's/(archive|security).ubuntu.com/mirrors.tuna.tsinghua.edu.cn/g' /etc/apt/sources.list

RUN apt-get update && \
    apt-get install -y git wget && \
    wget https://mirrors.aliyun.com/golang/go1.12.4.linux-amd64.tar.gz -O /tmp/go1.12.4.linux-amd64.tar.gz

RUN \
    tar -xf /tmp/go1.12.4.linux-amd64.tar.gz -C /opt && \
    wget https://github.com/caddyserver/xcaddy/releases/download/v0.4.2/xcaddy_0.4.2_linux_amd64.deb && \
    apt-get install ./xcaddy_0.4.2_linux_amd64.deb

RUN \
    xcaddy build \
        --with github.com/caddyserver/caddy/v2=github.com/ai-dock/caddy/v2@httpredirect \
        --with github.com/caddyserver/replace-response && \
    mkdir -p /opt/caddy/bin && \
    mkdir -p /opt/caddy/tls && \
    mv ./caddy /opt/caddy/bin

FROM jlesage/baseimage:ubuntu-22.04-v3 AS base

# For build automation - Allows building from any Debian-based image

FROM ${IMAGE_BASE}

# System libs are handled in /etc/ld.so.conf.d
# Python environments only to use this variable
ENV LD_LIBRARY_PATH=""

#COPY --from=caddybuilder /opt/caddy/ /opt/caddy/
COPY --from=base /defaults/service /defaults/service
COPY --from=base /etc/logmonitor /etc/logmonitor
COPY --from=base /etc/services.d /etc/services.d
COPY --from=base /opt/base/etc /opt/base/etc
COPY --from=base /opt/base/bin /opt/base/bin
COPY --from=base /opt/base/sbin /opt/base/sbin

# Determines which scripts at /opt/ai-dock/bin/build/layerX will be run by init.sh
# GPU_AMD, CPU
ARG XPU_TARGET="GPU_NVIDIA"
ENV XPU_TARGET=${XPU_TARGET}

ARG NODE_VERSION=v22.2.0
ENV NODE_VERSION=${NODE_VERSION}

LABEL org.opencontainers.image.source=https://github.com/ai-dock/base-image

LABEL org.opencontainers.image.description="Base image for ai-dock."

LABEL maintainer="Rob Ballantyne <rob@dynamedia.uk>"

SHELL ["/bin/bash", "-c"]
# Set ENV variables
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV TZ=UTC
ENV SHELL="/bin/bash"
ENV USER_NAME=develop
ENV USER_PASSWORD=develop
ENV USER_GROUPS=users,ai-dock,adm,sudo,audio,video,tty,cdrom,dialout,dip,fax,floppy,lp,plugdev,ssl-cert,sudo,tape,voice
ENV DEBIAN_FRONTEND=noninteractive
ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt/base/sbin:/opt/base/bin:/opt/ai-dock/bin:/opt/caddy/bin
ENV OPT_SYNC=""
ENV PYTHONUNBUFFERED=true
ENV VENV_DIR=/opt/environments/python
ENV SERVICEPORTAL_VENV=${VENV_DIR}/serviceportal
ENV SERVICEPORTAL_VENV_PYTHON=${SERVICEPORTAL_VENV}/bin/python
ENV SERVICEPORTAL_VENV_PIP=${SERVICEPORTAL_VENV}/bin/pip
ENV SUPERVISOR_NO_AUTOSTART=""

ENV APT_INSTALL="apt-get install -y --no-install-recommends"
ENV RCLONE_CONFIG="/etc/rclone/rclone.conf"
ENV IMAGE_SLUG="base-image"
ENV GROUP_ID=1000
ENV USER_ID=1000
# Copy early so we can use scripts in the build - Changes to these files will invalidate the cache and cause a rebuild.
COPY --chown=0:1111 ./COPY_ROOT_0/ /

ARG CUDA_STRING
ARG ROCM_STRING

# Update mirror
RUN sed -i -E 's/(archive|security).ubuntu.com/mirrors.tuna.tsinghua.edu.cn/g' /etc/apt/sources.list

# Use build scripts to ensure we can build all targets from one Dockerfile in a single layer.
# Don't put anything heavy in here - We can use multi-stage building above if necessary.
#RUN yes | unminimize && \
#    set -eo pipefail && /opt/ai-dock/bin/build/layer0/init.sh | tee /var/log/build.log

RUN /opt/ai-dock/bin/build/layer0/init.sh | tee /var/log/build.log
# Keep init.sh as-is and place additional logic in /opt/ai-dock/bin/preflight.d
CMD ["init.sh"]
