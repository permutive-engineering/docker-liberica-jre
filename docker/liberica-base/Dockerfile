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
  &&   apk add --no-cache jattach --repository http://dl-cdn.alpinelinux.org/alpine/edge/community/ \
  &&   apk add --no-cache tini libstdc++ \
  &&   PLATFORM=$([ `uname -m` = "x86_64" ] && echo "x64" || echo "arm64") \
  &&   ASYNC_PROFILER_URL="https://github.com/jvm-profiling-tools/async-profiler/releases/download/v2.8.3/async-profiler-2.8.3-linux-$PLATFORM.tar.gz" \
  &&   echo "Downloading $ASYNC_PROFILER_URL" \
  &&   apk add --no-cache curl && curl $ASYNC_PROFILER_URL -o /tmp/async-profiler.tgz -L -s  && apk del curl \
  &&   tar xf /tmp/async-profiler.tgz -C /opt \
  &&   rm /tmp/async-profiler.tgz \
  &&   mv opt/async-profiler* /opt/async-profiler
