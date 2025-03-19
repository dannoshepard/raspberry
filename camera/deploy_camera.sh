#!/bin/bash

# Source common functions
source "$(dirname "$0")/common.sh"

# Get command line arguments
REMOTE_USER=$1
REMOTE_HOST=$2

# Check arguments
check_arguments "$@"

# Check remote connection
check_remote_config

echo "Deploying camera service to $REMOTE_USER@$REMOTE_HOST..."

# Create temporary directory for files with correct permissions
echo "Creating temporary directory..."
ssh $REMOTE_USER@$REMOTE_HOST "sudo rm -rf /tmp/camera_deploy && \
    sudo mkdir -p /tmp/camera_deploy/app && \
    sudo chown -R $REMOTE_USER:$REMOTE_USER /tmp/camera_deploy"

# Copy files to temporary location
echo "Copying files..."
scp app/*.py requirements.txt setup_python.sh $REMOTE_USER@$REMOTE_HOST:/tmp/camera_deploy/

# Create target directory
echo "Creating target directory..."
ssh $REMOTE_USER@$REMOTE_HOST "sudo mkdir -p /opt/camera/app"

# Set up Python environment
echo "Setting up Python environment..."
ssh $REMOTE_USER@$REMOTE_HOST "cd /tmp/camera_deploy && sudo bash setup_python.sh"

# Move files to target location
echo "Moving files to target location..."
ssh $REMOTE_USER@$REMOTE_HOST "sudo mv /tmp/camera_deploy/*.py /opt/camera/app/ && sudo mv /tmp/camera_deploy/requirements.txt /opt/camera/"

# Create systemd service
echo "Creating systemd service..."
cat > /tmp/camera.service << EOL
[Unit]
Description=Camera Service
After=network.target

[Service]
ExecStart=/bin/sh -c 'cd /opt/camera && /opt/camera/venv/bin/python -m app'
WorkingDirectory=/opt/camera
Restart=always
User=root
Environment=PYTHONUNBUFFERED=1
Environment=CLIENT_DIR=/opt/client/.next

[Install]
WantedBy=multi-user.target
EOL

# Copy and enable service
scp /tmp/camera.service $REMOTE_USER@$REMOTE_HOST:/tmp/camera_deploy/
ssh $REMOTE_USER@$REMOTE_HOST "sudo mv /tmp/camera_deploy/camera.service /etc/systemd/system/ && \
    sudo systemctl daemon-reload && \
    sudo systemctl enable camera.service"

# Clean up temporary files
echo "Cleaning up..."
ssh $REMOTE_USER@$REMOTE_HOST "sudo rm -rf /tmp/camera_deploy"

# Restart service
echo "Restarting camera service..."
ssh $REMOTE_USER@$REMOTE_HOST "sudo systemctl restart camera.service"

# Show status
echo "Showing service status..."
ssh $REMOTE_USER@$REMOTE_HOST "sudo systemctl status camera.service"

echo "Deployment complete!" 