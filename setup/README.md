# Setup Scripts

This directory contains scripts for setting up SSH access and direct connection to Raspberry Pi devices.

## Scripts

### setup_ssh_key.sh

Sets up SSH key authentication for a Raspberry Pi.

```bash
./setup_ssh_key.sh <username> <raspberry-pi-ip>
```

#### Features
- Generates SSH key pair if not exists
- Copies public key to Raspberry Pi
- Tests SSH connection
- Configures SSH config file for easy access

#### Requirements
- SSH access to Raspberry Pi
- Password authentication enabled
- Sudo privileges on Raspberry Pi

### setup_direct_connection.sh

Configures direct connection to a Raspberry Pi using a USB-C cable.

```bash
./setup_direct_connection.sh <username> <raspberry-pi-ip>
```

#### Features
- Configures USB-C connection
- Sets up network interface
- Tests connection
- Configures SSH for direct connection

#### Requirements
- USB-C cable connected between host and Raspberry Pi
- SSH access to Raspberry Pi
- Sudo privileges on Raspberry Pi

## Directory Structure

```
setup/
├── setup_ssh_key.sh           # SSH key setup script
└── setup_direct_connection.sh # Direct connection setup script
```

## Usage

### SSH Key Setup

1. Run the SSH key setup script:
```bash
./setup_ssh_key.sh <username> <raspberry-pi-ip>
```

2. Enter your password when prompted

3. Verify the connection:
```bash
ssh <username>@<raspberry-pi-ip>
```

### Direct Connection Setup

1. Connect Raspberry Pi to host using USB-C cable

2. Run the direct connection script:
```bash
./setup_direct_connection.sh <username> <raspberry-pi-ip>
```

3. Test the connection:
```bash
ssh <username>@raspberrypi.local
```

## Troubleshooting

### Common Issues

1. **SSH Key Setup Failures**
   - Check SSH service is running on Raspberry Pi
   - Verify password authentication is enabled
   - Check SSH key permissions

2. **Direct Connection Issues**
   - Verify USB-C cable is properly connected
   - Check network interface configuration
   - Ensure mDNS is working (raspberrypi.local)

3. **Permission Errors**
   - Ensure user has sudo privileges
   - Check SSH key permissions
   - Verify SSH config file permissions

### Logs

- SSH connection logs: `ssh -v <username>@<raspberry-pi-ip>`
- System logs: `sudo journalctl -xe`
- Network logs: `ifconfig` or `ip addr` 