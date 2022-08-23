#!/bin/bash
###
#
#
#
###

script_dir="$(dirname $(readlink -e $0))"
scripts_dir="${script_dir}/scripts"

function install_dependencies () {
    sudo apt update
    sudo apt install -y autossh g++ gcc git haveged help2man \
        libgirepository1.0-dev libgudev-1.0-dev meson ninja-build \
        pkg-config ufw
}

function setup_autossh_service () {
sudo dd of=/etc/systemd/system/$1 << EOF
[Unit]
Description=Reverse proxy service
After=network-online.target

[Service]
Type=simple
ExecStartPre=/bin/sh -c 'until ping -c1 google.com; do sleep 1; done;'
ExecStart=autossh -N -R $3:localhost:$2 drone@$4
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
}

echo " => Installing modules dependencies..."
install_dependencies

${scripts_dir}/mavlink-install.sh

echo " => Updating global environment variables..."
cat env | sudo tee -a /etc/environment
source /etc/environment

echo " => Generating MAVlink router configuration..."
sudo dd of=/etc/mavlink-router/main.conf << EOF
[General]
ReportStats = true
DebugLogLevel = info
TcpServerPort = $MAV_PORT
MavlinkDialect = auto
Log = /etc/mavlink-router/logs
LogMode = while-armed

[UartEndpoint bravo]
Device = /dev/ttyAMA0
Baud = 921600,500000,115200,57600,38400,19200,9600
FlowControl = false
EOF

echo " => Reverse SSH automated connection service configuration..."
setup_autossh_service remote-mavlink.service "\$MAV_PORT" "\$RELAY_IP" "\$MAV_PORT"
setup_autossh_service remote-ssh.service 22 "\$RELAY_IP" "\$MAV_SSH"

echo " => Setup Network Manager"
sudo ${scripts_dir}/switch_to_networkmanager.sh

echo " => Airspace Access Point setup..."
ap_companion_ssid="DroneAirspace"
ap_companion_pass="Dron3Airsp@c3"
ap_companion_ip="192.168.100.128"
echo "    Static IP is ${ap_companion_ip}"
echo "    Access point SSID is ${ap_companion_ssid}"
echo "    Access point password is ${ap_companion_pass}"
sudo ${scripts_dir}/nm_ap_setup.sh wlan0 "${ap_companion_ssid}" "${ap_companion_pass}" "${ap_companion_ip}"

sudo ufw allow from $(sed -E 's/.[0-9]+$//g' <<< ${ap_companion_ip}).0/24
sudo ufw allow SSH
echo y | sudo ufw enable

sudo systemctl daemon-reload
for service in "mavlink-router" "remote-mavlink" "remote-ssh" "haveged"
do
    sudo systemctl enable ${service}
    sudo systemctl start ${service}
done
echo "Companion configuration completed"
