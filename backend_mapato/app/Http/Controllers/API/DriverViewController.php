<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\Transaction;
use App\Helpers\ResponseHelper;
use Illuminate\Http\Request;

class DriverViewController extends Controller
{
    /**
     * Get driver dashboard (read-only view)
     */
    public function dashboard(Request $request)
    {
        try {
            $user = $request->user();
            $driver = $user->driver;

            if (!$driver) {
                return ResponseHelper::error('Driver profile not found', 404);
            }

            // Get assigned vehicle
            $assignedVehicle = $user->assignedDevice;

            // Get payment history for this driver
            $recentPayments = Transaction::where('driver_id', $driver->id)
                                        ->where('type', 'income')
                                        ->with('device')
                                        ->latest()
                                        ->take(10)
                                        ->get();

            // Calculate statistics
            $totalPaymentsToday = Transaction::where('driver_id', $driver->id)
                                            ->where('type', 'income')
                                            ->where('status', 'completed')
                                            ->whereDate('created_at', today())
                                            ->sum('amount');

            $totalPaymentsThisWeek = Transaction::where('driver_id', $driver->id)
                                               ->where('type', 'income')
                                               ->where('status', 'completed')
                                               ->whereBetween('created_at', [now()->startOfWeek(), now()->endOfWeek()])
                                               ->sum('amount');

            $totalPaymentsThisMonth = Transaction::where('driver_id', $driver->id)
                                                ->where('type', 'income')
                                                ->where('status', 'completed')
                                                ->whereMonth('created_at', now()->month)
                                                ->sum('amount');

            $stats = [
                'assigned_vehicle' => $assignedVehicle,
                'payments_today' => $totalPaymentsToday,
                'payments_this_week' => $totalPaymentsThisWeek,
                'payments_this_month' => $totalPaymentsThisMonth,
                'recent_payments' => $recentPayments,
                'total_trips' => $driver->total_trips,
                'total_earnings' => $driver->total_earnings,
                'rating' => $driver->rating,
            ];

            return ResponseHelper::success($stats, 'Driver dashboard data retrieved successfully');

        } catch (\Exception $e) {
            return ResponseHelper::error('Failed to retrieve dashboard data: ' . $e->getMessage(), 500);
        }
    }

    /**
     * Payments summary for authenticated driver (totals for today/week/month or custom range)
     */
    public function getPaymentsSummary(Request $request)
    {
        try {
            $user = $request->user();
            $driver = $user->driver;
            if (!$driver) {
                return \App\Helpers\ResponseHelper::error('Driver profile not found', 404);
            }

            $driverId = $driver->id;
            $startDate = $request->get('start_date');
            $endDate = $request->get('end_date');

            // Base queries
            $payments = \App\Models\Payment::byDriver($driverId)->completed();
            $debtPaidNoPayment = \App\Models\DebtRecord::byDriver($driverId)->paid()->whereNull('payment_id');
            $transactions = \App\Models\Transaction::where('driver_id', $driverId)->where('type', 'income')->where('status', 'completed');

            // Periods
            $today = now()->toDateString();
            $weekStart = now()->startOfWeek();
            $weekEnd = now()->endOfWeek();
            $monthStart = now()->startOfMonth();
            $monthEnd = now()->endOfMonth();

            $totals = [
                'today' => (float) ($payments->clone()->whereDate('payment_date', $today)->sum('amount'))
                    + (float) ($debtPaidNoPayment->clone()->whereDate('paid_at', $today)->sum('paid_amount'))
                    + (float) ($transactions->clone()->whereDate('transaction_date', $today)->sum('amount')
                        ?: $transactions->clone()->whereDate('created_at', $today)->sum('amount')),
                'week' => (float) ($payments->clone()->whereBetween('payment_date', [$weekStart, $weekEnd])->sum('amount'))
                    + (float) ($debtPaidNoPayment->clone()->whereBetween('paid_at', [$weekStart, $weekEnd])->sum('paid_amount'))
                    + (float) ($transactions->clone()->whereBetween('transaction_date', [$weekStart, $weekEnd])->sum('amount')
                        ?: $transactions->clone()->whereBetween('created_at', [$weekStart, $weekEnd])->sum('amount')),
                'month' => (float) ($payments->clone()->whereBetween('payment_date', [$monthStart, $monthEnd])->sum('amount'))
                    + (float) ($debtPaidNoPayment->clone()->whereBetween('paid_at', [$monthStart, $monthEnd])->sum('paid_amount'))
                    + (float) ($transactions->clone()->whereBetween('transaction_date', [$monthStart, $monthEnd])->sum('amount')
                        ?: $transactions->clone()->whereBetween('created_at', [$monthStart, $monthEnd])->sum('amount')),
            ];

            $data = [ 'totals' => $totals ];

            if ($startDate && $endDate) {
                // Normalize to date strings
                $start = \Carbon\Carbon::parse($startDate)->startOfDay();
                $end = \Carbon\Carbon::parse($endDate)->endOfDay();
                $rangePayments = (float) \App\Models\Payment::byDriver($driverId)->completed()->whereBetween('payment_date', [$start, $end])->sum('amount');
                $rangeDebt = (float) \App\Models\DebtRecord::byDriver($driverId)->paid()->whereNull('payment_id')->whereBetween('paid_at', [$start, $end])->sum('paid_amount');
                $rangeTxn = (float) \App\Models\Transaction::where('driver_id', $driverId)->where('type','income')->where('status','completed')
                    ->whereBetween('transaction_date', [$start, $end])->sum('amount');
                if ($rangeTxn <= 0) {
                    $rangeTxn = (float) \App\Models\Transaction::where('driver_id', $driverId)->where('type','income')->where('status','completed')
                        ->whereBetween('created_at', [$start, $end])->sum('amount');
                }
                $data['range'] = [
                    'start_date' => $start->toDateString(),
                    'end_date' => $end->toDateString(),
                    'total' => $rangePayments + $rangeDebt,
                ];
            }

            return \App\Helpers\ResponseHelper::success($data, 'Driver payments summary retrieved successfully');
        } catch (\Exception $e) {
            return \App\Helpers\ResponseHelper::error('Failed to retrieve payments summary: ' . $e->getMessage(), 500);
        }
    }

