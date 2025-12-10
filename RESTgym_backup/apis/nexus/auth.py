"""
Sonatype Nexus Repository - Authentication Script
Basic Auth with default admin credentials
"""
import base64

class NexusAuth:
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
        flow.request.headers["Authorization"] = self.get_auth_header()

addons = [NexusAuth()]
