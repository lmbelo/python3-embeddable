#!/bin/bash

set -e
set -x

apt-get update -y
apt-get install -y autoconf autoconf-archive automake cmake gawk gettext git gcc make patch pkg-config

cd /python3-linux

./build.sh "$@"
