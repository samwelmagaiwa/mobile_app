<?php
require_once 'vendor/autoload.php';

// Test the dashboard API endpoints
echo "Testing Dashboard API Endpoints...\n\n";

// Step 1: Test if Laravel server is running
echo "1. Testing server health...\n";
$healthUrl = 'http://127.0.0.1:8000/api/health';
$healthResponse = @file_get_contents($healthUrl);

if ($healthResponse) {
    $healthData = json_decode($healthResponse, true);
    echo "✓ Server is running: " . $healthData['message'] . "\n";
} else {
    echo "✗ Server is not responding at http://127.0.0.1:8000\n";
    exit(1);
}

// Step 2: Create a test admin user and get auth token
echo "\n2. Creating test admin user and getting auth token...\n";

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

try {
    // Create or get admin user
    $adminUser = DB::table('users')->where('email', 'admin@test.com')->first();
    
    if (!$adminUser) {
        DB::table('users')->insert([
            'id' => DB::raw('UUID()'),
            'name' => 'Test Admin',
            'email' => 'admin@test.com',
            'phone_number' => '+256700000000',
            'role' => 'admin',
            'email_verified_at' => Carbon::now(),
            'password' => password_hash('password', PASSWORD_DEFAULT),
            'is_active' => 1,
            'created_at' => Carbon::now(),
            'updated_at' => Carbon::now()
        ]);
        echo "✓ Created test admin user\n";
    } else {
        echo "✓ Admin user exists\n";
    }
    
    // Login via API to get token
    $loginData = [
        'email' => 'admin@test.com',
        'password' => 'password',
        'phone_number' => '+256700000000'
    ];
    
    $loginResponse = makeApiRequest('POST', 'http://127.0.0.1:8000/api/auth/login', $loginData);
    
    if (isset($loginResponse['data']['token'])) {
        $authToken = $loginResponse['data']['token'];
        echo "✓ Got auth token: " . substr($authToken, 0, 20) . "...\n";
    } elseif (isset($loginResponse['token'])) {
        $authToken = $loginResponse['token'];
        echo "✓ Got auth token: " . substr($authToken, 0, 20) . "...\n";
    } else {
        echo "✗ Failed to get auth token: " . json_encode($loginResponse) . "\n";
        exit(1);
    }
    
} catch (Exception $e) {
    echo "✗ Database error: " . $e->getMessage() . "\n";
    exit(1);
}

// Step 3: Test dashboard endpoints
echo "\n3. Testing dashboard endpoints...\n";

// Test main dashboard endpoint
echo "\nTesting /admin/dashboard-data...\n";
$dashboardResponse = makeApiRequest('GET', 'http://127.0.0.1:8000/api/admin/dashboard-data', null, $authToken);
if ($dashboardResponse && isset($dashboardResponse['success'])) {
    echo "✓ Dashboard data endpoint works\n";
    if (isset($dashboardResponse['data'])) {
        $data = $dashboardResponse['data'];
        echo "  - Total drivers: " . ($data['total_drivers'] ?? 'N/A') . "\n";
        echo "  - Active drivers: " . ($data['active_drivers'] ?? 'N/A') . "\n";
        echo "  - Monthly revenue: " . ($data['monthly_revenue'] ?? 'N/A') . "\n";
    }
} else {
    echo "✗ Dashboard endpoint failed: " . json_encode($dashboardResponse) . "\n";
}

// Test individual dashboard count endpoints
$endpoints = [
    'active-drivers-count' => '/admin/dashboard/active-drivers-count',
    'active-devices-count' => '/admin/dashboard/active-devices-count',
    'unpaid-debts-count' => '/admin/dashboard/unpaid-debts-count',
    'daily-revenue' => '/admin/dashboard/daily-revenue',
    'weekly-revenue' => '/admin/dashboard/weekly-revenue',
    'monthly-revenue' => '/admin/dashboard/monthly-revenue'
];

foreach ($endpoints as $name => $endpoint) {
    echo "\nTesting $endpoint...\n";
    $response = makeApiRequest('GET', 'http://127.0.0.1:8000/api' . $endpoint, null, $authToken);
    
    if ($response && isset($response['success']) && $response['success']) {
        echo "✓ $name works\n";
        if (isset($response['data'])) {
            $data = $response['data'];
            if (isset($data['count'])) {
                echo "  - Count: " . $data['count'] . "\n";
            }
            if (isset($data['revenue'])) {
                echo "  - Revenue: " . $data['revenue'] . "\n";
            }
        }
    } else {
        echo "✗ $name failed: " . json_encode($response) . "\n";
    }
}

echo "\nTest complete!\n";

function makeApiRequest($method, $url, $data = null, $authToken = null) {
    $curl = curl_init();
    
    $headers = [
        'Content-Type: application/json',
        'Accept: application/json'
    ];
    
    if ($authToken) {
        $headers[] = 'Authorization: Bearer ' . $authToken;
    }
    
    curl_setopt_array($curl, [
        CURLOPT_URL => $url,
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_TIMEOUT => 30,
        CURLOPT_CUSTOMREQUEST => $method,
        CURLOPT_HTTPHEADER => $headers,
    ]);
    
    if ($data && in_array($method, ['POST', 'PUT', 'PATCH'])) {
        curl_setopt($curl, CURLOPT_POSTFIELDS, json_encode($data));
    }
    
    $response = curl_exec($curl);
    $httpCode = curl_getinfo($curl, CURLINFO_HTTP_CODE);
    $error = curl_error($curl);
    curl_close($curl);
    
    if ($error) {
        return ['error' => $error];
    }
    
    if ($httpCode >= 400) {
        return ['http_error' => $httpCode, 'response' => $response];
    }
    
    return json_decode($response, true);
}
?>