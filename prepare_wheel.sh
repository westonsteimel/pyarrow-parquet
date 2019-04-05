#!/bin/bash
set -e
set -x

mkdir -p build
(
cd build

curl -fSL "https://github.com/apache/arrow/archive/apache-arrow-${ARROW_VERSION}.tar.gz" -o arrow.tar.gz
tar -xvf arrow.tar.gz --strip 1
cd python/manylinux1
cp ../../../build_arrow.sh .

docker run \
    --env PYTHON_VERSION="${PYTHON_VERSION}" \
    --env UNICODE_WIDTH=16 \
    --shm-size=2g \
    --rm -it \
    -v $PWD:/io \
    -v $PWD/../../:/arrow \
    quay.io/xhochy/arrow_manylinux1_x86_64_base:latest /io/build_arrow.sh

mkdir -p ../../../
cp -r dist ../../../
)

sudo rm -rf build
