#!/bin/bash
set -e

ALPINE_IMAGE="alpine:3.15"
export PUSH=$1
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


export BASE_IMAGE_NAME="permutive-liberica-base"
export IMAGE_NAME="permutive-jre-liberica"


function tag {
  docker tag $1 $2
  docker tag $1 $REMOTE_REPO/$2
  if [ "$PUSH" == "push" ]; then
    docker push $REMOTE_REPO/$2
  fi
}

pushd $(dirname "$0")

if [[ "$BUILD_BASE" == "true" ]]; then
  pushd liberica-base

  docker build . -t $BASE_IMAGE_NAME
  tag $BASE_IMAGE_NAME $BASE_IMAGE_NAME

  echo $BASE_SHA > $BASE_SHA_FILE
  popd
fi

pushd liberica-jre

function build_jre {
    JRE=$1
    BUILD_BASE=$2
    echo $3 | while read -r downloadUrl version sha1 latest latestInFeatureVersion; do
      echo $version
      # Build an image for each JRE using the base image that includes glibc

      TEMP_TAG=$sha1
      SANITISED_VERSION_BUILD=$(echo $version | sed -e 's/\+/b/')
      SANITISED_VERSION=$(echo $version | cut -d '+' -f 1)

      # As above, due to the commands run in the docker build we can't use --cache-from, so we use the JRE's SHA
      # If the base image has been rebuilt, then we need to rebuild here too

      BUILD_IMAGE=true
      CACHED_SHA_FILE=/tmp/docker-builds/jre-$SANITISED_VERSION_BUILD-sha
      if [[ -f $CACHED_SHA_FILE ]]; then
          if [[ $(cat $CACHED_SHA_FILE | xargs) == $sha1 && "$BUILD_BASE" == "false" ]]; then
            echo "JRE sha matches cache, not building $version"
            BUILD_IMAGE=false
          fi
      fi


      if [[ "$BUILD_IMAGE" == "true" ]];then
        docker build . --build-arg LIBERICA_PKG_URL=$downloadUrl --build-arg LIBERICA_VERSION=$version --build-arg LIBERICA_SHA1=$sha1 -t "$IMAGE_NAME:$TEMP_TAG"
        tag "$IMAGE_NAME:$TEMP_TAG" "$IMAGE_NAME:$SANITISED_VERSION_BUILD"
        tag "$IMAGE_NAME:$TEMP_TAG" "$IMAGE_NAME:$SANITISED_VERSION"
        if [ "$latest" == "true" ]; then
          tag "$IMAGE_NAME:$TEMP_TAG" "$IMAGE_NAME:latest"
        fi
        if [ "$latestInFeatureVersion" == "true" ]; then
          tag "$IMAGE_NAME:$TEMP_TAG" "$IMAGE_NAME:$JRE"
        fi

        docker rmi $IMAGE_NAME:$TEMP_TAG

        echo $sha1 > $CACHED_SHA_FILE
      fi
    done
}

export SHELL=$(type -p bash)
export -f build_jre
export -f tag

for JRE in $JRES; do
  # Use the Liberica API to get all of the releases for the major version
  curl "https://api.bell-sw.com/v1/liberica/releases?version-feature=$JRE&bitness=64&os=linux&arch=x86&package-type=tar.gz&bundle-type=jre" 2> /dev/null | jq -r '.[] | [.downloadUrl, .version, .sha1, .latest, .latestInFeatureVersion] | @tsv' | parallel -j 4 "build_jre $JRE $BUILD_BASE {}"
done

popd
popd
