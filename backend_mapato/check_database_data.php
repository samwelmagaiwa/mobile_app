<?php
require_once 'vendor/autoload.php';

use Illuminate\Database\Capsule\Manager as DB;
use Carbon\Carbon;

// Initialize Eloquent
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

echo "Checking database tables and data...\n\n";

try {
    // Check if tables exist and count records
    $tables = ['users', 'drivers', 'devices', 'payments', 'payment_receipts', 'debt_records'];
    
    foreach ($tables as $table) {
        try {
            $count = DB::table($table)->count();
            echo "Table {$table}: {$count} records\n";
            
            // Show some sample data
            if ($count > 0) {
                $sample = DB::table($table)->limit(2)->get();
                foreach ($sample as $record) {
                    echo "  Sample: " . json_encode((array)$record) . "\n";
                }
            }
        } catch (Exception $e) {
            echo "Table {$table}: Error - " . $e->getMessage() . "\n";
        }
    }
    
    echo "\n--- Checking specific data for dashboard ---\n";
    
    // Check active drivers
    $activeDrivers = DB::table('drivers')->where('is_active', 1)->count();
    echo "Active drivers (is_active = 1): {$activeDrivers}\n";
    
    // Check active devices
    $activeDevices = DB::table('devices')->where('is_active', 1)->count();
    echo "Active devices (is_active = 1): {$activeDevices}\n";
    
    // Check payments with status
    $completedPayments = DB::table('payments')->where('status', 'completed')->count();
    $totalPayments = DB::table('payments')->count();
    echo "Completed payments: {$completedPayments} / {$totalPayments} total\n";
    
    // Check unpaid debts
    $unpaidDebts = DB::table('debt_records')->where('is_paid', 0)->count();
    echo "Unpaid debts (is_paid = 0): {$unpaidDebts}\n";
    
    // Check payment amounts for revenue
    $totalPaymentAmount = DB::table('payments')->where('status', 'completed')->sum('amount');
    $totalDebtAmount = DB::table('debt_records')->where('is_paid', 1)->sum('paid_amount');
    echo "Total completed payment amount: {$totalPaymentAmount}\n";
    echo "Total paid debt amount: {$totalDebtAmount}\n";
    
    echo "\n--- Creating sample data if needed ---\n";
    
    // Create sample data if tables are empty
    if ($activeDrivers == 0) {
        echo "Creating sample drivers...\n";
        
        // Insert sample users first
        DB::table('users')->insertOrIgnore([
            [
                'id' => 1,
                'name' => 'John Mukasa',
                'email' => 'john.mukasa@example.com',
                'phone' => '+256701234567',
                'role' => 'driver',
                'email_verified_at' => Carbon::now(),
                'password' => password_hash('password', PASSWORD_DEFAULT),
                'created_at' => Carbon::now(),
                'updated_at' => Carbon::now()
            ],
            [
                'id' => 2,
                'name' => 'Mary Nakato',
                'email' => 'mary.nakato@example.com',
                'phone' => '+256701234568',
                'role' => 'driver',
                'email_verified_at' => Carbon::now(),
                'password' => password_hash('password', PASSWORD_DEFAULT),
                'created_at' => Carbon::now(),
                'updated_at' => Carbon::now()
            ]
        ]);
        
        // Insert sample drivers
        DB::table('drivers')->insertOrIgnore([
            [
                'id' => 1,
                'user_id' => 1,
                'name' => 'John Mukasa',
                'phone' => '+256701234567',
                'license_number' => 'DL001',
                'is_active' => 1,
                'created_at' => Carbon::now(),
                'updated_at' => Carbon::now()
            ],
            [
                'id' => 2,
                'user_id' => 2,
                'name' => 'Mary Nakato',
                'phone' => '+256701234568',
                'license_number' => 'DL002',
                'is_active' => 1,
                'created_at' => Carbon::now(),
                'updated_at' => Carbon::now()
            ]
        ]);
        
        echo "Sample drivers created.\n";
    }
    
    if ($activeDevices == 0) {
        echo "Creating sample devices...\n";
        
        DB::table('devices')->insertOrIgnore([
            [
                'id' => 1,
                'device_number' => 'UBE123A',
                'device_type' => 'bajaji',
                'driver_id' => 1,
                'is_active' => 1,
                'created_at' => Carbon::now(),
                'updated_at' => Carbon::now()
            ],
            [
                'id' => 2,
                'device_number' => 'UBF456B',
                'device_type' => 'bajaji',
                'driver_id' => 2,
                'is_active' => 1,
                'created_at' => Carbon::now(),
                'updated_at' => Carbon::now()
            ]
        ]);
        
        echo "Sample devices created.\n";
    }
    
    if ($completedPayments == 0) {
        echo "Creating sample payments...\n";
        
        DB::table('payments')->insertOrIgnore([
            [
                'id' => 1,
                'driver_id' => 1,
                'reference_number' => 'PAY001',
                'amount' => 50000,
                'payment_date' => Carbon::today(),
                'status' => 'completed',
                'payment_channel' => 'mobile_money',
                'created_at' => Carbon::now(),
                'updated_at' => Carbon::now()
            ],
            [
                'id' => 2,
                'driver_id' => 2,
                'reference_number' => 'PAY002',
                'amount' => 75000,
                'payment_date' => Carbon::today(),
                'status' => 'completed',
                'payment_channel' => 'mobile_money',
                'created_at' => Carbon::now(),
                'updated_at' => Carbon::now()
            ],
            [
                'id' => 3,
                'driver_id' => 1,
                'reference_number' => 'PAY003',
                'amount' => 60000,
                'payment_date' => Carbon::yesterday(),
                'status' => 'completed',
                'payment_channel' => 'cash',
                'created_at' => Carbon::now(),
                'updated_at' => Carbon::now()
            ]
        ]);
        
        echo "Sample payments created.\n";
    }
    
    if ($unpaidDebts == 0) {
        echo "Creating sample debt records...\n";
        
        DB::table('debt_records')->insertOrIgnore([
            [
                'id' => 1,
                'driver_id' => 1,
                'earning_date' => Carbon::today()->subDays(3),
                'expected_amount' => 30000,
                'paid_amount' => 0,
                'is_paid' => 0,
                'notes' => 'Pending payment',
                'created_at' => Carbon::now(),
                'updated_at' => Carbon::now()
            ],
            [
                'id' => 2,
                'driver_id' => 2,
                'earning_date' => Carbon::today()->subDays(2),
                'expected_amount' => 40000,
                'paid_amount' => 40000,
                'paid_at' => Carbon::now(),
                'is_paid' => 1,
                'notes' => 'Paid in full',
                'created_at' => Carbon::now(),
                'updated_at' => Carbon::now()
            ]
        ]);
        
        echo "Sample debt records created.\n";
    }
    
    echo "\n--- Final counts after sample data ---\n";
    foreach ($tables as $table) {
        $count = DB::table($table)->count();
        echo "Table {$table}: {$count} records\n";
    }
    
} catch (Exception $e) {
    echo "Error: " . $e->getMessage() . "\n";
}

echo "\nDatabase check complete.\n";
?>