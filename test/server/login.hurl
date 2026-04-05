# Register a new user
POST http://localhost:1337/register
Content-Type: application/json
{ "accountName": "newuser", "accountPassword": "newpassword" }
HTTP/1.1 200

# Login with newly registered user
POST http://localhost:1337/login
Content-Type: application/json
{ "accountName": "newuser", "accountPassword": "newpassword" }
HTTP/1.1 200
[Captures]
TOKEN: jsonpath "$.token"


# Fail login for new user with wrong pass
POST http://localhost:1337/login
Content-Type: application/json
{ "accountName": "newuser", "accountPassword": "wrongpassword" }
HTTP/1.1 401
`Invalid login or password`

# Unknown User
POST http://localhost:1337/login
Content-Type: application/json
{ "accountName": "notreal", "accountPassword": "password1" }
HTTP/1.1 401
`Invalid login or password`

# Attempt duplicate user registration
POST http://localhost:1337/register
Content-Type: application/json
{ "accountName": "newuser", "accountPassword": "newpassword" }
HTTP/1.1 409
`Username already exists`

# Registration - missing password
POST http://localhost:1337/register
Content-Type: application/json
{ "accountName": "missingpw" }
HTTP/1.1 400

# Registration - missing accountName
POST http://localhost:1337/register
Content-Type: application/json
{ "accountPassword": "validpassword" }
HTTP/1.1 400

# Registration - empty values
POST http://localhost:1337/register
Content-Type: application/json
{ "accountName": "", "accountPassword": "" }
HTTP/1.1 400

# Registration - short password (<8 chars)
POST http://localhost:1337/register
Content-Type: application/json
{ "accountName": "shortpw", "accountPassword": "short" }
HTTP/1.1 400
`Password must be at least 8 characters`

# Registration - malformed JSON
POST http://localhost:1337/register
Content-Type: application/json
`{ "accountName": "foo", `
HTTP/1.1 400

# Login with missing password
POST http://localhost:1337/login
Content-Type: application/json
{ "accountName": "newuser" }
HTTP/1.1 400

# Login with missing username
POST http://localhost:1337/login
Content-Type: application/json
{ "accountPassword": "newpassword" }
HTTP/1.1 400

# Login with case sensitivity (should fail)
POST http://localhost:1337/login
Content-Type: application/json
{ "accountName": "NewUser", "accountPassword": "newpassword" }
HTTP/1.1 401
`Invalid login or password`

# Login with non-ASCII username/password (should fail unless allowed)
POST http://localhost:1337/login
Content-Type: application/json
{ "accountName": "üser", "accountPassword": "pässword" }
HTTP/1.1 401

# Login with blank profile value
POST http://localhost:1337/login
Content-Type: application/json
{ "accountName": "newuser", "accountPassword": "newpassword" }
HTTP/1.1 200

# Login - echo JWT to verify in shell
POST http://localhost:1337/login
Content-Type: application/json
{ "accountName": "newuser", "accountPassword": "newpassword" }
HTTP/1.1 200
# The response body should contain a 'token' field. Manual step: decode JWT externally.

# Brute force simulation: multiple failed login attempts for same user
POST http://localhost:1337/login
Content-Type: application/json
{ "accountName": "newuser", "accountPassword": "wrongpassword" }
HTTP/1.1 401
`Invalid login or password`

GET http://localhost:1337/profile
Content-Type: application/json
Authorization: Bearer {{TOKEN}}
HTTP/1.1 200
[Asserts]
jsonpath "$.profileName" == "newuser"

GET http://localhost:1337/profile
Content-Type: application/json
HTTP/1.1 401
`Invalid or expired token`

GET http://localhost:1337/profile
Content-Type: application/json
Authorization: Bearer wrongtoken
HTTP/1.1 401
`Invalid or expired token`
