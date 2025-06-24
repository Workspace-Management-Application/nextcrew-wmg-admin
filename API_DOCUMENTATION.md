# API Authentication Documentation

This document describes the JWT-based authentication API for the Workspace Management Rails application.

## Base URL
```
http://localhost:3000/api
```

## Authentication Flow

### 1. User Registration
**POST** `/api/users`

**Request Body:**
```json
{
  "user": {
    "email": "user@example.com",
    "password": "password123",
    "password_confirmation": "password123"
  }
}
```

**Response (201 Created):**
```json
{
  "user": {
    "id": 1,
    "email": "user@example.com",
    "created_at": "2024-01-01T00:00:00.000Z"
  },
  "message": "User registered successfully"
}
```

### 2. User Login
**POST** `/api/login`

**Request Body:**
```json
{
  "user": {
    "email": "user@example.com",
    "password": "password123"
  }
}
```

**Response (200 OK):**
```json
{
  "token": "eyJhbGciOiJIUzI1NiJ9...",
  "user": {
    "id": 1,
    "email": "user@example.com",
    "created_at": "2024-01-01T00:00:00.000Z"
  },
  "message": "Logged in successfully"
}
```

### 3. User Logout
**DELETE** `/api/logout`

**Headers:**
```
Authorization: Bearer <JWT_TOKEN>
```

**Response (204 No Content):**
No response body

### 4. Get User Profile
**GET** `/api/users/:id`

**Headers:**
```
Authorization: Bearer <JWT_TOKEN>
```

**Response (200 OK):**
```json
{
  "user": {
    "id": 1,
    "email": "user@example.com",
    "created_at": "2024-01-01T00:00:00.000Z",
    "confirmed_at": "2024-01-01T00:00:00.000Z"
  }
}
```

### 5. Update User Profile
**PUT/PATCH** `/api/users/:id`

**Headers:**
```
Authorization: Bearer <JWT_TOKEN>
```

**Request Body:**
```json
{
  "user": {
    "email": "newemail@example.com",
    "password": "newpassword123",
    "password_confirmation": "newpassword123"
  }
}
```

**Response (200 OK):**
```json
{
  "user": {
    "id": 1,
    "email": "newemail@example.com",
    "created_at": "2024-01-01T00:00:00.000Z",
    "confirmed_at": "2024-01-01T00:00:00.000Z"
  },
  "message": "Profile updated successfully"
}
```

## JWT Token Usage

### Token Format
JWT tokens are returned upon successful login and should be included in the `Authorization` header for all protected API requests.

### Token Expiration
Tokens expire after 30 minutes. When a token expires, the user must log in again to obtain a new token.

### Security Considerations
- Always use HTTPS in production
- Store tokens securely on the client side
- Never expose tokens in client-side code or logs
- Implement token refresh logic for better user experience

## Error Responses

### Authentication Errors (401 Unauthorized)
```json
{
  "error": "You need to sign in or sign up before continuing."
}
```

### Validation Errors (422 Unprocessable Entity)
```json
{
  "error": "Email has already been taken"
}
```

### Not Found Errors (404 Not Found)
```json
{
  "error": "User not found"
}
```

## Testing the API

### Using cURL

1. **Register a new user:**
```bash
curl -X POST http://localhost:3000/api/users \
  -H "Content-Type: application/json" \
  -d '{"user": {"email": "test@example.com", "password": "password123", "password_confirmation": "password123"}}'
```

2. **Login:**
```bash
curl -X POST http://localhost:3000/api/login \
  -H "Content-Type: application/json" \
  -d '{"user": {"email": "test@example.com", "password": "password123"}}'
```

3. **Get user profile (replace TOKEN with the actual token):**
```bash
curl -X GET http://localhost:3000/api/users/1 \
  -H "Authorization: Bearer TOKEN"
```

### Using Postman or Similar Tools
- Set the `Content-Type` header to `application/json`
- Include the JWT token in the `Authorization` header as `Bearer <token>`
- Use the request bodies as shown in the examples above

## Development Notes

- The API uses Devise for authentication with JWT tokens
- User confirmation is enabled but can be configured
- Account locking is enabled after failed login attempts
- Password recovery is available through Devise
- All responses are in JSON format 