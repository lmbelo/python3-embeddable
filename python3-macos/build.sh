#!/bin/bash

set -e
set -x

# Install requirements
brew install xz

#Initialize variables
THIS_DIR="$PWD"
PY_SRC_DIR=src/Python-$PYVER

# Create the Python source dir
mkdir -p src
pushd src

# Download Python
curl -vLO https://www.python.org/ftp/python/$PYVER/Python-$PYVER.tar.xz
tar --no-same-owner -xf Python-$PYVER.tar.xz

popd src

pushd $PY_SRC_DIR

# Configure and make Python from source
./configure --prefix=/usr "$@" --enable-shared
make
make install DESTDIR="$THIS_DIR/build"

popd