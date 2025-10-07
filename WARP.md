# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Project Overview

Boda Mapato is a mobile application system for managing motorcycle taxi (boda boda) payments and operations in Tanzania. The project consists of two main components:

1. **Backend API** (`backend_mapato/`) - Laravel 11 PHP backend with API endpoints
2. **Mobile App** (`boda_mapato/`) - Flutter mobile application with responsive design

The system supports two user roles: **Admins** (vehicle owners) who manage drivers and payments, and **Drivers** who have read-only access to their payment history and dashboard.

## Development Commands

### Backend (Laravel)

```bash
# Navigate to backend directory
cd backend_mapato

# Install dependencies
composer install
npm install

# Environment setup
cp .env.example .env
php artisan key:generate

# Database operations
php artisan migrate
php artisan migrate:fresh --seed

# Start development server (with concurrent services)
composer run dev

# Alternative: Start individual services
php artisan serve                    # API server on :8000
php artisan queue:listen --tries=1   # Queue worker
php artisan pail --timeout=0         # Real-time logs
npm run dev                          # Vite frontend assets

# Testing
composer run test                    # Run all tests
php artisan test                     # Alternative test command

# Code quality
vendor/bin/pint                      # Laravel Pint (code formatting)
php artisan analyze                  # Code analysis

# API testing
curl http://localhost:8000/api/health
curl http://localhost:8000/api/test/reports
```

### Mobile App (Flutter)

```bash
# Navigate to Flutter directory
cd boda_mapato

# Install dependencies
flutter pub get

# Code generation (if needed)
flutter pub run build_runner build

# Development
flutter run                          # Run on connected device/emulator
flutter run --debug                  # Debug mode
flutter run --release                # Release mode

# Testing
flutter test                         # Run all tests
flutter test --coverage             # With coverage

# Code analysis and formatting
flutter analyze                      # Static analysis
flutter analyze --verbose           # Detailed analysis
dart fix --apply                     # Auto-fix issues
dart format .                        # Format code

# Build for production
flutter build apk                    # Android APK
flutter build appbundle             # Android App Bundle
flutter build ios                    # iOS (macOS only)

# Performance profiling
flutter run --profile               # Profile mode for performance analysis
```

## High-Level Architecture

### Backend Architecture (Laravel)

**Core Structure:**
- **Controllers:** API endpoints organized by feature (`API/AdminController`, `API/AuthController`, etc.)
- **Services:** Business logic layer (`ReportService` for complex report generation)
- **Models:** Eloquent models for `Driver`, `Transaction`, `Device`, `Receipt`
- **Middleware:** Authentication (`sanctum`) and role-based access control
- **Routes:** RESTful API structure with role-based route groups

**Key Features:**
- **Authentication:** Laravel Sanctum with OTP verification
- **Role-based Access:** Admin vs Driver permissions
- **Report System:** Comprehensive reporting with revenue, expenses, profit/loss analysis
- **Multi-language Support:** Swahili language interface
- **Test Environment:** Dedicated test endpoints for development

**API Structure:**
```
/api/auth/*           - Authentication (login, OTP, password reset)
/api/admin/*          - Admin-only operations (protected)
/api/driver/*         - Driver read-only operations (protected) 
/api/test/*           - Development/testing endpoints (unprotected)
/api/health           - System health check
```

### Mobile App Architecture (Flutter)

**Core Structure:**
- **Provider Pattern:** State management using `provider` package
- **Responsive Design:** `flutter_screenutil` for cross-device compatibility
- **Service Layer:** `ApiService` for backend communication
- **Screen Organization:** Separate screen hierarchies for admin and driver roles

**Key Providers:**
- `AuthProvider` - Authentication state and user management
- `TransactionProvider` - Payment and transaction data
- `DeviceProvider` - Vehicle/device management

**Responsive System:**
- **Base Design Size:** 375x812 (iPhone X)
- **Breakpoints:** Mobile (<600px), Tablet (600-900px), Desktop (>900px)
- **Utilities:** `ResponsiveUtils` class for adaptive sizing
- **Components:** Responsive widgets with automatic scaling

