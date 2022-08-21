#!/bin/bash
###
#
#   QMI modem setup script
#   Required dependencies: libqmi udhcpc
#
###

APN="$1"
APN_USER="$2"
APN_PASS="$3"

function print_help() {
    echo "usage: $0 <apn> <?apn_user> <?apn_pass>"
    exit -1
}

if [[ "$(id -u)" != "0" ]]; then
    echo "Please run with sudo"
    exit -2
fi

if [[ -z $APN ]]; then
    print_help
fi

cdc_device="/dev/cdc-wdm0"
qmi_conf="/etc/qmi-network.conf"

if ! test $cdc_device; then
    echo "QMI module not found!"
    exit -2
fi

if_name="$(qmicli -d $cdc_device -w)"
if [[ -z $if_name ]]; then
    echo "Unable to retrieve QMI network interface name!"
    exit -3
fi

echo " => Writing QMI configuration file to '$qmi_conf'"
cat > $qmi_conf << EOF
APN=$APN
IP_TYPE=4
EOF

echo " => Enabling automatic network interface setup"
cat > /etc/network/interfaces.d/$if_name << EOF
allow-hotplug $if_name
iface $if_name inet manual
    pre-up ifconfig $if_name down
    pre-up echo 'Y' > /sys/class/net/$if_name/qmi/raw_ip
    pre-up for _ in $(seq 1 10); do /usr/bin/test -c $cdc_device && break; /bin/sleep 1; done
    pre-up for _ in $(seq 1 10); do /usr/bin/qmicli -d $cdc_device --nas-get-signal-strength && break; /bin/sleep 1; done
    pre-up /usr/bin/qmi-network $cdc_device start
    pre-up udhcpc -i $if_name
    post-down /usr/bin/qmi-network $cdc_device stop
EOF
