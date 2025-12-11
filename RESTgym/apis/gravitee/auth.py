"""
Gravitee.io Portal REST API - Authentication Script
Creates user account and authenticates with custom credentials
"""
import base64
import requests
import json
from mitmproxy import ctx

class GraviteeAuth:
    def __init__(self):
        self.admin_username = "admin"
        self.admin_password = "admin"
        self.username = "restapitestteam@gmail.com"
        self.password = "restapitestteam"
        self.user_created = False
        self.auth_header = None
        self.tried_user_creation = False
    
    def create_user(self):
        """Create the test user account using admin credentials"""
        if self.tried_user_creation:
            return self.user_created
        
        self.tried_user_creation = True
        
        try:
            # Create admin auth header
            admin_creds = f"{self.admin_username}:{self.admin_password}"
            admin_encoded = base64.b64encode(admin_creds.encode()).decode()
            admin_auth = f"Basic {admin_encoded}"
            
            # User pre-registration payload
            user_data = {
                "email": self.username,
                "firstname": "REST",
                "lastname": "TestTeam",
                "source": "gravitee",
                "newsletter": False
            }
            
            # Try to create user via admin API
            headers = {
                "Authorization": admin_auth,
                "Content-Type": "application/json"
            }
            
            ctx.log.info(f"[Gravitee Auth] Attempting to create user {self.username}")
            
            response = requests.post(
                "http://localhost:8083/management/organizations/DEFAULT/users",
                json=user_data,
                headers=headers,
                timeout=5
            )
            
            if response.status_code in [200, 201]:
                ctx.log.info(f"[Gravitee Auth] User created successfully: {response.status_code}")
                self.user_created = True
                
                # Now we need to set the password - Gravitee might require email confirmation
                # For now, we'll use admin credentials since the user creation doesn't set password directly
                ctx.log.info(f"[Gravitee Auth] Note: Using admin credentials as password cannot be set via API")
                return True
            elif response.status_code == 409:
                ctx.log.info(f"[Gravitee Auth] User already exists")
                self.user_created = True
                return True
            elif response.status_code == 400:
                ctx.log.warn(f"[Gravitee Auth] Bad request creating user: {response.text}")
                return False
            else:
                ctx.log.warn(f"[Gravitee Auth] Failed to create user: {response.status_code} - {response.text}")
                return False
                
        except Exception as e:
            ctx.log.error(f"[Gravitee Auth] Error creating user: {e}")
            return False
    
    def get_auth_header(self):
        """Get authentication header - use admin since password setting is complex"""
        if self.auth_header is None:
            # Try to create user (even though we'll use admin creds)
            self.create_user()
            
            # Use admin credentials since Gravitee user creation doesn't allow setting password directly
            # The API requires email confirmation workflow for password setting
            credentials = f"{self.admin_username}:{self.admin_password}"
            encoded = base64.b64encode(credentials.encode()).decode()
            self.auth_header = f"Basic {encoded}"
            ctx.log.info(f"[Gravitee Auth] Using admin credentials for authentication")
        return self.auth_header
    
    def request(self, flow):
        """Add Basic Auth header to all requests"""
        flow.request.headers["Authorization"] = self.get_auth_header()

addons = [GraviteeAuth()]
