from flask import Flask, Response, send_from_directory
import os
from .camera_manager import CameraManager

class CameraServer:
    def __init__(self, camera_manager: CameraManager):
        """Initialize the camera server.
        
        Args:
            camera_manager: Instance of CameraManager to handle camera operations
        """
        self.camera = camera_manager
        self.app = Flask(__name__)
        
        # Get client directory from environment or use default
        self.client_dir = os.getenv('CLIENT_DIR', '/opt/client/.next')
        self._register_routes()

    def _register_routes(self):
        """Register all route handlers."""
        
        @self.app.route('/')
        def index():
            """Serve the Next.js app."""
            app_dir = os.path.join(self.client_dir, 'server/app')
            if not os.path.exists(os.path.join(app_dir, 'index.html')):
                return 'Client app not found. Please deploy the client first.', 404
            return send_from_directory(app_dir, 'index.html')

        @self.app.route('/_next/static/<path:path>')
        def serve_static(path):
            """Serve Next.js static files."""
            static_dir = os.path.join(self.client_dir, 'static')
            if not os.path.exists(os.path.join(static_dir, path)):
                return f'Static file {path} not found', 404
            return send_from_directory(static_dir, path)

        @self.app.route('/_next/<path:path>')
        def serve_next(path):
            """Serve Next.js files."""
            if path.startswith('static/'):
                return send_from_directory(self.client_dir, path)
            server_dir = os.path.join(self.client_dir, 'server')
            if not os.path.exists(os.path.join(server_dir, path)):
                return f'Next.js file {path} not found', 404
            return send_from_directory(server_dir, path)

        @self.app.route('/video_feed')
        def video_feed():
            """Video streaming route."""
            return Response(
                self.camera.generate_frames(),
                mimetype='multipart/x-mixed-replace; boundary=frame',
                headers={
                    'Cache-Control': 'no-cache, no-store, must-revalidate',
                    'Pragma': 'no-cache',
                    'Expires': '0',
                    'Connection': 'keep-alive'
                }
            )

        @self.app.route('/set_focus/<int:focus_value>')
        def set_focus(focus_value):
            """Set camera focus value."""
            success = self.camera.set_focus(focus_value)
            return {'success': success}

        @self.app.route('/set_backlight/<int:enabled>')
        def set_backlight(enabled):
            """Enable/disable camera backlight compensation."""
            success = self.camera.set_backlight(bool(enabled))
            return {'success': success}

    def run(self, host='0.0.0.0', port=5000, debug=False):
        """Run the camera server.
        
        Args:
            host: Host to bind to
            port: Port to bind to
            debug: Whether to run in debug mode
        """
        self.app.run(host=host, port=port, debug=debug)
