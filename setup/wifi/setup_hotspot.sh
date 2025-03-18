#!/bin/bash

# Exit on any error
set -e

# Set the WiFi interface name
WIFI_INTERFACE="p2p-dev-wlan0"

# Function to check if NetworkManager is running
check_network_manager() {
    echo "Checking NetworkManager status..."
    if ! systemctl is-active --quiet NetworkManager; then
        echo "NetworkManager is not running. Starting it..."
        sudo systemctl start NetworkManager
        sleep 2
    fi
    echo "NetworkManager is running"
}

# Function to check if interface is enabled in rfkill
check_rfkill() {
    local interface=$1
    echo "Checking rfkill status for $interface..."
    if rfkill list | grep -A1 "$interface" | grep -q "Soft blocked: yes"; then
        echo "Interface $interface is soft blocked. Unblocking..."
        sudo rfkill unblock $(rfkill list | grep -B1 "$interface" | head -n1 | cut -d: -f1)
        sleep 2
    fi
}

# Function to check interface stability
check_interface_stability() {
    local interface=$1
    local max_attempts=5
    local attempt=1
    local last_state=""
    local current_state=""
    
    echo "Checking interface stability..."
    while [ $attempt -le $max_attempts ]; do
        current_state=$(nmcli device show $interface | grep "GENERAL.STATE" | awk '{print $2}')
        if [ "$current_state" = "$last_state" ]; then
            return 0
        fi
        last_state=$current_state
        echo "Interface state: $current_state (attempt $attempt/$max_attempts)"
        sleep 2
        attempt=$((attempt + 1))
    done
    return 1
}

# Function to check interface status
check_interface() {
    local interface=$1
    echo "Checking interface $interface..."
    
    # Check if interface exists
    if ! ip link show $interface >/dev/null 2>&1; then
        echo "Error: Interface $interface does not exist"
        return 1
    fi
    
    echo "Interface status:"
    nmcli device show $interface
}

# Function to reset interface
reset_interface() {
    local interface=$1
    echo "Resetting interface $interface..."
    
    # Clean up existing connections
    echo "Cleaning up existing connections..."
    nmcli connection show | grep "pifi" | awk '{print $1}' | while read -r conn; do
        nmcli connection delete "$conn" || true
    done
    
    # Ensure interface is unblocked
    check_rfkill $interface
    
    # Disconnect interface
    echo "Disconnecting interface..."
    nmcli device disconnect $interface || true
    sleep 2
    
    # Wait for interface to stabilize
    if ! check_interface_stability $interface; then
        echo "Error: Interface not stable after reset"
        return 1
    fi
    
    return 0
}

# Function to create hotspot
create_hotspot() {
    local interface=$1
    echo "Creating hotspot on $interface..."
    
    # Delete any existing pifi connection
    nmcli connection show | grep "pifi" | awk '{print $1}' | while read -r conn; do
        nmcli connection delete "$conn" || true
    done
    
    # Create new hotspot
    echo "Creating new hotspot..."
    nmcli connection add \
        type wifi \
        ifname "$interface" \
        con-name "pifi" \
        autoconnect yes \
        ssid "pifi" \
        mode ap \
        ipv4.method shared \
        ipv4.addresses 192.168.12.1/24 \
        wifi-sec.key-mgmt wpa-psk \
        wifi-sec.psk "Password1"
        
    # Activate the connection
    echo "Activating hotspot..."
    nmcli connection up "pifi" ifname "$interface"
    
    # Verify hotspot is active
    sleep 5
    if ! nmcli -t -f GENERAL.STATE device show "$interface" | grep -q "100"; then
        echo "Error: Hotspot not active"
        return 1
    fi
    
    echo "Hotspot created successfully"
    return 0
}

# Function to check and update NetworkManager
check_network_manager_version() {
    echo "Checking NetworkManager version..."
    local current_version=$(nmcli --version | grep -oP 'NetworkManager \K[0-9.]+')
    echo "Current NetworkManager version: $current_version"
    
    # Check if there are any updates available
    if ! sudo apt-get update; then
        echo "Warning: Failed to update package lists"
        return 1
    fi
    
    # Get available version from repository
    local available_version=$(apt-cache policy network-manager | grep "Candidate:" | awk '{print $2}')
    echo "Available NetworkManager version: $available_version"
    
    # Compare versions
    if [ "$current_version" != "$available_version" ]; then
        echo "Updating NetworkManager to version $available_version..."
        sudo apt-get install -y network-manager
        sudo systemctl restart NetworkManager
        sleep 5
    else
        echo "NetworkManager is up to date"
    fi
}

# Main script
echo "Starting hotspot setup..."

# Check NetworkManager
check_network_manager

# Check and update NetworkManager version
check_network_manager_version

# Check interface
check_interface "$WIFI_INTERFACE"

# Reset interface
if ! reset_interface "$WIFI_INTERFACE"; then
    echo "Error: Interface reset failed"
    exit 1
fi

# Create hotspot
if ! create_hotspot "$WIFI_INTERFACE"; then
    echo "Error: Failed to create hotspot"
    exit 1
fi

# Show final status
echo "Final network status:"
nmcli device status
nmcli connection show --active

exit 0 