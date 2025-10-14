# Backend Database Requirements - Exact Column Filtering

## 🎯 **Updated Dashboard Requirements**

The Flutter dashboard has been updated to fetch data with **exact database column filtering** as specified. Here are the precise backend endpoints and SQL queries needed:

## 📊 **Dashboard Cards & Database Mapping**

### **1. Malipo yasiyolipwa (Unpaid Debts)**
- **Database**: `debt_records` table
- **Filter**: `is_paid = 0`
- **Endpoint**: `GET /api/admin/dashboard/unpaid-debts-count`
- **SQL Query**:
```sql
SELECT COUNT(*) as count 
FROM debt_records 
WHERE is_paid = 0;
```
- **Expected Response**:
```json
{
  "success": true,
  "data": {
    "count": 15
  }
}
```

### **2. Vyombo vya usafiri (Active Transport Devices)**
- **Database**: `devices` table
- **Filter**: `is_active = 1`
- **Endpoint**: `GET /api/admin/dashboard/active-devices-count`
- **SQL Query**:
```sql
SELECT COUNT(*) as count 
FROM devices 
WHERE is_active = 1;
```
- **Expected Response**:
```json
{
  "success": true,
  "data": {
    "count": 12
  }
}
```

### **3. Madereva hai (Active Drivers)**
- **Database**: `drivers` table
- **Filter**: `is_active = 1`
- **Endpoint**: `GET /api/admin/dashboard/active-drivers-count`
- **SQL Query**:
```sql
SELECT COUNT(*) as count 
FROM drivers 
WHERE is_active = 1;
```
- **Expected Response**:
```json
{
  "success": true,
  "data": {
    "count": 18
  }
}
```

### **4. Malipo yenye risiti (Generated Receipts)**
- **Database**: `payment_receipts` table
- **Filter**: `receipt_status = 'generated'`
- **Endpoint**: `GET /api/admin/dashboard/generated-receipts-count`
- **SQL Query**:
```sql
SELECT COUNT(*) as count 
FROM payment_receipts 
WHERE receipt_status = 'generated';
```
- **Expected Response**:
```json
{
  "success": true,
  "data": {
    "count": 45
  }
}
```

### **5. Yamelipwa bado risiti (Pending Receipts)**
- **Database**: `payments` table
- **Filter**: `receipt_status = 'pending'`
- **Endpoint**: `GET /api/admin/dashboard/pending-receipts-count`
- **SQL Query**:
```sql
SELECT COUNT(*) as count 
FROM payments 
WHERE receipt_status = 'pending';
```
- **Expected Response**:
```json
{
  "success": true,
  "data": {
    "count": 8
  }
}
```

### **6. Mapato ya mwezi (Monthly Revenue)**
- **Database**: `debt_records` (is_paid=1) + `payments` tables
- **Filter**: Current month
- **Endpoint**: `GET /api/admin/dashboard/monthly-revenue`
- **SQL Query**:
```sql
SELECT COALESCE(SUM(total_amount), 0) as revenue
FROM (
  SELECT amount as total_amount 
  FROM debt_records 
  WHERE is_paid = 1 
    AND MONTH(paid_at) = MONTH(NOW()) 
    AND YEAR(paid_at) = YEAR(NOW())
  UNION ALL
  SELECT amount as total_amount 
  FROM payments 
  WHERE MONTH(created_at) = MONTH(NOW()) 
    AND YEAR(created_at) = YEAR(NOW())
) as monthly_revenue;
```
- **Expected Response**:
```json
{
  "success": true,
  "data": {
    "revenue": 240000
  }
}
```

### **7. Mapato ya wiki (Weekly Revenue)**
- **Database**: `debt_records` (is_paid=1) + `payments` tables
- **Filter**: Current week
- **Endpoint**: `GET /api/admin/dashboard/weekly-revenue`
- **SQL Query**:
```sql
SELECT COALESCE(SUM(total_amount), 0) as revenue
FROM (
  SELECT amount as total_amount 
  FROM debt_records 
  WHERE is_paid = 1 
    AND WEEK(paid_at) = WEEK(NOW()) 
    AND YEAR(paid_at) = YEAR(NOW())
  UNION ALL
  SELECT amount as total_amount 
  FROM payments 
  WHERE WEEK(created_at) = WEEK(NOW()) 
    AND YEAR(created_at) = YEAR(NOW())
) as weekly_revenue;
```
- **Expected Response**:
```json
{
  "success": true,
  "data": {
    "revenue": 85000
  }
}
```

### **8. Mapato ya siku (Daily Revenue)**
- **Database**: `debt_records` (is_paid=1) + `payments` tables
- **Filter**: Today
- **Endpoint**: `GET /api/admin/dashboard/daily-revenue`
- **SQL Query**:
```sql
SELECT COALESCE(SUM(total_amount), 0) as revenue
FROM (
  SELECT amount as total_amount 
  FROM debt_records 
  WHERE is_paid = 1 
    AND DATE(paid_at) = CURDATE()
  UNION ALL
  SELECT amount as total_amount 
  FROM payments 
  WHERE DATE(created_at) = CURDATE()
) as daily_revenue;
```
- **Expected Response**:
```json
{
  "success": true,
  "data": {
    "revenue": 15000
  }
}
```

## 🚀 **Comprehensive Endpoint (Recommended)**

For optimal performance, implement a single endpoint that returns all data:

**Endpoint**: `GET /api/admin/dashboard/comprehensive`

