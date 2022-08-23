#!/bin/bash
###
#
#   Replace default Modem Manager with Network Manager
#
###
set -e
set -x

if [[ "$(id -u)" != "0" ]]; then
    echo "Please run with sudo"
    exit -2
fi

rm /etc/network/interfaces
dd of=/etc/network/interfaces << EOF
auto lo
iface lo inet loopback

source /etc/network/interfaces.d/*
EOF
apt install -y network-manager

systemctl disable networking
systemctl stop networking

apt remove -y modemmanager

# Disable wpa_supplicant
if [ -e /etc/wpa_supplicant/wpa_supplicant.conf ]; then
    mv /etc/wpa_supplicant/wpa_supplicant.conf{,-unused}
fi
systemctl stop wpa_supplicant
systemctl disable wpa_supplicant
killall /sbin/wpa_supplicant || true

# Enable NetworkManager
systemctl start NetworkManager
systemctl enable NetworkManager
