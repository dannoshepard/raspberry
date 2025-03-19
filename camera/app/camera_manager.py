import cv2
import numpy as np
from typing import Generator, Tuple, Optional
import subprocess
import re
import os
import pwd
import grp
import time

class CameraManager:
    def __init__(self):
        """Initialize the camera manager."""
        self.camera = None
        self.focus = 30
        self.backlight_enabled = True
        self.device_num = None
        self.consecutive_failures = 0
        self.last_frame_time = 0
        
        if not self._init_camera():
            raise RuntimeError("Failed to initialize camera")

    def _find_camera_device(self) -> Optional[int]:
        """Find the Arducam B0497 camera device number."""
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

    def _try_open_camera(self, device_num: int) -> bool:
        """Try to open a camera device."""
        try:
            print(f"Attempting to open /dev/video{device_num}")
            cap = cv2.VideoCapture(device_num)
            if not cap.isOpened():
                print(f"Failed to open /dev/video{device_num}")
                return False
                
            # Try to read a frame to verify the camera works
            ret, frame = cap.read()
            if not ret or frame is None:
                print(f"Failed to read frame from /dev/video{device_num}")
                cap.release()
                return False
                
            print(f"Successfully opened and read from /dev/video{device_num}")
            self.camera = cap
            self.device_num = device_num
            
            # Configure camera settings
            self.camera.set(cv2.CAP_PROP_FRAME_WIDTH, 1920)
            self.camera.set(cv2.CAP_PROP_FRAME_HEIGHT, 1080)
            self.camera.set(cv2.CAP_PROP_AUTOFOCUS, 0)
            self.camera.set(cv2.CAP_PROP_FOCUS, self.focus)
            self.camera.set(cv2.CAP_PROP_BACKLIGHT, int(self.backlight_enabled))
            
            # Reset failure counter on successful open
            self.consecutive_failures = 0
            self.last_frame_time = time.time()
            
            return True
        except Exception as e:
            print(f"Error opening /dev/video{device_num}: {e}")
            return False

    def _init_camera(self) -> bool:
        """Initialize the camera."""
        # Find the camera device
        device_num = self._find_camera_device()
        if device_num is None:
            print("Cannot find Arducam B0497 camera")
            return False

        # Try to open the camera
        return self._try_open_camera(device_num)

    def _reset_camera(self) -> bool:
        """Reset the camera connection."""
        print("Resetting camera connection...")
        if self.camera is not None:
            self.camera.release()
            self.camera = None
            time.sleep(1)  # Give the camera time to reset
        
        if self.device_num is not None:
            return self._try_open_camera(self.device_num)
        return self._init_camera()

    def get_frame(self) -> Tuple[bool, np.ndarray]:
        """Get a frame from the camera with recovery logic."""
        if self.camera is None:
            return False, np.array([])

        # Check if we haven't received a frame in too long
        if time.time() - self.last_frame_time > 5:  # 5 seconds timeout
            print("No frames received for 5 seconds, resetting camera...")
            if not self._reset_camera():
                return False, np.array([])
        
        try:
            ret, frame = self.camera.read()
            if not ret or frame is None:
                self.consecutive_failures += 1
                print(f"Failed to get frame (attempt {self.consecutive_failures})")
                
                # If we've failed too many times in a row, try to reset the camera
                if self.consecutive_failures >= 5:
                    print("Too many consecutive failures, resetting camera...")
                    if not self._reset_camera():
                        return False, np.array([])
                return False, np.array([])
            
            # Success - reset failure counter and update last frame time
            self.consecutive_failures = 0
            self.last_frame_time = time.time()
            return True, frame
            
        except Exception as e:
            print(f"Error getting frame: {e}")
            self.consecutive_failures += 1
            return False, np.array([])

    def generate_frames(self) -> Generator[bytes, None, None]:
        """Generate a sequence of JPEG frames from the camera."""
        while True:
            success, frame = self.get_frame()
            if not success:
                # Add a small delay to prevent tight loop when failing
                time.sleep(0.1)
                continue

            try:
                # Encode frame as JPEG
                ret, buffer = cv2.imencode('.jpg', frame)
                if not ret:
                    print("Failed to encode frame as JPEG")
                    continue

                # Convert to bytes with multipart boundary
                frame_bytes = buffer.tobytes()
                yield (b'--frame\r\n'
                      b'Content-Type: image/jpeg\r\n\r\n' + frame_bytes + b'\r\n')

            except Exception as e:
                print(f"Error generating frame: {e}")
                continue

    def __del__(self):
        """Release the camera when the object is destroyed."""
        if self.camera is not None:
            self.camera.release()

    def set_focus(self, value: int) -> bool:
        """Set the camera focus value.
        
        Args:
            value: Focus value between 0 and 255
            
        Returns:
            bool: True if successful, False otherwise
        """
        if self.camera is None:
            return False
            
        try:
            self.focus = max(0, min(255, value))
            return self.camera.set(cv2.CAP_PROP_FOCUS, self.focus)
        except Exception as e:
            print(f"Error setting focus: {e}")
            return False

    def set_backlight(self, enabled: bool) -> bool:
        """Enable or disable camera backlight compensation.
        
        Args:
            enabled: True to enable backlight compensation, False to disable
            
        Returns:
            bool: True if successful, False otherwise
        """
        if self.camera is None:
            return False
            
        try:
            self.backlight_enabled = enabled
            return self.camera.set(cv2.CAP_PROP_BACKLIGHT, int(enabled))
        except Exception as e:
            print(f"Error setting backlight: {e}")
            return False 