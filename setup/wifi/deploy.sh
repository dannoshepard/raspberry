#!/bin/bash

# Check if required arguments are provided
if [ "$#" -lt 2 ]; then
    echo "Usage: $0 <remote_user> <remote_host> [remote_path]"
    echo "Example: $0 danielshepard 192.168.86.41"
    echo "Optional: $0 danielshepard 192.168.86.41 /home/danielshepard/projects"
    exit 1
fi

REMOTE_USER=$1
REMOTE_HOST=$2
REMOTE_BASE_PATH=${3:-"/home/$REMOTE_USER/projects"}  # Default to user's projects directory

# Function to test SSH connection
test_ssh_connection() {
    ssh $REMOTE_USER@$REMOTE_HOST "echo 'SSH connection successful'"
    return $?
}

# Function to deploy a file
deploy_file() {
    local local_file=$1
    local remote_dir=$2
    local remote_path="$REMOTE_BASE_PATH/$remote_dir"
    
    echo "Deploying $local_file to $REMOTE_USER@$REMOTE_HOST:$remote_path"
    
    # Create remote directory if it doesn't exist
    echo "Creating remote directory..."
    if ! ssh $REMOTE_USER@$REMOTE_HOST "mkdir -p $remote_path"; then
        echo "Error: Failed to create remote directory"
        return 1
    fi
    
    # Copy the file
    echo "Copying $local_file..."
    if ! scp $local_file $REMOTE_USER@$REMOTE_HOST:$remote_path/; then
        echo "Error: Failed to copy $local_file"
        return 1
    fi
    
    # Set executable permissions if it's a script
    if [[ $local_file == *.sh ]] || [[ $local_file == *.py ]]; then
        echo "Setting executable permissions..."
        if ! ssh $REMOTE_USER@$REMOTE_HOST "chmod +x $remote_path/$local_file"; then
            echo "Error: Failed to set executable permissions"
            return 1
        fi
    fi
    
    # Verify the file was copied
    echo "Verifying deployment..."
    if ! ssh $REMOTE_USER@$REMOTE_HOST "ls -l $remote_path/$local_file"; then
        echo "Error: Failed to verify file deployment"
        return 1
    fi
    
    return 0
}

# Test SSH connection
echo "Testing SSH connection to $REMOTE_USER@$REMOTE_HOST..."
if ! test_ssh_connection; then
    echo "Error: Could not establish SSH connection"
    exit 1
fi

# Deploy router.sh
if [ -f "router.sh" ]; then
    echo "Deploying router script..."
    if ! deploy_file "router.sh" "router"; then
        echo "Error: Failed to deploy router.sh"
        exit 1
    fi
fi

# Deploy camera files
if [ -f "run_camera.py" ]; then
    echo "Deploying camera script..."
    if ! deploy_file "run_camera.py" "camera"; then
        echo "Error: Failed to deploy run_camera.py"
        exit 1
    fi
fi

# Deploy requirements.txt
if [ -f "requirements.txt" ]; then
    echo "Deploying requirements.txt..."
    if ! deploy_file "requirements.txt" "camera"; then
        echo "Error: Failed to deploy requirements.txt"
        exit 1
    fi
fi

# Deploy setup_python.sh
if [ -f "setup_python.sh" ]; then
    echo "Deploying Python setup script..."
    if ! deploy_file "setup_python.sh" "camera"; then
        echo "Error: Failed to deploy setup_python.sh"
        exit 1
    fi
fi

echo "Deployment complete!"
echo "To run the router script on the remote device:"
echo "ssh $REMOTE_USER@$REMOTE_HOST 'sudo $REMOTE_BASE_PATH/router/router.sh'"
echo ""
echo "To set up and run the camera on the remote device:"
echo "ssh $REMOTE_USER@$REMOTE_HOST 'cd $REMOTE_BASE_PATH/camera && sudo ./setup_python.sh && python3 run_camera.py'" 