<?php
require_once 'vendor/autoload.php';

echo "=== DEBUG: Testing Flutter Dashboard API Calls ===\n\n";

// Step 1: Login as admin and get token
echo "1. Logging in as admin...\n";
$loginResponse = makeApiRequest('POST', 'http://127.0.0.1:8000/api/auth/login', [
    'email' => 'admin@test.com',
    'password' => 'password',
    'phone_number' => '+256700000000'
]);

if (!isset($loginResponse['data']['token'])) {
    echo "❌ Login failed: " . json_encode($loginResponse) . "\n";
    exit(1);
}

$token = $loginResponse['data']['token'];
$user = $loginResponse['data']['user'];
echo "✅ Login successful\n";
echo "   User: {$user['name']} ({$user['role']})\n";
echo "   Token: " . substr($token, 0, 20) . "...\n\n";

// Step 2: Test the exact API calls that ModernDashboardScreen makes
echo "2. Testing Flutter ModernDashboardScreen API calls...\n\n";

$apiCalls = [
    // Main dashboard data (from _apiService.getDashboardData())
    [
        'name' => 'getDashboardData()',
        'endpoint' => '/admin/dashboard',
        'expect' => 'total_drivers, active_drivers, monthly_revenue'
    ],
    
    // Specific counts (from _loadDriversCountFromExisting())
    [
        'name' => 'getActiveDriversCount()',
        'endpoint' => '/admin/dashboard/active-drivers-count',
        'expect' => 'count'
    ],
    
    // Device counts (from _loadDevicesCountFromExisting())
    [
        'name' => 'getActiveDevicesCount()',
        'endpoint' => '/admin/dashboard/active-devices-count', 
        'expect' => 'count'
    ],
    
    // Revenue data (from _loadRevenueDataFromExisting())
    [
        'name' => 'getDailyRevenue()',
        'endpoint' => '/admin/dashboard/daily-revenue',
        'expect' => 'revenue'
    ],
    [
        'name' => 'getWeeklyRevenue()',
        'endpoint' => '/admin/dashboard/weekly-revenue',
        'expect' => 'revenue'
    ],
    [
        'name' => 'getMonthlyRevenue()',
        'endpoint' => '/admin/dashboard/monthly-revenue',
        'expect' => 'revenue'
    ],
    
    // Debt counts (from _loadUnpaidDebtsCountFromExisting())
    [
        'name' => 'getUnpaidDebtsCount()',
        'endpoint' => '/admin/dashboard/unpaid-debts-count',
        'expect' => 'count'
    ],
    
    // Receipt counts (from _loadPaymentReceiptsCountFromExisting())
    [
        'name' => 'getGeneratedReceiptsCount()',
        'endpoint' => '/admin/dashboard/generated-receipts-count',
        'expect' => 'count'
    ],
    [
        'name' => 'getPendingReceiptsCount()',
        'endpoint' => '/admin/dashboard/pending-receipts-count',
        'expect' => 'count'
    ],
    
    // Chart data (from _loadRevenueChartData())
    [
        'name' => 'getRevenueChart()',
        'endpoint' => '/admin/reports/revenue?start_date=2025-09-14&end_date=2025-10-14',
        'expect' => 'daily_data or chart data'
    ]
];

$results = [];
foreach ($apiCalls as $call) {
    echo "Testing: {$call['name']}\n";
    echo "  Endpoint: {$call['endpoint']}\n";
    
    $response = makeApiRequest('GET', 'http://127.0.0.1:8000/api' . $call['endpoint'], null, $token);
    
    if (isset($response['status']) && $response['status'] === 'success') {
        echo "  ✅ SUCCESS\n";
        
        if (isset($response['data'])) {
            $data = $response['data'];
            if (isset($data['count'])) {
                echo "     Count: {$data['count']}\n";
                $results[$call['name']] = $data['count'];
            }
            if (isset($data['revenue'])) {
                echo "     Revenue: {$data['revenue']}\n";
                $results[$call['name']] = $data['revenue'];
            }
            if (isset($data['total_drivers'])) {
                echo "     Total Drivers: {$data['total_drivers']}\n";
                $results[$call['name']] = $data['total_drivers'];
            }
            if (isset($data['monthly_revenue'])) {
                echo "     Monthly Revenue: {$data['monthly_revenue']}\n";
                $results[$call['name']] = $data['monthly_revenue'];
            }
        }
    } else {
        echo "  ❌ FAILED\n";
        echo "     Response: " . json_encode($response) . "\n";
        $results[$call['name']] = 'FAILED';
    }
    echo "\n";
}

// Step 3: Summary of what Flutter should display
echo "3. Expected Flutter Dashboard Values:\n";
echo "=====================================\n";
echo "Daily Revenue (Mapato ya Siku): " . ($results['getDailyRevenue()'] ?? 'FAILED') . " TSH\n";
echo "Weekly Revenue (Mapato ya Wiki): " . ($results['getWeeklyRevenue()'] ?? 'FAILED') . " TSH\n";
echo "Monthly Revenue (Mapato ya Mwezi): " . ($results['getMonthlyRevenue()'] ?? 'FAILED') . " TSH\n";
echo "Active Drivers (Madereva): " . ($results['getActiveDriversCount()'] ?? 'FAILED') . "\n";
echo "Active Devices (Vyombo vya Usafiri): " . ($results['getActiveDevicesCount()'] ?? 'FAILED') . "\n";
echo "Unpaid Debts (Malipo Yasiyolipwa): " . ($results['getUnpaidDebtsCount()'] ?? 'FAILED') . "\n";
echo "Generated Receipts: " . ($results['getGeneratedReceiptsCount()'] ?? 'FAILED') . "\n";
echo "Pending Receipts: " . ($results['getPendingReceiptsCount()'] ?? 'FAILED') . "\n";

echo "\nIf your Flutter app is still showing zeros, the issue is likely:\n";
echo "1. ❌ Not logged in as admin user\n";
echo "2. ❌ Authentication token not being sent with requests\n";
echo "3. ❌ API calls failing silently\n";
echo "4. ❌ Response parsing issues in Flutter code\n";

echo "\n=== Next Steps ===\n";
echo "1. Make sure you're logged in as: admin@test.com / password / +256700000000\n";
echo "2. Check Flutter debug console for API errors\n";
echo "3. Verify the user role is 'admin' in the Flutter app\n";

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