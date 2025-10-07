<?php

/**
 * Complete Database Setup Script for Boda Mapato
 * 
 * This script will:
 * 1. Reset all migrations
 * 2. Run fresh migrations
 * 3. Seed initial data
 * 
 * Run this from the backend_mapato directory: php setup_database.php
 */

echo "=== Boda Mapato Database Setup ===\n\n";

// Check if we're in the right directory
if (!file_exists('artisan')) {
    echo "❌ Error: Please run this script from the backend_mapato directory\n";
    echo "   Current directory: " . getcwd() . "\n";
    echo "   Expected files: artisan, .env\n";
    exit(1);
}

// Check if .env exists
if (!file_exists('.env')) {
    echo "❌ Error: .env file not found\n";
    echo "   Please copy .env.example to .env and configure your database settings\n";
    exit(1);
}

echo "✅ Environment check passed\n\n";

// Function to run command and show output
function runCommand($command, $description) {
    echo "🔄 $description...\n";
    $output = [];
    $return_var = 0;
    
    exec($command . ' 2>&1', $output, $return_var);
    
    if ($return_var === 0) {
        echo "✅ $description completed successfully\n";
        if (!empty($output)) {
            foreach ($output as $line) {
                if (trim($line)) {
                    echo "   $line\n";
                }
            }
        }
        echo "\n";
        return true;
    } else {
        echo "❌ $description failed\n";
        if (!empty($output)) {
            foreach ($output as $line) {
                if (trim($line)) {
                    echo "   $line\n";
                }
            }
        }
        echo "\n";
        return false;
    }
}

// Step 1: Check database connection
echo "Step 1: Testing database connection...\n";
if (!runCommand('php artisan db:show --database=mysql', 'Database connection test')) {
    echo "❌ Database connection failed. Please check your .env configuration:\n";
    echo "   - DB_HOST\n";
    echo "   - DB_PORT\n";
    echo "   - DB_DATABASE\n";
    echo "   - DB_USERNAME\n";
    echo "   - DB_PASSWORD\n\n";
    echo "Make sure MySQL is running and the database exists.\n";
    exit(1);
}

// Step 2: Drop all tables and run fresh migrations
echo "Step 2: Running fresh migrations...\n";

// First try to drop all tables manually to avoid conflicts
echo "🔄 Dropping existing tables...\n";
runCommand('php artisan db:wipe --force', 'Drop all tables');

if (!runCommand('php artisan migrate --force', 'Run migrations')) {
    echo "❌ Migration failed. Trying fresh approach...\n";
    
    if (!runCommand('php artisan migrate:fresh --force', 'Fresh migration')) {
        echo "❌ Migration still failed. Manual intervention required.\n";
        echo "\nTroubleshooting steps:\n";
        echo "1. Check if MySQL is running\n";
        echo "2. Verify database exists and user has permissions\n";
        echo "3. Try manually: php artisan migrate:fresh --force\n";
        echo "4. Check Laravel logs in storage/logs/\n";
        echo "5. Or manually drop the database and recreate it\n";
        exit(1);
    }
}

// Step 3: Seed initial data
echo "Step 3: Seeding initial data...\n";
if (!runCommand('php artisan db:seed --force', 'Database seeding')) {
    echo "⚠️  Seeding failed, but migrations completed successfully.\n";
    echo "   You can manually create users or run: php artisan db:seed\n\n";
} else {
    echo "✅ Database setup completed successfully!\n\n";
}

// Step 4: Show final status
echo "=== Setup Complete ===\n";
echo "Your Boda Mapato database is ready!\n\n";

echo "📋 Default Login Credentials:\n";
echo "   Admin: admin@bodamapato.com / password123\n";
echo "   Driver 1: john@example.com / password123\n";
echo "   Driver 2: jane@example.com / password123\n\n";

echo "🚀 Next Steps:\n";
echo "1. Start your Laravel server: php artisan serve\n";
echo "2. Test the API endpoints\n";
echo "3. Configure your Flutter app to connect to the API\n\n";

echo "📚 API Documentation:\n";
echo "   Base URL: http://localhost:8000/api\n";
echo "   Health Check: GET /api/health\n";
echo "   Login: POST /api/auth/login\n";
echo "   Admin Dashboard: GET /api/admin/dashboard\n\n";

echo "Happy coding! 🎉\n";