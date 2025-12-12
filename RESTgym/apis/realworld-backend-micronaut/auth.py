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
            signup_url = f"{self.base_url}/api/users"
            signup_payload = {
                "user": {
                    "username": "restapitestteam",
                    "email": "restapitestteam@gmail.com",
                    "password": "universe"
                }
            }
            headers = {
                "Content-Type": "application/json",
                "Accept": "application/json"
            }
            try:
                # Always try to register the user (idempotent)
                requests.post(signup_url, json=signup_payload, headers=headers, timeout=5)
            except Exception as e:
                print(f"[RealWorld Auth] Error during user seed: {e}")
            try:
                # Login
                login_url = f"{self.base_url}/api/users/login"
                login_payload = {
                    "user": {
                        "email": "restapitestteam@gmail.com",
                        "password": "universe"
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
        # Skip auth endpoints (signup and login)
        if ("/api/users/login" in flow.request.pretty_url or 
            (flow.request.method == "POST" and "/api/users" in flow.request.pretty_url and "/api/users/" not in flow.request.pretty_url)):
            return
        
        token = self.get_token()
        if token:
            flow.request.headers["Authorization"] = f"Token {token}"

addons = [RealWorldAuth()]
