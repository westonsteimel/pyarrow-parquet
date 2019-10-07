#!/bin/bash
set -e
set -x

mkdir -p /arrow
(
cd /arrow
curl -fSL "https://github.com/apache/arrow/archive/apache-arrow-${ARROW_VERSION}.tar.gz" -o arrow.tar.gz
tar -xvf arrow.tar.gz --strip 1
cd python/manylinux2010
cp -r ./scripts /io
ls /io
/io/manylinux2010/build_arrow.sh
rm -rf /io/scripts
)
