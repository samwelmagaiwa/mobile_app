<?php
require_once 'vendor/autoload.php';

use Illuminate\Database\Capsule\Manager as DB;
use Carbon\Carbon;

// Initialize database connection
$capsule = new DB;
$capsule->addConnection([
    'driver'    => 'mysql',
    'host'      => 'localhost',
    'database'  => 'marejesho',
    'username'  => 'root',
    'password'  => '',
    'charset'   => 'utf8',
    'collation' => 'utf8_unicode_ci',
]);
$capsule->setAsGlobal();
$capsule->bootEloquent();

echo "Checking for admin users...\n";

try {
    // Check existing admin users
    $adminUsers = DB::table('users')->where('role', 'admin')->get();
    
    echo "Found " . count($adminUsers) . " admin users:\n";
    foreach ($adminUsers as $user) {
        echo "- {$user->name} ({$user->email}) - Active: " . ($user->is_active ? 'Yes' : 'No') . "\n";
    }
    
    // Check if we have the test admin user
    $testAdmin = DB::table('users')->where('email', 'admin@test.com')->first();
    
    if (!$testAdmin) {
        echo "\nCreating test admin user...\n";
        
        // Generate UUID
        $userId = sprintf('%04x%04x-%04x-%04x-%04x-%04x%04x%04x',
            mt_rand(0, 0xffff), mt_rand(0, 0xffff),
            mt_rand(0, 0xffff),
            mt_rand(0, 0x0fff) | 0x4000,
            mt_rand(0, 0x3fff) | 0x8000,
            mt_rand(0, 0xffff), mt_rand(0, 0xffff), mt_rand(0, 0xffff)
        );
        
        DB::table('users')->insert([
            'id' => $userId,
            'name' => 'Test Admin',
            'email' => 'admin@test.com',
            'phone_number' => '+256700000000',
            'role' => 'admin',
            'email_verified_at' => Carbon::now(),
            'password' => password_hash('password', PASSWORD_DEFAULT),
            'is_active' => 1,
            'email_verified' => 1,
            'phone_verified' => 1,
            'created_at' => Carbon::now(),
            'updated_at' => Carbon::now()
        ]);
        
        echo "✓ Created test admin user:\n";
        echo "  Email: admin@test.com\n";
        echo "  Password: password\n";
        echo "  Phone: +256700000000\n";
        
    } else {
        echo "\n✓ Test admin user already exists:\n";
        echo "  Email: {$testAdmin->email}\n";
        echo "  Password: password\n";
        echo "  Phone: {$testAdmin->phone_number}\n";
        echo "  Active: " . ($testAdmin->is_active ? 'Yes' : 'No') . "\n";
        
        // Make sure it's active
        if (!$testAdmin->is_active) {
            DB::table('users')->where('id', $testAdmin->id)->update([
                'is_active' => 1,
                'updated_at' => Carbon::now()
            ]);
            echo "  ✓ Activated user\n";
        }
    }
    
    echo "\n--- Instructions ---\n";
    echo "1. Open the Flutter app\n";
    echo "2. Login with:\n";
    echo "   Email: admin@test.com\n";
    echo "   Password: password\n";
    echo "   Phone: +256700000000\n";
    echo "3. You should see the ModernDashboardScreen with real data\n";
    
} catch (Exception $e) {
    echo "Error: " . $e->getMessage() . "\n";
    exit(1);
}

echo "\nAdmin user setup complete!\n";
?>