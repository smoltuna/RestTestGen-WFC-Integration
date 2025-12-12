#!/usr/bin/env python3
"""
Create Gravitee user directly in MongoDB database with BCrypt password
"""
import bcrypt
import pymongo
from datetime import datetime
import uuid
import sys
import time

def wait_for_mongodb():
    """Wait for MongoDB to be ready"""
    print("Waiting for MongoDB to be ready...")
    for i in range(30):
        try:
            client = pymongo.MongoClient("mongodb://localhost:27017/", serverSelectionTimeoutMS=2000)
            client.server_info()
            print("MongoDB is ready!")
            client.close()
            return True
        except:
            time.sleep(1)
    print("MongoDB did not become ready in time")
    return False

def create_user():
    """Create user directly in MongoDB with BCrypt password"""
    email = "restapitestteam@gmail.com"
    password = "universe"
    
    # Connect to MongoDB
    client = pymongo.MongoClient("mongodb://localhost:27017/")
    db = client["gravitee"]
    users_collection = db["users"]
    
    # Check if user already exists
    existing_user = users_collection.find_one({"email": email})
    if existing_user:
        print(f"User {email} already exists. Updating password...")
        user_id = existing_user["_id"]
        update_existing = True
    else:
        print(f"Creating new user {email}...")
        user_id = str(uuid.uuid4())
        update_existing = False
    
    # Hash password with BCrypt (Gravitee's default)
    password_bytes = password.encode('utf-8')
    salt = bcrypt.gensalt(rounds=10)
    hashed_password = bcrypt.hashpw(password_bytes, salt).decode('utf-8')
    
    print(f"Password hash generated: {hashed_password[:30]}...")
    
    # Prepare user document
    now = datetime.utcnow()
    
    if update_existing:
        # Update existing user's password
        result = users_collection.update_one(
            {"_id": user_id},
            {
                "$set": {
                    "password": hashed_password,
                    "updatedAt": now
                }
            }
        )
        if result.modified_count > 0:
            print(f"✓ User password updated successfully!")
        else:
            print(f"✗ Failed to update user password")
            return False
    else:
        # Create new user document
        user_doc = {
            "_id": user_id,
            "organizationId": "DEFAULT",
            "email": email,
            "password": hashed_password,
            "firstname": "REST",
            "lastname": "TestTeam",
            "source": "gravitee",
            "sourceId": email,
            "status": "ACTIVE",
            "createdAt": now,
            "updatedAt": now,
            "_class": "io.gravitee.rest.api.model.UserEntity"
        }
        
        try:
            users_collection.insert_one(user_doc)
            print(f"✓ User created successfully with ID: {user_id}")
        except Exception as e:
            print(f"✗ Failed to create user: {e}")
            return False
    
    # Verify the user exists
    verify_user = users_collection.find_one({"email": email})
    if verify_user:
        print(f"✓ User verified in database")
        print(f"  - ID: {verify_user['_id']}")
        print(f"  - Email: {verify_user['email']}")
        print(f"  - Status: {verify_user.get('status', 'N/A')}")
        print(f"  - Password hash: {verify_user['password'][:30]}...")
        return True
    else:
        print(f"✗ User verification failed")
        return False

if __name__ == "__main__":
    if not wait_for_mongodb():
        print("Setup failed: MongoDB not ready")
        sys.exit(1)
    
    # Give MongoDB a moment to fully initialize
    time.sleep(2)
    
    if create_user():
        print("\n✓ User setup complete!")
        print(f"Credentials: restapitestteam@gmail.com / universe")
        sys.exit(0)
    else:
        print("\n✗ User setup failed")
        sys.exit(1)
