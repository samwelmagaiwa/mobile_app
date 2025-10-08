<?php

namespace App\Http\Controllers;

use App\Models\Payment;
use App\Models\PaymentReceipt;
use App\Models\Driver;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Validator;
use Carbon\Carbon;

class ReceiptController extends Controller
{
    /**
     * Get pending receipts (payments without receipts generated)
     */
    public function getPendingReceipts(): JsonResponse
    {
        try {
            $pendingPayments = Payment::with(['driver', 'recordedBy'])
                ->pendingReceipt()
                ->where('status', 'completed')
                ->orderBy('payment_date', 'desc')
                ->get();

            $pendingReceipts = $pendingPayments->map(function ($payment) {
                return [
                    'payment_id' => $payment->id,
                    'reference_number' => $payment->reference_number,
                    'driver' => [
                        'id' => $payment->driver->id,
                        'name' => $payment->driver->name,
                        'phone' => $payment->driver->phone,
                        'email' => $payment->driver->email ?? null,
                    ],
                    'amount' => $payment->amount,
                    'payment_date' => $payment->payment_date->format('Y-m-d'),
                    'payment_time' => $payment->payment_date->format('H:i'),
                    'formatted_date' => $payment->payment_date->format('d/m/Y'),
                    'payment_channel' => $payment->payment_channel,
                    'formatted_payment_channel' => $payment->formatted_payment_channel,
                    'covered_days' => $payment->covers_days ?? [],
                    'covered_days_count' => count($payment->covers_days ?? []),
                    'payment_period' => $this->formatPaymentPeriod($payment->covers_days ?? []),
                    'remarks' => $payment->remarks,
                    'recorded_by' => $payment->recordedBy->name ?? 'System',
                ];
            });

            return response()->json([
                'success' => true,
                'message' => 'Pending receipts retrieved successfully',
                'data' => [
                    'pending_receipts' => $pendingReceipts,
                    'total_count' => $pendingReceipts->count(),
                ]
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to retrieve pending receipts: ' . $e->getMessage(),
                'data' => null
            ], 500);
        }
    }

