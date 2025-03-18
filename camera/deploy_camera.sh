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

# Install required packages
echo "Installing required packages..."
ssh $REMOTE_USER@$REMOTE_HOST "sudo apt-get update && sudo apt-get install -y v4l-utils"

# Create remote directory structure
echo "Creating remote directory structure..."
ssh $REMOTE_USER@$REMOTE_HOST "sudo mkdir -p /opt/camera/templates && sudo mkdir -p /tmp/templates && sudo chmod 777 /tmp/templates"

# Copy camera application files
echo "Copying camera application files..."
scp run_camera.py $REMOTE_USER@$REMOTE_HOST:/tmp/
scp requirements.txt $REMOTE_USER@$REMOTE_HOST:/tmp/
scp setup_python.sh $REMOTE_USER@$REMOTE_HOST:/tmp/
scp -r templates/* $REMOTE_USER@$REMOTE_HOST:/tmp/templates/

# Move files to final locations and set up Python environment
echo "Setting up Python environment and moving files..."
ssh $REMOTE_USER@$REMOTE_HOST "sudo cp /tmp/run_camera.py /opt/camera/ && \
    sudo cp /tmp/requirements.txt /opt/camera/ && \
    sudo cp /tmp/setup_python.sh /opt/camera/ && \
    sudo cp -r /tmp/templates/* /opt/camera/templates/ && \
    sudo chmod +x /opt/camera/setup_python.sh && \
    cd /opt/camera && \
    sudo ./setup_python.sh && \
    sudo chown -R root:root /opt/camera"

# Create systemd service file
echo "Creating systemd service..."
ssh $REMOTE_USER@$REMOTE_HOST "sudo bash -c 'cat > /etc/systemd/system/camera.service << EOL
[Unit]
Description=Camera Application Service
After=network.target

[Service]
Type=simple
User=root
Group=video
WorkingDirectory=/opt/camera
ExecStart=/opt/camera/venv/bin/python run_camera.py
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOL'"

# Enable and start the service
echo "Starting camera service..."
ssh $REMOTE_USER@$REMOTE_HOST "sudo systemctl daemon-reload && \
    sudo systemctl enable camera.service && \
    sudo systemctl start camera.service"

# Check service status
check_service_status

print_completion_message "deployment" "installed and running" 