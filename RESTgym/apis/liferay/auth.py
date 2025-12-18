"""
Liferay Portal - Authentication Script
Uses Basic Auth with restapitestteam@gmail.com / universe credentials
"""
import base64
from mitmproxy import http

class LiferayAuth:
    def __init__(self):
        # Standard RESTgym test user credentials
        self.username = "restapitestteam@gmail.com"
        self.password = "universe"
        
    def request(self, flow: http.HTTPFlow) -> None:
        """
        Add Basic Authentication to all requests
        """
        # Create Basic Auth header
        credentials = f"{self.username}:{self.password}"
        b64_credentials = base64.b64encode(credentials.encode()).decode()
        auth_header = f"Basic {b64_credentials}"
        
        # Add Authorization header to the request
        flow.request.headers["Authorization"] = auth_header

addons = [LiferayAuth()]
