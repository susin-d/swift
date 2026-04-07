# User App - Setup & Configuration

## 🎯 Overview
The User App is a Flutter application that connects to a **backend API for all authentication and business logic**. There is **NO direct Supabase connection** from the frontend.

All communication flows through:
- **User App (Flutter)** → **Backend API (Node.js/Fastify)** → **Supabase** → **Brevo Email Service**

## 🚀 Quick Start

### Prerequisites
- Flutter SDK 3.10.8+
- Backend server running on `http://localhost:3000`

### Run for Development

```bash
cd user_app

# Option 1: Use default backend URL (localhost:3000)
flutter run

# Option 2: Point to a different backend URL
flutter run --dart-define=BACKEND_API_URL=http://192.168.1.100:3000/api/v1

# Option 3: For production
flutter run --dart-define=BACKEND_API_URL=https://api.example.com/api/v1
```

### Build for Release

```bash
# Android
flutter build apk --dart-define=BACKEND_API_URL=https://api.example.com/api/v1

# iOS
flutter build ipa --dart-define=BACKEND_API_URL=https://api.example.com/api/v1
```

## 📁 Configuration

### `.env` File (Reference Only)
The `.env` file documents your local configuration:
```
BACKEND_API_URL=http://localhost:3000/api/v1
```

**Note:** Flutter doesn't read `.env` files at runtime. Use `--dart-define` during build/run for actual configuration.

### RuntimeConfig (`lib/core/config/runtime_config.dart`)
Handles backend API URL configuration:
```dart
factory RuntimeConfig.fromEnvironment() {
  const backendApiUrl = String.fromEnvironment(
    'BACKEND_API_URL',
    defaultValue: 'http://localhost:3000/api/v1',
  );
  
  return RuntimeConfig(backendApiUrl: backendApiUrl);
}
```

## 🔐 Authentication Flow

### Login
1. User enters email + password on login screen
2. App sends: `POST /auth/session` to backend
3. Backend authenticates with Supabase Auth
4. Backend returns: JWT token
5. App stores JWT in **secure storage** (encrypted)
6. All future requests include JWT as Bearer token

### Registration
1. User enters email + password + name
2. App sends: `POST /auth/register` to backend
3. Backend creates auth user in Supabase
4. Backend syncs to public database tables
5. App auto-logs in user
6. User navigated to home screen

### Password Reset
1. User enters email on forgot password screen
2. App sends: `POST /auth/password/forgot` to backend
3. Backend generates 6-digit OTP
4. Backend sends email via **Brevo Email Service**
5. User receives OTP in email inbox
6. User enters OTP + new password
7. App sends: `POST /auth/password/reset` to backend
8. Backend updates password in Supabase Auth

## 📋 Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `BACKEND_API_URL` | `http://localhost:3000/api/v1` | Backend API base URL |

## 🛠️ Development

### Analyze Code
```bash
flutter analyze
```

### Run Tests
```bash
flutter test
```

### Format Code
```bash
flutter format lib/
```

## 📦 Dependencies

Key packages:
- **dio**: HTTP client for API calls
- **flutter_riverpod**: State management
- **flutter_secure_storage**: Encrypted token storage
- **go_router**: Navigation/routing
- **flutter_svg**: SVG asset rendering
- **razorpay_flutter**: Payment processing

## 🚨 Troubleshooting

### "Connection Refused" Error
- Ensure backend is running: `cd backend && npm run dev`
- Verify backend URL: check `--dart-define=BACKEND_API_URL=...`

### "Unauthorized (401)" Error
- JWT token may be expired
- User needs to log in again
- Check token storage in FlutterSecureStorage

### "AssetManifest.json" Error
- Run `flutter clean`
- Run `flutter pub get`
- Run `flutter run`

## 📚 Related Documentation

- [Backend API Reference](../API_REFERENCE.md)
- [Developer Guide](../DEVELOPER_GUIDE.md)
- [Password Reset Flow](../PASSWORD_RESET_FLOW.md)
