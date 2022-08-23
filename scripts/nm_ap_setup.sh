#!/bin/bash
###
#
#   Setup a WiFi Access Point through Network Manager CLI
#
###
set -e
set -x

function print_help() {
    echo "usage: $0 <ifname> <ssid> <pass_key> <?ap_ip>"
    exit -1
}

if [ $# -lt 3 ]; then
    print_help
fi

IFNAME="$1"
SSID="$2"
KEY="$3"
IP="$4"
if [[ -z "${IP}" ]]; then
    IP="192.168.100.128"
fi

APNAME="${SSID}AP"

echo " => Installing dnsmasq"
apt install -y dnsmasq

# dnsmasq is managed directly by network manager
systemcl disable dnsmasq
systemcl stop dnsmasq

dd of=/etc/dnsmasq.d/${APNAME}.conf << EOF
interface=${IFNAME}
dhcp-range=$(sed -E 's/.[0-9]+$//g' <<< ${IP}).1,$(sed -E 's/.[0-9]+$//g' <<< ${IP}).5,12h
EOF

nmcli connection add type wifi ifname ${IFNAME} con-name ${APNAME} ssid ${SSID}
nmcli connection modify ${APNAME} connection.autoconnect yes
nmcli connection modify ${APNAME} 802-11-wireless.mode ap
nmcli connection modify ${APNAME} 802-11-wireless.band bg
nmcli connection modify ${APNAME} ipv4.method shared
nmcli connection modify ${APNAME} wifi-sec.key-mgmt wpa-psk
nmcli connection modify ${APNAME} ipv4.addresses ${IP}/24
nmcli connection modify ${APNAME} wifi-sec.psk "${KEY}"
nmcli connection modify ${APNAME} 802-11-wireless-security.group ccmp
nmcli connection modify ${APNAME} 802-11-wireless-security.pairwise ccmp
nmcli connection up ${APNAME}
