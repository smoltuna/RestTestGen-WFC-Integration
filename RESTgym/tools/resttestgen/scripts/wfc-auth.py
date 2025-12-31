#!/usr/bin/env python3
"""
WFC auth script for RestTestGen. Reads auth.yaml and outputs JSON.
Usage: python3 wfc-auth.py /path/to/auth.yaml
"""

import sys
import os
import json
import yaml
import requests
from urllib.parse import urljoin
import time

# Default token duration
DEFAULT_DURATION = 3600

# Suppress SSL warnings for development environments
import urllib3
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)


def load_auth_config(auth_yaml_path):
    """Load and parse the WFC auth.yaml configuration file"""
    if not os.path.exists(auth_yaml_path):
        print(f"Error: Auth file not found: {auth_yaml_path}", file=sys.stderr)
        sys.exit(1)
    
    with open(auth_yaml_path, 'r') as f:
        config = yaml.safe_load(f)
    
    if not config or 'auth' not in config:
        print("Error: Invalid auth.yaml - missing 'auth' array", file=sys.stderr)
        sys.exit(1)
    
    return config


def merge_with_template(user, template):
    """Merge user config with template (user values take precedence)"""
    merged = dict(template)
    
    for key, value in user.items():
        if key == 'loginEndpointAuth' and 'loginEndpointAuth' in merged:
            # Deep merge loginEndpointAuth
            merged_login = dict(merged.get('loginEndpointAuth', {}))
            if isinstance(value, dict):
                for login_key, login_value in value.items():
                    if login_key == 'token' and 'token' in merged_login:
                        # Deep merge token config
                        merged_token = dict(merged_login.get('token', {}))
                        if isinstance(login_value, dict):
                            merged_token.update(login_value)
                        merged_login['token'] = merged_token
                    elif login_value is not None:
                        merged_login[login_key] = login_value
            merged['loginEndpointAuth'] = merged_login
        elif value is not None:
            merged[key] = value
    
    return merged


def extract_token_from_json(json_data, json_pointer):
    """Extract value from JSON using JSON Pointer"""
    if not json_pointer:
        return None
    
    # Remove leading slash and split
    parts = json_pointer.lstrip('/').split('/')
    
    try:
        result = json_data
        for part in parts:
            if isinstance(result, dict):
                result = result.get(part)
            elif isinstance(result, list):
                result = result[int(part)]
            else:
                return None
        return result
    except (KeyError, IndexError, ValueError, TypeError):
        return None


def perform_signup(base_url, user):
    """Perform user signup/registration (extension to WFC schema)"""
    signup_config = user.get('signupEndpoint')
    if not signup_config:
        return True
    
    endpoint = signup_config.get('endpoint', '')
    verb = signup_config.get('verb', 'POST').upper()
    content_type = signup_config.get('contentType', 'application/json')
    payload_raw = signup_config.get('payloadRaw', '')
    
    signup_url = urljoin(base_url, endpoint)
    headers = {'Content-Type': content_type, 'Accept': 'application/json'}
    
    print(f"Performing signup at {signup_url}", file=sys.stderr)
    
    try:
        response = requests.request(verb, signup_url, data=payload_raw, headers=headers, timeout=10, verify=False)
        print(f"Signup response: {response.status_code}", file=sys.stderr)
        
        # Signup can fail if user already exists (409, 422, 400) - that's OK
        return response.status_code in [200, 201, 409, 422, 400]
        
    except Exception as e:
        print(f"Signup error: {e}", file=sys.stderr)
        return False