**SQL Implementation** (All queries combined):
```sql
SELECT 
  (SELECT COUNT(*) FROM debt_records WHERE is_paid = 0) as unpaid_debts_count,
  (SELECT COUNT(*) FROM devices WHERE is_active = 1) as active_devices_count,
  (SELECT COUNT(*) FROM drivers WHERE is_active = 1) as active_drivers_count,
  (SELECT COUNT(*) FROM payment_receipts WHERE receipt_status = 'generated') as generated_receipts_count,
  (SELECT COUNT(*) FROM payments WHERE receipt_status = 'pending') as pending_receipts_count,
  
  -- Daily Revenue
  (SELECT COALESCE(SUM(total_amount), 0) 
   FROM (
     SELECT amount as total_amount FROM debt_records WHERE is_paid = 1 AND DATE(paid_at) = CURDATE()
     UNION ALL
     SELECT amount as total_amount FROM payments WHERE DATE(created_at) = CURDATE()
   ) as daily_rev) as daily_revenue,
   
  -- Weekly Revenue  
  (SELECT COALESCE(SUM(total_amount), 0) 
   FROM (
     SELECT amount as total_amount FROM debt_records WHERE is_paid = 1 AND WEEK(paid_at) = WEEK(NOW()) AND YEAR(paid_at) = YEAR(NOW())
     UNION ALL
     SELECT amount as total_amount FROM payments WHERE WEEK(created_at) = WEEK(NOW()) AND YEAR(created_at) = YEAR(NOW())
   ) as weekly_rev) as weekly_revenue,
   
  -- Monthly Revenue
  (SELECT COALESCE(SUM(total_amount), 0) 
   FROM (
     SELECT amount as total_amount FROM debt_records WHERE is_paid = 1 AND MONTH(paid_at) = MONTH(NOW()) AND YEAR(paid_at) = YEAR(NOW())
     UNION ALL
     SELECT amount as total_amount FROM payments WHERE MONTH(created_at) = MONTH(NOW()) AND YEAR(created_at) = YEAR(NOW())
   ) as monthly_rev) as monthly_revenue;
```

**Expected Response**:
```json
{
  "success": true,
  "data": {
    "unpaid_debts_count": 15,
    "active_devices_count": 12,
    "active_drivers_count": 18,
    "generated_receipts_count": 45,
    "pending_receipts_count": 8,
    "daily_revenue": 15000,
    "weekly_revenue": 85000,
    "monthly_revenue": 240000
  }
}
```

## 📋 **Laravel Controller Implementation Example**

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
            $data = DB::selectOne("
                SELECT 
                  (SELECT COUNT(*) FROM debt_records WHERE is_paid = 0) as unpaid_debts_count,
                  (SELECT COUNT(*) FROM devices WHERE is_active = 1) as active_devices_count,
                  (SELECT COUNT(*) FROM drivers WHERE is_active = 1) as active_drivers_count,
                  (SELECT COUNT(*) FROM payment_receipts WHERE receipt_status = 'generated') as generated_receipts_count,
                  (SELECT COUNT(*) FROM payments WHERE receipt_status = 'pending') as pending_receipts_count,
                  
                  (SELECT COALESCE(SUM(total_amount), 0) 
                   FROM (
                     SELECT amount as total_amount FROM debt_records WHERE is_paid = 1 AND DATE(paid_at) = CURDATE()
                     UNION ALL
                     SELECT amount as total_amount FROM payments WHERE DATE(created_at) = CURDATE()
                   ) as daily_rev) as daily_revenue,
                   
                  (SELECT COALESCE(SUM(total_amount), 0) 
                   FROM (
                     SELECT amount as total_amount FROM debt_records WHERE is_paid = 1 AND WEEK(paid_at) = WEEK(NOW()) AND YEAR(paid_at) = YEAR(NOW())
                     UNION ALL
                     SELECT amount as total_amount FROM payments WHERE WEEK(created_at) = WEEK(NOW()) AND YEAR(created_at) = YEAR(NOW())
                   ) as weekly_rev) as weekly_revenue,
                   
                  (SELECT COALESCE(SUM(total_amount), 0) 
                   FROM (
                     SELECT amount as total_amount FROM debt_records WHERE is_paid = 1 AND MONTH(paid_at) = MONTH(NOW()) AND YEAR(paid_at) = YEAR(NOW())
                     UNION ALL
                     SELECT amount as total_amount FROM payments WHERE MONTH(created_at) = MONTH(NOW()) AND YEAR(created_at) = YEAR(NOW())
                   ) as monthly_rev) as monthly_revenue
            ");

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
    
    // Individual endpoint methods...
    public function getUnpaidDebtsCount()
    {
        $count = DB::table('debt_records')->where('is_paid', 0)->count();
        return response()->json(['success' => true, 'data' => ['count' => $count]]);
    }
    
    public function getActiveDevicesCount()
    {
        $count = DB::table('devices')->where('is_active', 1)->count();
        return response()->json(['success' => true, 'data' => ['count' => $count]]);
    }
    
    public function getActiveDriversCount()
    {
        $count = DB::table('drivers')->where('is_active', 1)->count();
        return response()->json(['success' => true, 'data' => ['count' => $count]]);
    }
    
    // ... other individual methods
}
```

## ✅ **Current Flutter App Status**

The Flutter app has been updated with:
- ✅ **Smart fallback logic** - tries new endpoints first, falls back to existing ones
- ✅ **Client-side filtering** - filters data when backend doesn't have new endpoints
- ✅ **Parallel loading** - all queries run simultaneously for performance
- ✅ **Error resilience** - graceful handling of missing endpoints or data

**The app will work immediately with existing endpoints and get even better performance once new endpoints are implemented!**