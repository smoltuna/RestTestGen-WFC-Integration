"""
Alfresco Content Services - Authentication Script
Creates test user if doesn't exist, then authenticates all requests with that user
"""
import requests
import base64
import json

class Authenticate:
    def __init__(self):
        self.token = None
        self.username = "restapitestteam@gmail.com"
        self.password = "universe"
        self.user_id = "restapitestteam"
        self.base_url = "http://localhost:8080/alfresco/api/-default-/public/alfresco/versions/1"
        self.admin_user = "admin"
        self.admin_password = "admin"
        self.user_created = False
    
    def get_basic_auth_header(self, username, password):
        """Generate Basic Auth header"""
        credentials = f"{username}:{password}"
        encoded = base64.b64encode(credentials.encode()).decode()
        return f"Basic {encoded}"
    
    def create_test_user(self):
        """Create the test user using admin credentials"""
        if self.user_created:
            return
        
        create_url = f"{self.base_url}/people"
        headers = {
            "Content-Type": "application/json",
            "Accept": "application/json",
            "Authorization": self.get_basic_auth_header(self.admin_user, self.admin_password)
        }
        
        payload = {
            "id": self.user_id,
            "firstName": "REST",
            "lastName": "TestTeam",
            "displayName": "REST API Test Team",
            "email": self.username,
            "password": self.password,
            "enabled": True
        }
        
        try:
            # Try to create the user (will fail if already exists)
            response = requests.post(create_url, json=payload, headers=headers, timeout=5)
            if response.status_code == 201:
                print(f"[Alfresco Auth] Test user created: {self.user_id}")
                self.user_created = True
            elif response.status_code == 409:
                print(f"[Alfresco Auth] Test user already exists: {self.user_id}")
                self.user_created = True
            else:
                print(f"[Alfresco Auth] User creation failed: {response.status_code} - {response.text[:200]}")
        except Exception as e:
            print(f"[Alfresco Auth] Error creating user: {e}")
    
    def request(self, flow):
        """Intercept and add authentication to requests"""
        # Create test user on first request
        if not self.user_created:
            self.create_test_user()
        
        # Add Basic Auth with test user credentials
        flow.request.headers["Authorization"] = self.get_basic_auth_header(self.user_id, self.password)

addons = [Authenticate()]
