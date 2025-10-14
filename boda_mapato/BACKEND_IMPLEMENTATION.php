<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Carbon\Carbon;

class DashboardController extends Controller
{
    /**
     * Get comprehensive dashboard data with exact database table filtering
     * 
     * @return \Illuminate\Http\JsonResponse
     */
    public function getComprehensiveData()
    {
        try {
            // Execute all queries in a single database call for optimal performance
            $data = DB::selectOne("
                SELECT 
                    -- Malipo yasiyolipwa: debt_records WHERE is_paid = 0
                    (SELECT COUNT(*) FROM debt_records WHERE is_paid = 0) as unpaid_debts_count,
                    
                    -- Vyombo vya usafiri: devices WHERE is_active = 1
                    (SELECT COUNT(*) FROM devices WHERE is_active = 1) as active_devices_count,
                    
                    -- Madereva hai: drivers WHERE is_active = 1
                    (SELECT COUNT(*) FROM drivers WHERE is_active = 1) as active_drivers_count,
                    
                    -- Malipo yenye risiti: payment_receipts WHERE receipt_status = 'generated'
                    (SELECT COUNT(*) FROM payment_receipts WHERE receipt_status = 'generated') as generated_receipts_count,
                    
                    -- Yamelipwa bado risiti: payments WHERE receipt_status = 'pending'
                    (SELECT COUNT(*) FROM payments WHERE receipt_status = 'pending') as pending_receipts_count,
                    
                    -- Mapato ya siku: debt_records (is_paid=1) + payments for today
                    (SELECT COALESCE(SUM(total_amount), 0) 
                     FROM (
                         SELECT amount as total_amount 
                         FROM debt_records 
                         WHERE is_paid = 1 AND DATE(paid_at) = CURDATE()
                         UNION ALL
                         SELECT amount as total_amount 
                         FROM payments 
                         WHERE DATE(created_at) = CURDATE()
                     ) as daily_rev) as daily_revenue,
                     
                    -- Mapato ya wiki: debt_records (is_paid=1) + payments for current week
                    (SELECT COALESCE(SUM(total_amount), 0) 
                     FROM (
                         SELECT amount as total_amount 
                         FROM debt_records 
                         WHERE is_paid = 1 
                           AND WEEK(paid_at, 1) = WEEK(NOW(), 1) 
                           AND YEAR(paid_at) = YEAR(NOW())
                         UNION ALL
                         SELECT amount as total_amount 
                         FROM payments 
                         WHERE WEEK(created_at, 1) = WEEK(NOW(), 1) 
                           AND YEAR(created_at) = YEAR(NOW())
                     ) as weekly_rev) as weekly_revenue,
                     
                    -- Mapato ya mwezi: debt_records (is_paid=1) + payments for current month
                    (SELECT COALESCE(SUM(total_amount), 0) 
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
                     ) as monthly_rev) as monthly_revenue
            ");

            return response()->json([
                'success' => true,
                'data' => $data
            ]);
            
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to load comprehensive dashboard data',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Get unpaid debts count from debt_records table WHERE is_paid = 0
     */
    public function getUnpaidDebtsCount()
    {
        try {
            $count = DB::table('debt_records')->where('is_paid', 0)->count();
            
            return response()->json([
                'success' => true,
                'data' => [
                    'count' => $count
                ]
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to load unpaid debts count',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Get active devices count from devices table WHERE is_active = 1
     */
    public function getActiveDevicesCount()
    {
        try {
            $count = DB::table('devices')->where('is_active', 1)->count();
            
            return response()->json([
                'success' => true,
                'data' => [
                    'count' => $count
                ]
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to load active devices count',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Get active drivers count from drivers table WHERE is_active = 1
     */
    public function getActiveDriversCount()
    {
        try {
            $count = DB::table('drivers')->where('is_active', 1)->count();
            
            return response()->json([
                'success' => true,
                'data' => [
                    'count' => $count
                ]
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to load active drivers count',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Get generated receipts count from payment_receipts table WHERE receipt_status = 'generated'
     */
    public function getGeneratedReceiptsCount()
    {
        try {
            $count = DB::table('payment_receipts')->where('receipt_status', 'generated')->count();
            
            return response()->json([
                'success' => true,
                'data' => [
                    'count' => $count
                ]
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to load generated receipts count',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Get pending receipts count from payments table WHERE receipt_status = 'pending'
     */
    public function getPendingReceiptsCount()
    {
        try {
            $count = DB::table('payments')->where('receipt_status', 'pending')->count();
            
            return response()->json([
                'success' => true,
                'data' => [
                    'count' => $count
                ]
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to load pending receipts count',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Get daily revenue from debt_records (is_paid=1) + payments tables for today
     */
    public function getDailyRevenue()
    {
        try {
            $revenue = DB::selectOne("
                SELECT COALESCE(SUM(total_amount), 0) as revenue
                FROM (
                    SELECT amount as total_amount 
                    FROM debt_records 
                    WHERE is_paid = 1 AND DATE(paid_at) = CURDATE()
                    UNION ALL
                    SELECT amount as total_amount 
                    FROM payments 
                    WHERE DATE(created_at) = CURDATE()
                ) as daily_revenue
            ");
            
            return response()->json([
                'success' => true,
                'data' => [
                    'revenue' => (float) $revenue->revenue
                ]
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to load daily revenue',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Get weekly revenue from debt_records (is_paid=1) + payments tables for current week
     */
    public function getWeeklyRevenue()
    {
        try {
            $revenue = DB::selectOne("
                SELECT COALESCE(SUM(total_amount), 0) as revenue
                FROM (
                    SELECT amount as total_amount 
                    FROM debt_records 
                    WHERE is_paid = 1 
                      AND WEEK(paid_at, 1) = WEEK(NOW(), 1) 
                      AND YEAR(paid_at) = YEAR(NOW())
                    UNION ALL
                    SELECT amount as total_amount 
                    FROM payments 
                    WHERE WEEK(created_at, 1) = WEEK(NOW(), 1) 
                      AND YEAR(created_at) = YEAR(NOW())
                ) as weekly_revenue
            ");
            
            return response()->json([
                'success' => true,
                'data' => [
                    'revenue' => (float) $revenue->revenue
                ]
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to load weekly revenue',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Get monthly revenue from debt_records (is_paid=1) + payments tables for current month
     */
    public function getMonthlyRevenue()
    {
        try {
            $revenue = DB::selectOne("
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
                ) as monthly_revenue
            ");
            
            return response()->json([
                'success' => true,
                'data' => [
                    'revenue' => (float) $revenue->revenue
                ]
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to load monthly revenue',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Get existing dashboard data (for compatibility)
     */
    public function getDashboardData()
    {
        try {
            // Return comprehensive data using the main method
            return $this->getComprehensiveData();
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to load dashboard data',
                'error' => $e->getMessage()
            ], 500);
        }
    }
}