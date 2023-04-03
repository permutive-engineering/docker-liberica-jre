#!/bin/bash
set -e 

ALPINE_IMAGE="alpine:3.17"
export REMOTE_REPO=ghcr.io/permutive-engineering
JRES="11 17"

# Re-tag alpine for use in the JRE base image
docker pull $ALPINE_IMAGE
docker tag $ALPINE_IMAGE alpine-base

# Work out if the base image need a rebuild
# Using the --cache-from argument was tried, but due to the nature of the docker build itself
# this failed. So instead we check to see if the Alpine base image SHA has changed


BUILD_BASE=true
BASE_SHA=$(docker images $ALPINE_IMAGE --no-trunc --format "{{.ID}}")
BASE_SHA_FILE=/tmp/docker-builds/alpine-sha
mkdir -p /tmp/docker-builds
if [[ -f $BASE_SHA_FILE ]]; then
  if [[ $(cat $BASE_SHA_FILE | xargs) == $BASE_SHA ]]; then
    echo "Alpine image sha matches cache, not building base"
    BUILD_BASE=false
  fi
fi


export BASE_IMAGE_NAME="$REMOTE_REPO/permutive-liberica-base"
export IMAGE_NAME="$REMOTE_REPO/permutive-jre-liberica"
export PUSHARG=""
if [[ "$1" == "push" ]]; then
  export PUSHARG="--push"
fi


if !(docker buildx ls | grep liberica); then
  docker buildx create --name liberica
fi
docker buildx use liberica
docker buildx inspect --bootstrap


pushd $(dirname "$0")

if [[ "$BUILD_BASE" == "true" ]]; then
  echo Building Base Image
  pushd liberica-base

  docker buildx build --platform linux/amd64,linux/arm64 -t $BASE_IMAGE_NAME $PUSHARG .

  echo $BASE_SHA > $BASE_SHA_FILE
  popd
fi

pushd liberica-jre

function build_jre {
    JRE=$1
    BUILD_BASE=$2
    echo $3 | while read -r armDownloadUrl armSha1 x86DownloadUrl x86Sha1 version latest latestInFeatureVersion; do
      echo $version
      # Build an image for each JRE using the base image that includes glibc

      SANITISED_VERSION_BUILD=$(echo $version | sed -e 's/\+/b/')
      SANITISED_VERSION=$(echo $version | cut -d '+' -f 1)

      # As above, due to the commands run in the docker build we can't use --cache-from, so we use the JRE's SHA
      # If the base image has been rebuilt, then we need to rebuild here too

      BUILD_IMAGE=true
      CACHED_SHA_FILE=/tmp/docker-builds/jre-$SANITISED_VERSION_BUILD-sha
      if [[ -f $CACHED_SHA_FILE ]]; then
          if [[ $(cat $CACHED_SHA_FILE | xargs) == "$armSha1$x86Sha1" && "$BUILD_BASE" == "false" ]]; then
            echo "JRE sha matches cache, not building $version"
            BUILD_IMAGE=false
          fi
      fi

      if [[ "$BUILD_IMAGE" == "true" ]];then
        TAGS="-t $IMAGE_NAME:$SANITISED_VERSION_BUILD -t $IMAGE_NAME:$SANITISED_VERSION"
        if [ "$latest" == "true" ]; then
          TAGS="$TAGS -t $IMAGE_NAME:latest"
        fi
        if [ "$latestInFeatureVersion" == "true" ]; then
          TAGS="$TAGS -t $IMAGE_NAME:$JRE"
        fi
        echo $TAGS

        docker buildx build --platform linux/amd64,linux/arm64 --build-arg LIBERICA_PKG_URL_ARM=$armDownloadUrl --build-arg LIBERICA_PKG_URL_X86=$x86DownloadUrl --build-arg LIBERICA_SHA1_ARM=$armSha1 --build-arg LIBERICA_SHA1_X86=$x86Sha1 $TAGS $PUSHARG .

        echo "$armSha1$x86Sha1" > $CACHED_SHA_FILE
      fi
    done
}

export SHELL=$(type -p bash)
export -f build_jre

for JRE in $JRES; do
  # Use the Liberica API to get all of the releases for the major version
  curl "https://api.bell-sw.com/v1/liberica/releases?version-feature=$JRE&bitness=64&os=linux&arch=x86&arch=arm&package-type=tar.gz&bundle-type=jre" 2> /dev/null | jq -r 'group_by(.version)[] | [sort_by(.architecture)[]] | [.[0].downloadUrl, .[0].sha1, .[1].downloadUrl, .[1].sha1, .[0].version, .[0].latest, .[0].latestInFeatureVersion] | @tsv' | parallel -j 4 "build_jre $JRE $BUILD_BASE {}"
done

popd
popd
