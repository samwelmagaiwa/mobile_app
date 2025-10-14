<?php

require_once __DIR__ . '/vendor/autoload.php';

$app = require_once __DIR__ . '/bootstrap/app.php';

use App\Http\Controllers\Api\PaymentController;
use Illuminate\Http\Request;

// Create a test request similar to what the mobile app sends
$requestData = [
    'driver_id' => '1', // Assuming driver ID 1 exists
    'amount' => 40000,
    'payment_date' => '2025-10-13',
    'month_for' => '2025-10',
    'notes' => 'Test payment from mobile app'
];

$request = new Request($requestData);

$controller = new PaymentController();

echo "Testing storeNewPayment endpoint...\n";
echo "Request data: " . json_encode($requestData) . "\n\n";

try {
    $response = $controller->storeNewPayment($request);
    echo "Response: " . $response->getContent() . "\n";
    echo "Status Code: " . $response->getStatusCode() . "\n";
} catch (Exception $e) {
    echo "Error: " . $e->getMessage() . "\n";
    echo "File: " . $e->getFile() . ":" . $e->getLine() . "\n";
    echo "Trace:\n" . $e->getTraceAsString() . "\n";
}