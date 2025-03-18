#!/bin/bash
set -e

# Function to check if interface supports AP mode
check_ap_capability() {
    local iface=$1
    if iw list 2>/dev/null | grep -A 10 "Supported interface modes:" | grep -q "* AP"; then
        return 0
    fi
    return 1
}

# Function to check interface status
check_interface_status() {
    local iface=$1
    if ip link show $iface | grep -q "state UP"; then
        return 0
    fi
    return 1
}

# Function to reset WiFi interface
reset_wifi_interface() {
    local iface=$1
    echo "Attempting to reset $iface..."
    
    # Bring down the interface
    ip link set $iface down
    sleep 1
    
    # Reset the interface
    iw dev $iface set type managed
    sleep 1
    
    # Bring up the interface
    ip link set $iface up
    sleep 2
    
    # Check if interface is now up
    if check_interface_status $iface; then
        return 0
    fi
    
    return 1
}

# Function to check USB power
check_usb_power() {
    local iface=$1
    echo "Checking USB power for $iface..."
    
    # Get USB device information
    local usb_info=$(lsusb -v 2>/dev/null | grep -A 5 "$iface")
    if [ -n "$usb_info" ]; then
        echo "USB device information:"
        echo "$usb_info"
    else
        echo "Could not find USB device information for $iface"
    fi
    
    # Check USB power status
    if [ -f "/sys/class/net/$iface/device/power/runtime_status" ]; then
        echo "USB power status:"
        cat "/sys/class/net/$iface/device/power/runtime_status"
    fi
}

# Function to backup network configuration
backup_network_config() {
    echo "Backing up network configuration..."
    mkdir -p /etc/network/backup
    
    # Backup files only if they exist
    if [ -f /etc/dhcpcd.conf ]; then
        cp /etc/dhcpcd.conf /etc/network/backup/dhcpcd.conf.orig
    fi
    
    if [ -f /etc/dnsmasq.conf ]; then
        cp /etc/dnsmasq.conf /etc/network/backup/dnsmasq.conf.orig
    fi
    
    if [ -f /etc/hostapd/hostapd.conf ]; then
        cp /etc/hostapd/hostapd.conf /etc/network/backup/hostapd.conf.orig
    fi
    
    if [ -f /etc/sysctl.conf ]; then
        cp /etc/sysctl.conf /etc/network/backup/sysctl.conf.orig
    fi
    
    if [ -f /etc/rc.local ]; then
        cp /etc/rc.local /etc/network/backup/rc.local.orig
    fi
    
    # Backup iptables rules if they exist
    if iptables-save > /etc/network/backup/iptables.orig 2>/dev/null; then
        echo "Backed up iptables rules"
    fi
}

# Function to restore network configuration
restore_network_config() {
    echo "Restoring network configuration..."
    
    # Restore files only if backups exist
    if [ -f /etc/network/backup/dhcpcd.conf.orig ]; then
        cp /etc/network/backup/dhcpcd.conf.orig /etc/dhcpcd.conf
    fi
    
    if [ -f /etc/network/backup/dnsmasq.conf.orig ]; then
        cp /etc/network/backup/dnsmasq.conf.orig /etc/dnsmasq.conf
    fi
    
    if [ -f /etc/network/backup/hostapd.conf.orig ]; then
        cp /etc/network/backup/hostapd.conf.orig /etc/hostapd/hostapd.conf
    fi
    
    if [ -f /etc/network/backup/sysctl.conf.orig ]; then
        cp /etc/network/backup/sysctl.conf.orig /etc/sysctl.conf
    fi
    
    if [ -f /etc/network/backup/rc.local.orig ]; then
        cp /etc/network/backup/rc.local.orig /etc/rc.local
    fi
    
    # Restore iptables rules if backup exists
    if [ -f /etc/network/backup/iptables.orig ]; then
        iptables-restore < /etc/network/backup/iptables.orig
    fi
    
    # Restart services
    systemctl restart dhcpcd
    systemctl restart dnsmasq
    systemctl restart hostapd
    
    echo "Network configuration restored. Please reboot the system."
    exit 0
}

# Check if restore is requested
if [ "$1" = "restore" ]; then
    restore_network_config
fi

# Detect which interface to use for the Access Point.
# Prefer a USB WiFi dongle (e.g. wlan1) if available; otherwise, default to wlan0.
if [ -d /sys/class/net/wlan1 ]; then
    AP_IFACE="wlan1"
else
    echo "External wifi adapter not available... exiting"
    exit 1
fi

echo "Using interface $AP_IFACE for AP mode"

# Check if the interface supports AP mode
echo "Checking if $AP_IFACE supports AP mode..."
if ! check_ap_capability $AP_IFACE; then
    echo "Error: $AP_IFACE does not support AP mode"
    echo "Please check:"
    echo "1. Your WiFi dongle supports AP mode (802.11 AP mode)"
    echo "2. The driver supports AP mode"
    echo "3. Try running 'iw list' to see supported modes"
    exit 1
fi

# Backup current configuration
backup_network_config

# Install required packages if not already installed
if ! dpkg -s hostapd >/dev/null 2>&1; then
    apt-get install -y hostapd
fi

if ! dpkg -s dnsmasq >/dev/null 2>&1; then
    apt-get install -y dnsmasq
fi

if ! dpkg -s dhcpcd >/dev/null 2>&1; then
    apt-get install -y dhcpcd
fi

if ! dpkg -s iptables >/dev/null 2>&1; then
    apt-get install -y iptables
fi

