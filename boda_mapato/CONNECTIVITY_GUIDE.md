# Boda Mapato API Connectivity Guide

## 🚀 Current Status

### ✅ Working Configuration
- **Laravel Backend**: Running on `http://127.0.0.1:8000`
- **Flutter App**: Configured to use `http://127.0.0.1:8000/api`
- **Connectivity**: ✅ VERIFIED AND WORKING

### 📊 Connection Test Results
```
🔍 Testing Boda Mapato API Connectivity...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Testing: http://127.0.0.1:8000/api/health
✅ SUCCESS: Boda Mapato API is running
   Status: success
   Server Time: 2025-10-08 04:42:33
   PHP Version: 8.2.12

Testing: http://192.168.1.124:8000/api/health
❌ ERROR: Connection timed out

Testing: http://10.0.2.2:8000/api/health
❌ ERROR: Connection timed out

🎯 RECOMMENDED API URL: http://127.0.0.1:8000/api
✅ ApiService.baseUrl = "http://127.0.0.1:8000/api"
✅ AuthService.baseUrl = "http://127.0.0.1:8000/api"
```

## 🛠️ Setup Instructions

### 1. Laravel Backend Setup
```bash
# Navigate to backend directory
cd C:\xampp\htdocs\mobile_app\backend_mapato

# Install dependencies (if not already done)
composer install

# Start the Laravel development server
php artisan serve

# Server will start on http://127.0.0.1:8000
```

### 2. Flutter App Configuration

The Flutter app is already configured correctly:

**File: `lib/services/api_service.dart`**
```dart
static const String baseUrl = "http://127.0.0.1:8000/api";
static const String webBaseUrl = "http://127.0.0.1:8000";
```

**File: `lib/services/auth_service.dart`**
```dart
static const String baseUrl = "http://127.0.0.1:8000/api";
```

### 3. Environment Configuration

**Backend `.env` file:**
```env
APP_URL=http://192.168.1.124:8000  # Currently set but not accessible
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_DATABASE=marejesho
```

## 📱 Different Environment Configurations

### For Desktop/Web Development (Current)
```dart
// Use this for development on the same machine
static const String baseUrl = "http://127.0.0.1:8000/api";
```

### For Android Emulator
```dart
// Use this when testing on Android emulator
static const String baseUrl = "http://10.0.2.2:8000/api";
```

### For Real Device Testing
```dart
// Use this for testing on real devices (if network allows)
static const String baseUrl = "http://192.168.1.124:8000/api";
```

### For Production
```dart
// Use this for production deployment
static const String baseUrl = "https://yourdomain.com/api";
```

## 🔧 Configuration Management

We've created a flexible configuration system in `lib/config/api_config.dart`:

```dart
class ApiConfig {
  // Change this to switch environments
  static const String _environment = Environment.local;
  
  static String get baseUrl {
    switch (_environment) {
      case Environment.local:
        return "http://127.0.0.1:8000/api";
      case Environment.network:
        return "http://192.168.1.124:8000/api";
      case Environment.emulator:
        return "http://10.0.2.2:8000/api";
      case Environment.production:
        return "https://yourdomain.com/api";
    }
  }
}
```

## 🧪 Testing Connectivity

### Quick Test Script
Run the connectivity test:
```bash
dart run test_connectivity.dart
```

### Manual Test
```powershell
# Test Laravel backend health
Invoke-WebRequest -Uri "http://127.0.0.1:8000/api/health" -Method GET

# Test network connectivity
Test-NetConnection -ComputerName 127.0.0.1 -Port 8000
```

## 🚨 Troubleshooting

### If Backend is Not Accessible

1. **Check if Laravel server is running:**
   ```bash
   # Navigate to backend directory
   cd C:\xampp\htdocs\mobile_app\backend_mapato
   
   # Start server
   php artisan serve
   ```

2. **Check if port 8000 is available:**
   ```powershell
   Test-NetConnection -ComputerName 127.0.0.1 -Port 8000
   ```

3. **Check XAMPP MySQL service:**
   - Ensure XAMPP MySQL is running
   - Database `marejesho` exists

### If Flutter App Can't Connect

1. **Update API URLs in code:**
   - `lib/services/api_service.dart`
   - `lib/services/auth_service.dart`

2. **Check network permissions:**
   - Add internet permission to `android/app/src/main/AndroidManifest.xml`
   ```xml
   <uses-permission android:name="android.permission.INTERNET" />
   ```

3. **For real device testing:**
   - Ensure both device and computer are on same network
   - Update backend URL to use network IP: `http://192.168.1.124:8000`

## 📋 Deployment Checklist

### Development Environment ✅
- [x] Laravel backend running on `127.0.0.1:8000`
- [x] Flutter app configured for local development
- [x] Database connection working
- [x] API endpoints accessible
- [x] Connectivity test passing

### For Real Device Testing
- [ ] Update Flutter app URLs to use network IP
- [ ] Ensure Laravel server is accessible on network
- [ ] Test API endpoints from device
- [ ] Update Laravel `.env` APP_URL if needed

### For Production
- [ ] Deploy Laravel backend to production server
- [ ] Update Flutter app URLs to production endpoints
- [ ] Configure SSL/HTTPS
- [ ] Update database connection for production
- [ ] Test all API endpoints in production

## 🔗 Useful Commands

```bash
# Backend
cd C:\xampp\htdocs\mobile_app\backend_mapato
php artisan serve
php artisan migrate
php artisan db:seed

# Flutter
flutter run
flutter build apk
flutter analyze

# Testing
dart run test_connectivity.dart
```

## 📝 Notes

- Current setup is optimized for **desktop development**
- **127.0.0.1:8000** is the only working endpoint currently
- **192.168.1.124:8000** is not accessible (network/firewall issues)
- All Flutter services are configured correctly for the working endpoint
- Connectivity test is integrated into the app for easy debugging