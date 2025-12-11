"""
Traccar GPS Tracking System - Authentication Script
Basic Auth with pre-configured admin user
"""
import base64
from mitmproxy import ctx
from urllib.parse import urlencode

class TraccarAuth:
    def __init__(self):
        self.username = "restapitestteam@gmail.com"
        self.password = "universe"
        self.auth_header = None
    
    def get_auth_header(self):
        if self.auth_header is None:
            credentials = f"{self.username}:{self.password}"
            encoded = base64.b64encode(credentials.encode()).decode()
            self.auth_header = f"Basic {encoded}"
        return self.auth_header
    
    def request(self, flow):
        # Handle /api/session POST requests - inject correct credentials
        if flow.request.method == "POST" and flow.request.path == "/api/session":
            # Replace with correct credentials
            correct_data = urlencode({
                'email': self.username,
                'password': self.password
            })
            flow.request.content = correct_data.encode()
            flow.request.headers["Content-Length"] = str(len(correct_data))
            ctx.log.info(f"[AUTH] Injecting correct credentials for login endpoint: {flow.request.pretty_url}")
            return
        
        # Add Basic Auth header to all other requests
        auth = self.get_auth_header()
        ctx.log.info(f"[AUTH] Adding Authorization header to {flow.request.pretty_url}")
        flow.request.headers["Authorization"] = auth

addons = [TraccarAuth()]
