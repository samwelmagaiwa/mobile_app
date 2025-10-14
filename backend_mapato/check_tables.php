<?php

require_once __DIR__ . '/vendor/autoload.php';

$app = require_once __DIR__ . '/bootstrap/app.php';

use Illuminate\Support\Facades\DB;

try {
    echo "Database Tables:\n";
    echo "================\n";
    
    $tables = DB::select('SHOW TABLES');
    
    foreach ($tables as $table) {
        $tableName = array_values((array) $table)[0];
        echo "- $tableName\n";
    }
    
    echo "\nTotal tables: " . count($tables) . "\n";
    
} catch (Exception $e) {
    echo "Error: " . $e->getMessage() . "\n";
}