<?php

require __DIR__ . '/vendor/autoload.php';
$app = require_once __DIR__ . '/bootstrap/app.php';
$app->make('Illuminate\Contracts\Console\Kernel')->bootstrap();

echo "=== DRIVERS TABLE STRUCTURE ===\n\n";

// Get drivers table structure
$columns = DB::select('DESCRIBE drivers');

echo "Field Name | Type | Nullable | Current Form Has?\n";
echo "-----------|------|----------|------------------\n";

foreach($columns as $column) {
    $nullable = $column->Null === 'YES' ? 'Yes' : 'No';
    echo sprintf("%-20s | %-15s | %-8s | ?\n", 
        $column->Field, 
        $column->Type, 
        $nullable
    );
}

echo "\n=== SAMPLE DRIVER DATA ===\n";
$driver = DB::table('drivers')->first();
if ($driver) {
    foreach ($driver as $field => $value) {
        echo "$field: " . ($value ?? 'NULL') . "\n";
    }
} else {
    echo "No drivers found in database\n";
}