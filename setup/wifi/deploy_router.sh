#!/bin/bash

# Check if required arguments are provided
if [ "$#" -lt 2 ]; then
    echo "Usage: $0 <remote_user> <remote_host> [remote_path]"
    echo "Example: $0 danielshepard 192.168.86.41"
    echo "Optional: $0 danielshepard 192.168.86.41 /home/danielshepard/projects/router"
    exit 1
fi

REMOTE_USER=$1
REMOTE_HOST=$2
REMOTE_PATH=${3:-"/home/$REMOTE_USER"}  # Default to user's home directory if not specified

# Check if router.sh exists locally
if [ ! -f "router.sh" ]; then
    echo "Error: router.sh not found in current directory"
    exit 1
fi

# Function to test SSH connection
test_ssh_connection() {
    ssh $REMOTE_USER@$REMOTE_HOST "echo 'SSH connection successful'"
    return $?
}

echo "Testing SSH connection to $REMOTE_USER@$REMOTE_HOST..."
if ! test_ssh_connection; then
    echo "Error: Could not establish SSH connection"
    exit 1
fi

echo "Deploying router.sh to $REMOTE_USER@$REMOTE_HOST:$REMOTE_PATH"

# Create remote directory if it doesn't exist
echo "Creating remote directory..."
if ! ssh $REMOTE_USER@$REMOTE_HOST "mkdir -p $REMOTE_PATH"; then
    echo "Error: Failed to create remote directory"
    exit 1
fi

# Copy the file
echo "Copying router.sh..."
if ! scp router.sh $REMOTE_USER@$REMOTE_HOST:$REMOTE_PATH/; then
    echo "Error: Failed to copy router.sh"
    exit 1
fi

# Set executable permissions
echo "Setting executable permissions..."
if ! ssh $REMOTE_USER@$REMOTE_HOST "chmod +x $REMOTE_PATH/router.sh"; then
    echo "Error: Failed to set executable permissions"
    exit 1
fi

# Verify the file was copied and has correct permissions
echo "Verifying deployment..."
if ! ssh $REMOTE_USER@$REMOTE_HOST "ls -l $REMOTE_PATH/router.sh"; then
    echo "Error: Failed to verify file deployment"
    exit 1
fi

echo "Deployment complete!"
echo "To run the script on the remote device:"
echo "ssh $REMOTE_USER@$REMOTE_HOST 'sudo $REMOTE_PATH/router.sh'" 