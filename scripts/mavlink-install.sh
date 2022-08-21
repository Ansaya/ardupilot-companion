#!/bin/bash
###
#
#   Clone, build, and install MAVlink router software from github repository
#   Required dependencies: g++ gcc git meson ninja-build pkg-config
#
###

git clone https://github.com/mavlink-router/mavlink-router.git
cd mavlink-router
git submodule update --init --recursive
meson setup build . --buildtype=release
ninja -C build
sudo ninja -C build install
