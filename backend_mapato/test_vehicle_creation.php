<?php

// Simple test script to debug vehicle creation issue
require_once 'vendor/autoload.php';

use Illuminate\Foundation\Application;
use Illuminate\Http\Request;

// Bootstrap Laravel
$app = require_once 'bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Http\Kernel::class);

// Create a test request
$request = Request::create('/api/admin/vehicles', 'POST', [
    'name' => 'Test Vehicle',
    'type' => 'bajaji',
    'plate_number' => 'TEST123',
    'description' => 'Test vehicle for debugging'
]);

try {
    // Test the controller directly
    $controller = new App\Http\Controllers\API\AdminController();
    $formRequest = App\Http\Requests\CreateVehicleRequest::createFrom($request);
    
    echo "Testing vehicle creation...\n";
    echo "Request data: " . json_encode($request->all()) . "\n";
    
    $response = $controller->createVehicle($formRequest);
    
    echo "Response: " . $response->getContent() . "\n";
    echo "Status: " . $response->getStatusCode() . "\n";
    
} catch (Exception $e) {
    echo "Error: " . $e->getMessage() . "\n";
    echo "File: " . $e->getFile() . ":" . $e->getLine() . "\n";
    echo "Trace: " . $e->getTraceAsString() . "\n";
}