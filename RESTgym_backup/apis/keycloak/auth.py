"""
Keycloak - Authentication Script
OAuth2 Bearer Token with admin credentials
"""
import requests
import json

class KeycloakAuth:
    def __init__(self):
        self.username = "restapitestteam@gmail.com"
        self.password = "universe"
        self.token = None
        self.token_url = "http://localhost:8080/realms/master/protocol/openid-connect/token"
    
    def get_token(self):
        if self.token is None:
            try:
                payload = {
                    "grant_type": "password",
                    "client_id": "admin-cli",
                    "username": self.username,
                    "password": self.password
                }
                headers = {
                    "Content-Type": "application/x-www-form-urlencoded"
                }
                response = requests.post(self.token_url, data=payload, headers=headers, timeout=5)
                if response.status_code == 200:
                    self.token = response.json()["access_token"]
                    print(f"[Keycloak Auth] Token obtained successfully")
                else:
                    print(f"[Keycloak Auth] Failed to get token: {response.status_code}")
            except Exception as e:
                print(f"[Keycloak Auth] Error getting token: {e}")
        return self.token
    
    def request(self, flow):
        # Skip token endpoint itself
        if "openid-connect/token" in flow.request.pretty_url:
            return
        
        token = self.get_token()
        if token:
            flow.request.headers["Authorization"] = f"Bearer {token}"

addons = [KeycloakAuth()]
