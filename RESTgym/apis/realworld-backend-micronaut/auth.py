"""
RealWorld Micronaut Backend - Authentication Script
JWT Bearer Token with signup and login
"""
import requests
import json

class RealWorldAuth:
    def __init__(self):
        self.token = None
        self.base_url = "http://localhost:8080"
    
    def get_token(self):
        if self.token is None:
            # Try to register a new user
            signup_url = f"{self.base_url}/api/users"
            signup_payload = {
                "user": {
                    "username": "restgym_test",
                    "email": "restgym.test@gmail.com",
                    "password": "RESTgym2024!"
                }
            }
            headers = {
                "Content-Type": "application/json",
                "Accept": "application/json"
            }
            
            try:
                # Try signup (might fail if user exists)
                signup_response = requests.post(signup_url, json=signup_payload, headers=headers, timeout=5)
                
                # Login
                login_url = f"{self.base_url}/api/users/login"
                login_payload = {
                    "user": {
                        "email": "restgym.test@gmail.com",
                        "password": "RESTgym2024!"
                    }
                }
                login_response = requests.post(login_url, json=login_payload, headers=headers, timeout=5)
                
                if login_response.status_code == 200:
                    self.token = login_response.json()["user"]["token"]
                    print(f"[RealWorld Auth] Token obtained: {self.token[:20]}...")
                else:
                    print(f"[RealWorld Auth] Login failed: {login_response.status_code}")
            except Exception as e:
                print(f"[RealWorld Auth] Error: {e}")
        
        return self.token
    
    def request(self, flow):
        # Skip auth endpoints
        if "/api/users/login" in flow.request.pretty_url or "/api/users" in flow.request.pretty_url:
            return
        
        token = self.get_token()
        if token:
            flow.request.headers["Authorization"] = f"Token {token}"

addons = [RealWorldAuth()]
