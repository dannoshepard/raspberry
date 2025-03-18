#!/bin/bash

# Check if required arguments are provided
if [ "$#" -lt 2 ]; then
    echo "Usage: $0 <remote_user> <remote_host>"
    echo "Example: $0 danielshepard 10.0.0.2"
    exit 1
fi

REMOTE_USER=$1
REMOTE_HOST=$2

# Build the Next.js app
echo "Building Next.js app..."
npm run build

# Create the out directory on the Raspberry Pi
echo "Creating out directory on Raspberry Pi..."
ssh $REMOTE_USER@$REMOTE_HOST 'sudo mkdir -p /opt/client/.next'

# Copy the built files to the Raspberry Pi
echo "Copying built files to Raspberry Pi..."
scp -r .next/* $REMOTE_USER@$REMOTE_HOST:/tmp/next-out/
ssh $REMOTE_USER@$REMOTE_HOST 'sudo cp -r /tmp/next-out/* /opt/client/.next/ && rm -rf /tmp/next-out'

# Restart the camera service
echo "Restarting camera service..."
ssh $REMOTE_USER@$REMOTE_HOST 'sudo systemctl restart camera.service'

echo "Deployment complete!" 