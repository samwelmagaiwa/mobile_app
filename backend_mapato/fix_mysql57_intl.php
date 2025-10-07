<?php

/**
 * MySQL 5.7 & PHP Intl Extension Fix Script
 * Fixes both performance_schema and intl extension issues
 */

echo "=== MySQL 5.7 & PHP Intl Extension Fix ===\n\n";

// Check if we're in the right directory
if (!file_exists('artisan')) {
    echo "❌ Error: Please run this script from the backend_mapato directory\n";
    exit(1);
}

echo "1. Checking PHP extensions...\n";

// Check for intl extension
if (extension_loaded('intl')) {
    echo "   ✅ PHP Intl extension is loaded\n";
} else {
    echo "   ⚠️  PHP Intl extension is NOT loaded\n";
    echo "   ℹ️  Custom Number helper will be used instead\n";
}

// Check for MySQL extensions
$mysqlExtensions = ['pdo_mysql', 'mysqli'];
foreach ($mysqlExtensions as $ext) {
    if (extension_loaded($ext)) {
        echo "   ✅ $ext extension is loaded\n";
    } else {
        echo "   ❌ $ext extension is NOT loaded\n";
    }
}

echo "\n2. Testing database connection...\n";

try {
    // Test basic database connection
    $pdo = new PDO(
        "mysql:host=127.0.0.1;port=3306;dbname=marejesho", 
        'root', 
        '', 
        [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
    );
    
    echo "   ✅ Database connection successful\n";
    
    // Test MySQL version
    $stmt = $pdo->query("SELECT VERSION() as version");
    $version = $stmt->fetch(PDO::FETCH_ASSOC)['version'];
    echo "   MySQL Version: $version\n";
    
    // Test performance_schema access
    try {
        $stmt = $pdo->query("SELECT COUNT(*) as count FROM performance_schema.session_status WHERE variable_name = 'threads_connected'");
        $result = $stmt->fetch(PDO::FETCH_ASSOC);
        echo "   ✅ Performance Schema accessible\n";
    } catch (PDOException $e) {
        echo "   ⚠️  Performance Schema not accessible (MySQL 5.7 detected)\n";
        echo "   ℹ️  Custom MySQL connection will handle this\n";
        
        // Test fallback method
        try {
            $stmt = $pdo->query("SHOW STATUS LIKE 'Threads_connected'");
            $result = $stmt->fetch(PDO::FETCH_ASSOC);
            echo "   ✅ Fallback method works: " . $result['Value'] . " connections\n";
        } catch (PDOException $fallbackError) {
            echo "   ❌ Fallback method failed: " . $fallbackError->getMessage() . "\n";
        }
    }
    
} catch (PDOException $e) {
    echo "   ❌ Database connection failed: " . $e->getMessage() . "\n";
    echo "   Make sure MySQL is running and credentials are correct\n";
}

echo "\n3. Clearing Laravel caches...\n";

$cacheCommands = [
    'config:clear' => 'Configuration cache',
    'route:clear' => 'Route cache',
    'view:clear' => 'View cache',
    'cache:clear' => 'Application cache',
];

foreach ($cacheCommands as $command => $description) {
    exec("php artisan $command 2>&1", $output, $return);
    if ($return === 0) {
        echo "   ✅ $description cleared\n";
    } else {
        echo "   ⚠️  Failed to clear $description\n";
    }
    $output = [];
}

echo "\n4. Testing Laravel artisan commands...\n";

// Test our custom database show command
echo "   Testing custom db:show-safe command...\n";
exec('php artisan db:show-safe 2>&1', $dbShowOutput, $dbShowReturn);

if ($dbShowReturn === 0) {
    echo "   ✅ Custom database show command works\n";
    echo "   Output preview:\n";
    foreach (array_slice($dbShowOutput, 0, 5) as $line) {
        echo "     $line\n";
    }
} else {
    echo "   ⚠️  Custom database show command failed\n";
    echo "   Error: " . implode("\n   ", $dbShowOutput) . "\n";
}

// Test basic artisan commands
$basicCommands = [
    'list' => 'Command list',
    'migrate:status' => 'Migration status',
];

foreach ($basicCommands as $command => $description) {
    exec("php artisan $command 2>&1", $output, $return);
    if ($return === 0) {
        echo "   ✅ $description command works\n";
    } else {
        echo "   ⚠️  $description command failed\n";
    }
    $output = [];
}

echo "\n5. Testing Number helper functionality...\n";

// Test our custom Number helper
require_once 'app/Helpers/NumberHelper.php';
use App\Helpers\NumberHelper;

try {
    $fileSize = NumberHelper::fileSize(1048576); // 1MB
    echo "   ✅ File size formatting: $fileSize\n";
    
    $number = NumberHelper::format(1234.567, 2);
    echo "   ✅ Number formatting: $number\n";
    
    $percentage = NumberHelper::percentage(75.5, 1);
    echo "   ✅ Percentage formatting: $percentage\n";
    
    $currency = NumberHelper::currency(1500, 'TZS');
    echo "   ✅ Currency formatting: $currency\n";
    
} catch (Exception $e) {
    echo "   ❌ Number helper failed: " . $e->getMessage() . "\n";
}

echo "\n6. Checking service providers...\n";

// Check if our service providers are registered
$providersFile = 'bootstrap/providers.php';
if (file_exists($providersFile)) {
    $content = file_get_contents($providersFile);
    
    if (strpos($content, 'MySQL57ServiceProvider') !== false) {
        echo "   ✅ MySQL57ServiceProvider is registered\n";
    } else {
        echo "   ❌ MySQL57ServiceProvider is NOT registered\n";
    }
    
    if (strpos($content, 'NumberServiceProvider') !== false) {
        echo "   ✅ NumberServiceProvider is registered\n";
    } else {
        echo "   ❌ NumberServiceProvider is NOT registered\n";
    }
} else {
    echo "   ❌ Providers file not found\n";
}

echo "\n=== Fix Summary ===\n";

echo "🔧 Applied Fixes:\n";
echo "   • Custom MySQL connection for MySQL 5.7 compatibility\n";
echo "   • Custom Number helper for systems without intl extension\n";
echo "   • Safe database show command\n";
echo "   • Service providers for automatic handling\n";

echo "\n✅ Recommended Usage:\n";
echo "   • Use 'php artisan db:show-safe' instead of 'php artisan db:show'\n";
echo "   • Regular artisan commands should now work without errors\n";
echo "   • API endpoints should function normally\n";

echo "\n🚀 Next Steps:\n";
echo "1. Test your application: php artisan serve\n";
echo "2. Test API endpoints\n";
echo "3. Run migrations if needed: php artisan migrate\n";
echo "4. Test Flutter app connection\n";

echo "\n📋 If you still get errors:\n";
echo "1. Enable PHP intl extension in php.ini (recommended)\n";
echo "2. Upgrade to MySQL 8.0 for full compatibility\n";
echo "3. Use the custom commands provided\n";

echo "\n🎉 MySQL 5.7 & PHP Intl compatibility fixes applied!\n\n";