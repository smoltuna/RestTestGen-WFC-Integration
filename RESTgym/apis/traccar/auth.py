"""
Traccar GPS Tracking System - Authentication Script
Basic Auth with pre-configured admin user
"""
import base64
from mitmproxy import ctx

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
        # Add Basic Auth header to all requests
        auth = self.get_auth_header()
        ctx.log.info(f"[AUTH] Adding Authorization header to {flow.request.pretty_url}")
        flow.request.headers["Authorization"] = auth

addons = [TraccarAuth()]
