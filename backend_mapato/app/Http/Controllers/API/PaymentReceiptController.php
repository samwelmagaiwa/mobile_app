<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\Payment;
use App\Models\PaymentReceipt;
use App\Models\Driver;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Log;

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
            $receipt = PaymentReceipt::with(['payment'])->findOrFail($request->receipt_id);
            $receipt->markAsSent($request->send_via);

            // Update related payment status to "receipt issued"
            if ($receipt->payment) {
                $receipt->payment->update(['receipt_status' => 'issued']);
            }

            DB::commit();

            return response()->json([
                'success' => true,
                'message' => 'Receipt sent successfully',
                'data' => $receipt->getPreviewData(),
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
        ];
    }
}