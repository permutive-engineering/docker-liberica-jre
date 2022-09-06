# Adapted from https://github.com/bell-sw/Liberica/blob/master/docker/repos/liberica-openjre-alpine/17/Dockerfile

FROM ghcr.io/permutive-engineering/permutive-liberica-base

ARG LIBERICA_VERSION=""
ARG LIBERICA_VARIANT=jre
ARG LIBERICA_SHA1_ARM=""
ARG LIBERICA_SHA1_X86=""
ARG LIBERICA_ROOT=/usr/lib/jvm/${LIBERICA_VARIANT}-${LIBERICA_VERSION}-bellsoft
ARG LIBERICA_PKG_URL_ARM=""
ARG LIBERICA_PKG_URL_X86=""


RUN case `uname -m` in \
              x86_64) \
                  LIBERICA_PKG_URL=$LIBERICA_PKG_URL_X86 \
                  LIBERICA_SHA1=$LIBERICA_SHA1_X86 \
                  ;; \
              aarch64) \
                  LIBERICA_PKG_URL=$LIBERICA_PKG_URL_ARM \
                  LIBERICA_SHA1=$LIBERICA_SHA1_ARM \
                  ;; \
              *) \
            LIBERICA_PKG_URL="" \
            LIBERICA_SHA1="" \
            ;; \
        esac \
  &&    mkdir -p $LIBERICA_ROOT \
  &&    mkdir -p /tmp/java \
  &&    RSUFFIX="" \
  &&    wget "${LIBERICA_PKG_URL}" -O /tmp/java/jre.tar.gz \
  &&    echo "${LIBERICA_SHA1} */tmp/java/jre.tar.gz" | sha1sum -c - \
  &&    tar xzvf /tmp/java/jre.tar.gz -C /tmp/java \
  &&    find "/tmp/java" -maxdepth 2 -mindepth 2 -exec mv "{}" "${LIBERICA_ROOT}/" \; \
  &&    ln -s $LIBERICA_ROOT /usr/lib/jvm/jre \
  &&    rm -rf /tmp/java \
  &&    (ls /usr/lib/jvm/jre/lib/client 1>/dev/null 2>&1 && (rm -rf /usr/lib/jvm/jre/lib/client && sed -i 's#-client\s\+KNOWN#-client IGNORE#g' /usr/lib/jvm/jre/lib/jvm.cfg) || : )

ENV JAVA_HOME=${LIBERICA_ROOT} \
	PATH=${LIBERICA_ROOT}/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
