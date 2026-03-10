# Variables (with defaults, can be overridden via CLI)
# Usage: hurl ./test/server/login.hurl --variable endpoint=localhost --variable port=8080

# Test 1: Successful Login (user1/password1)
POST http://localhost:8080/login
Content-Type: application/json
{ "accountName": "user1", "accountPassword": "password1", "accountProfile": "" }
HTTP/1.1 200

# Test 2: Incorrect Password (user1/wrongpassword)
POST http://localhost:8080/login
Content-Type: application/json
{ "accountName": "user1", "accountPassword": "Incorrect", "accountProfile": "" }
HTTP/1.1 401

# Test 3: Unknown User
POST http://localhost:8080/login
Content-Type: application/json
{ "accountName": "notreal", "accountPassword": "password1", "accountProfile": "" }
HTTP/1.1 401