    /**
     * Get driver's payment history
     */
    public function getPaymentHistory(Request $request)
    {
        try {
            $user = $request->user();
            $driver = $user->driver;
            $perPage = $request->get('per_page', 15);

            if (!$driver) {
                return ResponseHelper::error('Driver profile not found', 404);
            }

            $payments = Transaction::where('driver_id', $driver->id)
                                  ->where('type', 'income')
                                  ->with('device', 'receipt')
                                  ->orderBy('transaction_date', 'desc')
                                  ->paginate($perPage);

            return ResponseHelper::success($payments, 'Payment history retrieved successfully');

        } catch (\Exception $e) {
            return ResponseHelper::error('Failed to retrieve payment history: ' . $e->getMessage(), 500);
        }
    }

    /**
     * List completed payments for authenticated driver (from payments table)
     */
    public function getPayments(Request $request)
    {
        try {
            $user = $request->user();
            $driver = $user->driver;
            $perPage = (int) $request->get('per_page', 20);
            if (!$driver) {
                return ResponseHelper::error('Driver profile not found', 404);
            }
            $query = \App\Models\Payment::byDriver($driver->id)
                ->completed()
                ->orderByDesc('payment_date');
            if ($request->filled('start_date') && $request->filled('end_date')) {
                $query->dateRange($request->get('start_date'), $request->get('end_date'));
            }
            $payments = $query->paginate($perPage);
            $items = collect($payments->items())->map(function ($p) {
                return method_exists($p, 'toApiResponse') ? $p->toApiResponse() : $p;
            })->values();
            return ResponseHelper::success([
                'payments' => $items,
                'pagination' => [
                    'current_page' => $payments->currentPage(),
                    'per_page' => $payments->perPage(),
                    'total' => $payments->total(),
                    'total_pages' => $payments->lastPage(),
                ],
            ], 'Driver payments retrieved successfully');
        } catch (\Exception $e) {
            return ResponseHelper::error('Failed to retrieve payments: ' . $e->getMessage(), 500);
        }
    }

    /**
     * Get driver's debt records (paid/unpaid)
     */
    public function getDebtRecords(Request $request)
    {
        try {
            $user = $request->user();
            $driver = $user->driver;
            $perPage = (int) $request->get('per_page', 50);
            if (!$driver) {
                return ResponseHelper::error('Driver profile not found', 404);
            }
            $query = \App\Models\DebtRecord::byDriver($driver->id)
                ->orderByDesc('earning_date');
            if ($request->filled('only_paid')) {
                $onlyPaid = filter_var($request->get('only_paid'), FILTER_VALIDATE_BOOLEAN);
                if ($onlyPaid) $query->paid();
            }
            if ($request->filled('only_unpaid')) {
                $onlyUnpaid = filter_var($request->get('only_unpaid'), FILTER_VALIDATE_BOOLEAN);
                if ($onlyUnpaid) $query->unpaid();
            }
            if ($request->filled('start_date') && $request->filled('end_date')) {
                $query->dateRange($request->get('start_date'), $request->get('end_date'));
            }
            $records = $query->paginate($perPage);
            $items = collect($records->items())->map(fn($r) => method_exists($r, 'toApiResponse') ? $r->toApiResponse() : $r)->values();
            return ResponseHelper::success([
                'debt_records' => $items,
                'pagination' => [
                    'current_page' => $records->currentPage(),
                    'per_page' => $records->perPage(),
                    'total' => $records->total(),
                    'total_pages' => $records->lastPage(),
                ],
            ], 'Driver debt records retrieved successfully');
        } catch (\Exception $e) {
            return ResponseHelper::error('Failed to retrieve debt records: ' . $e->getMessage(), 500);
        }
    }

