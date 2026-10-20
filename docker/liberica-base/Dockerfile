# Adapted from https://github.com/bell-sw/Liberica/blob/master/docker/repos/liberica-openjre-alpine/17/Dockerfile

# First stage does nothing other than reference the glibc base image
FROM ghcr.io/permutive-engineering/permutive-glibc as glibc-base

# Second stage copies the various dynamic libaries into place, ignoring extra the majority of gcc and zlib binaries
FROM alpine:3.18 as glibc-extras

ARG GLIBC_PREFIX=/usr/glibc

COPY --from=glibc-base /root/dest/ /
COPY --from=glibc-base /root/zlib/ /tmp/zlib/
COPY --from=glibc-base /root/gcc/ /tmp/gcc/

RUN   cp -dP /tmp/zlib/usr/lib/libz.so* "${GLIBC_PREFIX}/lib" \
  &&  cp -dP /tmp/gcc/usr/lib/libgcc* /tmp/gcc/usr/lib/libstdc++* "${GLIBC_PREFIX}/lib"

# Final stage ensures the extra gcc and zlib binaries aren't included in the final image
FROM alpine:3.18

ARG GLIBC_PREFIX=/usr/glibc
ARG LANG=en_US.UTF-8
ARG OPT_PKGS=

ENV  LANG=${LANG} \
     LANGUAGE=${LANG}:en

COPY --from=glibc-extras /usr/glibc /usr/glibc

RUN ln -s /lib /lib64 \
  &&   ln -s ${GLIBC_PREFIX}/lib/ld-*.so* /lib \
  &&   ln -s ${GLIBC_PREFIX}/etc/ld.so.cache /etc \
  &&   for pkg in $OPT_PKGS ; do apk --no-cache add $pkg ; done \
  &&   ${GLIBC_PREFIX}/sbin/ldconfig \
  &&   echo 'hosts: files mdns4_minimal [NOTFOUND=return] dns mdns4' > /etc/nsswitch.conf \
  &&   apk upgrade --update --no-cache libcrypto3 libssl3 \
  &&   apk add --no-cache jattach --repository http://dl-cdn.alpinelinux.org/alpine/edge/community/ \
  &&   apk add --no-cache tini libstdc++

# async-profiler, installed at /opt/async-profiler with asprof and jfrconv on the PATH.
# async-profiler publishes no checksums: when bumping the version, update both SHA-256 values
# (`sha256sum async-profiler-<version>-linux-{x64,arm64}.tar.gz`) or the build fails.
# renovate: datasource=github-releases depName=async-profiler/async-profiler
ARG ASYNC_PROFILER_VERSION=4.5
ARG ASYNC_PROFILER_SHA256_X64=89546fbb9ee0fc5496c7edd4099b0709489bc78b0d8057ccbb4b801f6b032b62
ARG ASYNC_PROFILER_SHA256_ARM64=64c41d1465d60097439c50d7e924b4946f1f62b1cbd21ce5b034fad09c0d6979

# async-profiler 3+ moved profiler.sh to bin/asprof and build/ to lib/. The symlinks keep the 2.x paths
# (e.g. -agentpath:/opt/async-profiler/build/libasyncProfiler.so) working.
RUN case `uname -m` in \
       x86_64)  PLATFORM=x64   ASYNC_PROFILER_SHA256=$ASYNC_PROFILER_SHA256_X64 ;; \
       aarch64) PLATFORM=arm64 ASYNC_PROFILER_SHA256=$ASYNC_PROFILER_SHA256_ARM64 ;; \
       *)       echo "Unsupported architecture: `uname -m`" && exit 1 ;; \
     esac \
  &&   ASYNC_PROFILER_URL="https://github.com/async-profiler/async-profiler/releases/download/v${ASYNC_PROFILER_VERSION}/async-profiler-${ASYNC_PROFILER_VERSION}-linux-${PLATFORM}.tar.gz" \
  &&   echo "Downloading $ASYNC_PROFILER_URL" \
  &&   apk add --no-cache --virtual .fetch-deps curl \
  &&   curl -fsSL "$ASYNC_PROFILER_URL" -o /tmp/async-profiler.tgz \
  &&   apk del .fetch-deps \
  &&   echo "${ASYNC_PROFILER_SHA256}  /tmp/async-profiler.tgz" | sha256sum -c - \
  &&   mkdir -p /opt/async-profiler \
  &&   tar xzf /tmp/async-profiler.tgz -C /opt/async-profiler --strip-components=1 \
  &&   rm /tmp/async-profiler.tgz \
  &&   ln -s bin/asprof /opt/async-profiler/profiler.sh \
  &&   ln -s lib /opt/async-profiler/build \
  &&   ln -s /opt/async-profiler/bin/asprof /usr/local/bin/asprof \
  &&   ln -s /opt/async-profiler/bin/jfrconv /usr/local/bin/jfrconv \
  &&   asprof --version
