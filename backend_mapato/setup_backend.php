<?php

/**
 * Backend Setup Script for Boda Mapato OTP System
 * Run this script to set up the backend for OTP login flow
 */

require_once __DIR__ . '/vendor/autoload.php';

use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use App\Models\User;
use App\Models\OtpCode;

echo "🚀 Setting up Boda Mapato Backend for OTP Login Flow...\n\n";

try {
    // 1. Check database connection
    echo "1. Checking database connection...\n";
    DB::connection()->getPdo();
    echo "   ✅ Database connection successful\n\n";

    // 2. Run migrations
    echo "2. Running database migrations...\n";
    Artisan::call('migrate', ['--force' => true]);
    echo "   ✅ Migrations completed\n\n";

    // 3. Create test users
    echo "3. Creating test users...\n";
    
    // Admin user
    $admin = User::updateOrCreate(
        ['email' => 'admin@gmail.com'],
        [
            'name' => 'Admin User',
            'password' => Hash::make('12345678'),
            'phone_number' => '+255743519104',
            'role' => 'admin',
            'is_active' => true,
            'email_verified' => true,
            'phone_verified' => true,
        ]
    );
    echo "   ✅ Admin user created: {$admin->email}\n";

    // Driver user
    $driver = User::updateOrCreate(
        ['email' => 'john@example.com'],
        [
            'name' => 'John Driver',
            'password' => Hash::make('password123'),
            'phone_number' => '+255712345679',
            'role' => 'driver',
            'is_active' => true,
            'email_verified' => true,
            'phone_verified' => true,
        ]
    );
    echo "   ✅ Driver user created: {$driver->email}\n\n";

    // 4. Clean up old OTPs
    echo "4. Cleaning up expired OTPs...\n";
    $deletedCount = OtpCode::cleanupExpired();
    echo "   ✅ Cleaned up {$deletedCount} expired OTPs\n\n";

    // 5. Test OTP generation
    echo "5. Testing OTP generation...\n";
    $testOtp = OtpCode::generateOtp();
    echo "   ✅ Sample OTP generated: {$testOtp}\n\n";

    // 6. Display configuration
    echo "6. Backend Configuration:\n";
    echo "   📧 Admin Email: admin@gmail.com\n";
    echo "   🔑 Admin Password: 12345678\n";
    echo "   📱 Admin Phone: +255743519104\n";
    echo "   📧 Driver Email: john@example.com\n";
    echo "   🔑 Driver Password: password123\n";
    echo "   📱 Driver Phone: +255712345679\n";
    echo "   ⏰ OTP Expiry: " . OtpCode::EXPIRY_MINUTES . " minutes\n";
    echo "   🌍 Environment: " . config('app.env') . "\n";
    echo "   🐛 Debug Mode: " . (config('app.debug') ? 'enabled' : 'disabled') . "\n\n";

    // 7. API Endpoints
    echo "7. Available API Endpoints:\n";
    echo "   🔐 POST /api/auth/login - Login with credentials\n";
    echo "   ✅ POST /api/auth/verify-otp - Verify OTP code\n";
    echo "   🔄 POST /api/auth/resend-otp - Resend OTP\n";
    echo "   🚪 POST /api/auth/logout - Logout user\n";
    echo "   👤 GET /api/auth/user - Get user data\n";
    echo "   🧪 GET /api/test/otp-flow - Test OTP flow\n";
    echo "   📊 GET /api/test/system-status - System status\n";
    echo "   🏥 GET /api/health - Health check\n\n";

    // 8. Test URLs
    echo "8. Test URLs (replace with your server IP):\n";
    echo "   🌐 Health Check: http://192.168.1.124:8000/api/health\n";
    echo "   🧪 OTP Flow Test: http://192.168.1.124:8000/api/test/otp-flow\n";
    echo "   📊 System Status: http://192.168.1.124:8000/api/test/system-status\n\n";

    echo "✅ Backend setup completed successfully!\n";
    echo "🚀 You can now start the server with: php artisan serve --host=0.0.0.0 --port=8000\n";

} catch (Exception $e) {
    echo "❌ Setup failed: " . $e->getMessage() . "\n";
    echo "📝 Stack trace:\n" . $e->getTraceAsString() . "\n";
    exit(1);
}