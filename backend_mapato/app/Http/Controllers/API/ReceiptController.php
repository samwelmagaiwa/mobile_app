<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\Receipt;
use App\Models\Transaction;
use App\Helpers\ResponseHelper;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Barryvdh\DomPDF\Facade\Pdf;

class ReceiptController extends Controller
{
    /**
     * Get all receipts for authenticated driver
     */
    public function index(Request $request)
    {
        try {
            $driver = $request->user()->driver;
            $perPage = $request->get('per_page', 15);

            $receipts = Receipt::whereHas('transaction', function ($query) use ($driver) {
                $query->where('driver_id', $driver->id);
            })
            ->with('transaction.device')
            ->orderBy('created_at', 'desc')
            ->paginate($perPage);

            return ResponseHelper::success($receipts, 'Receipts retrieved successfully');
        } catch (\Exception $e) {
            return ResponseHelper::error('Failed to retrieve receipts: ' . $e->getMessage(), 500);
        }
    }

    /**
     * Generate receipt for transaction
     */
    public function generate(Request $request)
    {
        try {
            $request->validate([
                'transaction_id' => 'required|exists:transactions,id',
                'customer_name' => 'required|string|max:255',
                'customer_phone' => 'nullable|string|max:20',
                'service_description' => 'required|string|max:500',
                'notes' => 'nullable|string|max:1000',
            ]);

            $driver = $request->user()->driver;
            $transaction = Transaction::where('driver_id', $driver->id)
                                    ->with('device')
                                    ->findOrFail($request->transaction_id);

            // Check if receipt already exists
            if ($transaction->receipt) {
                return ResponseHelper::error('Receipt already exists for this transaction', 400);
            }

            // Generate receipt number
            $receiptNumber = 'R' . date('Ymd') . str_pad(Receipt::count() + 1, 4, '0', STR_PAD_LEFT);

            // Create receipt record
            $receipt = Receipt::create([
                'transaction_id' => $transaction->id,
                'receipt_number' => $receiptNumber,
                'customer_name' => $request->customer_name,
                'customer_phone' => $request->customer_phone,
                'service_description' => $request->service_description,
                'amount' => $transaction->amount,
                'notes' => $request->notes,
                'issued_at' => now(),
            ]);

            // Generate PDF
            $pdfData = [
                'receipt' => $receipt,
                'transaction' => $transaction,
                'driver' => $driver,
                'device' => $transaction->device,
            ];

            $pdf = Pdf::loadView('receipts.template', $pdfData);
            $pdfContent = $pdf->output();

            // Store PDF file
            $fileName = "receipt_{$receiptNumber}.pdf";
            $filePath = "receipts/{$fileName}";
            Storage::put($filePath, $pdfContent);

            // Update receipt with file path
            $receipt->update(['file_path' => $filePath]);

            $receipt->load('transaction.device');

            return ResponseHelper::success($receipt, 'Receipt generated successfully', 201);
        } catch (\Exception $e) {
            return ResponseHelper::error('Failed to generate receipt: ' . $e->getMessage(), 500);
        }
    }

    /**
     * Show specific receipt
     */
    public function show(Request $request, $id)
    {
        try {
            $driver = $request->user()->driver;
            $receipt = Receipt::whereHas('transaction', function ($query) use ($driver) {
                $query->where('driver_id', $driver->id);
            })
            ->with('transaction.device')
            ->findOrFail($id);

            return ResponseHelper::success($receipt, 'Receipt retrieved successfully');
        } catch (\Exception $e) {
            return ResponseHelper::error('Receipt not found', 404);
        }
    }

    /**
     * Download receipt PDF
     */
    public function download(Request $request, $id)
    {
        try {
            $driver = $request->user()->driver;
            $receipt = Receipt::whereHas('transaction', function ($query) use ($driver) {
                $query->where('driver_id', $driver->id);
            })->findOrFail($id);

            if (!$receipt->file_path || !Storage::exists($receipt->file_path)) {
                return ResponseHelper::error('Receipt file not found', 404);
            }

            return Storage::download($receipt->file_path, "receipt_{$receipt->receipt_number}.pdf");
        } catch (\Exception $e) {
            return ResponseHelper::error('Failed to download receipt: ' . $e->getMessage(), 500);
        }
    }

    /**
     * Delete receipt
     */
    public function destroy(Request $request, $id)
    {
        try {
            $driver = $request->user()->driver;
            $receipt = Receipt::whereHas('transaction', function ($query) use ($driver) {
                $query->where('driver_id', $driver->id);
            })->findOrFail($id);

            // Delete file if exists
            if ($receipt->file_path && Storage::exists($receipt->file_path)) {
                Storage::delete($receipt->file_path);
            }

            $receipt->delete();

            return ResponseHelper::success(null, 'Receipt deleted successfully');
        } catch (\Exception $e) {
            return ResponseHelper::error('Failed to delete receipt: ' . $e->getMessage(), 500);
        }
    }

    /**
     * Regenerate receipt PDF
     */
    public function regenerate(Request $request, $id)
    {
        try {
            $driver = $request->user()->driver;
            $receipt = Receipt::whereHas('transaction', function ($query) use ($driver) {
                $query->where('driver_id', $driver->id);
            })
            ->with('transaction.device')
            ->findOrFail($id);

            // Delete old file if exists
            if ($receipt->file_path && Storage::exists($receipt->file_path)) {
                Storage::delete($receipt->file_path);
            }

            // Generate new PDF
            $pdfData = [
                'receipt' => $receipt,
                'transaction' => $receipt->transaction,
                'driver' => $driver,
                'device' => $receipt->transaction->device,
            ];

            $pdf = Pdf::loadView('receipts.template', $pdfData);
            $pdfContent = $pdf->output();

            // Store new PDF file
            $fileName = "receipt_{$receipt->receipt_number}.pdf";
            $filePath = "receipts/{$fileName}";
            Storage::put($filePath, $pdfContent);

            // Update receipt with new file path
            $receipt->update(['file_path' => $filePath]);

            return ResponseHelper::success($receipt, 'Receipt regenerated successfully');
        } catch (\Exception $e) {
            return ResponseHelper::error('Failed to regenerate receipt: ' . $e->getMessage(), 500);
        }
    }

    /**
     * Get receipt statistics
     */
    public function statistics(Request $request)
    {
        try {
            $driver = $request->user()->driver;

            $stats = [
                'total_receipts' => Receipt::whereHas('transaction', function ($query) use ($driver) {
                    $query->where('driver_id', $driver->id);
                })->count(),
                'today_receipts' => Receipt::whereHas('transaction', function ($query) use ($driver) {
                    $query->where('driver_id', $driver->id);
                })->whereDate('created_at', today())->count(),
                'this_month_receipts' => Receipt::whereHas('transaction', function ($query) use ($driver) {
                    $query->where('driver_id', $driver->id);
                })->whereMonth('created_at', now()->month)->count(),
                'total_amount' => Receipt::whereHas('transaction', function ($query) use ($driver) {
                    $query->where('driver_id', $driver->id);
                })->sum('amount'),
            ];

            return ResponseHelper::success($stats, 'Receipt statistics retrieved successfully');
        } catch (\Exception $e) {
            return ResponseHelper::error('Failed to retrieve receipt statistics: ' . $e->getMessage(), 500);
        }
    }
}