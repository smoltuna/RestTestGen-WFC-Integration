"""
Quartz Manager - Authentication Script
Basic Auth (if configured)
"""
import base64

class QuartzAuth:
    def __init__(self):
        # Quartz Manager può essere configurato senza auth
        # Usa credenziali base se configurate
        self.username = "restapitestteam@gmail.com"
        self.password = "universe"
        self.auth_header = None
        self.enabled = False  # Set to True if auth is configured
    
    def get_auth_header(self):
        if self.auth_header is None and self.enabled:
            credentials = f"{self.username}:{self.password}"
            encoded = base64.b64encode(credentials.encode()).decode()
            self.auth_header = f"Basic {encoded}"
        return self.auth_header
    
    def request(self, flow):
        if self.enabled:
            auth = self.get_auth_header()
            if auth:
                flow.request.headers["Authorization"] = auth

addons = [QuartzAuth()]