**Navigation Structure:**
```
AuthWrapper
├── LoginScreen (unauthenticated)
├── AdminDashboardScreen (admin users)
│   ├── DriversManagementScreen
│   ├── VehiclesManagementScreen  
│   ├── PaymentsManagementScreen
│   └── RecordPaymentScreen
└── DriverDashboardScreen (driver users)
```

## Project-Specific Guidelines

### Backend Development

**Database Conventions:**
- Use descriptive Eloquent relationships (e.g., `incomeTransactions()`, `expenseTransactions()`)
- Transaction categories are defined as constants in the `Transaction` model
- All monetary amounts stored as decimal with 2 decimal places

**API Response Format:**
```json
{
  "status": "success|error",
  "message": "Human-readable message (in Swahili)",
  "data": { /* Response data */ }
}
```

**Error Handling:**
- Use `ResponseHelper` class for consistent API responses  
- Log errors with context using Laravel's logging system
- Return Swahili error messages for user-facing endpoints

**Testing:**
- Use test endpoints (`/api/test/*`) for development
- `TestReportController` provides sample data generation
- Clean up test data using cleanup endpoints

### Mobile App Development

**State Management:**
- Use Provider pattern consistently across the app
- Implement proper loading and error states in providers
- Use Consumer widgets to listen to provider changes

**Responsive Design:**
- Always use `ResponsiveUtils` methods instead of hardcoded values
- Test layouts on multiple screen sizes and orientations
- Use `ScreenUtil` extensions (.w, .h, .sp) for sizing

**UI Consistency:**
- Use `AppStyles` for consistent theming
- Follow the established color palette in `AppColors`
- Implement proper Material 3 design patterns

**API Integration:**
- Use `ApiService` class for all backend communication
- Handle authentication tokens properly
- Implement proper error handling for network requests

## Environment Setup

### Prerequisites
- **Backend:** PHP 8.2+, Composer, Node.js/npm, MySQL/PostgreSQL
- **Mobile:** Flutter SDK 3.4.4+, Android Studio/Xcode
- **Development Tools:** Git, VS Code with Flutter/Dart extensions

### Quick Setup
```bash
# Clone and setup backend
cd backend_mapato
composer install && npm install
cp .env.example .env
php artisan key:generate
php artisan migrate
php artisan serve

# Setup mobile app (new terminal)
cd ../boda_mapato  
flutter pub get
flutter run
```

### Development Database
The backend includes setup scripts:
- `setup_database.php` - Database initialization
- `setup_backend.php` - Backend configuration
- Use test endpoints to populate sample data

## Important Files & Configurations

**Backend Key Files:**
- `routes/api.php` - Complete API routing structure
- `app/Services/ReportService.php` - Business logic for reports
- `REPORT_SYSTEM_DOCUMENTATION.md` - Detailed API documentation

**Mobile App Key Files:**
- `lib/main.dart` - App initialization with responsive setup
- `lib/utils/responsive_utils.dart` - Responsive design utilities
- `RESPONSIVE_DESIGN_IMPLEMENTATION.md` - Complete responsive guide
- `ANALYSIS_GUIDE.md` - Flutter code quality standards

**Configuration Files:**
- Backend: `composer.json`, `package.json`, `.env`
- Mobile: `pubspec.yaml`, `analysis_options.yaml`

## Development Workflow

1. **Backend Changes:** Test with `/api/test/*` endpoints before implementing auth
2. **Mobile UI:** Use responsive utilities and test across screen sizes
3. **Integration:** Use the health check endpoint to verify backend connectivity
4. **Code Quality:** Run analysis tools before commits (`flutter analyze`, `vendor/bin/pint`)
5. **Testing:** Use the comprehensive test data system for development

This project emphasizes responsive design, bilingual support (English/Swahili), and comprehensive business reporting for the boda boda industry in Tanzania.