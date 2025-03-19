#!/usr/bin/env python3

"""
Main entry point for the camera application.
"""

import sys
import argparse
from .camera_manager import CameraManager
from .server import CameraServer

def parse_args():
    """Parse command line arguments."""
    parser = argparse.ArgumentParser(description='Camera Application Server')
    parser.add_argument('--host', default='0.0.0.0',
                      help='Host to bind to (default: 0.0.0.0)')
    parser.add_argument('--port', type=int, default=5000,
                      help='Port to bind to (default: 5000)')
    parser.add_argument('--debug', action='store_true',
                      help='Enable debug mode')
    return parser.parse_args()

def main():
    """Main entry point."""
    try:
        args = parse_args()
        print(f"Initializing camera...")
        camera = CameraManager()
        
        print(f"Starting camera server on {args.host}:{args.port}")
        server = CameraServer(camera)
        server.run(host=args.host, port=args.port, debug=args.debug)
    except KeyboardInterrupt:
        print("\nShutting down...")
        sys.exit(0)
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == '__main__':
    main() 