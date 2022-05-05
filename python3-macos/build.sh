#!/bin/bash

set -e
set -x

if [ $ARCH = "x86_64" ] || [ $ARCH = "universal2" ]; then
    echo "Building Python for $ARCH"
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

# Create the pre-built directory by extracting the zip file
mv -f ../MacOS/prebuiltdeps.tar.gz $THIS_DIR
tar --no-same-owner -xf $THIS_DIR/prebuiltdeps.tar.gz

# Copy our custom build-script to the BuildScript folder
mv -f -v ../MacOS/build-installer.py $PY_SRC_DIR/Mac/BuildScript/
mv -f -v ../MacOS/Makefile $PY_SRC_DIR/Doc/

pushd $PY_SRC_DIR/Mac/BuildScript/

# Runs the build-script
if [ $ARCH = "universal2" ]; then
  python3 build-installer.py --build-dir="$THIS_DIR/build" --third-party="$THIS_DIR/build/third-party" --prebuilt-deps="$THIS_DIR/prebuiltdeps" --dep-target=12 --universal-archs=universal2
else
  python3 build-installer.py --build-dir="$THIS_DIR/build" --third-party="$THIS_DIR/build/third-party" --dep-target=10.15 --universal-archs=intel-64
fi

popd

# Create the embeddable dir and moves Python distribution into it
PYSIMPLEVER=$(cut -d '.' -f 1,2 <<< "$PYVER")
mkdir -p embedabble

mv -v build/_root/usr/local/* "$THIS_DIR/embedabble/"
