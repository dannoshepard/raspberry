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

# Copy files to remote host
echo "Copying files to remote host..."
scp "$(dirname "$0")/setup_hotspot.sh" $REMOTE_USER@$REMOTE_HOST:/tmp/
scp "$(dirname "$0")/hotspot.service" $REMOTE_USER@$REMOTE_HOST:/tmp/

# Verify files were copied
echo "Verifying files were copied..."
ssh $REMOTE_USER@$REMOTE_HOST "ls -l /tmp/setup_hotspot.sh /tmp/hotspot.service"

# Move files to final locations and start the service
echo "Setting up and starting hotspot service..."
ssh $REMOTE_USER@$REMOTE_HOST "sudo cp /tmp/setup_hotspot.sh /usr/local/bin/ && \
    sudo cp /tmp/hotspot.service /etc/systemd/system/ && \
    sudo chmod +x /usr/local/bin/setup_hotspot.sh && \
    sudo systemctl daemon-reload && \
    sudo systemctl enable hotspot.service && \
    sudo systemctl start hotspot.service"

# Check service status and logs
echo "Checking service status and logs..."
ssh $REMOTE_USER@$REMOTE_HOST "echo '=== Service Status ===' && \
    sudo systemctl status hotspot.service && \
    echo '=== Service Logs ===' && \
    sudo journalctl -xeu hotspot.service && \
    echo '=== NetworkManager Status ===' && \
    sudo systemctl status NetworkManager && \
    echo '=== NetworkManager Logs ===' && \
    sudo journalctl -xeu NetworkManager"

# Verify files were moved
echo "Verifying files were installed..."
ssh $REMOTE_USER@$REMOTE_HOST "ls -l /usr/local/bin/setup_hotspot.sh /etc/systemd/system/hotspot.service"

echo "Deployment complete!"
echo "The hotspot service should now be installed and running."
echo "To check the service status at any time, run:"
echo "ssh $REMOTE_USER@$REMOTE_HOST 'sudo systemctl status hotspot.service'" 