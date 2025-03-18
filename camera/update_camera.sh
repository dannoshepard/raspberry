#!/bin/bash

# Source common functions
source "$(dirname "$0")/common.sh"

# Get command line arguments
REMOTE_USER=$1
REMOTE_HOST=$2

# Check arguments
check_arguments "$@"

# Test SSH connection
echo "Testing SSH connection to $REMOTE_USER@$REMOTE_HOST..."
if ! test_ssh_connection; then
    echo "Error: Could not establish SSH connection"
    exit 1
fi

# Create temporary directory on remote machine
echo "Creating temporary directory..."
ssh $REMOTE_USER@$REMOTE_HOST "sudo mkdir -p /tmp/camera_update && sudo chmod -R 777 /tmp/camera_update"

# Copy application files
echo "Copying application files..."
scp run_camera.py $REMOTE_USER@$REMOTE_HOST:/tmp/camera_update/
scp requirements.txt $REMOTE_USER@$REMOTE_HOST:/tmp/camera_update/

# Move files to final location and update Python environment
echo "Updating application files..."
ssh $REMOTE_USER@$REMOTE_HOST "sudo cp /tmp/camera_update/run_camera.py /opt/camera/ && \
    sudo cp /tmp/camera_update/requirements.txt /opt/camera/ && \
    cd /opt/camera && \
    sudo ./venv/bin/pip install -r requirements.txt && \
    sudo chown -R root:root /opt/camera"

# Restart the camera service
echo "Restarting camera service..."
ssh $REMOTE_USER@$REMOTE_HOST "sudo systemctl restart camera.service"

# Wait for service to start
echo "Waiting for service to start..."
sleep 2

# Check service status
check_service_status

# Clean up
echo "Cleaning up..."
ssh $REMOTE_USER@$REMOTE_HOST "sudo rm -rf /tmp/camera_update"

print_completion_message "update" "restarted with the new files" 