#!/bin/bash

set -e
set -x

apt-get update -y
apt-get remove openssl
apt-get install -y autoconf autoconf-archive gawk gettext git patch pkg-config build-essential

cd /python3-linux

./build.sh "$@"
