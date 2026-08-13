# OSCRouter as a container: the routing engine plus its web interface, no GUI.
#
# Build context is this repository root. The two sources are submodules under
# src/, kept as siblings because OSCRouter's CMakeLists refers to EosSyncLib as
# "../EosSyncLib".
#
#   git submodule update --init
#   docker build -t oscrouter .
#   docker run --rm --network host -v $PWD/config:/config oscrouter
#
# --network host is not optional if you use sACN, Art-Net, PSN or OTP: those are
# multicast and broadcast protocols, and Docker's default bridge network will
# silently fail to carry them.

# ---------------------------------------------------------------- build stage

FROM debian:trixie AS builder

RUN apt-get update && apt-get install -y --no-install-recommends \
      build-essential \
      cmake \
      ninja-build \
      qt6-base-dev \
      qt6-declarative-dev \
      libasound2-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src
COPY src/OSCRouter/ ./OSCRouter/
COPY src/EosSyncLib/ ./EosSyncLib/

# The desktop application is deliberately not built: it would pull in Qt Widgets
# and Qt Gui, which the container has no use for.
RUN cmake -S OSCRouter -B build -G Ninja \
      -DCMAKE_BUILD_TYPE=RelWithDebInfo \
      -DOSCROUTER_BUILD_GUI=OFF \
      -DOSCROUTER_BUILD_DAEMON=ON \
    && cmake --build build --parallel

# Work out which runtime packages the binary actually needs, rather than naming
# them here: Debian renames shared library packages fairly often (the recent
# 64-bit time_t transition added a "t64" suffix to many of them), and deriving
# the list keeps this working across releases.
#
# readlink -f matters twice over: ldd reports paths under /lib, which on a
# usrmerged system is a symlink to /usr/lib and so matches nothing in dpkg's
# database, and dpkg records the versioned real file rather than the SONAME
# symlink. Without it this silently yields almost nothing and the image ends up
# missing its Qt libraries, so the result is sanity checked.
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

FROM debian:trixie-slim

COPY --from=builder /runtime-packages.txt /tmp/runtime-packages.txt
RUN apt-get update \
    && xargs -a /tmp/runtime-packages.txt apt-get install -y --no-install-recommends \
    && rm -rf /var/lib/apt/lists/* /tmp/runtime-packages.txt

COPY --from=builder /src/build/oscrouterd /usr/local/bin/oscrouterd

# Qt warns and overrides the locale at startup otherwise.
ENV LANG=C.UTF-8

# The configuration lives on a volume so it survives the container.
VOLUME ["/config"]
EXPOSE 8099

ENTRYPOINT ["/usr/local/bin/oscrouterd"]
CMD ["--config", "/config/oscrouter.osc.txt", "--port", "8099", "--bind", "0.0.0.0"]
