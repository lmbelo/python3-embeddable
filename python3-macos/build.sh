#!/bin/bash

set -e
set -x

# Install requirements
brew install xz

if [ $ARCH = "x86_64" ] || [ $ARCH = "universal2" ]; then
    echo "Building for Python for $ARCH"
    mkdir $ARCH    
    cd $ARCH
else
    echo "Unsupported platform"
    exit 1
fi

# Initialize variables
THIS_DIR="$PWD"
PY_SRC_DIR=src/Python-$PYVER

# Clear the last build
if [ -d src ]; then rm -Rf src; fi
if [ -d build ]; then rm -Rf build; fi
if [ -d embedabble ]; then rm -Rf embedabble; fi

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
if [ $ARCH = "universal2" ]; then
  ./configure --prefix=/usr "$@" --enable-shared --enable-universalsdk --with-universal-archs=universal2
else
  ./configure --prefix=/usr "$@" --enable-shared
fi
make
make install DESTDIR="$THIS_DIR/build"

popd

# Create the embeddable dir and moves Python distribution into it
mkdir -p embedabble
mv build/usr/* embedabble