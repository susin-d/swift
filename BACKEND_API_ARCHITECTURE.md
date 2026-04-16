# Authentication Architecture - Backend-Driven API

## 🏗️ System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         USER APP (Flutter)                      │
│                    lib/services/api_service.dart                │
│                    lib/features/auth/...                        │
└────────────────────────┬────────────────────────────────────────┘
                         │ 
                         │ HTTP/Dio
                         ├─ POST /auth/session (login)
                         ├─ POST /auth/register (signup)
                         ├─ POST /auth/password/forgot (reset)
                         ├─ POST /auth/password/reset
                         ├─ GET /auth/me (session restore)
                         └─ PATCH /auth/me (profile update)
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│               BACKEND API (Node.js/Fastify)                     │
│         backend/src/modules/auth/auth.controller.ts             │
│         backend/src/middleware/auth.ts (JWT validation)         │
│              :3000/api/v1                                       │
└────────────────────────┬────────────────────────────────────────┘
                         │
        ┌────────────────┼─────────────────┐
        │                │                 │
        ▼                ▼                 ▼
┌──────────────┐  ┌─────────────┐  ┌────────────────┐
│ Supabase     │  │ Supabase    │  │ Brevo Email    │
│ Auth         │  │ PostgreSQL  │  │ Service        │
│ (JWT)        │  │ (RLS)       │  │ (SMTP)         │
└──────────────┘  └─────────────┘  └────────────────┘
```

## 🔄 Authentication Flows

### 1. **LOGIN FLOW**

```sequence
User App -> Backend: POST /auth/session
            email: "user@example.com"
            password: "secure_password"

Backend -> Supabase Auth: signInWithPassword()
Supabase Auth -> Backend: JWT access_token + user data

Backend -> Supabase DB: Query users table
Supabase DB -> Backend: User role & profile

Backend -> User App: {
              user: { id, email, role, profile },
              session: { access_token, expires_at }
            }

User App -> FlutterSecureStorage: Store JWT
            key: 'jwt'
            value: access_token

User App -> GoRouter: Navigate to Home Screen
```

**Time: ~500ms**

---

### 2. **REGISTRATION & AUTO-LOGIN FLOW**

```sequence
User App -> Backend: POST /auth/register
            email: "newuser@example.com"
            password: "secure_password"
            name: "John Doe"

Backend -> Validation: {
  - Email format ✓
  - Password length >= 8 ✓
  - Name not empty ✓
}

Backend -> Supabase Auth: signUp()
Supabase Auth -> Backend: New User ID (UUID)

Backend -> Supabase DB: INSERT public.users
            id, email, name, role='user'

Backend -> Supabase DB: INSERT customer_profiles
            id (auto-populated)

Backend -> User App: { user: {id, email}, status: 201 }

User App -> Backend: POST /auth/session (auto-login)
            email: "newuser@example.com"
            password: "secure_password"

Backend -> Supabase Auth: signInWithPassword()
Supabase Auth -> Backend: JWT access_token

Backend -> User App: { user, session }

User App -> FlutterSecureStorage: Store JWT

User App -> GoRouter: Navigate to Home Screen
```

**Time: ~800ms**

---

### 3. **PASSWORD RESET FLOW (with Brevo Email)**

```sequence
User App -> Backend: POST /auth/password/forgot
            email: "user@example.com"

Backend -> Supabase DB: Query users by email
Supabase DB -> Backend: User ID

Backend -> Generate: 6-digit OTP (e.g., "428510")
Backend -> Hash: SHA256(OTP)

Backend -> Supabase DB: INSERT password_reset_codes
            user_id, code_hash, expires_at (10 min)

Backend -> Brevo SMTP: POST /v3/smtp/email
            to: user@example.com
            subject: "Your Swift password reset code"
            body: "Use this code: 428510"

Brevo -> SMTP Server: Send email
SMTP Server -> Gmail/Outlook/etc: Deliver email

User -> Email Provider: Receive email with OTP
User -> User App: Enter OTP (428510) + new password

