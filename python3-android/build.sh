#!/bin/bash

set -e
set -x

THIS_DIR="$PWD"

PYVER=${PYVER:-3.9.0}
SRCDIR=src/Python-$PYVER
read version_major version_minor < <(echo $PYVER | sed -E 's/^([0-9]+)\.([0-9]+).*/\1 \2/')
version_short=$version_major.$version_minor
version_int=$(($version_major * 100 + $version_minor))

COMMON_ARGS="--arch ${ARCH:-arm} --api ${ANDROID_API:-21}"

if [ ! -d $SRCDIR ]; then
    mkdir -p src
    pushd src
    curl -vLO https://www.python.org/ftp/python/$PYVER/Python-$PYVER.tar.xz
    # Use --no-same-owner so that files extracted are still owned by the
    # running user in a rootless container
    ls -l
    tar --no-same-owner -xf Python-$PYVER.tar.xz
    popd
fi

cp -r Android $SRCDIR
pushd $SRCDIR

patches="unversioned-libpython lfs"
if [ $version_int -ge 312 ]; then
    patches+=" bldlibrary grp"
fi

if [ $version_int -eq 313 ]; then
    patches="lfs"
fi

for name in $patches; do
    patch -p1 -i ./Android/patches/$name.patch
done

#autoreconf -ifv

which python
python -m pip install dataclasses
./Android/build_deps.py $COMMON_ARGS
./Android/configure.py $COMMON_ARGS --prefix=/usr --disable-test-modules --with-build-python=$(which python3) "$@"
make
make install DESTDIR="$THIS_DIR/build"
popd
#cp -r $SRCDIR/Android/sysroot/usr/share/terminfo build/usr/share/
#cp devscripts/env.sh build/

# Create the embeddable dir and move Python distribution into it
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

chmod a+x activate.sh
