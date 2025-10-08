<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\Transaction;
use App\Models\Driver;
use App\Models\Device;
use App\Helpers\ResponseHelper;
use Illuminate\Http\Request;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;

class AdminReportController extends Controller
{
    /**
     * Get revenue report for admin dashboard
     */
    public function getRevenueReport(Request $request)
    {
        try {
            $startDate = $request->get('start_date', Carbon::now()->subDays(30)->format('Y-m-d'));
            $endDate = $request->get('end_date', Carbon::now()->format('Y-m-d'));
            
            // Parse dates
            $startDate = Carbon::parse($startDate)->startOfDay();
            $endDate = Carbon::parse($endDate)->endOfDay();

            // Get total revenue for the period
            $totalRevenue = Transaction::income()
                ->completed()
                ->whereBetween('transaction_date', [$startDate, $endDate])
                ->sum('amount');

            // Get transaction count
            $transactionCount = Transaction::income()
                ->completed()
                ->whereBetween('transaction_date', [$startDate, $endDate])
                ->count();

            // Calculate average per day
            $daysDifference = max(1, $startDate->diffInDays($endDate) + 1);
            $averagePerDay = $transactionCount > 0 ? round($totalRevenue / $daysDifference, 2) : 0;

            // Get breakdown by category
            $breakdown = Transaction::income()
                ->completed()
                ->whereBetween('transaction_date', [$startDate, $endDate])
                ->select('category', DB::raw('SUM(amount) as total'))
                ->groupBy('category')
                ->get()
                ->mapWithKeys(function ($item) {
                    $categoryName = Transaction::PAYMENT_CATEGORIES[$item->category] ?? $item->category;
                    return [$item->category => [
                        'name' => $categoryName,
                        'amount' => (float) $item->total
                    ]];
                });

            // Get daily data for the period (last 30 days max for performance)
            $dailyDataPeriod = min(30, $daysDifference);
            $dailyStartDate = Carbon::parse($endDate)->subDays($dailyDataPeriod - 1);
            
            $dailyData = [];
            for ($date = $dailyStartDate->copy(); $date <= $endDate; $date->addDay()) {
                $dayAmount = Transaction::income()
                    ->completed()
                    ->whereDate('transaction_date', $date->format('Y-m-d'))
                    ->sum('amount');
                
                $dailyData[] = [
                    'date' => $date->format('Y-m-d'),
                    'amount' => (float) $dayAmount
                ];
            }

            $data = [
                'total_revenue' => (float) $totalRevenue,
                'period_start' => $startDate->format('Y-m-d'),
                'period_end' => $endDate->format('Y-m-d'),
                'transaction_count' => $transactionCount,
                'average_per_day' => $averagePerDay,
                'breakdown' => $breakdown,
                'daily_data' => $dailyData
            ];

            return ResponseHelper::success($data, 'Revenue report generated successfully');

        } catch (\Exception $e) {
            \Log::error('Revenue report generation failed', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return ResponseHelper::error('Failed to generate revenue report: ' . $e->getMessage(), 500);
        }
    }

    /**
     * Get expense report for admin dashboard
     */
    public function getExpenseReport(Request $request)
    {
        try {
            $startDate = $request->get('start_date', Carbon::now()->subDays(30)->format('Y-m-d'));
            $endDate = $request->get('end_date', Carbon::now()->format('Y-m-d'));
            
            // Parse dates
            $startDate = Carbon::parse($startDate)->startOfDay();
            $endDate = Carbon::parse($endDate)->endOfDay();

            // Get total expenses for the period
            $totalExpenses = Transaction::expense()
                ->completed()
                ->whereBetween('transaction_date', [$startDate, $endDate])
                ->sum('amount');

            // Get transaction count
            $transactionCount = Transaction::expense()
                ->completed()
                ->whereBetween('transaction_date', [$startDate, $endDate])
                ->count();

            // Calculate average per day
            $daysDifference = max(1, $startDate->diffInDays($endDate) + 1);
            $averagePerDay = $transactionCount > 0 ? round($totalExpenses / $daysDifference, 2) : 0;

            // Get breakdown by category
            $breakdown = Transaction::expense()
                ->completed()
                ->whereBetween('transaction_date', [$startDate, $endDate])
                ->select('category', DB::raw('SUM(amount) as total'))
                ->groupBy('category')
                ->get()
                ->mapWithKeys(function ($item) {
                    $categoryName = Transaction::EXPENSE_CATEGORIES[$item->category] ?? $item->category;
                    return [$item->category => [
                        'name' => $categoryName,
                        'amount' => (float) $item->total
                    ]];
                });

            $data = [
                'total_expenses' => (float) $totalExpenses,
                'period_start' => $startDate->format('Y-m-d'),
                'period_end' => $endDate->format('Y-m-d'),
                'transaction_count' => $transactionCount,
                'average_per_day' => $averagePerDay,
                'breakdown' => $breakdown
            ];

            return ResponseHelper::success($data, 'Expense report generated successfully');

        } catch (\Exception $e) {
            \Log::error('Expense report generation failed', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return ResponseHelper::error('Failed to generate expense report: ' . $e->getMessage(), 500);
        }
    }

    /**
     * Get profit/loss report for admin dashboard
     */
    public function getProfitLossReport(Request $request)
    {
        try {
            $startDate = $request->get('start_date', Carbon::now()->subDays(30)->format('Y-m-d'));
            $endDate = $request->get('end_date', Carbon::now()->format('Y-m-d'));
            
            // Parse dates
            $startDate = Carbon::parse($startDate)->startOfDay();
            $endDate = Carbon::parse($endDate)->endOfDay();

            // Get total revenue
            $totalRevenue = Transaction::income()
                ->completed()
                ->whereBetween('transaction_date', [$startDate, $endDate])
                ->sum('amount');

            // Get total expenses
            $totalExpenses = Transaction::expense()
                ->completed()
                ->whereBetween('transaction_date', [$startDate, $endDate])
                ->sum('amount');

            // Calculate profit/loss
            $netProfit = $totalRevenue - $totalExpenses;
            $profitMargin = $totalRevenue > 0 ? round(($netProfit / $totalRevenue) * 100, 2) : 0;

            $data = [
                'total_revenue' => (float) $totalRevenue,
                'total_expenses' => (float) $totalExpenses,
                'net_profit' => (float) $netProfit,
                'profit_margin' => $profitMargin,
                'period_start' => $startDate->format('Y-m-d'),
                'period_end' => $endDate->format('Y-m-d'),
            ];

            return ResponseHelper::success($data, 'Profit/Loss report generated successfully');

        } catch (\Exception $e) {
            \Log::error('Profit/Loss report generation failed', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return ResponseHelper::error('Failed to generate profit/loss report: ' . $e->getMessage(), 500);
        }
    }

    /**
     * Get device performance report
     */
    public function getDevicePerformanceReport(Request $request)
    {
        try {
            $startDate = $request->get('start_date', Carbon::now()->subDays(30)->format('Y-m-d'));
            $endDate = $request->get('end_date', Carbon::now()->format('Y-m-d'));
            
            // Parse dates
            $startDate = Carbon::parse($startDate)->startOfDay();
            $endDate = Carbon::parse($endDate)->endOfDay();

            // Get device performance data
            $devices = Device::with(['driver.user'])
                ->whereHas('transactions', function ($query) use ($startDate, $endDate) {
                    $query->income()
                        ->completed()
                        ->whereBetween('transaction_date', [$startDate, $endDate]);
                })
                ->get()
                ->map(function ($device) use ($startDate, $endDate) {
                    $revenue = Transaction::where('device_id', $device->id)
                        ->income()
                        ->completed()
                        ->whereBetween('transaction_date', [$startDate, $endDate])
                        ->sum('amount');
                    
                    $trips = Transaction::where('device_id', $device->id)
                        ->income()
                        ->completed()
                        ->whereBetween('transaction_date', [$startDate, $endDate])
                        ->count();

                    return [
                        'id' => $device->id,
                        'name' => $device->name,
                        'plate_number' => $device->plate_number,
                        'driver_name' => $device->driver->user->name ?? 'No Driver',
                        'revenue' => (float) $revenue,
                        'trips' => $trips,
                        'average_per_trip' => $trips > 0 ? round($revenue / $trips, 2) : 0
                    ];
                })
                ->sortByDesc('revenue')
                ->values();

            $topPerformer = $devices->first();

            $data = [
                'devices' => $devices,
                'top_performer' => $topPerformer ? $topPerformer['name'] : null,
                'period_start' => $startDate->format('Y-m-d'),
                'period_end' => $endDate->format('Y-m-d'),
            ];

            return ResponseHelper::success($data, 'Device performance report generated successfully');

        } catch (\Exception $e) {
            \Log::error('Device performance report generation failed', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return ResponseHelper::error('Failed to generate device performance report: ' . $e->getMessage(), 500);
        }
    }

    /**
     * Get dashboard summary report
     */
    public function getDashboardReport(Request $request)
    {
        try {
            // Get current month data
            $currentMonth = Carbon::now();
            $startOfMonth = $currentMonth->copy()->startOfMonth();
            $endOfMonth = $currentMonth->copy()->endOfMonth();

            // Revenue data
            $monthlyRevenue = Transaction::income()
                ->completed()
                ->whereBetween('transaction_date', [$startOfMonth, $endOfMonth])
                ->sum('amount');

            $weeklyRevenue = Transaction::income()
                ->completed()
                ->thisWeek()
                ->sum('amount');

            $dailyRevenue = Transaction::income()
                ->completed()
                ->today()
                ->sum('amount');

            // Expense data
            $monthlyExpenses = Transaction::expense()
                ->completed()
                ->whereBetween('transaction_date', [$startOfMonth, $endOfMonth])
                ->sum('amount');

            // Calculate profit
            $netProfit = $monthlyRevenue - $monthlyExpenses;

            // Driver and device counts
            $totalDrivers = Driver::count();
            $activeDrivers = Driver::whereHas('transactions', function ($query) {
                $query->where('transaction_date', '>=', Carbon::now()->subDays(7));
            })->count();

            $totalVehicles = Device::count();
            $activeVehicles = Device::whereHas('transactions', function ($query) {
                $query->where('transaction_date', '>=', Carbon::now()->subDays(7));
            })->count();

            // Pending payments
            $pendingPayments = Transaction::pending()->count();

            // Calculate averages
            $daysInMonth = $startOfMonth->diffInDays($endOfMonth) + 1;
            $averagePerDay = $daysInMonth > 0 ? round($monthlyRevenue / $daysInMonth, 2) : 0;

            $data = [
                'total_revenue' => (float) $monthlyRevenue,
                'total_expenses' => (float) $monthlyExpenses,
                'net_profit' => (float) $netProfit,
                'monthly_revenue' => (float) $monthlyRevenue,
                'weekly_revenue' => (float) $weeklyRevenue,
                'daily_revenue' => (float) $dailyRevenue,
                'average_per_day' => $averagePerDay,
                'active_drivers' => $activeDrivers,
                'total_drivers' => $totalDrivers,
                'active_vehicles' => $activeVehicles,
                'total_vehicles' => $totalVehicles,
                'pending_payments' => $pendingPayments,
                'vehicle_count' => $totalVehicles, // For compatibility with Flutter
                'transaction_count' => Transaction::completed()
                    ->whereBetween('transaction_date', [$startOfMonth, $endOfMonth])
                    ->count(),
            ];

            return ResponseHelper::success($data, 'Dashboard report generated successfully');

        } catch (\Exception $e) {
            \Log::error('Dashboard report generation failed', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return ResponseHelper::error('Failed to generate dashboard report: ' . $e->getMessage(), 500);
        }
    }

    /**
     * Get comprehensive analytics overview for mobile app
     */
    public function getAnalyticsOverview(Request $request)
    {
        try {
            $period = $request->get('period', '30'); // days
            $endDate = Carbon::now();
            $startDate = Carbon::now()->subDays($period);
            
            // Get key metrics
            $totalRevenue = Transaction::income()->completed()
                ->whereBetween('transaction_date', [$startDate, $endDate])
                ->sum('amount');
                
            $totalExpenses = Transaction::expense()->completed()
                ->whereBetween('transaction_date', [$startDate, $endDate])
                ->sum('amount');
                
            $netProfit = $totalRevenue - $totalExpenses;
            $profitMargin = $totalRevenue > 0 ? round(($netProfit / $totalRevenue) * 100, 2) : 0;
            
            // Get growth rates
            $previousPeriodStart = Carbon::now()->subDays($period * 2);
            $previousPeriodEnd = Carbon::now()->subDays($period);
            
            $previousRevenue = Transaction::income()->completed()
                ->whereBetween('transaction_date', [$previousPeriodStart, $previousPeriodEnd])
                ->sum('amount');
                
            $revenueGrowth = $previousRevenue > 0 ? 
                round((($totalRevenue - $previousRevenue) / $previousRevenue) * 100, 2) : 0;
            
            // Transaction trends
            $transactionCount = Transaction::completed()
                ->whereBetween('transaction_date', [$startDate, $endDate])
                ->count();
                
            $averageTransactionValue = $transactionCount > 0 ? 
                round($totalRevenue / $transactionCount, 2) : 0;
            
            // Active metrics
            $activeDrivers = Driver::whereHas('transactions', function ($query) use ($startDate) {
                $query->where('transaction_date', '>=', $startDate);
            })->count();
            
            $activeVehicles = Device::whereHas('transactions', function ($query) use ($startDate) {
                $query->where('transaction_date', '>=', $startDate);
            })->count();
            
            // Daily trends for chart
            $dailyTrends = [];
            for ($date = $startDate->copy(); $date <= $endDate; $date->addDay()) {
                $dayRevenue = Transaction::income()->completed()
                    ->whereDate('transaction_date', $date->format('Y-m-d'))
                    ->sum('amount');
                    
                $dayExpenses = Transaction::expense()->completed()
                    ->whereDate('transaction_date', $date->format('Y-m-d'))
                    ->sum('amount');
                    
                $dailyTrends[] = [
                    'date' => $date->format('Y-m-d'),
                    'day_name' => $date->format('l'),
                    'revenue' => (float) $dayRevenue,
                    'expenses' => (float) $dayExpenses,
                    'profit' => (float) ($dayRevenue - $dayExpenses),
                    'transactions' => Transaction::completed()
                        ->whereDate('transaction_date', $date->format('Y-m-d'))
                        ->count()
                ];
            }
            
            $data = [
                'overview' => [
                    'total_revenue' => (float) $totalRevenue,
                    'total_expenses' => (float) $totalExpenses,
                    'net_profit' => (float) $netProfit,
                    'profit_margin' => $profitMargin,
                    'revenue_growth' => $revenueGrowth,
                    'transaction_count' => $transactionCount,
                    'average_transaction_value' => $averageTransactionValue,
                    'active_drivers' => $activeDrivers,
                    'active_vehicles' => $activeVehicles,
                    'period_days' => (int) $period
                ],
                'trends' => [
                    'daily' => $dailyTrends
                ],
                'generated_at' => Carbon::now()->toISOString(),
                'period_start' => $startDate->format('Y-m-d'),
                'period_end' => $endDate->format('Y-m-d')
            ];
            
            return ResponseHelper::success($data, 'Analytics overview retrieved successfully');
            
        } catch (\Exception $e) {
            \Log::error('Analytics overview failed', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return ResponseHelper::error('Failed to generate analytics overview: ' . $e->getMessage(), 500);
        }
    }
    
    /**
     * Get top performing metrics for mobile dashboard
     */
    public function getTopPerformers(Request $request)
    {
        try {
            $period = $request->get('period', '30');
            $startDate = Carbon::now()->subDays($period);
            $endDate = Carbon::now();
            
            // Top performing drivers
            $topDrivers = Driver::with(['user', 'transactions' => function($query) use ($startDate, $endDate) {
                $query->income()->completed()
                      ->whereBetween('transaction_date', [$startDate, $endDate]);
            }])
            ->whereHas('transactions', function($query) use ($startDate, $endDate) {
                $query->income()->completed()
                      ->whereBetween('transaction_date', [$startDate, $endDate]);
            })
            ->get()
            ->map(function($driver) {
                $revenue = $driver->transactions->sum('amount');
                $trips = $driver->transactions->count();
                return [
                    'id' => $driver->id,
                    'name' => $driver->user->name ?? 'Unknown',
                    'phone' => $driver->user->phone_number ?? '',
                    'revenue' => (float) $revenue,
                    'trips' => $trips,
                    'average_per_trip' => $trips > 0 ? round($revenue / $trips, 2) : 0,
                    'license_number' => $driver->license_number
                ];
            })
            ->sortByDesc('revenue')
            ->take(10)
            ->values();
            
            // Top performing vehicles
            $topVehicles = Device::with(['driver.user', 'transactions' => function($query) use ($startDate, $endDate) {
                $query->income()->completed()
                      ->whereBetween('transaction_date', [$startDate, $endDate]);
            }])
            ->whereHas('transactions', function($query) use ($startDate, $endDate) {
                $query->income()->completed()
                      ->whereBetween('transaction_date', [$startDate, $endDate]);
            })
            ->get()
            ->map(function($device) {
                $revenue = $device->transactions->sum('amount');
                $trips = $device->transactions->count();
                return [
                    'id' => $device->id,
                    'name' => $device->name,
                    'plate_number' => $device->plate_number,
                    'driver_name' => $device->driver->user->name ?? 'Unassigned',
                    'revenue' => (float) $revenue,
                    'trips' => $trips,
                    'average_per_trip' => $trips > 0 ? round($revenue / $trips, 2) : 0,
                    'device_type' => $device->device_type ?? 'Vehicle'
                ];
            })
            ->sortByDesc('revenue')
            ->take(10)
            ->values();
            
            // Revenue by category
            $revenueByCategory = Transaction::income()->completed()
                ->whereBetween('transaction_date', [$startDate, $endDate])
                ->select('category', DB::raw('SUM(amount) as total'), DB::raw('COUNT(*) as count'))
                ->groupBy('category')
                ->get()
                ->map(function($item) {
                    return [
                        'category' => $item->category,
                        'category_name' => Transaction::PAYMENT_CATEGORIES[$item->category] ?? $item->category,
                        'total' => (float) $item->total,
                        'count' => $item->count,
                        'percentage' => 0 // Will be calculated after getting totals
                    ];
                });
                
            $totalRevenue = $revenueByCategory->sum('total');
            $revenueByCategory = $revenueByCategory->map(function($item) use ($totalRevenue) {
                $item['percentage'] = $totalRevenue > 0 ? round(($item['total'] / $totalRevenue) * 100, 2) : 0;
                return $item;
            })->sortByDesc('total')->values();
            
            $data = [
                'top_drivers' => $topDrivers,
                'top_vehicles' => $topVehicles,
                'revenue_by_category' => $revenueByCategory,
                'period_start' => $startDate->format('Y-m-d'),
                'period_end' => $endDate->format('Y-m-d'),
                'generated_at' => Carbon::now()->toISOString()
            ];
            
            return ResponseHelper::success($data, 'Top performers data retrieved successfully');
            
        } catch (\Exception $e) {
            \Log::error('Top performers data failed', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return ResponseHelper::error('Failed to get top performers data: ' . $e->getMessage(), 500);
        }
    }
    
    /**
     * Get real-time analytics for live dashboard
     */
    public function getLiveAnalytics(Request $request)
    {
        try {
            $now = Carbon::now();
            $todayStart = $now->copy()->startOfDay();
            $weekStart = $now->copy()->startOfWeek();
            $monthStart = $now->copy()->startOfMonth();
            
            // Today's stats
            $todayRevenue = Transaction::income()->completed()
                ->whereBetween('transaction_date', [$todayStart, $now])
                ->sum('amount');
                
            $todayTransactions = Transaction::completed()
                ->whereBetween('transaction_date', [$todayStart, $now])
                ->count();
                
            // This week stats
            $weekRevenue = Transaction::income()->completed()
                ->whereBetween('transaction_date', [$weekStart, $now])
                ->sum('amount');
                
            // This month stats  
            $monthRevenue = Transaction::income()->completed()
                ->whereBetween('transaction_date', [$monthStart, $now])
                ->sum('amount');
                
            // Recent transactions (last 20)
            $recentTransactions = Transaction::with(['driver.user', 'device'])
                ->completed()
                ->orderBy('transaction_date', 'desc')
                ->limit(20)
                ->get()
                ->map(function($transaction) {
                    return [
                        'id' => $transaction->id,
                        'amount' => (float) $transaction->amount,
                        'type' => $transaction->type,
                        'category' => $transaction->category,
                        'category_name' => $transaction->type === 'income' ? 
                            (Transaction::PAYMENT_CATEGORIES[$transaction->category] ?? $transaction->category) :
                            (Transaction::EXPENSE_CATEGORIES[$transaction->category] ?? $transaction->category),
                        'driver_name' => $transaction->driver->user->name ?? 'N/A',
                        'device_name' => $transaction->device->name ?? 'N/A',
                        'date' => $transaction->transaction_date->toISOString(),
                        'formatted_date' => $transaction->transaction_date->format('M j, Y H:i'),
                        'payment_method' => $transaction->payment_method,
                        'reference_number' => $transaction->reference_number
                    ];
                });
                
            // Active drivers and vehicles count
            $activeDriversToday = Driver::whereHas('transactions', function($query) use ($todayStart) {
                $query->where('transaction_date', '>=', $todayStart);
            })->count();
            
            $activeVehiclesToday = Device::whereHas('transactions', function($query) use ($todayStart) {
                $query->where('transaction_date', '>=', $todayStart);
            })->count();
            
            // Hourly revenue for today (for mini chart)
            $hourlyRevenue = [];
            for ($hour = 0; $hour < 24; $hour++) {
                $hourStart = $todayStart->copy()->addHours($hour);
                $hourEnd = $hourStart->copy()->addHour();
                
                if ($hourEnd <= $now) {
                    $revenue = Transaction::income()->completed()
                        ->whereBetween('transaction_date', [$hourStart, $hourEnd])
                        ->sum('amount');
                } else {
                    $revenue = Transaction::income()->completed()
                        ->whereBetween('transaction_date', [$hourStart, $now])
                        ->sum('amount');
                }
                
                $hourlyRevenue[] = [
                    'hour' => $hour,
                    'hour_formatted' => $hourStart->format('H:i'),
                    'revenue' => (float) $revenue
                ];
            }
            
            $data = [
                'live_stats' => [
                    'today_revenue' => (float) $todayRevenue,
                    'today_transactions' => $todayTransactions,
                    'week_revenue' => (float) $weekRevenue,
                    'month_revenue' => (float) $monthRevenue,
                    'active_drivers_today' => $activeDriversToday,
                    'active_vehicles_today' => $activeVehiclesToday,
                    'average_per_transaction_today' => $todayTransactions > 0 ? 
                        round($todayRevenue / $todayTransactions, 2) : 0
                ],
                'recent_transactions' => $recentTransactions,
                'hourly_revenue' => $hourlyRevenue,
                'last_updated' => $now->toISOString()
            ];
            
            return ResponseHelper::success($data, 'Live analytics retrieved successfully');
            
        } catch (\Exception $e) {
            \Log::error('Live analytics failed', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return ResponseHelper::error('Failed to get live analytics: ' . $e->getMessage(), 500);
        }
    }

    /**
     * Export report to PDF (placeholder)
     */
    public function exportToPdf(Request $request)
    {
        try {
            $reportType = $request->get('report_type', 'revenue');
            $startDate = $request->get('start_date', Carbon::now()->subDays(30)->format('Y-m-d'));
            $endDate = $request->get('end_date', Carbon::now()->format('Y-m-d'));
            
            // For now, return a success response
            // In future, implement actual PDF generation using packages like DomPDF or TCPDF
            
            $data = [
                'message' => "PDF report for {$reportType} generated successfully",
                'report_type' => $reportType,
                'date_range' => "{$startDate} to {$endDate}",
                'pdf_url' => '/storage/reports/report_' . time() . '.pdf', // Placeholder
                'generated_at' => Carbon::now()->toISOString()
            ];

            return ResponseHelper::success($data, 'PDF report generated successfully');

        } catch (\Exception $e) {
            \Log::error('PDF export failed', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return ResponseHelper::error('Failed to generate PDF report: ' . $e->getMessage(), 500);
        }
    }
}