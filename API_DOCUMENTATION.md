# WeTwo Backend API Documentation

## Base URL
```
https://wetwobackend-production.up.railway.app
```

## Authentication
All protected endpoints require a Bearer token in the Authorization header:
```
Authorization: Bearer <jwt_token>
```

## Response Format
All API responses follow this format:
```json
{
  "success": true,
  "data": { ... },
  "message": "Optional message",
  "error": null
}
```

## Endpoints

### 🔐 Authentication

#### POST /api/auth
**Sign In**
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "uuid",
      "email": "user@example.com",
      "name": "User Name",
      "birth_date": "1990-05-15",
      "created_at": "2024-01-01T00:00:00Z"
    },
    "token": "jwt_token",
    "refresh_token": "refresh_token"
  }
}
```

#### POST /api/auth/signup
**Sign Up**
```json
{
  "email": "user@example.com",
  "password": "password123",
  "name": "User Name",
  "birth_date": "1990-05-15"
}
```

#### POST /api/auth/refresh
**Refresh Token**
```json
{
  "refresh_token": "refresh_token"
}
```

#### POST /api/auth/logout
**Logout** (requires authentication)

#### GET /api/auth/verify
**Verify Email** (requires verification token)
```
/api/auth/verify?token=verification_token
```

#### POST /api/auth/forgot-password
**Forgot Password**
```json
{
  "email": "user@example.com"
}
```

#### POST /api/auth/reset-password
**Reset Password**
```json
{
  "token": "reset_token",
  "password": "new_password"
}
```

### 👤 Profiles

#### GET /api/profiles
**Get Current User Profile** (requires authentication)

#### PUT /api/profiles
**Update Profile** (requires authentication)
```json
{
  "name": "Updated Name",
  "birth_date": "1990-05-15",
  "zodiac_sign": "Taurus",
  "relationship_status": "married",
  "has_children": "true",
  "children_count": "2"
}
```

#### GET /api/profiles/{user_id}
**Get User Profile by ID** (requires authentication)

#### PUT /api/profiles/push-token
**Update Push Token** (requires authentication)
```json
{
  "push_token": "firebase_token"
}
```

### 💕 Partnerships

#### POST /api/partnerships
**Create Partnership** (requires authentication)
```json
{
  "partner_id": "partner_uuid",
  "connection_code": "ABC123"
}
```

#### GET /api/partnerships
**Get User Partnerships** (requires authentication)

#### GET /api/partnerships/code/{code}
**Find Partnership by Code** (requires authentication)

#### GET /api/partnerships/user/{user_id}
**Get Partnership for User** (requires authentication)

#### PUT /api/partnerships/{partnership_id}
**Update Partnership Status** (requires authentication)
```json
{
  "status": "active"
}
```

#### DELETE /api/partnerships/{partnership_id}
**Delete Partnership** (requires authentication)

### 📸 Memories

#### POST /api/memories
**Create Memory** (requires authentication)
```json
{
  "partner_id": "partner_uuid",
  "date": "2024-01-01",
  "title": "Memory Title",
  "description": "Memory description",
  "photo_data": "base64_encoded_image",
  "location": "Location",
  "mood_level": "5",
  "tags": "tag1,tag2,tag3",
  "is_shared": "true"
}
```

#### GET /api/memories
**Get User Memories** (requires authentication)
```
/api/memories?start_date=2024-01-01&end_date=2024-01-31&is_shared=true
```

#### GET /api/memories/{memory_id}
**Get Memory by ID** (requires authentication)

#### PUT /api/memories/{memory_id}
**Update Memory** (requires authentication)

#### DELETE /api/memories/{memory_id}
**Delete Memory** (requires authentication)

#### GET /api/memories/shared
**Get Shared Memories** (requires authentication)

### 😊 Mood Entries

#### POST /api/mood-entries
**Create Mood Entry** (requires authentication)
```json
{
  "date": "2024-01-01",
  "mood_level": 5,
  "event_label": "Great day",
  "location": "Home",
  "photo_data": "base64_encoded_image",
  "insight": "Feeling happy today",
  "love_message": "Sending love!"
}
```

#### GET /api/mood-entries
**Get Mood Entries** (requires authentication)
```
/api/mood-entries?start_date=2024-01-01&end_date=2024-01-31
```

#### GET /api/mood-entries/today
**Get Today's Mood Entry** (requires authentication)

#### PUT /api/mood-entries/{entry_id}
**Update Mood Entry** (requires authentication)

#### DELETE /api/mood-entries/{entry_id}
**Delete Mood Entry** (requires authentication)

### 💌 Love Messages

#### POST /api/love-messages
**Send Love Message** (requires authentication)
```json
{
  "receiver_id": "partner_uuid",
  "message": "I love you!"
}
```

#### GET /api/love-messages
**Get Love Messages** (requires authentication)

#### GET /api/love-messages/conversation/{partner_id}
**Get Conversation with Partner** (requires authentication)

#### PUT /api/love-messages/{message_id}/read
**Mark Message as Read** (requires authentication)

#### DELETE /api/love-messages/{message_id}
**Delete Love Message** (requires authentication)

### 📱 Notifications

#### POST /api/notifications/push
**Send Push Notification** (requires authentication)
```json
{
  "partner_id": "partner_uuid",
  "title": "Notification Title",
  "body": "Notification body",
  "data": {
    "type": "memory",
    "memory_id": "memory_uuid"
  }
}
```

#### GET /api/notifications
**Get User Notifications** (requires authentication)

#### PUT /api/notifications/{notification_id}/read
**Mark Notification as Read** (requires authentication)

### 📁 Storage

#### POST /api/storage/profile-photo
**Upload Profile Photo** (requires authentication)
```
Content-Type: multipart/form-data
Body: 
  - file: binary image data
  - user_id: uuid
