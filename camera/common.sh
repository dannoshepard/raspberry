#!/bin/bash

# Function to check remote configuration
check_remote_config() {
    echo "Testing SSH connection to $REMOTE_USER@$REMOTE_HOST..."
    if ! ssh $REMOTE_USER@$REMOTE_HOST "echo 'SSH connection successful'"; then
        echo "Error: Could not establish SSH connection"
        exit 1
    fi
}

# Function to check required arguments
check_arguments() {
    if [ "$#" -lt 2 ]; then
        echo "Usage: $0 <remote_user> <remote_host>"
        echo "Example: $0 danielshepard 192.168.86.41"
        exit 1
    fi
}

# Function to check service status
check_service_status() {
    echo "Checking service status..."
    ssh $REMOTE_USER@$REMOTE_HOST "echo '=== Service Status ===' && \
        sudo systemctl status camera.service && \
        echo '=== Service Logs ===' && \
        sudo journalctl -xeu camera.service --no-pager | tail -n 20"
}

# Function to print completion message
print_completion_message() {
    echo "Camera $1 complete!"
    echo "The camera service should now be $2."
    echo "To check the service status at any time, run:"
    echo "ssh $REMOTE_USER@$REMOTE_HOST 'sudo systemctl status camera.service'"
} 