#!/bin/bash
###
#
#   Build and install MAVlink router software from github repository
#   Required dependencies: g++ gcc git meson ninja-build pkg-config
#
###
script_dir="$(dirname $(readlink -e $0))"

cd ${script_dir}/../mavlink-router
meson setup build . --buildtype=release
ninja -C build
sudo ninja -C build install