```

**Response:**
```json
{
  "success": true,
  "data": {
    "file_id": "uuid",
    "file_url": "https://fa151e87de0b5708a9317ae0e5be1cd6.r2.cloudflarestorage.com/profile-photos/user_id/filename.jpg",
    "file_size": 1024000,
    "mime_type": "image/jpeg"
  }
}
```

#### GET /api/storage/profile-photo/{user_id}
**Get Profile Photo URL** (requires authentication)

#### DELETE /api/storage/profile-photo
**Delete Profile Photo** (requires authentication)

#### POST /api/storage/memory-photo
**Upload Memory Photo** (requires authentication)
```
Content-Type: multipart/form-data
Body:
  - file: binary image data
  - memory_id: uuid
```

#### GET /api/storage/buckets
**Get Storage Buckets Configuration** (requires authentication)

#### POST /api/storage/buckets
**Create Storage Bucket** (admin only)
```json
{
  "bucket_name": "memory-photos",
  "bucket_url": "https://your-bucket.r2.cloudflarestorage.com/memory-photos",
  "region": "auto"
}
```

### 🔍 Search

#### GET /api/search/memories
**Search Memories** (requires authentication)
```
/api/search/memories?query=beach&tags=summer,vacation&location=hawaii
```

#### GET /api/search/memories/advanced
**Advanced Memory Search** (requires authentication)
```
/api/search/memories/advanced?query=beach&start_date=2024-01-01&end_date=2024-12-31&mood_level=5&is_shared=true
```

### 📊 Analytics

#### GET /api/analytics/memory-stats
**Get Memory Statistics** (requires authentication)

#### GET /api/analytics/mood-history
**Get Mood History** (requires authentication)
```
/api/analytics/mood-history?days=30
```

#### GET /api/analytics/partner-activity
**Get Partner Activity** (requires authentication)
```
/api/analytics/partner-activity?days=7
```

### 🏥 Health Check

#### GET /health
**Health Check**
```json
{
  "status": "healthy",
  "timestamp": "2024-01-01T00:00:00Z",
  "version": "1.0.0"
}
```

#### GET /
**Root Endpoint**
```json
{
  "message": "WeTwo Backend API",
  "version": "1.0.0",
  "status": "running"
}
```

## Error Responses

### 400 Bad Request
```json
{
  "success": false,
  "data": null,
  "message": "Validation error",
  "error": "Invalid email format"
}
```

### 401 Unauthorized
```json
{
  "success": false,
  "data": null,
  "message": "Authentication required",
  "error": "Invalid or missing token"
}
```

### 403 Forbidden
```json
{
  "success": false,
  "data": null,
  "message": "Access denied",
  "error": "Insufficient permissions"
}
```

### 404 Not Found
```json
{
  "success": false,
  "data": null,
  "message": "Resource not found",
  "error": "User not found"
}
```

### 500 Internal Server Error
```json
{
  "success": false,
  "data": null,
  "message": "Internal server error",
  "error": "Database connection failed"
}
```

## Data Types

### User
```json
{
  "id": "uuid",
  "email": "string",
  "name": "string",
  "birth_date": "date (YYYY-MM-DD)",
  "created_at": "datetime",
  "updated_at": "datetime"
}
```

### Profile
```json
{
  "id": "uuid",
  "name": "string",
  "zodiac_sign": "string",
  "birth_date": "date (YYYY-MM-DD)",
  "profile_photo_url": "string (optional)",
  "relationship_status": "string (optional)",
  "has_children": "string (true/false)",
  "children_count": "string (optional)",
  "push_token": "string (optional)",
  "apple_user_id": "string (optional)",
  "created_at": "datetime",
  "updated_at": "datetime"
}
```

### Memory
```json
{
  "id": "uuid",
  "user_id": "uuid",
  "partner_id": "uuid (optional)",
  "date": "date (YYYY-MM-DD)",
  "title": "string",
  "description": "string (optional)",
  "photo_data": "string (base64 or URL)",
  "location": "string (optional)",
  "mood_level": "string (1-5)",
  "tags": "string (comma-separated)",
  "is_shared": "string (true/false)",
  "created_at": "datetime",
  "updated_at": "datetime"
}
```

### MoodEntry
```json
{
  "id": "uuid",
  "user_id": "uuid",
  "date": "date (YYYY-MM-DD)",
  "mood_level": "integer (1-5)",
  "event_label": "string (optional)",
  "location": "string (optional)",
  "photo_data": "string (base64)",
  "insight": "string (optional)",
  "love_message": "string (optional)",
  "created_at": "datetime",
  "updated_at": "datetime"
}
```

### Partnership
```json
{
  "id": "uuid",
  "user_id": "uuid",
  "partner_id": "uuid",
  "connection_code": "string (6 chars)",
  "status": "string (active/pending/disconnected)",
  "created_at": "datetime",
  "updated_at": "datetime"
}
```

### LoveMessage
```json
{
  "id": "uuid",
  "sender_id": "uuid",
  "receiver_id": "uuid",
  "message": "string",
  "is_read": "boolean",
  "timestamp": "datetime",
  "created_at": "datetime"
}
```

## Rate Limiting
- 100 requests per minute per IP
- 1000 requests per hour per user

## CORS
The API supports CORS for web applications:
```
Access-Control-Allow-Origin: *
Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS
Access-Control-Allow-Headers: Content-Type, Authorization
```

## WebSocket Support (Future)
For real-time features like live messaging and notifications:
```
ws://wetwobackend-production.up.railway.app/ws
```

## Testing
Use the provided test endpoints to verify your implementation:
- `GET /health` - Basic health check
- `GET /api/test/connection` - Test database connection
- `GET /api/test/auth` - Test authentication endpoints
