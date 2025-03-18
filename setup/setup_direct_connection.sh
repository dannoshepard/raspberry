#!/bin/bash

# Check if required arguments are provided
if [ "$#" -lt 2 ]; then
    echo "Usage: $0 <remote_user> <remote_host>"
    echo "Example: $0 danielshepard 192.168.86.41"
    exit 1
fi

REMOTE_USER=$1
REMOTE_HOST=$2

# Function to test SSH connection
test_ssh_connection() {
    ssh $REMOTE_USER@$REMOTE_HOST "echo 'SSH connection successful'"
    return $?
}

# Test SSH connection
echo "Testing SSH connection to $REMOTE_USER@$REMOTE_HOST..."
if ! test_ssh_connection; then
    echo "Error: Could not establish SSH connection"
    exit 1
fi

# Install dhcpcd5
echo "Installing dhcpcd5..."
ssh $REMOTE_USER@$REMOTE_HOST "sudo apt-get update && sudo apt-get install -y dhcpcd5"

# Add static IP configuration to dhcpcd.conf with metrics
echo "Configuring static IP and interface priorities..."
ssh $REMOTE_USER@$REMOTE_HOST "echo -e '\n# Direct connection configuration\ninterface eth0\nstatic ip_address=10.0.0.2/24\nstatic routers=10.0.0.1\nstatic domain_name_servers=8.8.8.8 8.8.4.4\nmetric 100\n\n# Ensure wlan0 is primary\ninterface wlan0\nmetric 50' | sudo tee -a /etc/dhcpcd.conf"

# Restart dhcpcd service
echo "Restarting dhcpcd service..."
ssh $REMOTE_USER@$REMOTE_HOST "sudo systemctl restart dhcpcd"

# Verify configuration
echo "Verifying configuration..."
ssh $REMOTE_USER@$REMOTE_HOST "echo '=== dhcpcd.conf ===' && sudo cat /etc/dhcpcd.conf | grep -A 5 'interface eth0' && echo -e '\n=== dhcpcd status ===' && sudo systemctl status dhcpcd && echo -e '\n=== Network Routes ===' && ip route"

echo "Direct connection setup complete!"
echo "The Raspberry Pi should now be configured with static IP 10.0.0.2 on eth0"
echo "wlan0 is set as the primary interface for internet traffic" 