    /**
     * Generate receipt for a payment
     */
    public function generateReceipt(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'payment_id' => 'required|exists:payments,id',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'data' => $validator->errors()
            ], 422);
        }

        try {
            $payment = Payment::with(['driver', 'recordedBy'])->findOrFail($request->payment_id);

            // Check if receipt already exists
            if ($payment->paymentReceipt) {
                return response()->json([
                    'success' => false,
                    'message' => 'Receipt already exists for this payment',
                    'data' => null
                ], 409);
            }

            // Generate receipt data
            $receiptData = $this->prepareReceiptData($payment);

            // Create the receipt record
            $receipt = PaymentReceipt::create([
                'receipt_number' => PaymentReceipt::generateReceiptNumber(),
                'payment_id' => $payment->id,
                'driver_id' => $payment->driver_id,
                'generated_by' => Auth::id(),
                'amount' => $payment->amount,
                'payment_period' => $this->formatPaymentPeriod($payment->covers_days ?? []),
                'covered_days' => $payment->covers_days ?? [],
                'status' => 'generated',
                'generated_at' => now(),
                'receipt_data' => $receiptData,
            ]);

            // Update payment status
            $payment->update(['receipt_status' => 'generated']);

            return response()->json([
                'success' => true,
                'message' => 'Receipt generated successfully',
                'data' => [
                    'receipt' => $receipt->getPreviewData(),
                    'receipt_data' => $receiptData,
                ]
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to generate receipt: ' . $e->getMessage(),
                'data' => null
            ], 500);
        }
    }

    /**
     * Get receipt preview
     */
    public function getReceiptPreview($receiptId): JsonResponse
    {
        try {
            $receipt = PaymentReceipt::with(['payment', 'driver', 'generatedBy'])
                ->findOrFail($receiptId);

            return response()->json([
                'success' => true,
                'message' => 'Receipt preview retrieved successfully',
                'data' => [
                    'receipt' => $receipt->getPreviewData(),
                    'receipt_data' => $receipt->receipt_data,
                ]
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to retrieve receipt preview: ' . $e->getMessage(),
                'data' => null
            ], 500);
        }
    }

    /**
     * Send receipt to driver
     */
    public function sendReceipt(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'receipt_id' => 'required|exists:payment_receipts,id',
            'send_via' => 'required|in:whatsapp,email,system',
            'contact_info' => 'required|string', // Phone for WhatsApp, email for email
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'data' => $validator->errors()
            ], 422);
        }

        try {
            $receipt = PaymentReceipt::findOrFail($request->receipt_id);

            // Here you would implement the actual sending logic
            // For now, we'll simulate the sending process
            $sendResult = $this->sendReceiptVia($receipt, $request->send_via, $request->contact_info);

            if ($sendResult['success']) {
                // Update receipt status
                $receipt->markAsSent($request->send_via);

                // Update payment status
                $receipt->payment->update(['receipt_status' => 'sent']);

                return response()->json([
                    'success' => true,
                    'message' => 'Receipt sent successfully',
                    'data' => [
                        'receipt_id' => $receipt->id,
                        'sent_via' => $request->send_via,
                        'sent_at' => $receipt->fresh()->sent_at->format('d/m/Y H:i'),
                    ]
                ]);
            } else {
                return response()->json([
                    'success' => false,
                    'message' => 'Failed to send receipt: ' . $sendResult['message'],
                    'data' => null
                ], 500);
            }

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to send receipt: ' . $e->getMessage(),
                'data' => null
            ], 500);
        }
    }

    /**
     * Get all receipts with filtering
     */
    public function getReceipts(Request $request): JsonResponse
    {
        try {
            $query = PaymentReceipt::with(['driver', 'payment', 'generatedBy']);

            // Apply filters
            if ($request->has('status')) {
                $query->where('status', $request->status);
            }

            if ($request->has('driver_id')) {
                $query->where('driver_id', $request->driver_id);
            }

            if ($request->has('date_from')) {
                $query->whereDate('generated_at', '>=', $request->date_from);
            }

            if ($request->has('date_to')) {
                $query->whereDate('generated_at', '<=', $request->date_to);
            }

            $receipts = $query->orderBy('generated_at', 'desc')->get();

            $formattedReceipts = $receipts->map(function ($receipt) {
                return $receipt->getPreviewData();
            });

            return response()->json([
                'success' => true,
                'message' => 'Receipts retrieved successfully',
                'data' => [
                    'receipts' => $formattedReceipts,
                    'total_count' => $receipts->count(),
                ]
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to retrieve receipts: ' . $e->getMessage(),
                'data' => null
            ], 500);
        }
    }

    /**
     * Prepare receipt data for generation
     */
    private function prepareReceiptData(Payment $payment): array
    {
        $coveredDays = $payment->covers_days ?? [];
        
        return [
            'company_name' => config('app.name', 'Boda Mapato'),
            'company_address' => config('app.address', 'Dar es Salaam, Tanzania'),
            'company_phone' => config('app.phone', '+255 123 456 789'),
            'receipt_number' => null, // Will be set when creating the receipt
            'issue_date' => now()->format('d/m/Y'),
            'issue_time' => now()->format('H:i'),
            'driver_name' => $payment->driver->name,
            'driver_phone' => $payment->driver->phone,
            'vehicle_info' => $payment->driver->vehicle_number ?? 'N/A',
            'payment_amount' => number_format($payment->amount, 2),
            'amount_in_words' => $this->convertAmountToWords($payment->amount),
            'payment_channel' => $payment->formatted_payment_channel,
            'payment_date' => $payment->payment_date->format('d/m/Y'),
            'covered_period' => $this->formatPaymentPeriod($coveredDays),
            'covered_days_list' => array_map(function($date) {
                return Carbon::parse($date)->format('d/m/Y');
            }, $coveredDays),
            'remarks' => $payment->remarks ?? '',
            'recorded_by' => $payment->recordedBy->name ?? 'System',
        ];
    }

    /**
     * Format payment period based on covered days
     */
    private function formatPaymentPeriod(array $coveredDays): string
    {
        $daysCount = count($coveredDays);
        
        if ($daysCount === 1) {
            return '1 siku';
        } elseif ($daysCount <= 7) {
            return $daysCount . ' siku';
        } elseif ($daysCount <= 14) {
            return '1-2 wiki';
        } elseif ($daysCount <= 30) {
            return round($daysCount / 7) . ' wiki';
        } else {
            return round($daysCount / 30) . ' miezi';
        }
    }

    /**
     * Convert amount to words in Swahili
     */
    private function convertAmountToWords(float $amount): string
    {
        // Basic implementation - you can enhance this with a proper Swahili number formatter
        $integerPart = floor($amount);
        $decimalPart = round(($amount - $integerPart) * 100);
        
        $words = $this->numberToWords($integerPart) . ' shilingi';
        
        if ($decimalPart > 0) {
            $words .= ' na senti ' . $this->numberToWords($decimalPart);
        }
        
        return ucfirst($words);
    }

    /**
     * Basic number to words conversion (you can enhance this)
     */
    private function numberToWords(int $number): string
    {
        if ($number == 0) return 'sifuri';
        
        // This is a simplified version - you may want to use a proper library
        $units = ['', 'moja', 'mbili', 'tatu', 'nne', 'tano', 'sita', 'saba', 'nane', 'tisa'];
        $teens = ['kumi', 'kumi na moja', 'kumi na mbili', 'kumi na tatu', 'kumi na nne', 'kumi na tano', 'kumi na sita', 'kumi na saba', 'kumi na nane', 'kumi na tisa'];
        $tens = ['', '', 'ishirini', 'thelathini', 'arobaini', 'hamsini', 'sitini', 'sabini', 'themanini', 'tisini'];
        
        if ($number < 10) {
            return $units[$number];
        } elseif ($number < 20) {
            return $teens[$number - 10];
        } elseif ($number < 100) {
            $ten = intval($number / 10);
            $unit = $number % 10;
            return $tens[$ten] . ($unit > 0 ? ' na ' . $units[$unit] : '');
        }
        
        // For larger numbers, you would need to expand this
        return (string)$number;
    }

    /**
     * Send receipt via specified method
     */
    private function sendReceiptVia(PaymentReceipt $receipt, string $method, string $contactInfo): array
    {
        switch ($method) {
            case 'whatsapp':
                return $this->sendViaWhatsApp($receipt, $contactInfo);
            case 'email':
                return $this->sendViaEmail($receipt, $contactInfo);
            case 'system':
                return $this->sendViaSystem($receipt, $contactInfo);
            default:
                return ['success' => false, 'message' => 'Invalid send method'];
        }
    }

    /**
     * Send receipt via WhatsApp (placeholder implementation)
     */
    private function sendViaWhatsApp(PaymentReceipt $receipt, string $phone): array
    {
        // Implement WhatsApp API integration here
        // For now, we'll simulate success
        
        return [
            'success' => true,
            'message' => 'Receipt sent via WhatsApp to ' . $phone
        ];
    }

    /**
     * Send receipt via Email (placeholder implementation)
     */
    private function sendViaEmail(PaymentReceipt $receipt, string $email): array
    {
        // Implement email sending here using Laravel Mail
        // For now, we'll simulate success
        
        return [
            'success' => true,
            'message' => 'Receipt sent via email to ' . $email
        ];
    }

    /**
     * Send receipt via System message (placeholder implementation)
     */
    private function sendViaSystem(PaymentReceipt $receipt, string $identifier): array
    {
        // Implement in-app notification system here
        // For now, we'll simulate success
        
        return [
            'success' => true,
            'message' => 'Receipt sent via system message'
        ];
    }
}