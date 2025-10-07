#!/bin/bash

echo "Starting Laravel Server for Network Access"
echo "=========================================="
echo
echo "Your server will be accessible at:"
echo "- Local: http://127.0.0.1:8000"
echo "- Network: http://192.168.1.124:8000"
echo "- API: http://192.168.1.124:8000/api"
echo
echo "Make sure firewall allows PHP on port 8000"
echo "Press Ctrl+C to stop the server"
echo

php artisan serve --host=0.0.0.0 --port=8000