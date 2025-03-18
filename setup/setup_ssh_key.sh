#!/bin/bash

# Check if required arguments are provided
if [ "$#" -lt 2 ]; then
    echo "Usage: $0 <remote_user> <remote_host>"
    echo "Example: $0 danielshepard 192.168.86.41"
    exit 1
fi

REMOTE_USER=$1
REMOTE_HOST=$2

# Check if SSH key exists locally
if [ ! -f ~/.ssh/id_rsa ]; then
    echo "Generating new SSH key..."
    ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
fi

# Set correct permissions on local SSH key
chmod 600 ~/.ssh/id_rsa
chmod 644 ~/.ssh/id_rsa.pub

# Create .ssh directory on remote server if it doesn't exist
echo "Setting up SSH directory on remote server..."
ssh $REMOTE_USER@$REMOTE_HOST "mkdir -p ~/.ssh && chmod 700 ~/.ssh"

# Copy the public key to the remote server
echo "Copying SSH key to remote server..."
cat ~/.ssh/id_rsa.pub | ssh $REMOTE_USER@$REMOTE_HOST "cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"

# Test the connection
echo "Testing SSH connection..."
if ssh -o StrictHostKeyChecking=no $REMOTE_USER@$REMOTE_HOST "echo 'SSH key authentication successful'"; then
    echo "SSH key authentication setup complete!"
    echo "You can now use deploy.sh without password authentication"
else
    echo "Error: Failed to set up SSH key authentication"
    echo "Please check:"
    echo "1. Your SSH key permissions (should be 600 for ~/.ssh/id_rsa)"
    echo "2. The remote server's authorized_keys file permissions (should be 600)"
    echo "3. The remote server's .ssh directory permissions (should be 700)"
    echo "4. Try running 'ssh -v $REMOTE_USER@$REMOTE_HOST' for verbose output"
    exit 1
fi 