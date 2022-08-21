#!/bin/bash
###
#
#   Build and install MAVlink router software from github repository
#   Required dependencies: g++ gcc git meson ninja-build pkg-config
#
###

cd mavlink-router
meson setup build . --buildtype=release
ninja -C build
sudo ninja -C build install
