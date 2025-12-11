import base64

class NexusAuth:
    def __init__(self):
        self.username = "admin"
        self.password = "admin123"
        self.auth_header = None
    
    def get_auth_header(self):
        if self.auth_header is None:
            credentials = f"{self.username}:{self.password}"
            encoded = base64.b64encode(credentials.encode()).decode()
            self.auth_header = f"Basic {encoded}"
        return self.auth_header
    
    def request(self, flow):
        flow.request.headers["Authorization"] = self.get_auth_header()

addons = [NexusAuth()]
