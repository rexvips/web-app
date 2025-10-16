#!/usr/bin/env python3
"""
Simple HTTP server for testing the Daily Routine PWA
Run with: python server.py
"""

import http.server
import socketserver
import os
import sys
from urllib.parse import urlparse

class PWAHandler(http.server.SimpleHTTPRequestHandler):
    """Custom handler to serve PWA with proper headers"""
    
    def end_headers(self):
        # Add PWA-friendly headers
        self.send_header('Cache-Control', 'no-cache, no-store, must-revalidate')
        self.send_header('Pragma', 'no-cache')
        self.send_header('Expires', '0')
        
        # CORS headers for local development
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        
        super().end_headers()
    
    def do_GET(self):
        """Handle GET requests with PWA routing"""
        parsed_path = urlparse(self.path)
        
        # Serve manifest.json with correct MIME type
        if parsed_path.path == '/manifest.json':
            self.send_response(200)
            self.send_header('Content-type', 'application/manifest+json')
            self.end_headers()
            with open('manifest.json', 'rb') as f:
                self.wfile.write(f.read())
            return
        
        # Serve service worker with correct MIME type
        if parsed_path.path == '/sw.js':
            self.send_response(200)
            self.send_header('Content-type', 'application/javascript')
            self.end_headers()
            with open('sw.js', 'rb') as f:
                self.wfile.write(f.read())
            return
        
        # Default handling
        super().do_GET()
    
    def guess_type(self, path):
        """Guess the MIME type with PWA-specific types"""
        mimetype, encoding = super().guess_type(path)
        
        # Override specific file types
        if path.endswith('.webmanifest') or path.endswith('manifest.json'):
            return 'application/manifest+json'
        
        return mimetype, encoding

def main():
    PORT = 8000
    
    # Change to the WebApp directory
    os.chdir(os.path.dirname(os.path.abspath(__file__)))
    
    try:
        with socketserver.TCPServer(("", PORT), PWAHandler) as httpd:
            print(f"🚀 Daily Routine PWA Server")
            print(f"📱 Open in browser: http://localhost:{PORT}")
            print(f"📲 On mobile: http://[your-ip]:{PORT}")
            print(f"🛑 Press Ctrl+C to stop")
            print(f"")
            print(f"📋 Features available:")
            print(f"   ✅ Box Breathing (4-7 seconds configurable)")
            print(f"   ✅ 4-7-8 Breathing")
            print(f"   ✅ Audio cues every X seconds")
            print(f"   ✅ Haptic feedback")
            print(f"   ✅ Offline functionality")
            print(f"   ✅ Install as PWA")
            print(f"")
            
            httpd.serve_forever()
    except KeyboardInterrupt:
        print("\n🛑 Server stopped")
    except OSError as e:
        if e.errno == 48:  # Address already in use
            print(f"❌ Port {PORT} is already in use")
            print(f"💡 Try a different port or stop the existing server")
        else:
            print(f"❌ Server error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()