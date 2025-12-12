"""
Gravitee.io Portal REST API - Authentication Script
Authenticates with restapitestteam@gmail.com credentials
"""
import base64
from mitmproxy import ctx

class GraviteeAuth:
    def __init__(self):
        self.username = "restapitestteam@gmail.com"
        self.password = "universe"
        self.auth_header = None
    
    def get_auth_header(self):
        """Get authentication header with restapitestteam credentials"""
        if self.auth_header is None:
            credentials = f"{self.username}:{self.password}"
            encoded = base64.b64encode(credentials.encode()).decode()
            self.auth_header = f"Basic {encoded}"
            ctx.log.info(f"[Gravitee Auth] Using credentials: {self.username}")
        return self.auth_header
    
    def request(self, flow):
        """Add Basic Auth header to all requests"""
        flow.request.headers["Authorization"] = self.get_auth_header()

addons = [GraviteeAuth()]
