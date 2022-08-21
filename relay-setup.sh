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
    sudo apt install -y g++ gcc git meson ninja-build pkg-config
}

${scripts_dir}/mavlink-install.sh

echo " => Updating global environment variables..."
cat env | sudo tee -a /etc/environment
source /etc/environment

echo " => Generating MAVlink router configuration..."
sudo cat > /etc/mavlink-router/main.conf << EOF
[General]
ReportStats = true
DebugLogLevel = info
TcpServerPort = $RELAY_PORT
MavlinkDialect = auto
Log = /etc/mavlink-router/logs
LogMode = while-armed

[TcpEndpoint delta]
Address = 127.0.0.1
Port = $MAV_PORT
RetryTimeout=1
EOF

sudo systemctl daemon-reload
sudo systemctl enable mavlink-router
sudo systemctl start mavlink-router

echo "Relay server configuration completed"
