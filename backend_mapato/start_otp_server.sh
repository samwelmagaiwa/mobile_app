#!/bin/bash

echo "🚀 Starting Boda Mapato OTP Backend Server..."
echo

# Check if we're in the right directory
if [ ! -f "artisan" ]; then
    echo "❌ Error: artisan file not found. Make sure you're in the Laravel project directory."
    exit 1
fi

# Set environment variables for development
export APP_ENV=local
export APP_DEBUG=true

echo "📋 Configuration:"
echo "   Environment: $APP_ENV"
echo "   Debug Mode: $APP_DEBUG"
echo "   Server: http://0.0.0.0:8000"
echo "   Network Access: http://192.168.1.124:8000"
echo

echo "🔧 Running setup..."
php setup_backend.php
echo

echo "🌐 Starting Laravel server..."
echo "   Press Ctrl+C to stop the server"
echo

php artisan serve --host=0.0.0.0 --port=8000