import cv2
import numpy as np
from flask import Flask, Response, render_template, jsonify, send_file, send_from_directory
import threading
import subprocess
import re
import os
from datetime import datetime

app = Flask(__name__, static_folder='../client/.next')

# Global variables for camera and focus
cap = None
current_focus = 30
backlight_enabled = True  # Default to enabled

def find_camera_device():
    """Find the Arducam B0497 camera device number"""
    try:
        # Run v4l2-ctl to list devices
        result = subprocess.run(['v4l2-ctl', '--list-devices'], 
                              capture_output=True, text=True)
        
        # Split output into lines
        lines = result.stdout.split('\n')
        
        # Look for Arducam B0497 in the output
        for i, line in enumerate(lines):
            if 'Arducam B0497' in line:
                # Get the next line which should contain the device path
                if i + 1 < len(lines):
                    device_line = lines[i + 1].strip()
                    # Extract the video device number
                    match = re.search(r'/dev/video(\d+)', device_line)
                    if match:
                        device_num = int(match.group(1))
                        print(f"Found Arducam B0497 at /dev/video{device_num}")
                        return device_num
        print("Could not find Arducam B0497 in device list")
        return None
    except Exception as e:
        print(f"Error finding camera device: {e}")
        return None

def try_open_camera(device_num):
    """Try to open a camera device and return True if successful"""
    try:
        print(f"Attempting to open /dev/video{device_num}")
        cap = cv2.VideoCapture(device_num)
        if not cap.isOpened():
            print(f"Failed to open /dev/video{device_num}")
            return None
            
        # Try to read a frame to verify the camera works
        ret, frame = cap.read()
        if not ret:
            print(f"Failed to read frame from /dev/video{device_num}")
            cap.release()
            return None
            
        print(f"Successfully opened and read from /dev/video{device_num}")
        return cap
    except Exception as e:
        print(f"Error opening /dev/video{device_num}: {e}")
        return None

def init_camera():
    global cap
    # Find the correct camera device
    device_num = find_camera_device()
    if device_num is None:
        print("Cannot find Arducam B0497 camera")
        return False

    # Try to open the camera
    cap = try_open_camera(device_num)
    if cap is None:
        # If first device fails, try the other one
        print(f"Trying alternate device for Arducam B0497")
        alternate_device = 2 if device_num == 1 else 1
        cap = try_open_camera(alternate_device)
        if cap is None:
            print("Failed to open camera on both devices")
            return False

    # Set initial backlight state
    cap.set(cv2.CAP_PROP_BACKLIGHT, 1 if backlight_enabled else 0)
    
    # Disable autofocus (if supported)
    cap.set(cv2.CAP_PROP_AUTOFOCUS, 0)
    
    # Set initial focus
    cap.set(cv2.CAP_PROP_FOCUS, current_focus)
    
    return True

def generate_frames():
    while True:
        if cap is None or not cap.isOpened():
            break
            
        ret, frame = cap.read()
        if not ret:
            break
            
        # Encode the frame in JPEG format
        ret, buffer = cv2.imencode('.jpg', frame)
        if not ret:
            continue
            
        # Convert to bytes for streaming
        frame_bytes = buffer.tobytes()
        yield (b'--frame\r\n'
               b'Content-Type: image/jpeg\r\n\r\n' + frame_bytes + b'\r\n')

@app.route('/')
def index():
    return send_from_directory(os.path.join(app.static_folder, 'server/app'), 'index.html')

@app.route('/_next/static/<path:path>')
def next_static(path):
    return send_from_directory(os.path.join(app.static_folder, 'static'), path)

@app.route('/_next/server/<path:path>')
def next_server(path):
    return send_from_directory(os.path.join(app.static_folder, 'server'), path)

@app.route('/static/<path:path>')
def static_files(path):
    return send_from_directory(os.path.join(app.static_folder, 'static'), path)

@app.after_request
def after_request(response):
    response.headers.add('Access-Control-Allow-Origin', '*')
    response.headers.add('Access-Control-Allow-Headers', 'Content-Type,Authorization')
    response.headers.add('Access-Control-Allow-Methods', 'GET,PUT,POST,DELETE,OPTIONS')
    return response

@app.route('/video_feed')
def video_feed():
    """Video streaming route."""
    return Response(
        generate_frames(),
        mimetype='multipart/x-mixed-replace; boundary=frame',
        headers={
            'Cache-Control': 'no-cache, no-store, must-revalidate',
            'Pragma': 'no-cache',
            'Expires': '0',
            'Access-Control-Allow-Origin': '*',
            'Connection': 'keep-alive'
        }
    )

@app.route('/set_focus/<int:focus_value>')
def set_focus(focus_value):
    global current_focus
    if cap is not None and cap.isOpened():
        current_focus = focus_value
        cap.set(cv2.CAP_PROP_FOCUS, focus_value)
    return {'status': 'success', 'focus': focus_value}

@app.route('/set_backlight/<int:enabled>')
def set_backlight(enabled):
    global backlight_enabled
    if cap is not None and cap.isOpened():
        backlight_enabled = bool(enabled)
        cap.set(cv2.CAP_PROP_BACKLIGHT, 1 if backlight_enabled else 0)
    return jsonify({'status': 'success', 'backlight_enabled': backlight_enabled})

@app.route('/get_backlight')
def get_backlight():
    return jsonify({'backlight_enabled': backlight_enabled})

def run_flask():
    app.run(host='0.0.0.0', port=5000, debug=False)

if __name__ == '__main__':
    if not init_camera():
        print("Failed to initialize camera")
        exit(1)
        
    # Start Flask in a separate thread
    flask_thread = threading.Thread(target=run_flask)
    flask_thread.daemon = True
    flask_thread.start()
    
    try:
        # Keep the main thread alive
        while True:
            pass
    except KeyboardInterrupt:
        print("Shutting down...")
        if cap is not None:
            cap.release()
