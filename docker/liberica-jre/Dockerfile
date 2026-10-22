# Adapted from https://github.com/bell-sw/Liberica/blob/master/docker/repos/liberica-openjre-alpine/17/Dockerfile

FROM ghcr.io/permutive-engineering/permutive-liberica-base as jre

ARG LIBERICA_VARIANT=jre
ARG LIBERICA_PKG_URL_ARM=""
ARG LIBERICA_SHA1_ARM=""
ARG LIBERICA_PKG_URL_X86=""
ARG LIBERICA_SHA1_X86=""
ARG LIBERICA_ROOT=/usr/lib/jvm/${LIBERICA_VARIANT}-bellsoft

ADD ${LIBERICA_PKG_URL_ARM} /jre-arm.tar.gz
ADD ${LIBERICA_PKG_URL_X86} /jre-x86.tar.gz

RUN case `uname -m` in \
              x86_64) \
                  LIBERICA_PKG="/jre-x86.tar.gz" \
                  LIBERICA_SHA1=$LIBERICA_SHA1_X86 \
                  ;; \
              aarch64) \
                  LIBERICA_PKG="/jre-arm.tar.gz" \
                  LIBERICA_SHA1=$LIBERICA_SHA1_ARM \
                  ;; \
              *) \
            LIBERICA_PKG="" \
            LIBERICA_SHA1="" \
            ;; \
        esac \
  &&    mkdir -p $LIBERICA_ROOT \
  &&    mkdir -p /tmp/java \
  &&    RSUFFIX="" \
  &&    echo "${LIBERICA_SHA1} *${LIBERICA_PKG}" | sha1sum -c - \
  &&    tar xzvf ${LIBERICA_PKG} -C /tmp/java \
  &&    find "/tmp/java" -maxdepth 2 -mindepth 2 -exec /bin/mv "{}" "${LIBERICA_ROOT}/" \; \
  &&    ln -s $LIBERICA_ROOT /usr/lib/jvm/jre 

FROM ghcr.io/permutive-engineering/permutive-liberica-base

ARG LIBERICA_VARIANT=jre
ARG LIBERICA_ROOT=/usr/lib/jvm/${LIBERICA_VARIANT}-bellsoft

COPY --from=jre ${LIBERICA_ROOT} ${LIBERICA_ROOT}

RUN ln -s $LIBERICA_ROOT /usr/lib/jvm/jre \
  &&    (ls /usr/lib/jvm/jre/lib/client 1>/dev/null 2>&1 && (rm -rf /usr/lib/jvm/jre/lib/client && sed -i 's#-client\s\+KNOWN#-client IGNORE#g' /usr/lib/jvm/jre/lib/jvm.cfg) || : )

ENV JAVA_HOME=${LIBERICA_ROOT} \
	PATH=${LIBERICA_ROOT}/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# eMudhra CA compromise: BellSoft's interim mitigation (remove emSign ECC Root CA - G3 and AAA Certificate Services),
# matched by SHA-256 fingerprint because the alias differs between Liberica builds. Fails the build if either remains.
# https://bell-sw.com/blog/distrusting-compromised-emudhra-intermediates-in-java
RUN keytool -list -v -cacerts -storepass changeit \
    | awk '/^Alias name: /{sub(/^Alias name: /,""); a=$0} /SHA256: /{print $2 "\t" a}' \
    | grep -E '^(86:A1:EC:BA:08:9C:4A:8D:3B:BE:27:34:C6:12:BA:34:1D:81:3E:04:3C:F9:E8:A8:62:CD:5C:57:A3:6B:BE:6B|D7:A7:A0:FB:5D:7E:27:31:D7:71:E9:48:4E:BC:DE:F7:1D:5F:0C:3E:0A:29:48:78:2B:C8:3E:E0:EA:69:9E:F4)	' \
    | cut -f2 \
    | while IFS= read -r alias; do keytool -delete -cacerts -storepass changeit -alias "$alias"; done \
 && ! keytool -list -v -cacerts -storepass changeit | grep -qE 'SHA256: (86:A1:EC:BA:08:9C|D7:A7:A0:FB:5D:7E)'
