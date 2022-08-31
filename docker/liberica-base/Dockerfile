# Adapted from https://github.com/bell-sw/Liberica/blob/master/docker/repos/liberica-openjre-alpine/17/Dockerfile

FROM ghcr.io/permutive-engineering/permutive-glibc as glibc-base

FROM alpine:3.15 as base

ARG GLIBC_PREFIX=/usr/glibc
ARG EXT_GCC_LIBS_URL_X86=https://archive.archlinux.org/packages/g/gcc-libs/gcc-libs-11.1.0-3-x86_64.pkg.tar.zst
ARG EXT_ZLIB_URL_X86=https://archive.archlinux.org/packages/z/zlib/zlib-1%3A1.2.11-5-x86_64.pkg.tar.zst
ARG EXT_GCC_LIBS_URL_ARM=https://alaa.ad24.cz/packages/g/gcc-libs/gcc-libs-11.2.0-3-aarch64.pkg.tar.xz
ARG EXT_ZLIB_URL_ARM=https://alaa.ad24.cz/packages/z/zlib/zlib-1%3A1.2.11-5-aarch64.pkg.tar.xz
ARG LANG=en_US.UTF-8
ARG OPT_PKGS=

ENV  LANG=${LANG} \
     LANGUAGE=${LANG}:en

COPY --from=glibc-base /root/dest/ /

RUN     ln -s ${GLIBC_PREFIX}/lib/ld-*.so* /lib \
  &&    ln -s ${GLIBC_PREFIX}/etc/ld.so.cache /etc \
  &&    if [ `uname -m` = "x86_64" ]; then ln -s /lib /lib64 \
  &&      apk --no-cache add zstd \
  &&      mkdir /tmp/zlib && wget -O - "${EXT_ZLIB_URL_X86}" | unzstd | tar xf - -C /tmp/zlib \
  &&      cp -dP /tmp/zlib/usr/lib/libz.so* "${GLIBC_PREFIX}/lib" \
  &&      rm -rf /tmp/zlib \
  &&      mkdir /tmp/gcc && wget -O - "${EXT_GCC_LIBS_URL_X86}" | unzstd | tar xf - -C /tmp/gcc \
  &&      cp -dP /tmp/gcc/usr/lib/libgcc* /tmp/gcc/usr/lib/libstdc++* "${GLIBC_PREFIX}/lib" \
  &&      rm -rf /tmp/gcc \
  &&      apk del zstd; \
        fi \
  &&    if [ `uname -m` = "aarch64" ]; then ln -s /lib /lib64 \
  &&      mkdir /tmp/zlib && wget -O /tmp/zlib.tar.xz "${EXT_ZLIB_URL_ARM}" \
  &&      tar -xvf /tmp/zlib.tar.xz -C /tmp/zlib \
  &&      cp -dP /tmp/zlib/usr/lib/libz.so* "${GLIBC_PREFIX}/lib" \
  &&      rm -rf /tmp/zlib /tmp/zlib.tar.xz \
  &&      mkdir /tmp/gcc && wget -O /tmp/gcc.tar.xz "${EXT_GCC_LIBS_URL_ARM}" \
  &&      tar xf /tmp/gcc.tar.xz -C /tmp/gcc \
  &&      cp -dP /tmp/gcc/usr/lib/libgcc* /tmp/gcc/usr/lib/libstdc++* "${GLIBC_PREFIX}/lib" \
  &&      rm -rf /tmp/gcc /tmp/gcc.tar.xz; \
        fi \
  &&    for pkg in $OPT_PKGS ; do apk --no-cache add $pkg ; done \
  &&    ${GLIBC_PREFIX}/sbin/ldconfig \
  &&    echo 'hosts: files mdns4_minimal [NOTFOUND=return] dns mdns4' > /etc/nsswitch.conf \
  &&    apk add --no-cache jattach --repository http://dl-cdn.alpinelinux.org/alpine/edge/community/ \
  &&    apk add --no-cache tini