    /**
     * Get driver's receipts
     */
    public function getReceipts(Request $request)
    {
        try {
            $user = $request->user();
            $driver = $user->driver;
            $perPage = $request->get('per_page', 15);

            if (!$driver) {
                return ResponseHelper::error('Driver profile not found', 404);
            }

            // Use PaymentReceipt (admin-generated receipts) so drivers see what owners send
            $query = \App\Models\PaymentReceipt::where('driver_id', $driver->id)
                ->orderBy('generated_at', 'desc');

            $receipts = $query->paginate($perPage);

            // Normalize to a simple array structure the mobile app expects
            $items = collect($receipts->items())->map(function ($r) {
                return [
                    'id' => (string) $r->id,
                    'receipt_number' => $r->receipt_number,
                    'payment_id' => (string) ($r->payment_id ?? ''),
                    'driver_id' => (string) ($r->driver_id ?? ''),
                    'driver_name' => optional($r->driver)->name ?? '',
                    'amount' => (float) $r->amount,
                    'payment_channel' => optional($r->payment)->payment_channel ?? 'cash',
                    'generated_at' => optional($r->generated_at)->toIso8601String(),
                    'paid_dates' => $r->covered_days ?? [],
                    'status' => $r->status ?? 'generated',
                    'remarks' => optional($r->payment)->remarks,
                    'trips_total' => (int) \App\Models\PaymentReceipt::where('driver_id', $r->driver_id)->count(),
                  ];
            })->values();

            return ResponseHelper::success([
                'receipts' => $items,
                'pagination' => [
                    'current_page' => $receipts->currentPage(),
                    'per_page' => $receipts->perPage(),
                    'total' => $receipts->total(),
                    'total_pages' => $receipts->lastPage(),
                ],
            ], 'Receipts retrieved successfully');

        } catch (\Exception $e) {
            return ResponseHelper::error('Failed to retrieve receipts: ' . $e->getMessage(), 500);
        }
    }

    /**
     * Get driver profile
     */
    public function getProfile(Request $request)
    {
        try {
            $user = $request->user();
            $driver = $user->driver;

            if (!$driver) {
                return ResponseHelper::error('Driver profile not found', 404);
            }

            $user->load('driver', 'assignedDevice', 'creator');

            return ResponseHelper::success($user, 'Driver profile retrieved successfully');

        } catch (\Exception $e) {
            return ResponseHelper::error('Failed to retrieve driver profile: ' . $e->getMessage(), 500);
        }
    }

    /**
     * Submit payment request (driver can request payment to be recorded)
     */
    public function submitPaymentRequest(Request $request)
    {
        try {
            $request->validate([
                'amount' => 'required|numeric|min:0.01',
                'description' => 'required|string|max:500',
                'payment_method' => 'required|in:cash,mobile_money,bank_transfer',
                'notes' => 'nullable|string|max:1000',
            ]);

            $user = $request->user();
            $driver = $user->driver;

            if (!$driver) {
                return ResponseHelper::error('Driver profile not found', 404);
            }

            if (!$user->assignedDevice) {
                return ResponseHelper::error('No vehicle assigned to driver', 400);
            }

            // Create a pending transaction that admin needs to approve
            $transaction = Transaction::create([
                'driver_id' => $driver->id,
                'device_id' => $user->device_id,
                'amount' => $request->amount,
                'type' => 'income',
                'category' => 'daily_payment',
                'description' => $request->description,
                'status' => 'pending', // Admin needs to approve
                'payment_method' => $request->payment_method,
                'notes' => $request->notes,
                'transaction_date' => now(),
            ]);

            $transaction->load('device');

            return ResponseHelper::success($transaction, 'Payment request submitted successfully. Waiting for admin approval.', 201);

        } catch (\Exception $e) {
            return ResponseHelper::error('Failed to submit payment request: ' . $e->getMessage(), 500);
        }
    }

    /**
     * Get driver's reminders
     */
    public function getReminders(Request $request)
    {
        try {
            $user = $request->user();
            $driver = $user->driver;

            if (!$driver) {
                return ResponseHelper::error('Driver profile not found', 404);
            }

            $reminders = \App\Models\Reminder::where('driver_id', $driver->id)
                                            ->where('status', 'active')
                                            ->orderBy('reminder_date', 'asc')
                                            ->get();

            return ResponseHelper::success($reminders, 'Reminders retrieved successfully');

        } catch (\Exception $e) {
            return ResponseHelper::error('Failed to retrieve reminders: ' . $e->getMessage(), 500);
        }
    }
}