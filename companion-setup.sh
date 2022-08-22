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
    sudo apt install -y autossh g++ gcc git help2man libgirepository1.0-dev \
        libgudev-1.0-dev meson ninja-build pkg-config udhcpd ufw
}

function setup_autossh_service () {
sudo cat > /etc/systemd/system/$1 << EOF
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

${scripts_dir}/libqmi-install.sh

echo " => Updating global environment variables..."
cat env | sudo tee -a /etc/environment
source /etc/environment

echo " => Generating MAVlink router configuration..."
sudo cat > /etc/mavlink-router/main.conf << EOF
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
setup_autossh_service remote-mavlink.service $MAV_PORT $RELAY_IP $MAV_PORT
setup_autossh_service remote-ssh.service 22 $RELAY_IP $MAV_SSH

echo " => Airspace Access Point setup..."
ap_companion_ssid="DroneAirspace"
ap_companion_pass="Dron3Airsp@c3"
ap_companion_ip="192.168.100.254"
sudo cat > /etc/udhcpd.conf << EOF
start           $(sed -E 's/.[0-9]+$//g' <<< ${ap_companion_ip}).1
end             $(sed -E 's/.[0-9]+$//g' <<< ${ap_companion_ip}).5
interface       wlan0
remaining       yes
opt     dns     ${ap_companion_ip}
opt     subnet  255.255.255.0
opt     router  ${ap_companion_ip}
opt     lease   1800
EOF
sudo sed -i 's/DHCPD_ENABLED="no"/DHCPD_ENABLED="yes"/' /etc/default/udhcpd
sudo cat > /etc/network/interfaces.d/airspace << EOF
iface wlan0 inet static
address ${ap_companion_ip}
netmask 255.255.255.0
wpa-roam /etc/wpa_supplicant/wpa_supplicant.conf
EOF
sudo cat > /etc/hostapd/hostapd.conf << EOF
interface=wlan0
driver=n180211
ssid=${ap_companion_ssid}
hw_mode=g
channel=6
macaddr_ac1=0
auth_algs=1
ignore_broadcast_ssid=0
ieee80211n=1
dtim_period=1
max_num_sta=8
wpa=2
wpa_key_mgmt=SAE
rsn_pairwise=CCMP
ieee80211w=2
wpa_passphrase=$(wpa_passphrase ${ap_companion_ssid} ${ap_companion_pass} | grep psk= | tail -1 | sed 's/.*=//g')
sae_pwe=2
EOF
echo 'DAEMON_CONF="/etc/hostapd/hostapd.conf"' | sudo tee -a /etc/default/hostapd
sudo ufw allow from $(sed -E 's/.[0-9]+$//g' <<< ${ap_companion_ip}).0/24
sudo ufw allow SSH
echo y | sudo ufw enable

sudo systemctl daemon-reload
for service in "mavlink-router" "remote-mavlink" "remote-ssh" "hostapd" "udhcpd"
do
    sudo systemctl enable ${service}
    sudo systemctl start ${service}
done
echo "Companion configuration completed"
