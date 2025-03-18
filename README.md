# Raspberry Pi Camera Project

A complete solution for deploying and managing a camera application on Raspberry Pi devices.

## Project Structure

```
raspberry/
├── camera/           # Camera application
│   ├── run_camera.py    # Main camera application
│   ├── requirements.txt # Python dependencies
│   └── templates/       # Web interface templates
├── setup/            # Setup and deployment scripts
│   ├── setup_ssh_key.sh           # SSH key setup
│   └── setup_direct_connection.sh # Direct connection setup
└── wifi/             # WiFi configuration scripts
```

## Components

### Camera Application
- Flask-based web interface
- Live video streaming
- Focus and backlight control
- Automatic camera detection
- Systemd service for production deployment

### Setup Scripts
- SSH key authentication setup
- Direct USB-C connection configuration
- Deployment automation
- Service management

## Quick Start

1. Set up SSH access:
```bash
cd setup
./setup_ssh_key.sh <username> <raspberry-pi-ip>
```

2. Deploy camera application:
```bash
cd camera
./deploy_camera.sh <username> <raspberry-pi-ip>
```

3. Access the web interface:
```
http://<raspberry-pi-ip>:5000
```

## Documentation

- [Camera Application Documentation](camera/README.md)
- [Setup Scripts Documentation](setup/README.md)
- [WiFi Configuration Documentation](wifi/README.md)

## Requirements

- Raspberry Pi with Arducam B0497 camera
- Python 3.11+
- USB-C cable for direct connection
- SSH access to Raspberry Pi

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

The MIT License is a permissive license that is short and to the point. It lets people do anything they want with the code as long as they provide attribution back to you and don't hold you liable. 