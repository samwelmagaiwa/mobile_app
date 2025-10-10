<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Payment;
use App\Models\DebtRecord;
use App\Models\Driver;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Log;
use Carbon\Carbon;

class PaymentController extends Controller
{
    /**
     * Get drivers with outstanding debts
     */
    public function getDriversWithDebts(Request $request): JsonResponse
    {
        try {
            $page = max((int) $request->get('page', 1), 1);
            $limit = min((int) $request->get('limit', 50), 100);
            $onlyWithDebts = $request->boolean('only_with_debts', false);

            // Load all drivers with their unpaid debt records and user relation for name/phone
            $driversQuery = Driver::with(['user', 'debtRecords' => function ($query) {
                $query->where('is_paid', false)
                      ->orderBy('earning_date', 'desc');
            }]);

            $drivers = $driversQuery->get();

            // Build formatted collection with totals and status
            $formatted = $drivers->map(function ($driver) {
                $unpaidRecords = $driver->debtRecords ?? collect();
                $totalDebt = (float) $unpaidRecords->sum(function ($r) {
                    // remaining_amount is an accessor (expected_amount - paid_amount)
                    return (float) $r->remaining_amount;
                });
                $unpaidCount = $unpaidRecords->count();

                return [
                    'id' => (string) $driver->id,
                    'name' => (string) ($driver->name ?? ''),
                    'email' => (string) ($driver->email ?? ''),
                    'phone' => (string) ($driver->phone ?? ''),
                    'vehicle_number' => $driver->vehicle_number,
                    'vehicle_type' => $driver->vehicle_type,
                    'status' => $driver->status,
                    'total_debt' => $totalDebt,
                    'unpaid_days' => $unpaidCount,
                    'overdue_days' => $unpaidRecords->where('is_overdue', true)->count(),
                    'has_debt' => $totalDebt > 0,
                    'status_text' => $totalDebt > 0 ? 'Ana deni' : 'Hana deni',
                ];
            });

            // Optionally filter to only those with debts
            if ($onlyWithDebts) {
                $formatted = $formatted->filter(fn ($d) => $d['has_debt']);
            }

            // Sort: drivers with debts first, then by total debt desc, then by name asc
            $sorted = $formatted->sortBy([
                ['has_debt', 'desc'],
                ['total_debt', 'desc'],
                ['name', 'asc'],
            ])->values();

            // Manual pagination on the sorted collection
            $total = $sorted->count();
            $offset = ($page - 1) * $limit;
            $pagedDrivers = $sorted->slice($offset, $limit)->values();
            $totalPages = (int) ceil($total / $limit ?: 1);

            return response()->json([
                'success' => true,
                'message' => 'Drivers retrieved successfully',
                'data' => [
                    'drivers' => $pagedDrivers,
                    'pagination' => [
                        'current_page' => $page,
                        'per_page' => $limit,
                        'total' => $total,
                        'total_pages' => $totalPages,
                    ]
                ]
            ]);

        } catch (\Exception $e) {
            Log::error('Error fetching drivers with debts: ' . $e->getMessage());
            
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch drivers',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Get debt summary for a specific driver
     */
public function getDriverDebtSummary(string $driverId): JsonResponse
    {
        try {
            // Accept either drivers.id or users.id and normalize to drivers.id
$driver = Driver::where('id', $driverId)
                            ->orWhere('user_id', $driverId)
                            ->first();
            $summary = DebtRecord::getSummaryForDriver($driver?->id ?? $driverId);

            return response()->json([
                'success' => true,
                'message' => 'Driver debt summary retrieved successfully',
                'data' => array_merge($summary, [
                    'driver_name' => $driver->name,
                ])
            ]);

        } catch (\Exception $e) {
            Log::error('Error fetching driver debt summary: ' . $e->getMessage());
            
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch driver debt summary',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Get debt records for a specific driver
     */
public function getDriverDebtRecords(string $driverId, Request $request): JsonResponse
    {
        try {
            $unpaidOnly = $request->boolean('unpaid_only', true);
            $limit = min($request->get('limit', 100), 500);

            // Normalize driver id
$driver = Driver::where('id', $driverId)
                            ->orWhere('user_id', $driverId)
                            ->first();

            $query = DebtRecord::byDriver($driver?->id ?? $driverId)
                               ->with('payment')
                               ->orderBy('earning_date', 'desc');

            if ($unpaidOnly) {
                $query->unpaid();
            }

            $debtRecords = $query->limit($limit)->get();

            return response()->json([
                'success' => true,
                'message' => 'Driver debt records retrieved successfully',
                'data' => [
                    'debt_records' => $debtRecords->map->toApiResponse(),
                    'count' => $debtRecords->count()
                ]
            ]);

        } catch (\Exception $e) {
            Log::error('Error fetching driver debt records: ' . $e->getMessage());
            
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch driver debt records',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Record a new payment and update debt records
     */
    public function recordPayment(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
'driver_id' => 'required|exists:drivers,id',
            'amount' => 'required|numeric|min:0.01',
            'payment_channel' => 'required|in:cash,mpesa,bank,mobile,other',
            'covers_days' => 'required|array|min:1',
            'covers_days.*' => 'required|date',
            'remarks' => 'nullable|string|max:1000',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors()
            ], 422);
        }

        DB::beginTransaction();
        
        try {
            $driverId = $request->driver_id;
            $amount = $request->amount;
            $coversDays = $request->covers_days;
            
            // Get or create debt records for the specified days
            $debtRecords = collect();
            $totalExpectedAmount = 0;
            
            foreach ($coversDays as $date) {
                // Find existing debt record or create a new one
                $debtRecord = DebtRecord::firstOrCreate(
                    [
                        'driver_id' => $driverId,
                        'earning_date' => Carbon::parse($date)->format('Y-m-d')
                    ],
                    [
                        'expected_amount' => 10000, // Default expected amount - should be configurable
                        'paid_amount' => 0,
                        'is_paid' => false,
                    ]
                );
                
                // Only include unpaid debt records
                if (!$debtRecord->is_paid) {
                    $debtRecords->push($debtRecord);
                    $totalExpectedAmount += $debtRecord->remaining_amount;
                }
            }

            if ($debtRecords->isEmpty()) {
                DB::rollBack();
                return response()->json([
                    'success' => false,
                    'message' => 'No unpaid debt records found for the selected dates',
                ], 400);
            }

            // Create payment record
            $payment = Payment::create([
                'driver_id' => $driverId,
                'amount' => $amount,
                'payment_channel' => $request->payment_channel,
                'covers_days' => $coversDays,
                'remarks' => $request->remarks,
                'status' => 'completed',
                'payment_date' => now(),
                'recorded_by' => auth()->id() ?? 1, // Default to admin if not authenticated
                'receipt_status' => 'pending',
            ]);

            // Update debt records as paid
            $remainingAmount = $amount;
            $paidDays = [];
            
            foreach ($debtRecords as $debtRecord) {
                if ($remainingAmount <= 0) break;
                
                $amountToPay = min($remainingAmount, $debtRecord->remaining_amount);
                
                // Mark debt record as paid
                $debtRecord->markAsPaid($payment, $debtRecord->paid_amount + $amountToPay);
                
                $paidDays[] = $debtRecord->earning_date->format('d/m/Y');
                $remainingAmount -= $amountToPay;
            }

            // Receipt will be generated manually later via the admin interface
            // Keep payment in 'pending' status for receipt generation

            DB::commit();

            // Log the successful payment
            Log::info("Payment recorded successfully", [
                'payment_id' => $payment->id,
                'reference_number' => $payment->reference_number,
                'driver_id' => $driverId,
                'amount' => $amount,
                'paid_days' => $paidDays
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Payment recorded successfully',
                'data' => [
                    'payment' => $payment->toApiResponse(),
                    'paid_days' => $paidDays,
                    'covered_days_count' => count($paidDays),
                    'total_amount_applied' => $amount - $remainingAmount,
                    'remaining_amount' => $remainingAmount,
                ]
            ], 201);

        } catch (\Exception $e) {
            DB::rollBack();
            Log::error('Error recording payment: ' . $e->getMessage(), [
                'driver_id' => $request->driver_id,
                'amount' => $request->amount,
                'covers_days' => $request->covers_days
            ]);
            
            return response()->json([
                'success' => false,
                'message' => 'Failed to record payment',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Get payment history
     */
    public function getPaymentHistory(Request $request): JsonResponse
    {
        try {
            $page = $request->get('page', 1);
            $limit = min($request->get('limit', 20), 100);
            $driverId = $request->get('driver_id');
            $startDate = $request->get('start_date');
            $endDate = $request->get('end_date');

            $query = Payment::with(['driver', 'recordedBy'])
                           ->orderBy('payment_date', 'desc');

            if ($driverId) {
                // Normalize driver id if a user id was passed
$driver = Driver::where('id', $driverId)
                                ->orWhere('user_id', $driverId)
                                ->first();
                $query->byDriver($driver?->id ?? $driverId);
            }

            if ($startDate && $endDate) {
                $query->dateRange($startDate, $endDate);
            }

$payments = $query->paginate($limit, ['*'], 'page', $page);

            $items = collect($payments->items())->map(function ($p) {
                return method_exists($p, 'toApiResponse') ? $p->toApiResponse() : $p;
            })->values();

            return response()->json([
                'success' => true,
                'message' => 'Payment history retrieved successfully',
                'data' => [
                    'payments' => $items,
                    'pagination' => [
                        'current_page' => $payments->currentPage(),
                        'per_page' => $payments->perPage(),
                        'total' => $payments->total(),
                        'total_pages' => $payments->lastPage(),
                    ]
                ]
            ]);

        } catch (\Exception $e) {
            Log::error('Error fetching payment history: ' . $e->getMessage());
            
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch payment history',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Update a payment record
     */
    public function updatePayment(int $paymentId, Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'amount' => 'sometimes|numeric|min:0.01',
            'payment_channel' => 'sometimes|in:cash,mpesa,bank,mobile,other',
            'remarks' => 'nullable|string|max:1000',
            'status' => 'sometimes|in:pending,completed,cancelled',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors()
            ], 422);
        }

        try {
            $payment = Payment::findOrFail($paymentId);
            $payment->update($request->only(['amount', 'payment_channel', 'remarks', 'status']));

            return response()->json([
                'success' => true,
                'message' => 'Payment updated successfully',
                'data' => $payment->toApiResponse()
            ]);
        } catch (\Exception $e) {
            Log::error('Error updating payment: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Failed to update payment',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Delete a payment record
     */
    public function deletePayment(int $paymentId): JsonResponse
    {
        DB::beginTransaction();
        
        try {
            $payment = Payment::findOrFail($paymentId);
            
            // Reset associated debt records
            DebtRecord::where('payment_id', $paymentId)
                      ->update([
                          'is_paid' => false,
                          'payment_id' => null,
                          'paid_at' => null,
                      ]);

            $payment->delete();
            
            DB::commit();

            return response()->json([
                'success' => true,
                'message' => 'Payment deleted successfully and debt records reset'
            ]);

        } catch (\Exception $e) {
            DB::rollBack();
            Log::error('Error deleting payment: ' . $e->getMessage());
            
            return response()->json([
                'success' => false,
                'message' => 'Failed to delete payment',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Get payment summary statistics
     */
    public function getPaymentSummary(Request $request): JsonResponse
    {
        try {
            $startDate = $request->get('start_date', now()->startOfMonth());
            $endDate = $request->get('end_date', now()->endOfMonth());

            $totalPayments = Payment::dateRange($startDate, $endDate)->sum('amount');
            $paymentCount = Payment::dateRange($startDate, $endDate)->count();
            $averagePayment = $paymentCount > 0 ? $totalPayments / $paymentCount : 0;

            $paymentsByChannel = Payment::dateRange($startDate, $endDate)
                                      ->selectRaw('payment_channel, SUM(amount) as total, COUNT(*) as count')
                                      ->groupBy('payment_channel')
                                      ->get();

            $totalDebt = DebtRecord::unpaid()->sum('remaining_amount');
            $overdueDebt = DebtRecord::overdue()->sum('remaining_amount');

            return response()->json([
                'success' => true,
                'message' => 'Payment summary retrieved successfully',
                'data' => [
                    'period' => [
                        'start_date' => $startDate,
                        'end_date' => $endDate,
                    ],
                    'total_payments' => $totalPayments,
                    'payment_count' => $paymentCount,
                    'average_payment' => $averagePayment,
                    'payments_by_channel' => $paymentsByChannel,
                    'outstanding_debt' => [
                        'total_debt' => $totalDebt,
                        'overdue_debt' => $overdueDebt,
                        'current_debt' => $totalDebt - $overdueDebt,
                    ]
                ]
            ]);

        } catch (\Exception $e) {
            Log::error('Error fetching payment summary: ' . $e->getMessage());
            
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch payment summary',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Mark specific debt record as paid
     */
    public function markDebtAsPaid(int $debtId, Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'payment_id' => 'required|integer|exists:payments,id',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors()
            ], 422);
        }

        try {
            $debtRecord = DebtRecord::findOrFail($debtId);
            $payment = Payment::findOrFail($request->payment_id);

            $debtRecord->markAsPaid($payment);

            return response()->json([
                'success' => true,
                'message' => 'Debt record marked as paid successfully',
                'data' => $debtRecord->toApiResponse()
            ]);

        } catch (\Exception $e) {
            Log::error('Error marking debt as paid: ' . $e->getMessage());
            
            return response()->json([
                'success' => false,
                'message' => 'Failed to mark debt as paid',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    private function formatPeriod(int $days): string
    {
        if ($days <= 0) return '';
        if ($days === 1) return 'Siku 1';
        if ($days < 7) return $days . ' siku';
        if ($days < 14) return 'Wiki 1';
        if ($days < 21) return 'Wiki 2';
        if ($days < 30) return 'Wiki ' . round($days / 7);
        return 'Mwezi ' . round($days / 30);
    }

    private function buildReceiptDataForPayment(\App\Models\Payment $payment, array $paidDays): array
    {
        $driver = $payment->driver;
        return [
            'company_name' => config('app.name', 'Boda Mapato'),
            'company_address' => '',
            'company_phone' => '',
            'issue_date' => now()->format('d/m/Y'),
            'issue_time' => now()->format('H:i'),
            'driver_name' => $driver->name ?? '',
            'driver_phone' => $driver->phone ?? '',
            'vehicle_info' => $driver->vehicle_number ?? '',
            'payment_amount' => number_format((float) $payment->amount, 0),
            'amount_in_words' => '',
            'payment_channel' => $payment->formatted_payment_channel,
            'payment_date' => optional($payment->payment_date)->format('d/m/Y') ?? '',
            'covered_period' => $this->formatPeriod(count($payment->covers_days ?? [])),
            'covered_days_list' => $payment->covers_days ?? $paidDays,
            'remarks' => $payment->remarks ?? '',
            'recorded_by' => $payment->recordedBy->name ?? '',
        ];
    }
}