User App -> Backend: POST /auth/password/reset
            email: "user@example.com"
            pin: "428510"
            new_password: "new_secure_password"

Backend -> Verify: {
  - OTP not expired ✓
  - SHA256(pin) == stored_hash ✓
  - Attempts < 5 ✓
}

Backend -> Supabase Auth: updateUserByID(password)
Supabase Auth -> Backend: Success

Backend -> Supabase DB: Mark code as consumed

Backend -> User App: { status: "success" }

User App -> GoRouter: Navigate to Login Screen
```

**Time: Varies (depends on email delivery)**

---

## 🔐 Security Model

### JWT Token Management
- **Storage**: Encrypted via `FlutterSecureStorage` (Android KeyStore / iOS Keychain)
- **Attachment**: Automatically added as `Authorization: Bearer {token}` header
- **Refresh**: If 401 received, clear token and force re-login
- **Expiry**: Handled by Supabase (default: 60 minutes)

### API Request Interceptor
```dart
// lib/services/api_service.dart
onRequest: (options, handler) async {
  final token = await _resolveAccessToken();
  if (token != null && token.isNotEmpty) {
    options.headers['Authorization'] = 'Bearer $token';
  }
  return handler.next(options);
}
```

### Backend JWT Validation
```typescript
// backend/src/middleware/auth.ts
app.register(authMiddlewarePlugin);

// Validates JWT on protected routes
app.get('/auth/me', { preValidation: [app.authenticate] }, getMeHandler);
```

### Row Level Security (RLS)
- All database queries enforce RLS policies
- Users can only access their own data
- Admin operations protected by role checks

---

## 📋 API Endpoints

### Authentication Endpoints

| Method | Endpoint | Auth Required | Purpose |
|--------|----------|---------------|---------|
| POST | `/auth/session` | ❌ | Login with email/password |
| POST | `/auth/register` | ❌ | Create new user account |
| GET | `/auth/me` | ✅ | Get current session/user profile |
| PATCH | `/auth/me` | ✅ | Update user profile (name/phone/address) |
| POST | `/auth/password/forgot` | ❌ | Send password reset email |
| POST | `/auth/password/reset` | ❌ | Reset password with OTP |
| POST | `/auth/staff/onboarding/accept` | ✅ | Accept staff invitation |

### Response Formats

**Login Success (200)**
```json
{
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "role": "user",
    "name": "John Doe",
    "profile": {
      "phone": "...",
      "address": "...",
      "created_at": "2024-04-07T..."
    }
  },
  "session": {
    "access_token": "eyJhbGc...",
    "expires_at": "2024-04-08T..."
  }
}
```

**Error Response (401/400/500)**
```json
{
  "error": "Unauthorized",
  "message": "Invalid credentials"
}
```

---

## 🌍 Environment Configuration

### Development (Default)
```bash
flutter run
# Uses: http://localhost:3000/api/v1
```

### Staging
```bash
# Edit user_app/.env or user_app/.env.production as needed
flutter run
```

### Production
```bash
flutter build apk --release
```

### Configuration File
Files: `user_app/.env`, `user_app/.env.production`, `user_app/lib/core/config/runtime_config.dart`
```dart
static String get backendApiUrl =>
    dotenv.env['BACKEND_API_URL'] ?? 'http://localhost:3000/api/v1';
```

---

## 🚀 Deployment Checklist

- [ ] Backend running on secure HTTPS endpoint
- [ ] `.env` and `.env.production` files present for Flutter apps
- [ ] JWT expiration policies set appropriately
- [ ] RLS policies enforced in Supabase
- [ ] Brevo SMTP credentials configured
- [ ] SSL certificate valid for backend domain
- [ ] CORS properly configured on backend
- [ ] Rate limiting enabled on auth endpoints
- [ ] Error logs monitored for failed auth attempts
- [ ] Database backups scheduled

---

## 📞 Support

For issues:
1. Check backend logs: `npm run dev` in `backend/` directory
2. Verify network connectivity: test with Postman
3. Confirm JWT token validity in storage
4. Review [API_REFERENCE.md](../API_REFERENCE.md) for endpoint details
