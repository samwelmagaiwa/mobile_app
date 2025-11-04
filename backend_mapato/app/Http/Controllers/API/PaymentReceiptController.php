<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\Payment;
use App\Models\DebtRecord;
use App\Models\PaymentReceipt;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Log;
use Carbon\Carbon;

class PaymentReceiptController extends Controller
{
    /**
     * Get pending receipts (payments without receipts sent)
     */
    public function getPendingReceipts(Request $request)
    {
        try {
            $limit = min((int) $request->get('limit', 100), 200);

            $payments = Payment::with(['driver', 'recordedBy'])
                ->completed()
                ->pendingReceipt()
                ->orderByDesc('payment_date')
                ->limit($limit)
                ->get();

            $pending = $payments->map(function (Payment $p) {
                $coveredDays = $p->covers_days ?? [];
                $coveredDaysCount = count($coveredDays);
                // Compute remaining outstanding debt for this driver (after this payment)
                // Remaining = SUM(expected_amount - paid_amount) for unpaid records
                $remainingDebtTotal = (float) DebtRecord::unpaid()
                    ->where('driver_id', $p->driver_id)
                    ->selectRaw('COALESCE(SUM(expected_amount - paid_amount),0) as total')
                    ->value('total');

                // Get all unpaid dates for this driver (ordered)
                $unpaidDates = DebtRecord::unpaid()
                    ->where('driver_id', $p->driver_id)
                    ->orderBy('earning_date')
                    ->pluck('earning_date')
                    ->map(function ($d) { return Carbon::parse($d)->format('Y-m-d'); })
                    ->values()
                    ->toArray();

                $unpaidDaysCount = count($unpaidDates);

                return [
                    'payment_id' => (string) $p->id,
                    'reference_number' => $p->reference_number,
                    'driver' => [
                        'id' => (string) ($p->driver->id ?? ''),
                        'name' => $p->driver->name ?? '',
                        'phone' => $p->driver->phone ?? '',
                        'email' => $p->driver->email ?? null,
                    ],
                    'amount' => (float) $p->amount,
                    'payment_date' => optional($p->payment_date)->format('d/m/Y') ?? '',
                    'payment_time' => optional($p->payment_date)->format('H:i') ?? '',
                    'formatted_date' => optional($p->payment_date)->format('d/m/Y H:i') ?? '',
                    'payment_channel' => $p->payment_channel,
                    'formatted_payment_channel' => $p->formatted_payment_channel,
                    'covered_days' => $coveredDays,
                    'covered_days_count' => $coveredDaysCount,
                    'payment_period' => $this->formatPeriod($coveredDaysCount),
                    'remarks' => $p->remarks,
                    'recorded_by' => $p->recordedBy->name ?? '',
                    // New outstanding debt indicators
                    'has_remaining_debt' => $remainingDebtTotal > 0,
                    'remaining_debt_total' => $remainingDebtTotal,
                    'unpaid_days_count' => $unpaidDaysCount,
                    'unpaid_dates' => $unpaidDates,
                ];
            });

            return response()->json([
                'success' => true,
                'message' => 'Pending receipts retrieved successfully',
                'data' => [
                    'pending_receipts' => $pending,
                    'count' => $pending->count(),
                ]
            ]);
        } catch (\Exception $e) {
            Log::error('Error fetching pending receipts: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch pending receipts',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Generate receipt for a payment
     */
    public function generateReceipt(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'payment_id' => 'required|integer|exists:payments,id',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors(),
            ], 422);
        }

        DB::beginTransaction();
        try {
            /** @var Payment $payment */
            $payment = Payment::with(['driver', 'recordedBy'])
                ->findOrFail($request->payment_id);

            // If receipt already exists, return it
            if ($payment->paymentReceipt) {
                DB::commit();
                return response()->json([
                    'success' => true,
                    'message' => 'Receipt already generated',
                    'data' => $payment->paymentReceipt->getPreviewData(),
                ], 200);
            }

            $receiptNumber = PaymentReceipt::generateReceiptNumber();

            $receipt = PaymentReceipt::create([
                'receipt_number' => $receiptNumber,
                'payment_id' => $payment->id,
                'driver_id' => $payment->driver_id,
                'generated_by' => auth()->id() ?? 1,
                'amount' => $payment->amount,
                'payment_period' => $this->formatPeriod(count($payment->covers_days ?? [])),
                'covered_days' => $payment->covers_days ?? [],
                'status' => 'generated',
                'generated_at' => now(),
                'receipt_data' => $this->buildReceiptData($payment),
            ]);

            // Update payment receipt status
            $payment->update(['receipt_status' => 'generated']);

            DB::commit();

            return response()->json([
                'success' => true,
                'message' => 'Receipt generated successfully',
                'data' => $receipt->getPreviewData(),
            ], 201);
        } catch (\Exception $e) {
            DB::rollBack();
            Log::error('Error generating receipt: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Failed to generate receipt',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Get receipt preview data
     */
    public function getReceiptPreview(int $receiptId)
    {
        try {
            $receipt = PaymentReceipt::with(['driver', 'payment.recordedBy', 'generatedBy'])
                ->findOrFail($receiptId);

            $data = array_merge($receipt->getPreviewData(), [
                'receipt_data' => $receipt->receipt_data,
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Receipt preview retrieved successfully',
                'data' => $data,
            ]);
        } catch (\Exception $e) {
            Log::error('Error getting receipt preview: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Failed to get receipt preview',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Send receipt to driver and mark as issued on payment
     */
    public function sendReceipt(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'receipt_id' => 'required|integer|exists:payment_receipts,id',
            'send_via' => 'required|in:whatsapp,email,system',
            'contact_info' => 'required|string',
            'message' => 'nullable|string|max:2000',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors(),
            ], 422);
        }

        DB::beginTransaction();
        try {
            $receipt = PaymentReceipt::with(['payment','driver'])->findOrFail($request->receipt_id);
            $receipt->markAsSent($request->send_via);

            // Update related payment status to "receipt issued"
            if ($receipt->payment) {
                $receipt->payment->update(['receipt_status' => 'issued']);
            }

            // Build the final message including remarks if available
            $data = $receipt->getPreviewData();
            $receiptData = $receipt->receipt_data ?? [];
            $remarks = $receiptData['remarks'] ?? ($receipt->payment->remarks ?? '');
            $tripsTotal = (int) PaymentReceipt::where('driver_id', $receipt->driver_id)->count();
            $humanMessage = $request->get('message');
            if (!$humanMessage || trim($humanMessage) === '') {
                $humanMessage = sprintf(
                    "Receipt %s\nAmount: %s\nPeriod: %s\nDays: %s\nTrips: %d%s",
                    $data['receipt_number'] ?? '',
                    number_format((float) ($receipt->amount ?? 0), 0),
                    $receipt->formatted_period,
                    implode(', ', $receipt->covered_days ?? []),
                    $tripsTotal,
                    $remarks ? ("\nRemarks: " . $remarks) : ''
                );
            }

            DB::commit();

            return response()->json([
                'success' => true,
                'message' => 'Receipt sent successfully',
                'data' => array_merge($data, [
                    'receipt_data' => $receiptData,
                    'remarks' => $remarks,
                    'message_sent' => $humanMessage,
                ]),
            ]);
        } catch (\Exception $e) {
            DB::rollBack();
            Log::error('Error sending receipt: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Failed to send receipt',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Get all receipts with filters
     */
    public function getReceipts(Request $request)
    {
        try {
            $status = $request->get('status');
            $driverId = $request->get('driver_id');
            $dateFrom = $request->get('date_from');
            $dateTo = $request->get('date_to');

            $query = PaymentReceipt::with(['driver', 'payment.recordedBy', 'generatedBy'])
                ->orderByDesc('generated_at');

            if ($status) {
                if ($status === 'pending') {
                    $query->where('status', 'generated');
                } elseif (in_array($status, ['generated', 'sent', 'delivered'])) {
                    $query->where('status', $status);
                }
            }

            if ($driverId) {
                $query->where('driver_id', $driverId);
            }

            if ($dateFrom && $dateTo) {
                $query->whereBetween(DB::raw('DATE(generated_at)'), [$dateFrom, $dateTo]);
            }

            $receipts = $query->paginate(min((int) $request->get('limit', 20), 100));

            $data = $receipts->getCollection()->map(function (PaymentReceipt $r) {
                return array_merge($r->getPreviewData(), [
                    'receipt_id' => (string) $r->id,
                    'receipt_data' => $r->receipt_data,
                ]);
            });

            return response()->json([
                'success' => true,
                'message' => 'Receipts retrieved successfully',
                'data' => [
                    'receipts' => $data,
                    'pagination' => [
                        'current_page' => $receipts->currentPage(),
                        'per_page' => $receipts->perPage(),
                        'total' => $receipts->total(),
                        'total_pages' => $receipts->lastPage(),
                    ],
                ],
            ]);
        } catch (\Exception $e) {
            Log::error('Error fetching receipts: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch receipts',
                'error' => $e->getMessage(),
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

    private function buildReceiptData(Payment $payment): array
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
            'covered_days_list' => $payment->covers_days ?? [],
            'remarks' => $payment->remarks ?? '',
            'recorded_by' => $payment->recordedBy->name ?? '',
            'trips_total' => (int) PaymentReceipt::where('driver_id', $driver->id)->count() + 1,
        ];
    }

    /**
     * Update receipt status
     */
    public function updateReceiptStatus(Request $request, int $receiptId)
    {
        $validator = Validator::make($request->all(), [
            'status' => 'required|in:generated,sent,delivered,cancelled',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors(),
            ], 422);
        }

        try {
            $receipt = PaymentReceipt::findOrFail($receiptId);
            $receipt->update(['status' => $request->status]);

            return response()->json([
                'success' => true,
                'message' => 'Receipt status updated successfully',
                'data' => $receipt->getPreviewData(),
            ]);
        } catch (\Exception $e) {
            Log::error('Error updating receipt status: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Failed to update receipt status',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Cancel receipt
     */
    public function cancelReceipt(Request $request, int $receiptId)
    {
        try {
            $receipt = PaymentReceipt::findOrFail($receiptId);
            $receipt->update(['status' => 'cancelled']);

            return response()->json([
                'success' => true,
                'message' => 'Receipt cancelled successfully',
                'data' => $receipt->getPreviewData(),
            ]);
        } catch (\Exception $e) {
            Log::error('Error cancelling receipt: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Failed to cancel receipt',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Delete receipt
     */
    public function deleteReceipt(Request $request, int $receiptId)
    {
        try {
            $receipt = PaymentReceipt::findOrFail($receiptId);
            $receipt->delete();

            return response()->json([
                'success' => true,
                'message' => 'Receipt deleted successfully',
            ]);
        } catch (\Exception $e) {
            Log::error('Error deleting receipt: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Failed to delete receipt',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Get receipt statistics
     */
    public function getReceiptStats(Request $request)
    {
        try {
            $startDate = $request->get('start_date');
            $endDate = $request->get('end_date');

            $query = PaymentReceipt::query();

            if ($startDate && $endDate) {
                $query->whereBetween(DB::raw('DATE(generated_at)'), [$startDate, $endDate]);
            }

            $stats = [
                'total_receipts' => $query->count(),
                'generated_receipts' => $query->where('status', 'generated')->count(),
                'sent_receipts' => $query->where('status', 'sent')->count(),
                'delivered_receipts' => $query->where('status', 'delivered')->count(),
                'cancelled_receipts' => $query->where('status', 'cancelled')->count(),
                'total_amount' => $query->sum('amount'),
            ];

            return response()->json([
                'success' => true,
                'message' => 'Receipt statistics retrieved successfully',
                'data' => $stats,
            ]);
        } catch (\Exception $e) {
            Log::error('Error getting receipt statistics: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Failed to get receipt statistics',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Export receipts
     */
    public function exportReceipts(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'format' => 'required|in:pdf,excel',
            'status' => 'nullable|in:generated,sent,delivered,cancelled',
            'driver_id' => 'nullable|integer|exists:drivers,id',
            'date_from' => 'nullable|date',
            'date_to' => 'nullable|date',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors(),
            ], 422);
        }

        try {
            // For now, return a placeholder response
            // TODO: Implement actual export functionality
            return response()->json([
                'success' => true,
                'message' => 'Export functionality not yet implemented',
                'data' => [
                    'format' => $request->format,
                    'filters' => $request->only(['status', 'driver_id', 'date_from', 'date_to']),
                ],
            ]);
        } catch (\Exception $e) {
            Log::error('Error exporting receipts: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Failed to export receipts',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Generate bulk receipts
     */
    public function generateBulkReceipts(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'payment_ids' => 'required|array|min:1',
            'payment_ids.*' => 'integer|exists:payments,id',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors(),
            ], 422);
        }

        DB::beginTransaction();
        try {
            $results = [];
            $errors = [];

            foreach ($request->payment_ids as $paymentId) {
                try {
                    $payment = Payment::with(['driver', 'recordedBy'])->findOrFail($paymentId);

                    // Skip if receipt already exists
                    if ($payment->paymentReceipt) {
                        $results[] = [
                            'payment_id' => $paymentId,
                            'status' => 'skipped',
                            'message' => 'Receipt already exists',
                        ];
                        continue;
                    }

                    $receiptNumber = PaymentReceipt::generateReceiptNumber();

                    $receipt = PaymentReceipt::create([
                        'receipt_number' => $receiptNumber,
                        'payment_id' => $payment->id,
                        'driver_id' => $payment->driver_id,
                        'generated_by' => auth()->id() ?? 1,
                        'amount' => $payment->amount,
                        'payment_period' => $this->formatPeriod(count($payment->covers_days ?? [])),
                        'covered_days' => $payment->covers_days ?? [],
                        'status' => 'generated',
                        'generated_at' => now(),
                        'receipt_data' => $this->buildReceiptData($payment),
                    ]);

                    $payment->update(['receipt_status' => 'generated']);

                    $results[] = [
                        'payment_id' => $paymentId,
                        'receipt_id' => $receipt->id,
                        'receipt_number' => $receipt->receipt_number,
                        'status' => 'success',
                        'message' => 'Receipt generated successfully',
                    ];
                } catch (\Exception $e) {
                    $errors[] = [
                        'payment_id' => $paymentId,
                        'status' => 'error',
                        'message' => $e->getMessage(),
                    ];
                }
            }

            DB::commit();

            return response()->json([
                'success' => true,
                'message' => 'Bulk receipt generation completed',
                'data' => [
                    'results' => $results,
                    'errors' => $errors,
                    'summary' => [
                        'total_requested' => count($request->payment_ids),
                        'successful' => count(array_filter($results, fn($r) => $r['status'] === 'success')),
                        'skipped' => count(array_filter($results, fn($r) => $r['status'] === 'skipped')),
                        'errors' => count($errors),
                    ],
                ],
            ]);
        } catch (\Exception $e) {
            DB::rollBack();
            Log::error('Error in bulk receipt generation: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Failed to generate bulk receipts',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Search receipts
     */
    public function searchReceipts(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'q' => 'required|string|min:1',
            'page' => 'nullable|integer|min:1',
            'limit' => 'nullable|integer|min:1|max:100',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors(),
            ], 422);
        }

        try {
            $searchQuery = $request->get('q');
            $page = (int) $request->get('page', 1);
            $limit = min((int) $request->get('limit', 20), 100);

            $query = PaymentReceipt::with(['driver', 'payment.recordedBy', 'generatedBy'])
                ->where(function ($q) use ($searchQuery) {
                    $q->where('receipt_number', 'LIKE', "%{$searchQuery}%")
                      ->orWhereHas('driver', function ($driverQuery) use ($searchQuery) {
                          $driverQuery->where('name', 'LIKE', "%{$searchQuery}%")
                                     ->orWhere('phone', 'LIKE', "%{$searchQuery}%");
                      })
                      ->orWhereHas('payment', function ($paymentQuery) use ($searchQuery) {
                          $paymentQuery->where('reference_number', 'LIKE', "%{$searchQuery}%");
                      });
                })
                ->orderByDesc('generated_at');

            $receipts = $query->paginate($limit, ['*'], 'page', $page);

            $data = $receipts->getCollection()->map(function (PaymentReceipt $r) {
                return $r->getPreviewData();
            });

            return response()->json([
                'success' => true,
                'message' => 'Search results retrieved successfully',
                'data' => [
                    'receipts' => $data,
                    'pagination' => [
                        'current_page' => $receipts->currentPage(),
                        'per_page' => $receipts->perPage(),
                        'total' => $receipts->total(),
                        'total_pages' => $receipts->lastPage(),
                    ],
                    'search_query' => $searchQuery,
                ],
            ]);
        } catch (\Exception $e) {
            Log::error('Error searching receipts: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Failed to search receipts',
                'error' => $e->getMessage(),
            ], 500);
        }
    }
}
