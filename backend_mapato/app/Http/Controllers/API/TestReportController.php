<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Services\ReportService;
use App\Models\Driver;
use App\Models\User;
use App\Models\Device;
use App\Models\Transaction;
use App\Helpers\ResponseHelper;
use Illuminate\Http\Request;
use Carbon\Carbon;

class TestReportController extends Controller
{
    protected $reportService;

    public function __construct(ReportService $reportService)
    {
        $this->reportService = $reportService;
    }

    /**
     * Test report generation with sample data
     */
    public function testReports(Request $request)
    {
        try {
            // Create or get a test driver
            $testDriver = $this->getOrCreateTestDriver();
            
            if (!$testDriver) {
                return ResponseHelper::error('Imeshindwa kutengeneza dereva wa majaribio', 500);
            }

            // Create sample transactions if none exist
            $this->createSampleTransactions($testDriver);

            // Generate test reports
            $startDate = Carbon::now()->subDays(30)->format('Y-m-d');
            $endDate = Carbon::now()->format('Y-m-d');

            $reports = [
                'revenue_report' => $this->reportService->generateRevenueReport(
                    $testDriver, 
                    $startDate, 
                    $endDate
                ),
                'expense_report' => $this->reportService->generateExpenseReport(
                    $testDriver, 
                    $startDate, 
                    $endDate
                ),
                'profit_loss_report' => $this->reportService->generateProfitLossReport(
                    $testDriver, 
                    $startDate, 
                    $endDate
                ),
                'daily_summary' => $this->reportService->generateDailySummary(
                    $testDriver, 
                    Carbon::now()->format('Y-m-d')
                ),
                'dashboard' => $this->reportService->getReportDashboard($testDriver),
            ];

            return ResponseHelper::success($reports, 'Ripoti za majaribio zimetengenezwa kikamilifu');

        } catch (\Exception $e) {
            \Log::error('Test report generation failed', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return ResponseHelper::error('Imeshindwa kutengeneza ripoti za majaribio: ' . $e->getMessage(), 500);
        }
    }

    /**
     * Get or create a test driver
     */
    private function getOrCreateTestDriver(): ?Driver
    {
        // Try to find existing test driver
        $testUser = User::where('phone', 'test_driver_255123456789')->first();
        
        if ($testUser && $testUser->driver) {
            return $testUser->driver;
        }

        // Create test user and driver
        try {
            $testUser = User::create([
                'name' => 'Dereva wa Majaribio',
                'phone' => 'test_driver_255123456789',
                'role' => 'driver',
                'is_active' => true,
            ]);

            $testDriver = Driver::create([
                'user_id' => $testUser->id,
                'license_number' => 'TEST123456',
                'license_expiry' => Carbon::now()->addYears(2),
                'address' => 'Dar es Salaam',
                'emergency_contact' => '255987654321',
                'is_active' => true,
                'national_id' => 'TEST123456789',
            ]);

            // Create test device
            Device::create([
                'driver_id' => $testDriver->id,
                'name' => 'Bajaji ya Majaribio',
                'type' => 'bajaji',
                'plate_number' => 'TEST001',
                'description' => 'Bajaji ya majaribio kwa ripoti',
                'is_active' => true,
                'purchase_date' => Carbon::now()->subYear(),
                'purchase_price' => 2500000,
            ]);

            return $testDriver;

        } catch (\Exception $e) {
            \Log::error('Failed to create test driver', [
                'error' => $e->getMessage()
            ]);
            return null;
        }
    }

    /**
     * Create sample transactions for testing
     */
    private function createSampleTransactions(Driver $driver): void
    {
        $device = $driver->devices()->first();
        
        if (!$device) {
            return;
        }

        // Check if transactions already exist
        $existingTransactions = $driver->transactions()->count();
        
        if ($existingTransactions > 0) {
            return; // Don't create duplicates
        }

        // Create sample income transactions
        $incomeCategories = array_keys(Transaction::PAYMENT_CATEGORIES);
        $expenseCategories = array_keys(Transaction::EXPENSE_CATEGORIES);
        $paymentMethods = array_keys(Transaction::PAYMENT_METHODS);

        // Create transactions for the last 30 days
        for ($i = 0; $i < 30; $i++) {
            $date = Carbon::now()->subDays($i);
            
            // Create 1-3 income transactions per day
            $incomeCount = rand(1, 3);
            for ($j = 0; $j < $incomeCount; $j++) {
                Transaction::create([
                    'driver_id' => $driver->id,
                    'device_id' => $device->id,
                    'amount' => rand(5000, 50000), // 5,000 to 50,000 TSh
                    'type' => 'income',
                    'category' => $incomeCategories[array_rand($incomeCategories)],
                    'description' => 'Malipo ya safari ' . ($j + 1),
                    'customer_name' => 'Mteja ' . rand(1, 100),
                    'customer_phone' => '255' . rand(700000000, 799999999),
                    'status' => 'completed',
                    'transaction_date' => $date->copy()->addHours(rand(6, 20)),
                    'payment_method' => $paymentMethods[array_rand($paymentMethods)],
                ]);
            }

            // Create 0-2 expense transactions per day
            $expenseCount = rand(0, 2);
            for ($j = 0; $j < $expenseCount; $j++) {
                Transaction::create([
                    'driver_id' => $driver->id,
                    'device_id' => $device->id,
                    'amount' => rand(2000, 20000), // 2,000 to 20,000 TSh
                    'type' => 'expense',
                    'category' => $expenseCategories[array_rand($expenseCategories)],
                    'description' => 'Gharama ya ' . ($j + 1),
                    'status' => 'completed',
                    'transaction_date' => $date->copy()->addHours(rand(6, 20)),
                    'payment_method' => $paymentMethods[array_rand($paymentMethods)],
                ]);
            }
        }
    }

    /**
     * Clean up test data
     */
    public function cleanupTestData(Request $request)
    {
        try {
            $testUser = User::where('phone', 'test_driver_255123456789')->first();
            
            if ($testUser) {
                // Delete related data
                if ($testUser->driver) {
                    // Delete transactions
                    Transaction::where('driver_id', $testUser->driver->id)->delete();
                    
                    // Delete devices
                    Device::where('driver_id', $testUser->driver->id)->delete();
                    
                    // Delete driver
                    $testUser->driver->delete();
                }
                
                // Delete user
                $testUser->delete();
            }

            return ResponseHelper::success(null, 'Data za majaribio zimefutwa kikamilifu');

        } catch (\Exception $e) {
            return ResponseHelper::error('Imeshindwa kufuta data za majaribio: ' . $e->getMessage(), 500);
        }
    }

    /**
     * Get test data status
     */
    public function getTestDataStatus(Request $request)
    {
        try {
            $testUser = User::where('phone', 'test_driver_255123456789')->first();
            
            if (!$testUser || !$testUser->driver) {
                return ResponseHelper::success([
                    'test_data_exists' => false,
                    'message' => 'Hakuna data za majaribio'
                ]);
            }

            $driver = $testUser->driver;
            $transactionCount = $driver->transactions()->count();
            $deviceCount = $driver->devices()->count();

            return ResponseHelper::success([
                'test_data_exists' => true,
                'driver_name' => $testUser->name,
                'transaction_count' => $transactionCount,
                'device_count' => $deviceCount,
                'total_income' => $driver->incomeTransactions()->sum('amount'),
                'total_expenses' => $driver->expenseTransactions()->sum('amount'),
            ], 'Hali ya data za majaribio');

        } catch (\Exception $e) {
            return ResponseHelper::error('Imeshindwa kupata hali ya data za majaribio: ' . $e->getMessage(), 500);
        }
    }
    
    /**
     * Test revenue report endpoint
     */
    public function testRevenueReport(Request $request)
    {
        try {
            $testDriver = $this->getOrCreateTestDriver();
            
            if (!$testDriver) {
                return ResponseHelper::error('Imeshindwa kutengeneza dereva wa majaribio', 500);
            }

            $this->createSampleTransactions($testDriver);

            $startDate = $request->get('start_date', Carbon::now()->subDays(30)->format('Y-m-d'));
            $endDate = $request->get('end_date', Carbon::now()->format('Y-m-d'));
            $deviceId = $request->get('device_id');
            $groupBy = $request->get('group_by', 'day');

            $report = $this->reportService->generateRevenueReport(
                $testDriver,
                $startDate,
                $endDate,
                $deviceId,
                $groupBy
            );

            return ResponseHelper::success($report, 'Ripoti ya mapato imetengenezwa kikamilifu');

        } catch (\Exception $e) {
            \Log::error('Test revenue report failed', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return ResponseHelper::error('Imeshindwa kutengeneza ripoti ya mapato: ' . $e->getMessage(), 500);
        }
    }
    
    /**
     * Test expense report endpoint
     */
    public function testExpenseReport(Request $request)
    {
        try {
            $testDriver = $this->getOrCreateTestDriver();
            
            if (!$testDriver) {
                return ResponseHelper::error('Imeshindwa kutengeneza dereva wa majaribio', 500);
            }

            $this->createSampleTransactions($testDriver);

            $startDate = $request->get('start_date', Carbon::now()->subDays(30)->format('Y-m-d'));
            $endDate = $request->get('end_date', Carbon::now()->format('Y-m-d'));
            $deviceId = $request->get('device_id');
            $category = $request->get('category');

            $report = $this->reportService->generateExpenseReport(
                $testDriver,
                $startDate,
                $endDate,
                $deviceId,
                $category
            );

            return ResponseHelper::success($report, 'Ripoti ya matumizi imetengenezwa kikamilifu');

        } catch (\Exception $e) {
            \Log::error('Test expense report failed', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return ResponseHelper::error('Imeshindwa kutengeneza ripoti ya matumizi: ' . $e->getMessage(), 500);
        }
    }
    
    /**
     * Test profit/loss report endpoint
     */
    public function testProfitLossReport(Request $request)
    {
        try {
            $testDriver = $this->getOrCreateTestDriver();
            
            if (!$testDriver) {
                return ResponseHelper::error('Imeshindwa kutengeneza dereva wa majaribio', 500);
            }

            $this->createSampleTransactions($testDriver);

            $startDate = $request->get('start_date', Carbon::now()->subDays(30)->format('Y-m-d'));
            $endDate = $request->get('end_date', Carbon::now()->format('Y-m-d'));
            $deviceId = $request->get('device_id');

            $report = $this->reportService->generateProfitLossReport(
                $testDriver,
                $startDate,
                $endDate,
                $deviceId
            );

            return ResponseHelper::success($report, 'Ripoti ya faida na hasara imetengenezwa kikamilifu');

        } catch (\Exception $e) {
            \Log::error('Test profit/loss report failed', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return ResponseHelper::error('Imeshindwa kutengeneza ripoti ya faida na hasara: ' . $e->getMessage(), 500);
        }
    }
    
    /**
     * Test device performance report endpoint
     */
    public function testDevicePerformanceReport(Request $request)
    {
        try {
            $testDriver = $this->getOrCreateTestDriver();
            
            if (!$testDriver) {
                return ResponseHelper::error('Imeshindwa kutengeneza dereva wa majaribio', 500);
            }

            $this->createSampleTransactions($testDriver);

            $startDate = $request->get('start_date', Carbon::now()->subDays(30)->format('Y-m-d'));
            $endDate = $request->get('end_date', Carbon::now()->format('Y-m-d'));

            $report = $this->reportService->generateDevicePerformanceReport(
                $testDriver,
                $startDate,
                $endDate
            );

            return ResponseHelper::success($report, 'Ripoti ya utendaji wa vifaa imetengenezwa kikamilifu');

        } catch (\Exception $e) {
            \Log::error('Test device performance report failed', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return ResponseHelper::error('Imeshindwa kutengeneza ripoti ya utendaji wa vifaa: ' . $e->getMessage(), 500);
        }
    }
}