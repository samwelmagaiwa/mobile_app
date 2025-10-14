# Backend API Requirements for Dashboard

## Issue
The dashboard is trying to fetch comprehensive data from `/admin/dashboard/comprehensive` but this endpoint doesn't exist yet (returns 404).

## Solution Options

### Option 1: Quick Fix - Update Existing Endpoint
Update the existing `/admin/dashboard` endpoint to include the additional database counts:

```php
// Current endpoint: GET /api/admin/dashboard
// Add these fields to the existing response:

{
  "success": true,
  "data": {
    // Existing fields (keep as is)
    "monthly_income": 240000,
    "weekly_revenue": 0, 
    "daily_revenue": 0,
    "net_profit": 0,
    "total_drivers": 0,
    "total_vehicles": 0,
    "active_drivers": 0,
    "pending_payments": 0,
    
    // NEW FIELDS - Add these database counts
    "drivers_count": 0,           // SELECT COUNT(*) FROM drivers
    "devices_count": 0,           // SELECT COUNT(*) FROM devices  
    "unpaid_debts_count": 0,      // SELECT COUNT(*) FROM debt_records WHERE paid = false
    "payment_receipts_count": 0,   // SELECT COUNT(*) FROM payment_receipts
    "pending_receipts_count": 0    // SELECT COUNT(*) FROM payments WHERE receipt_status = 'pending'
  }
}
```

### Option 2: Create New Comprehensive Endpoint
Create the new endpoint as expected:

```php
// New endpoint: GET /api/admin/dashboard/comprehensive
Route::get('/admin/dashboard/comprehensive', [DashboardController::class, 'getComprehensiveData']);
```

## Database Queries Needed

```sql
-- Drivers count
SELECT COUNT(*) as drivers_count FROM drivers;

-- Devices/Vehicles count  
SELECT COUNT(*) as devices_count FROM devices;

-- Unpaid debts count
SELECT COUNT(*) as unpaid_debts_count FROM debt_records WHERE paid = 0 OR paid IS NULL;

-- Payment receipts count
SELECT COUNT(*) as payment_receipts_count FROM payment_receipts;

-- Pending receipts count (payments without receipts)
SELECT COUNT(*) as pending_receipts_count FROM payments WHERE receipt_status = 'pending';

-- Daily revenue (today)
SELECT COALESCE(SUM(amount), 0) as daily_revenue 
FROM (
  SELECT amount FROM payments WHERE DATE(created_at) = CURDATE()
  UNION ALL
  SELECT amount FROM debt_records WHERE DATE(paid_at) = CURDATE() AND paid = 1
) as daily_payments;

-- Weekly revenue (this week)
SELECT COALESCE(SUM(amount), 0) as weekly_revenue 
FROM (
  SELECT amount FROM payments WHERE WEEK(created_at) = WEEK(NOW()) AND YEAR(created_at) = YEAR(NOW())
  UNION ALL  
  SELECT amount FROM debt_records WHERE WEEK(paid_at) = WEEK(NOW()) AND YEAR(paid_at) = YEAR(NOW()) AND paid = 1
) as weekly_payments;

-- Monthly revenue (this month)
SELECT COALESCE(SUM(amount), 0) as monthly_revenue 
FROM (
  SELECT amount FROM payments WHERE MONTH(created_at) = MONTH(NOW()) AND YEAR(created_at) = YEAR(NOW())
  UNION ALL
  SELECT amount FROM debt_records WHERE MONTH(paid_at) = MONTH(NOW()) AND YEAR(paid_at) = YEAR(NOW()) AND paid = 1  
) as monthly_payments;
```

## Controller Implementation Example

```php
<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class DashboardController extends Controller
{
    public function getComprehensiveData()
    {
        try {
            $data = [
                // Database table counts
                'drivers_count' => DB::table('drivers')->count(),
                'devices_count' => DB::table('devices')->count(), 
                'unpaid_debts_count' => DB::table('debt_records')->where('paid', 0)->orWhereNull('paid')->count(),
                'payment_receipts_count' => DB::table('payment_receipts')->count(),
                'pending_receipts_count' => DB::table('payments')->where('receipt_status', 'pending')->count(),
                
                // Revenue calculations
                'daily_revenue' => $this->getDailyRevenue(),
                'weekly_revenue' => $this->getWeeklyRevenue(), 
                'monthly_revenue' => $this->getMonthlyRevenue(),
                
                // Existing fields (if needed for compatibility)
                'total_drivers' => DB::table('drivers')->count(),
                'total_vehicles' => DB::table('devices')->count(),
                'net_profit' => 0, // Calculate as needed
            ];

            return response()->json([
                'success' => true,
                'data' => $data
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to load dashboard data',
                'error' => $e->getMessage()
            ], 500);
        }
    }
    
    private function getDailyRevenue()
    {
        return DB::select("
            SELECT COALESCE(SUM(amount), 0) as total
            FROM (
                SELECT amount FROM payments WHERE DATE(created_at) = CURDATE()
                UNION ALL
                SELECT amount FROM debt_records WHERE DATE(paid_at) = CURDATE() AND paid = 1
            ) as daily_payments
        ")[0]->total ?? 0;
    }
    
    private function getWeeklyRevenue()
    {
        return DB::select("
            SELECT COALESCE(SUM(amount), 0) as total
            FROM (
                SELECT amount FROM payments WHERE WEEK(created_at) = WEEK(NOW()) AND YEAR(created_at) = YEAR(NOW())
                UNION ALL  
                SELECT amount FROM debt_records WHERE WEEK(paid_at) = WEEK(NOW()) AND YEAR(paid_at) = YEAR(NOW()) AND paid = 1
            ) as weekly_payments
        ")[0]->total ?? 0;
    }
    
    private function getMonthlyRevenue()
    {
        return DB::select("
            SELECT COALESCE(SUM(amount), 0) as total
            FROM (
                SELECT amount FROM payments WHERE MONTH(created_at) = MONTH(NOW()) AND YEAR(created_at) = YEAR(NOW())
                UNION ALL
                SELECT amount FROM debt_records WHERE MONTH(paid_at) = MONTH(NOW()) AND YEAR(paid_at) = YEAR(NOW()) AND paid = 1  
            ) as monthly_payments
        ")[0]->total ?? 0;
    }
}
```

## Current App Behavior

The Flutter app has been updated with fallback logic:

1. **First tries** the comprehensive endpoint (`/admin/dashboard/comprehensive`)
2. **Falls back** to existing endpoint (`/admin/dashboard`) if 404
3. **Loads individual counts** from existing endpoints (drivers, vehicles, payments, receipts)
4. **Gracefully handles** missing data with defaults

## Recommendation

**Option 1 (Quick Fix)** is recommended - just add the new fields to the existing `/admin/dashboard` endpoint. This requires minimal backend changes and will immediately fix the 404 error while providing all the required data.

The Flutter app will work with either approach, but Option 1 is faster to implement.