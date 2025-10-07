<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\Driver;
use App\Models\Device;
use App\Models\Transaction;
use App\Models\Receipt;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Carbon\Carbon;

class AdminDashboardController extends Controller
{
    /**
     * Display the admin dashboard
     */
    public function index()
    {
        // Get dashboard statistics
        $stats = $this->getDashboardStats();
        
        // Get recent transactions
        $recent_transactions = $this->getRecentTransactions();
        
        // Get recent activities
        $recent_activities = $this->getRecentActivities();
        
        return view('admin.dashboard', compact('stats', 'recent_transactions', 'recent_activities'));
    }
    
    /**
     * Get dashboard statistics
     */
    private function getDashboardStats()
    {
        $currentMonth = Carbon::now()->startOfMonth();
        $lastMonth = Carbon::now()->subMonth()->startOfMonth();
        
        // Total drivers
        $totalDrivers = User::where('role', 'driver')->count();
        $lastMonthDrivers = User::where('role', 'driver')
            ->where('created_at', '<', $currentMonth)
            ->count();
        $driversGrowth = $lastMonthDrivers > 0 ? 
            round((($totalDrivers - $lastMonthDrivers) / $lastMonthDrivers) * 100, 1) : 0;
        
        // Active vehicles (devices)
        $activeVehicles = Device::where('is_active', true)->count();
        $lastMonthActiveVehicles = Device::where('is_active', true)
            ->where('created_at', '<', $currentMonth)
            ->count();
        $vehiclesGrowth = $lastMonthActiveVehicles > 0 ? 
            round((($activeVehicles - $lastMonthActiveVehicles) / $lastMonthActiveVehicles) * 100, 1) : 0;
        
        // Monthly revenue (if transactions table exists)
        $monthlyRevenue = 0;
        $lastMonthRevenue = 0;
        $revenueGrowth = 0;
        
        if (DB::getSchemaBuilder()->hasTable('transactions')) {
            $monthlyRevenue = Transaction::whereMonth('created_at', Carbon::now()->month)
                ->whereYear('created_at', Carbon::now()->year)
                ->sum('amount') ?? 0;
                
            $lastMonthRevenue = Transaction::whereMonth('created_at', Carbon::now()->subMonth()->month)
                ->whereYear('created_at', Carbon::now()->subMonth()->year)
                ->sum('amount') ?? 0;
                
            $revenueGrowth = $lastMonthRevenue > 0 ? 
                round((($monthlyRevenue - $lastMonthRevenue) / $lastMonthRevenue) * 100, 1) : 0;
        }
        
        // Pending payments
        $pendingPayments = 0;
        if (DB::getSchemaBuilder()->hasTable('transactions')) {
            $pendingPayments = Transaction::where('status', 'pending')->count();
        }
        
        return [
            'total_drivers' => $totalDrivers,
            'drivers_growth' => $driversGrowth,
            'active_vehicles' => $activeVehicles,
            'vehicles_growth' => $vehiclesGrowth,
            'monthly_revenue' => $monthlyRevenue,
            'revenue_growth' => $revenueGrowth,
            'pending_payments' => $pendingPayments,
        ];
    }
    
    /**
     * Get recent transactions
     */
    private function getRecentTransactions()
    {
        $transactions = [];
        
        if (DB::getSchemaBuilder()->hasTable('transactions')) {
            $transactions = Transaction::with(['driver.user', 'device'])
                ->orderBy('created_at', 'desc')
                ->limit(10)
                ->get()
                ->map(function ($transaction) {
                    return [
                        'id' => $transaction->id,
                        'driver_name' => $transaction->driver->user->name ?? 'Unknown Driver',
                        'vehicle_number' => $transaction->device->device_number ?? 'Unknown Vehicle',
                        'amount' => $transaction->amount,
                        'date' => $transaction->created_at,
                        'status' => $transaction->status,
                    ];
                })
                ->toArray();
        }
        
        // If no transactions table or no data, return sample data
        if (empty($transactions)) {
            $transactions = [
                [
                    'id' => 'sample-1',
                    'driver_name' => 'John Mukasa',
                    'vehicle_number' => 'UBE 123A',
                    'amount' => 50000,
                    'date' => Carbon::now()->subHours(2),
                    'status' => 'paid',
                ],
                [
                    'id' => 'sample-2',
                    'driver_name' => 'Peter Ssali',
                    'vehicle_number' => 'UBF 456B',
                    'amount' => 45000,
                    'date' => Carbon::now()->subHours(6),
                    'status' => 'pending',
                ],
                [
                    'id' => 'sample-3',
                    'driver_name' => 'Mary Nakato',
                    'vehicle_number' => 'UBG 789C',
                    'amount' => 55000,
                    'date' => Carbon::now()->subDay(),
                    'status' => 'paid',
                ],
            ];
        }
        
        return $transactions;
    }
    
