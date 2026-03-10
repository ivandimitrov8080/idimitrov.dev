# Register a new user
POST http://localhost:1337/register
Content-Type: application/json
{ "accountName": "newuser", "accountPassword": "newpassword", "accountProfile": "" }
HTTP/1.1 200

# Login with newly registered user
POST http://localhost:1337/login
Content-Type: application/json
{ "accountName": "newuser", "accountPassword": "newpassword", "accountProfile": "" }
HTTP/1.1 200

# Fail login for new user with wrong pass
POST http://localhost:1337/login
Content-Type: application/json
{ "accountName": "newuser", "accountPassword": "wrongpassword", "accountProfile": "" }
HTTP/1.1 401
`Invalid login or password`

# Unknown User
POST http://localhost:1337/login
Content-Type: application/json
{ "accountName": "notreal", "accountPassword": "password1", "accountProfile": "" }
HTTP/1.1 401
`Invalid login or password`

# Attempt duplicate user registration
POST http://localhost:1337/register
Content-Type: application/json
{ "accountName": "newuser", "accountPassword": "newpassword", "accountProfile": "" }
HTTP/1.1 409
`Username already exists`
