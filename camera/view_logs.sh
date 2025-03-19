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

echo "Streaming camera service logs..."
echo "Press Ctrl+C to stop"
echo "----------------------------------------"

# Stream the logs with follow mode (-f)
ssh $REMOTE_USER@$REMOTE_HOST 'sudo journalctl -xfu camera.service' 