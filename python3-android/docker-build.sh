#!/bin/bash

set -e
set -x

apt-get update -y
apt-get install -y autoconf autoconf-archive automake cmake gawk gettext git gcc make patch pkg-config xz-utils gzip

export ANDROID_NDK=/android-ndk

if [ ! -d "$ANDROID_NDK" ] ; then
    # In general we don't want download NDK for every build, but it is simpler to do it here
    # for CI builds
    NDK_VER=r21b
    apt-get install -y wget unzip #bsdtar    
    wget --no-verbose https://dl.google.com/android/repository/android-ndk-$NDK_VER-linux-x86_64.zip
    # bsdtar xf android-ndk-${NDK_VER}-linux-x86_64.zip
    unzip android-ndk-${NDK_VER}-linux-x86_64.zip
    ANDROID_NDK=/android-ndk-$NDK_VER
fi

cd /python3-android

./build.sh "$@"
