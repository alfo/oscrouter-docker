# Home Assistant add-on image for OSCRouter.
#
# BUILD_FROM is supplied by build.yaml. Since Supervisor 2026.04.0 it is no
# longer injected automatically, so build.yaml names the base image explicitly.
#
# The Debian base is used rather than the default Alpine one: Qt 6 against musl
# is a considerably rougher path than against glibc, and the Debian archive has
# the Qt packages this needs.
ARG BUILD_FROM
ARG BUILD_ARCH

# ---------------------------------------------------------------- build stage

FROM debian:trixie AS builder

# Where to fetch the sources. This repository carries both OSCRouter and
# EosSyncLib as submodules under src/, already pointing at the forks that hold
# the Linux port; upstream ETCLabs builds for macOS and Windows only.
ARG SOURCE_REPO
ARG SOURCE_REF=main

RUN apt-get update && apt-get install -y --no-install-recommends \
      build-essential \
      cmake \
      ninja-build \
      git \
      ca-certificates \
      qt6-base-dev \
      qt6-declarative-dev \
      libasound2-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /work
RUN git clone --depth 1 --recurse-submodules --shallow-submodules \
      --branch "${SOURCE_REF}" "${SOURCE_REPO}" .

WORKDIR /src
RUN cmake -S /work/src/OSCRouter -B build -G Ninja \
      -DCMAKE_BUILD_TYPE=RelWithDebInfo \
      -DOSCROUTER_BUILD_GUI=OFF \
      -DOSCROUTER_BUILD_DAEMON=ON \
    && cmake --build build --parallel

# Derived rather than hard-coded; see the comment in the root Dockerfile for why
# readlink -f is needed and why the result is sanity checked.
RUN ldd build/oscrouterd \
      | awk '/=> \//{print $3}' \
      | xargs -r readlink -f \
      | xargs -r dpkg-query -S 2>/dev/null \
      | cut -d: -f1 \
      | sort -u \
      > /runtime-packages.txt \
    && cat /runtime-packages.txt \
    && grep -q '^libqt6core' /runtime-packages.txt \
    && grep -q '^libqt6qml' /runtime-packages.txt \
    && grep -q '^libqt6network' /runtime-packages.txt

# -------------------------------------------------------------- runtime stage

FROM ${BUILD_FROM}

COPY --from=builder /runtime-packages.txt /tmp/runtime-packages.txt
RUN apt-get update \
    && xargs -a /tmp/runtime-packages.txt apt-get install -y --no-install-recommends \
    && rm -rf /var/lib/apt/lists/* /tmp/runtime-packages.txt

COPY --from=builder /src/build/oscrouterd /usr/local/bin/oscrouterd

COPY run.sh /run.sh
RUN chmod a+x /run.sh

CMD ["/run.sh"]
