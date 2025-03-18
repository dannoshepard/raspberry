# Raspberry Pi Camera Application

A Flask-based web application for controlling and streaming video from an Arducam B0497 camera on a Raspberry Pi.

## Features

- Live video streaming
- Manual focus control
- Backlight control
- Automatic camera device detection
- Systemd service for production deployment

## Requirements

- Raspberry Pi with Arducam B0497 camera
- Python 3.11+
- OpenCV
- Flask
- v4l-utils (for camera device detection)

## Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd camera
```

2. Create and activate a virtual environment:
```bash
python3 -m venv venv
source venv/bin/activate
```

3. Install dependencies:
```bash
pip install -r requirements.txt
```

4. Deploy to Raspberry Pi:
```bash
./deploy_camera.sh <username> <raspberry-pi-ip>
```

## Usage

### Web Interface

Access the web interface at `http://<raspberry-pi-ip>:5000`

- View live video feed
- Adjust focus using the slider
- Toggle backlight on/off

### Service Management

The application runs as a systemd service named `camera.service`.

- Check service status:
```bash
sudo systemctl status camera.service
```

- View logs:
```bash
sudo journalctl -u camera.service -f
```

- Restart service:
```bash
sudo systemctl restart camera.service
```

## Camera Configuration

The application automatically detects the Arducam B0497 camera and configures:
- Manual focus mode
- Initial focus value: 30
- Backlight enabled by default

## Troubleshooting

1. Camera not detected:
   - Check camera connection
   - Verify v4l-utils is installed
   - Check service logs for device detection errors

2. Video stream not working:
   - Verify camera permissions (video group)
   - Check service logs for initialization errors
   - Ensure camera is not in use by another application

3. Focus/backlight controls not working:
   - Check service logs for capability errors
   - Verify camera supports these features

## Development

### Local Development

1. Run the application locally:
```bash
python run_camera.py
```

2. Access the web interface at `http://localhost:5000`

### Deployment

The deployment script (`deploy_camera.sh`) handles:
- Package installation
- Directory setup
- Service configuration
- Application deployment
