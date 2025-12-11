import base64

class FlowableAuth:
    def __init__(self):
        self.username = "restapitestteam@gmail.com"
        self.password = "restapitestteam"
        self.auth_header = None
    
    def get_auth_header(self):
        """Generate Basic Auth header with configured credentials"""
        if self.auth_header is None:
            credentials = f"{self.username}:{self.password}"
            encoded = base64.b64encode(credentials.encode()).decode()
            self.auth_header = f"Basic {encoded}"
        return self.auth_header
    
    def request(self, flow):
        """Add Basic Auth header to all requests"""
        flow.request.headers["Authorization"] = self.get_auth_header()

addons = [FlowableAuth()]
