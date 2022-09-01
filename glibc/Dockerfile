# Adapted from https://github.com/bell-sw/Liberica/blob/master/docker/repos/liberica-openjre-alpine/17/Dockerfile

FROM debian:11-slim 

ARG GLIBC_VERSION=2.34
ARG GLIBC_PREFIX=/usr/glibc
ARG LANG=en_US.UTF-8
ARG EXT_GCC_LIBS_URL_X86=https://archive.archlinux.org/packages/g/gcc-libs/gcc-libs-11.1.0-3-x86_64.pkg.tar.zst
ARG EXT_ZLIB_URL_X86=https://archive.archlinux.org/packages/z/zlib/zlib-1%3A1.2.11-5-x86_64.pkg.tar.zst
ARG EXT_GCC_LIBS_URL_ARM=https://alaa.ad24.cz/packages/g/gcc-libs/gcc-libs-11.2.0-3-aarch64.pkg.tar.xz
ARG EXT_ZLIB_URL_ARM=https://alaa.ad24.cz/packages/z/zlib/zlib-1%3A1.2.11-5-aarch64.pkg.tar.xz

RUN apt-get update && apt-get install -y \
  curl build-essential gawk bison python3 texinfo gettext wget zstd

RUN cd /root \
  &&  if [ `uname -m` = "x86_64" ]; then mkdir /root/zlib \
  &&      wget -O - "${EXT_ZLIB_URL_X86}" | unzstd | tar xf - -C /root/zlib \
  &&      mkdir /root/gcc \
  &&      wget -O - "${EXT_GCC_LIBS_URL_X86}" | unzstd | tar xf - -C /root/gcc; \
      fi \
  &&  if [ `uname -m` = "aarch64" ]; then mkdir /root/zlib \
  &&     wget -O /tmp/zlib.tar.xz "${EXT_ZLIB_URL_ARM}" \
  &&     tar -xf /tmp/zlib.tar.xz -C /root/zlib \
  &&     mkdir /root/gcc \
  &&     wget -O /tmp/gcc.tar.xz "${EXT_GCC_LIBS_URL_ARM}" \
  &&     tar xf /tmp/gcc.tar.xz -C /root/gcc; \
      fi

RUN cd /root && \
  curl -SL http://ftp.gnu.org/gnu/glibc/glibc-${GLIBC_VERSION}.tar.gz | tar xzf - && \
  mkdir -p /root/build && cd /root/build && \
  ../glibc-${GLIBC_VERSION}/configure \
    --prefix=${GLIBC_PREFIX} \
    --libdir="${GLIBC_PREFIX}/lib" \
    --libexecdir="${GLIBC_PREFIX}/lib" \
    --enable-multi-arch \
    --enable-stack-protector=strong \
  && \
  make -j`nproc` > /dev/null && make DESTDIR=/root/dest install > /dev/null && \
  RTLD=`find /root/dest${GLIBC_PREFIX}/lib -name 'ld-linux-*.so.*'` && [ -x "$RTLD" ] && \
  LOCALEDEF="$RTLD --library-path /root/dest${GLIBC_PREFIX}/lib /root/dest${GLIBC_PREFIX}/bin/localedef --alias-file=/root/glibc-${GLIBC_VERSION}/intl/locale.alias" && \
  export I18NPATH=/root/glibc-${GLIBC_VERSION}/localedata && \
  export GCONVPATH=/root/glibc-${GLIBC_VERSION}/iconvdata && \
  LOCALE=$(echo ${LANG} | cut -d. -f1) && CHARMAP=$(echo ${LANG} | cut -d. -f2) && \
  mkdir -pv /root/dest${GLIBC_PREFIX}/lib/locale && \
  cd /root/glibc-${GLIBC_VERSION}/localedata && \
  ${LOCALEDEF} -i locales/$LOCALE -f charmaps/$CHARMAP --prefix=/root/dest $LANG && \
  cd /root && rm -rf build glibc-${GLIBC_VERSION} && \
  cd /root/dest${GLIBC_PREFIX} && \
  ( strip bin/* sbin/* lib/* || true ) && \
  echo "/usr/local/lib" > /root/dest${GLIBC_PREFIX}/etc/ld.so.conf && \
  echo "${GLIBC_PREFIX}/lib" >> /root/dest${GLIBC_PREFIX}/etc/ld.so.conf && \
  echo "/usr/lib" >> /root/dest${GLIBC_PREFIX}/etc/ld.so.conf && \
  echo "/lib" >> /root/dest${GLIBC_PREFIX}/etc/ld.so.conf

RUN cd /root/dest${GLIBC_PREFIX} && \
  rm -rf etc/rpc var include share bin sbin/[^l]*  \
	lib/*.o lib/*.a lib/audit lib/gconv lib/getconf

