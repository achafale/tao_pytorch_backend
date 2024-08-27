#!/usr/bin/env bash

set -eo pipefail
cd "$( dirname "${BASH_SOURCE[0]}" )"

registry="nvcr.io"
repository="nvstaging/tao/tao_pytorch_base_image"
base_image="nvcr.io/nvidia/pytorch:24.04-py3"

tag="$USER-$(date +%Y%m%d%H%M)"
local_tag="$USER"

# Build parameters.
BUILD_DOCKER="0"
PUSH_DOCKER="0"
FORCE="0"


# Parse command line.
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -b|--build)
    BUILD_DOCKER="1"
    shift # past argument
    ;;
    -p|--push)
    PUSH_DOCKER="1"
    shift # past argument
    ;;
    -f|--force)
    FORCE=1
    shift
    ;;
    --default)
    BUILD_DOCKER="1"
    PUSH_DOCKER="0"
    FORCE="0"
    shift # past argument
    ;;
    *)    # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift # past argument
    ;;
esac
done

# Build docker
if [ $BUILD_DOCKER = "1" ]; then
    echo "Building base docker ..."
    if [ $FORCE = "1" ]; then
        echo "Forcing docker build without cache ..."
        NO_CACHE="--no-cache"
    else
        NO_CACHE=""
    fi
    DOCKER_BUILDKIT=1 docker build --pull -f $NV_TAO_PYTORCH_TOP/docker/Dockerfile -t $registry/$repository:$local_tag $NO_CACHE \
        --network=host --build-arg PYTORCH_BASE_IMAGE=${base_image} \
        $NV_TAO_PYTORCH_TOP/.
    if [ $PUSH_DOCKER = "1" ]; then
        echo "Pusing docker ..."
        docker tag $registry/$repository:$local_tag $registry/$repository:$tag
        docker push $registry/$repository:$tag
        digest=$(docker inspect --format='{{index .RepoDigests 0}}' $registry/$repository:$tag)
        echo -e "\033[1;33mUpdate the digest in the manifest.json file to:\033[0m"
        echo $digest
    else
        echo "Skip pushing docker ..."
    fi
# Exit by printing usage.
else
    echo "Usage: ./build.sh [--build] [--push] [--force] [--default]"
fi
