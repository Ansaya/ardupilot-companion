#!/bin/bash
###
#
#   Build and install lbqmi from github repository
#   Required dependencies: g++ gcc git help2man libgirepository1.0-dev libgudev-1.0-dev meson ninja-build pkg-config
#
###
script_dir="$(dirname $(readlink -e $0))"

cd ${script_dir}/../libqmi
meson setup build . --prefix=/usr --buildtype=release -Dcollection=full -Dmbim_qmux=false -Dqrtr=false
ninja -C build
sudo ninja -C build install
