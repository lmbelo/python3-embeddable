#!/bin/bash

set -e
set -x

# Initialize variables
THIS_DIR="$PWD"
SRCDIR=src/Python-$PYVER

# Clear the last build
if [ -d src ]; then rm -Rf src; fi
if [ -d build ]; then rm -Rf build; fi
if [ -d embedabble ]; then rm -Rf embedabble; fi

if [ ! -d $SRCDIR ]; then
    mkdir -p src
    pushd src
    curl -vLO https://www.python.org/ftp/python/$PYVER/Python-$PYVER.tar.xz
    # Use --no-same-owner so that files extracted are still owned by the
    # running user in a rootless container
    tar --no-same-owner -xf Python-$PYVER.tar.xz
    popd
fi

cp -r Linux $SRCDIR
pushd $SRCDIR

# Build deps
python -m pip install dataclasses
./Linux/build_deps.py
./Linux/configure.py --prefix=/usr --disable-test-modules "$@"

# Make Python from source
make
make install DESTDIR="$THIS_DIR/build"

popd

# Create the embeddable dir and moves Python distribution into it
mkdir -p embedabble
mv build/usr/* embedabble

cd "$THIS_DIR/embedabble"

# Delete undesired packages
PYSIMPLEVER=$(cut -d '.' -f 1,2 <<< "$PYVER")
find "lib/python$PYSIMPLEVER" -type d -name "config-$PYSIMPLEVER*" -prune -exec rm -rf {} \;
find "lib/python$PYSIMPLEVER" -type d -name "test" -prune -exec rm -rf {} \;

# Create the activate script
touch activate.sh
cat <<EOT >> activate.sh
#!/bin/bash
export PYTHONHOME=\$PWD
export PATH=\$PWD/bin:\$PATH
if [ ! -z "\$LD_LIBRARY_PATH" ] ; then
    export LD_LIBRARY_PATH="\$LD_LIBRARY_PATH:"
fi
export LD_LIBRARY_PATH="\$PWD/lib:\$LD_LIBRARY_PATH"
EOT

sudo chmod a+x activate.sh