# Stop services to safely reconfigure them
systemctl stop hostapd || true
systemctl stop dnsmasq || true
systemctl stop dhcpcd || true

# Unmask and enable hostapd service
systemctl unmask hostapd
systemctl enable hostapd

# Bring up the interface
echo "Bringing up $AP_IFACE..."
ip link set $AP_IFACE up

# Wait for interface to be ready
sleep 2

# Check interface status
if ! check_interface_status $AP_IFACE; then
    echo "Error: Failed to bring up $AP_IFACE"
    echo "Current interface status:"
    ip link show $AP_IFACE
    
    echo "Checking USB power status..."
    check_usb_power $AP_IFACE
    
    echo "Attempting to reset interface..."
    if ! reset_wifi_interface $AP_IFACE; then
        echo "Error: Failed to reset $AP_IFACE"
        echo "Please check:"
        echo "1. Is the WiFi adapter properly plugged in?"
        echo "2. Try unplugging and replugging the adapter"
        echo "3. Try using a different USB port"
        echo "4. Check if the adapter is getting enough power"
        echo "5. Run 'dmesg | tail' to check for USB errors"
        exit 1
    fi
fi

# ---------------------------
# Configure Static IP for the AP interface
# ---------------------------
DHCPD_MARKER="# Raspberry Pi AP configuration for $AP_IFACE"
if ! grep -q "$DHCPD_MARKER" /etc/dhcpcd.conf; then
    cat <<EOF >> /etc/dhcpcd.conf

$DHCPD_MARKER
interface $AP_IFACE
    static ip_address=192.168.4.1/24
    nohook wpa_supplicant
EOF
fi

# ---------------------------
# Configure dnsmasq for DHCP on the AP interface
# ---------------------------
DNSMASQ_CONF="/etc/dnsmasq.conf"
DNSMASQ_MARKER="# Raspberry Pi AP dnsmasq config for $AP_IFACE"

# Backup original dnsmasq config if not already backed up
if [ ! -f "${DNSMASQ_CONF}.orig" ]; then
    mv $DNSMASQ_CONF ${DNSMASQ_CONF}.orig
fi

if ! grep -q "$DNSMASQ_MARKER" $DNSMASQ_CONF; then
    cat <<EOF > $DNSMASQ_CONF
$DNSMASQ_MARKER
interface=$AP_IFACE
dhcp-range=192.168.4.2,192.168.4.20,255.255.255.0,24h
EOF
fi

# ---------------------------
# Configure hostapd for the AP
# ---------------------------
HOSTAPD_CONF="/etc/hostapd/hostapd.conf"
HOSTAPD_MARKER="# Raspberry Pi AP hostapd config for $AP_IFACE"
if ! grep -q "$HOSTAPD_MARKER" $HOSTAPD_CONF 2>/dev/null; then
    cat <<EOF > $HOSTAPD_CONF
$HOSTAPD_MARKER
interface=$AP_IFACE
driver=nl80211
ssid=PiFi
hw_mode=g
channel=7
wmm_enabled=0
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
wpa=2
wpa_passphrase=raspberry 
wpa_key_mgmt=WPA-PSK
wpa_pairwise=TKIP
rsn_pairwise=CCMP
EOF
fi

# Point hostapd's default configuration to our config file if not already set
if ! grep -q 'DAEMON_CONF="/etc/hostapd/hostapd.conf"' /etc/default/hostapd; then
    sed -i 's|^#DAEMON_CONF="".*|DAEMON_CONF="/etc/hostapd/hostapd.conf"|' /etc/default/hostapd
fi

# ---------------------------
# Enable IP Forwarding and NAT
# ---------------------------
if ! grep -q '^net.ipv4.ip_forward=1' /etc/sysctl.conf; then
    sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
    sysctl -w net.ipv4.ip_forward=1
fi

# Clear existing NAT rules
iptables -t nat -F POSTROUTING

# Set up NAT using iptables if rule doesn't already exist.
# Replace eth0 with your primary internet interface if it's different.
if ! iptables -t nat -C POSTROUTING -o eth0 -j MASQUERADE 2>/dev/null; then
    iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
fi

# Save iptables rules so they persist on reboot.
iptables-save > /etc/iptables.ipv4.nat

# Ensure iptables rules are restored on boot via /etc/rc.local.
RC_LOCAL="/etc/rc.local"
if [ -f "$RC_LOCAL" ]; then
    if ! grep -q "iptables-restore < /etc/iptables.ipv4.nat" $RC_LOCAL; then
        sed -i '/exit 0/i iptables-restore < /etc/iptables.ipv4.nat' $RC_LOCAL
    fi
else
    cat <<EOF > $RC_LOCAL
#!/bin/sh -e
iptables-restore < /etc/iptables.ipv4.nat
exit 0
EOF
    chmod +x $RC_LOCAL
fi

# ---------------------------
# Restart Services
# ---------------------------
echo "Restarting services..."
systemctl restart dhcpcd
sleep 2
systemctl restart dnsmasq
sleep 2
systemctl restart hostapd

# Check service status
echo "Checking service status..."
systemctl status hostapd --no-pager
systemctl status dnsmasq --no-pager
systemctl status dhcpcd --no-pager

echo "WiFi router setup is complete using interface $AP_IFACE!"
echo "To check if the AP is working:"
echo "1. Look for 'PiFi' network on your devices"
echo "2. Try to connect with password 'raspberry'"
echo "3. Check if you get an IP address in the 192.168.4.x range"
echo ""
echo "If you need to restore the original network configuration, run:"
echo "sudo $0 restore"