def perform_login(base_url, user):
    """Perform login and extract token/cookies based on WFC config"""
    login_config = user.get('loginEndpointAuth')
    
    if not login_config:
        print("No loginEndpointAuth configured", file=sys.stderr)
        return None
    
    # Determine login URL
    endpoint = login_config.get('endpoint', '')
    external_url = login_config.get('externalEndpointURL')
    
    if external_url:
        login_url = external_url
    else:
        login_url = urljoin(base_url, endpoint)
    
    # Prepare request
    verb = login_config.get('verb', 'POST').upper()
    content_type = login_config.get('contentType', 'application/json')
    
    headers = {'Content-Type': content_type, 'Accept': 'application/json'}
    
    # Add any additional headers from config
    for header in login_config.get('headers', []):
        headers[header['name']] = header['value']
    
    # Prepare payload
    payload = None
    payload_raw = login_config.get('payloadRaw')
    payload_user_pwd = login_config.get('payloadUserPwd')
    
    if payload_raw:
        payload = payload_raw
    elif payload_user_pwd:
        username = payload_user_pwd.get('username')
        password = payload_user_pwd.get('password')
        username_field = payload_user_pwd.get('usernameField', 'username')
        password_field = payload_user_pwd.get('passwordField', 'password')
        
        if 'json' in content_type.lower():
            payload = json.dumps({username_field: username, password_field: password})
        else:
            payload = f"{username_field}={username}&{password_field}={password}"
    
    print(f"Performing login at {login_url}", file=sys.stderr)
    
    try:
        response = requests.request(verb, login_url, data=payload, headers=headers, timeout=10, verify=False)
        print(f"Login response: {response.status_code}", file=sys.stderr)
        
        if response.status_code not in [200, 201]:
            print(f"Login failed: {response.text[:500]}", file=sys.stderr)
            return None
        
        # Handle token extraction ()
        token_config = login_config.get('token')
        if token_config:
            # uses extractFromField (JSON pointer, implies body)
            extract_from_field = token_config.get('extractFromField')
            
            if extract_from_field:
                try:
                    json_response = response.json()
                    token = extract_token_from_json(json_response, extract_from_field)
                    if token:
                        # Extract duration: expires_in (seconds), expiresIn (seconds), or exp (unix timestamp)
                        duration = None
                        for field in ['expires_in', 'expiresIn']:
                            if field in json_response and isinstance(json_response[field], (int, float)):
                                duration = int(json_response[field])
                                break
                        if duration is None and 'exp' in json_response:
                            exp_value = json_response.get('exp')
                            if isinstance(exp_value, (int, float)):
                                duration = max(0, int(exp_value) - int(time.time()))
                        
                        return {
                            'token': token,
                            'config': token_config,
                            'duration': duration
                        }
                    else:
                        print(f"Failed to extract token using {extract_from_field}", file=sys.stderr)
                except json.JSONDecodeError:
                    print("Failed to parse JSON response", file=sys.stderr)
        
        return None
        
    except Exception as e:
        print(f"Login error: {e}", file=sys.stderr)
        return None


def get_auth_info(base_url, user):
    """Get authentication info for a user in RestTestGen format"""
    
    # Check for fixed headers first (no login required)
    fixed_headers = user.get('fixedHeaders', [])
    if fixed_headers:
        # Use the first fixed header
        header = fixed_headers[0]
        return {
            "name": header['name'],
            "value": header['value'],
            "in": "header",
            "duration": DEFAULT_DURATION
        }
    
    # Need to perform login (with signup first if configured)
    if user.get('signupEndpoint'):
        perform_signup(base_url, user)
    
    login_result = perform_login(base_url, user)
    
    if not login_result:
        print("Authentication failed", file=sys.stderr)
        return None
    
    # Token-based auth ()
    if 'token' in login_result:
        token = login_result['token']
        token_config = login_result['config']
        
        # : httpHeaderName and headerPrefix
        header_name = token_config.get('httpHeaderName', 'Authorization')
        header_prefix = token_config.get('headerPrefix', '')
        
        # Use duration from response if available, otherwise use default
        duration = login_result.get('duration') or DEFAULT_DURATION
        
        return {
            "name": header_name,
            "value": f"{header_prefix}{token}",
            "in": "header",
            "duration": duration
        }
    
    # Cookie-based auth
    if 'cookies' in login_result:
        cookies = login_result['cookies']
        cookie_str = '; '.join([f"{k}={v}" for k, v in cookies.items()])
        
        return {
            "name": "Cookie",
            "value": cookie_str,
            "in": "header",
            "duration": DEFAULT_DURATION
        }
    
    return None


def main():
    if len(sys.argv) < 2:
        print("Usage: python3 wfc-auth.py /path/to/auth.yaml", file=sys.stderr)
        sys.exit(1)
    
    auth_yaml_path = sys.argv[1]
    
    # Load configuration
    config = load_auth_config(auth_yaml_path)
    
    # Get base_url from authTemplate or use default
    template = config.get('authTemplate', {})
    base_url = template.get('baseUrl', 'http://localhost:9090')
    users = config.get('auth', [])
    
    if not users:
        print("Error: No users defined in auth.yaml", file=sys.stderr)
        sys.exit(1)
    
    # Use first user (labeled 'default' if available, otherwise first)
    user = None
    for u in users:
        if u.get('name') == 'default':
            user = u
            break
    if not user:
        user = users[0]
    
    # Merge with template
    merged_user = merge_with_template(user, template)
    
    # Get authentication info
    auth_info = get_auth_info(base_url, merged_user)
    
    if not auth_info:
        print("Error: Failed to obtain authentication", file=sys.stderr)
        sys.exit(1)
    
    # Output JSON to stdout
    print(json.dumps(auth_info))


if __name__ == "__main__":
    main()
