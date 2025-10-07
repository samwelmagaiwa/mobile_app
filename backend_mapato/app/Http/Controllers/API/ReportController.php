<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Services\ReportService;
use App\Helpers\ResponseHelper;
use Illuminate\Http\Request;

class ReportController extends Controller
{
    protected $reportService;

    public function __construct(ReportService $reportService)
    {
        $this->reportService = $reportService;
    }

    /**
     * Get revenue report
     */
    public function revenue(Request $request)
    {
        try {
            $request->validate([
                'start_date' => 'required|date',
                'end_date' => 'required|date|after_or_equal:start_date',
                'device_id' => 'nullable|exists:devices,id',
                'group_by' => 'nullable|in:day,week,month',
            ]);

            $driver = $request->user()->driver;
            
            if (!$driver) {
                return ResponseHelper::error('Driver profile not found', 404);
            }

            $report = $this->reportService->generateRevenueReport(
                $driver,
                $request->start_date,
                $request->end_date,
                $request->device_id,
                $request->get('group_by', 'day')
            );

            return ResponseHelper::success($report, 'Ripoti ya mapato imetengenezwa kikamilifu');
        } catch (\Illuminate\Validation\ValidationException $e) {
            return ResponseHelper::validationError($e->errors());
        } catch (\Exception $e) {
            \Log::error('Revenue report generation failed', [
                'user_id' => $request->user()->id,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return ResponseHelper::error('Imeshindwa kutengeneza ripoti ya mapato: ' . $e->getMessage(), 500);
        }
    }

    /**
     * Get expense report
     */
    public function expenses(Request $request)
    {
        try {
            $request->validate([
                'start_date' => 'required|date',
                'end_date' => 'required|date|after_or_equal:start_date',
                'device_id' => 'nullable|exists:devices,id',
                'category' => 'nullable|string',
            ]);

            $driver = $request->user()->driver;
            
            if (!$driver) {
                return ResponseHelper::error('Profaili ya dereva haijapatikana', 404);
            }

            $report = $this->reportService->generateExpenseReport(
                $driver,
                $request->start_date,
                $request->end_date,
                $request->device_id,
                $request->category
            );

            return ResponseHelper::success($report, 'Ripoti ya matumizi imetengenezwa kikamilifu');
        } catch (\Illuminate\Validation\ValidationException $e) {
            return ResponseHelper::validationError($e->errors());
        } catch (\Exception $e) {
            \Log::error('Expense report generation failed', [
                'user_id' => $request->user()->id,
                'error' => $e->getMessage()
            ]);
            return ResponseHelper::error('Imeshindwa kutengeneza ripoti ya matumizi: ' . $e->getMessage(), 500);
        }
    }

    /**
     * Get profit/loss report
     */
    public function profitLoss(Request $request)
    {
        try {
            $request->validate([
                'start_date' => 'required|date',
                'end_date' => 'required|date|after_or_equal:start_date',
                'device_id' => 'nullable|exists:devices,id',
            ]);

            $driver = $request->user()->driver;
            
            if (!$driver) {
                return ResponseHelper::error('Profaili ya dereva haijapatikana', 404);
            }

            $report = $this->reportService->generateProfitLossReport(
                $driver,
                $request->start_date,
                $request->end_date,
                $request->device_id
            );

            return ResponseHelper::success($report, 'Ripoti ya faida na hasara imetengenezwa kikamilifu');
        } catch (\Illuminate\Validation\ValidationException $e) {
            return ResponseHelper::validationError($e->errors());
        } catch (\Exception $e) {
            \Log::error('Profit/Loss report generation failed', [
                'user_id' => $request->user()->id,
                'error' => $e->getMessage()
            ]);
            return ResponseHelper::error('Imeshindwa kutengeneza ripoti ya faida na hasara: ' . $e->getMessage(), 500);
        }
    }

    /**
     * Get daily summary report
     */
    public function dailySummary(Request $request)
    {
        try {
            $request->validate([
                'date' => 'nullable|date',
            ]);

            $driver = $request->user()->driver;
            $date = $request->get('date', today()->toDateString());
            
            $report = $this->reportService->generateDailySummary($driver, $date);

            return ResponseHelper::success($report, 'Daily summary report generated successfully');
        } catch (\Exception $e) {
            return ResponseHelper::error('Failed to generate daily summary: ' . $e->getMessage(), 500);
        }
    }

    /**
     * Get weekly summary report
     */
    public function weeklySummary(Request $request)
    {
        try {
            $request->validate([
                'week_start' => 'nullable|date',
            ]);

            $driver = $request->user()->driver;
            $weekStart = $request->get('week_start', now()->startOfWeek()->toDateString());
            
            $report = $this->reportService->generateWeeklySummary($driver, $weekStart);

            return ResponseHelper::success($report, 'Weekly summary report generated successfully');
        } catch (\Exception $e) {
            return ResponseHelper::error('Failed to generate weekly summary: ' . $e->getMessage(), 500);
        }
    }

    /**
     * Get monthly summary report
     */
    public function monthlySummary(Request $request)
    {
        try {
            $request->validate([
                'month' => 'nullable|integer|between:1,12',
                'year' => 'nullable|integer|min:2020',
            ]);

            $driver = $request->user()->driver;
            $month = $request->get('month', now()->month);
            $year = $request->get('year', now()->year);
            
            $report = $this->reportService->generateMonthlySummary($driver, $month, $year);

            return ResponseHelper::success($report, 'Monthly summary report generated successfully');
        } catch (\Exception $e) {
            return ResponseHelper::error('Failed to generate monthly summary: ' . $e->getMessage(), 500);
        }
    }

    /**
     * Get device performance report
     */
    public function devicePerformance(Request $request)
    {
        try {
            $request->validate([
                'start_date' => 'required|date',
                'end_date' => 'required|date|after_or_equal:start_date',
            ]);

            $driver = $request->user()->driver;
            $report = $this->reportService->generateDevicePerformanceReport(
                $driver,
                $request->start_date,
                $request->end_date
            );

            return ResponseHelper::success($report, 'Device performance report generated successfully');
        } catch (\Exception $e) {
            return ResponseHelper::error('Failed to generate device performance report: ' . $e->getMessage(), 500);
        }
    }

    /**
     * Export report to PDF
     */
    public function exportPdf(Request $request)
    {
        try {
            $request->validate([
                'report_type' => 'required|in:revenue,expenses,profit_loss,daily,weekly,monthly,device_performance',
                'start_date' => 'required|date',
                'end_date' => 'required|date|after_or_equal:start_date',
                'device_id' => 'nullable|exists:devices,id',
            ]);

            $driver = $request->user()->driver;
            $pdfFile = $this->reportService->exportReportToPdf(
                $driver,
                $request->report_type,
                $request->start_date,
                $request->end_date,
                $request->device_id
            );

            return response()->download($pdfFile);
        } catch (\Exception $e) {
            return ResponseHelper::error('Failed to export report: ' . $e->getMessage(), 500);
        }
    }

    /**
     * Get report dashboard
     */
    public function dashboard(Request $request)
    {
        try {
            $driver = $request->user()->driver;
            
            if (!$driver) {
                return ResponseHelper::error('Profaili ya dereva haijapatikana', 404);
            }

            $dashboard = $this->reportService->getReportDashboard($driver);

            return ResponseHelper::success($dashboard, 'Takwimu za ripoti zimepatikana kikamilifu');
        } catch (\Exception $e) {
            \Log::error('Report dashboard retrieval failed', [
                'user_id' => $request->user()->id,
                'error' => $e->getMessage()
            ]);
            return ResponseHelper::error('Imeshindwa kupata takwimu za ripoti: ' . $e->getMessage(), 500);
        }
    }
}