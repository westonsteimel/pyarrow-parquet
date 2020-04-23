#!/bin/bash
set -e
set -x

export ARROW_VERSION=0.17.0

rm -rf arrow-temp
mkdir -p dist
mkdir -p arrow-temp
(
cd arrow-temp
curl -fSL "https://github.com/apache/arrow/archive/apache-arrow-${ARROW_VERSION}.tar.gz" -o arrow.tar.gz
tar -xvf arrow.tar.gz --strip 1
cp -r ../manylinux1/* python/manylinux1/
cp -r ../manylinux201x/* python/manylinux201x/
mkdir -p python/manylinux1/dist
mkdir -p python/manylinux201x/dist

docker-compose run -e PYTHON_VERSION="3.8" centos-python-manylinux2014
cp python/manylinux201x/dist/* ../dist/
docker-compose run -e PYTHON_VERSION="3.7" centos-python-manylinux2014
cp python/manylinux201x/dist/* ../dist/
docker-compose run -e PYTHON_VERSION="3.6" centos-python-manylinux2014
cp python/manylinux201x/dist/* ../dist/

docker-compose run -e PYTHON_VERSION="3.8" centos-python-manylinux2010
cp python/manylinux201x/dist/* ../dist/
docker-compose run -e PYTHON_VERSION="3.7" centos-python-manylinux2010
cp python/manylinux201x/dist/* ../dist/
docker-compose run -e PYTHON_VERSION="3.6" centos-python-manylinux2010
cp python/manylinux201x/dist/* ../dist/

)
rm -rf arrow-temp
