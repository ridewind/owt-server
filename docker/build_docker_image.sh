#!/bin/bash

build_type=${1:-owt}

BASEDIR="$(dirname "$(readlink -fm "$0")")"
CONTEXTDIR="$(dirname "$BASEDIR")"
DISTDIR="${2:-$BASEDIR/dist}"

if [ $build_type == "owt" ]; then
  dockerfile=Dockerfile
  docker build --target owt-build -t owt:build \
    --build-arg http_proxy=${HTTP_PROXY} \
    --build-arg https_proxy=${HTTPS_PROXY} \
    .

  docker build --target owt-run -t owt:run \
    --build-arg http_proxy=${HTTP_PROXY} \
    --build-arg https_proxy=${HTTPS_PROXY} \
    .

elif [ $build_type == "openvino" ]; then
  dockerfile=gst-analytics.Dockerfile
  docker build -f ${BASEDIR}/${dockerfile} -t owt:openvino \
    --build-arg http_proxy=${HTTP_PROXY} \
    --build-arg https_proxy=${HTTPS_PROXY} \
    .

elif [ $build_type == "package" ]; then
  dockerfile=ridewind.Dockerfile
  docker build --target owt-build -t owt:build \
    --build-arg http_proxy=${HTTP_PROXY} \
    --build-arg https_proxy=${HTTPS_PROXY} \
    .

  mkdir -p $DISTDIR
  #rm -f $DISTDIR/owt-server.tgz
  rm -f $DISTDIR/Release-master.tgz
  docker run --rm -v $DISTDIR:/dist owt:build mv /home/owt-server/Release-master.tgz /dist/
  #docker run --rm -v $DISTDIR:/dist owt:build tar -zcvf /dist/owt-server.tgz /home/owt-server/dist

else
  echo "Usage: ./build_docker_image.sh [BUILDTYPE]"
  echo "ERROR: please set BUILDTYPE to on of the following: [owt, openvino, package]"
  exit
fi