    /**
     * Get recent activities
     */
    private function getRecentActivities()
    {
        $activities = [];
        
        // Get recent user registrations
        $recentUsers = User::where('role', 'driver')
            ->orderBy('created_at', 'desc')
            ->limit(3)
            ->get();
            
        foreach ($recentUsers as $user) {
            $activities[] = [
                'title' => "New driver {$user->name} registered",
                'time' => $user->created_at->diffForHumans(),
                'type' => 'user_registration',
            ];
        }
        
        // Get recent device assignments
        $recentDevices = Device::whereNotNull('driver_id')
            ->orderBy('updated_at', 'desc')
            ->limit(2)
            ->get();
            
        foreach ($recentDevices as $device) {
            $driverName = $device->driver->user->name ?? 'Unknown Driver';
            $activities[] = [
                'title' => "Vehicle {$device->device_number} assigned to {$driverName}",
                'time' => $device->updated_at->diffForHumans(),
                'type' => 'device_assignment',
            ];
        }
        
        // Sort activities by time (most recent first)
        usort($activities, function ($a, $b) {
            return strtotime($b['time']) - strtotime($a['time']);
        });
        
        // If no activities, return sample data
        if (empty($activities)) {
            $activities = [
                [
                    'title' => 'New driver John Mukasa registered',
                    'time' => '2 hours ago',
                    'type' => 'user_registration',
                ],
                [
                    'title' => 'Payment received from Peter Ssali',
                    'time' => '4 hours ago',
                    'type' => 'payment_received',
                ],
                [
                    'title' => 'Vehicle UBG 789C assigned to Mary Nakato',
                    'time' => '6 hours ago',
                    'type' => 'device_assignment',
                ],
                [
                    'title' => 'Monthly report generated',
                    'time' => '1 day ago',
                    'type' => 'report_generated',
                ],
            ];
        }
        
        return array_slice($activities, 0, 5); // Return only top 5 activities
    }
    
    /**
     * Get dashboard data as JSON (for AJAX requests)
     */
    public function getData()
    {
        $stats = $this->getDashboardStats();
        $recent_transactions = $this->getRecentTransactions();
        $recent_activities = $this->getRecentActivities();
        
        return response()->json([
            'stats' => $stats,
            'recent_transactions' => $recent_transactions,
            'recent_activities' => $recent_activities,
        ]);
    }
    
    /**
     * Get revenue chart data
     */
    public function getRevenueChart(Request $request)
    {
        $days = $request->get('days', 30);
        $startDate = Carbon::now()->subDays($days);
        
        $chartData = [];
        
        if (DB::getSchemaBuilder()->hasTable('transactions')) {
            $transactions = Transaction::where('created_at', '>=', $startDate)
                ->where('status', 'paid')
                ->selectRaw('DATE(created_at) as date, SUM(amount) as total')
                ->groupBy('date')
                ->orderBy('date')
                ->get();
                
            foreach ($transactions as $transaction) {
                $chartData[] = [
                    'date' => $transaction->date,
                    'amount' => $transaction->total,
                ];
            }
        }
        
        // If no data, generate sample data
        if (empty($chartData)) {
            for ($i = $days - 1; $i >= 0; $i--) {
                $date = Carbon::now()->subDays($i);
                $chartData[] = [
                    'date' => $date->format('Y-m-d'),
                    'amount' => rand(30000, 80000), // Sample revenue data
                ];
            }
        }
        
        return response()->json($chartData);
    }
}