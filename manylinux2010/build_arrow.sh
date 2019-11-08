#!/bin/bash
#
# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.
#
# Build upon the scripts in https://github.com/matthew-brett/manylinux-builds
# * Copyright (c) 2013-2016, Matt Terry and Matthew Brett (BSD 2-clause)
#
# Usage:
#   either build:
#     $ docker-compose build python-manylinux2010
#   or pull:
#     $ docker-compose pull python-manylinux2010
#   an then run:
#     $ docker-compose run -e PYTHON_VERSION=3.7 python-manylinux2010

source /multibuild/manylinux_utils.sh

# Quit on failure
set -e

# Print commands for debugging
# set -x

cd /arrow/python

# PyArrow build configuration
export PYARROW_BUILD_TYPE='release'
export PYARROW_CMAKE_GENERATOR='Ninja'

# ARROW-6860: Disabling ORC in wheels until Protobuf static linking issues
# across projects is resolved
export PYARROW_WITH_ORC=0

export PYARROW_WITH_PARQUET=1
export PYARROW_WITH_PLASMA=0
export PYARROW_BUNDLE_ARROW_CPP=1
export PYARROW_BUNDLE_BOOST=1
export PYARROW_BOOST_NAMESPACE=arrow_boost
export PKG_CONFIG_PATH=/usr/lib/pkgconfig:/arrow-dist/lib/pkgconfig

export PYARROW_CMAKE_OPTIONS='-DBoost_NAMESPACE=arrow_boost -DBOOST_ROOT=/arrow_boost_dist'
# Ensure the target directory exists
mkdir -p /io/dist

# Must pass PYTHON_VERSION and UNICODE_WIDTH env variables
# possible values are: 2.7,16 2.7,32 3.5,16 3.6,16 3.7,16

CPYTHON_PATH="$(cpython_path ${PYTHON_VERSION} ${UNICODE_WIDTH})"
PYTHON_INTERPRETER="${CPYTHON_PATH}/bin/python"
PIP="${CPYTHON_PATH}/bin/pip"
PATH="${PATH}:${CPYTHON_PATH}"

export PYARROW_WITH_FLIGHT=0
export PYARROW_WITH_GANDIVA=0
export BUILD_ARROW_FLIGHT=OFF
export BUILD_ARROW_GANDIVA=OFF

# ARROW-3052(wesm): ORC is being bundled until it can be added to the
# manylinux1 image

echo "=== (${PYTHON_VERSION}) Building Arrow C++ libraries ==="
ARROW_BUILD_DIR=/tmp/build-PY${PYTHON_VERSION}-${UNICODE_WIDTH}
mkdir -p "${ARROW_BUILD_DIR}"
pushd "${ARROW_BUILD_DIR}"
PATH="${CPYTHON_PATH}/bin:${PATH}" cmake -DCMAKE_BUILD_TYPE=Release \
    -DARROW_DEPENDENCY_SOURCE="SYSTEM" \
    -DZLIB_ROOT=/usr/local \
    -DCMAKE_INSTALL_PREFIX=/arrow-dist \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DARROW_BUILD_TESTS=OFF \
    -DARROW_BUILD_SHARED=ON \
    -DARROW_BUILD_STATIC=OFF \
    -DARROW_BOOST_USE_SHARED=ON \
    -DARROW_GANDIVA_PC_CXX_FLAGS="-isystem;/opt/rh/devtoolset-8/root/usr/include/c++/8/;-isystem;/opt/rh/devtoolset-8/root/usr/include/c++/8/x86_64-redhat-linux/" \
    -DARROW_JEMALLOC=ON \
    -DARROW_RPATH_ORIGIN=ON \
    -DARROW_PYTHON=ON \
    -DARROW_PARQUET=ON \
    -DPythonInterp_FIND_VERSION=${PYTHON_VERSION} \
    -DARROW_PLASMA=OFF \
    -DARROW_TENSORFLOW=OFF \
    -DARROW_ORC=OFF \
    -DORC_SOURCE=BUNDLED \
    -DARROW_WITH_BZ2=OFF \
    -DARROW_WITH_ZLIB=OFF \
    -DARROW_WITH_ZSTD=OFF \
    -DARROW_WITH_LZ4=OFF \
    -DARROW_WITH_SNAPPY=ON \
    -DARROW_WITH_BROTLI=OFF \
    -DARROW_FLIGHT=${BUILD_ARROW_FLIGHT} \
    -DARROW_GANDIVA=${BUILD_ARROW_GANDIVA} \
    -DARROW_GANDIVA_JAVA=OFF \
    -DBoost_NAMESPACE=arrow_boost \
    -DBOOST_ROOT=/arrow_boost_dist \
    -DOPENSSL_USE_STATIC_LIBS=ON \
    -GNinja /arrow/cpp
ninja install
popd

# Check that we don't expose any unwanted symbols
/io/scripts/check_arrow_visibility.sh

echo "=== (${PYTHON_VERSION}) Install the wheel build dependencies ==="
$PIP install -r requirements-wheel.txt

# Clear output directories and leftovers
rm -rf dist/
rm -rf build/
rm -rf repaired_wheels/
find -name "*.so" -delete

echo "=== (${PYTHON_VERSION}) Building wheel ==="
PATH="$PATH:${CPYTHON_PATH}/bin" $PYTHON_INTERPRETER setup.py build_ext --inplace
PATH="$PATH:${CPYTHON_PATH}/bin" $PYTHON_INTERPRETER setup.py bdist_wheel
# Source distribution is used for debian pyarrow packages.
PATH="$PATH:${CPYTHON_PATH}/bin" $PYTHON_INTERPRETER setup.py sdist

echo "=== (${PYTHON_VERSION}) Tag the wheel with manylinux2010 ==="
mkdir -p repaired_wheels/
auditwheel repair --plat manylinux2010_x86_64 -L . dist/pyarrow-*.whl -w repaired_wheels/

# Install the built wheels
$PIP install repaired_wheels/*.whl

# Test that the modules are importable
$PYTHON_INTERPRETER -c "
import sys
import pyarrow
import pyarrow.parquet
"

# More thorough testing happens outside of the build to prevent
# packaging issues like ARROW-4372
mv dist/*.tar.gz /io/dist
mv repaired_wheels/*.whl /io/dist
