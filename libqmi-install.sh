#!/bin/bash
###
#
#   Build and install lbqmi from github repository
#   Required dependencies: g++ gcc git gobject-introspection help2man libgudev-1.0-dev meson ninja-build pkg-config
#
###

cd libqmi
meson setup build . --prefix=/usr --buildtype=release -Dcollection=full -Dmbim_qmux=false -Dqrtr=false
ninja -C build
sudo ninja -C build install
