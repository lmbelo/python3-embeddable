#!/bin/bash

set -e
set -x

# Install requirements
brew install xz

# Initialize variables
THIS_DIR="$PWD"
PY_SRC_DIR=src/Python-$PYVER

# Navigate to the target dir
cd python3-macos

# Create the Python source dir
mkdir -p src
pushd src

# Download Python
curl -vLO https://www.python.org/ftp/python/$PYVER/Python-$PYVER.tar.xz
tar --no-same-owner -xf Python-$PYVER.tar.xz

popd

# ---------------- #

pushd $PY_SRC_DIR

# Configure and make Python from source
./configure --prefix=/usr "$@" --enable-shared
make
make install DESTDIR="$THIS_DIR/build"

popd

# Create the embeddable dir and moves Python distribution into it
mkdir -p embedabble
mv build/usr/* embedabble
ls -R