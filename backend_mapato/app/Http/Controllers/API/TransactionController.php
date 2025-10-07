<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Http\Requests\TransactionRequest;
use App\Models\Transaction;
use App\Services\TransactionService;
use App\Helpers\ResponseHelper;
use Illuminate\Http\Request;

class TransactionController extends Controller
{
    protected $transactionService;

    public function __construct(TransactionService $transactionService)
    {
        $this->transactionService = $transactionService;
    }

    /**
     * Get all transactions for authenticated driver
     */
    public function index(Request $request)
    {
        try {
            $driver = $request->user()->driver;
            $perPage = $request->get('per_page', 15);
            $type = $request->get('type'); // income, expense
            $status = $request->get('status'); // pending, completed, cancelled
            $deviceId = $request->get('device_id');
            $startDate = $request->get('start_date');
            $endDate = $request->get('end_date');

            $query = Transaction::where('driver_id', $driver->id)
                              ->with('device');

            // Apply filters
            if ($type) {
                $query->where('type', $type);
            }

            if ($status) {
                $query->where('status', $status);
            }

            if ($deviceId) {
                $query->where('device_id', $deviceId);
            }

            if ($startDate) {
                $query->whereDate('created_at', '>=', $startDate);
            }

            if ($endDate) {
                $query->whereDate('created_at', '<=', $endDate);
            }

            $transactions = $query->orderBy('created_at', 'desc')
                                 ->paginate($perPage);

            return ResponseHelper::success($transactions, 'Transactions retrieved successfully');
        } catch (\Exception $e) {
            return ResponseHelper::error('Failed to retrieve transactions: ' . $e->getMessage(), 500);
        }
    }

    /**
     * Store a new transaction
     */
    public function store(TransactionRequest $request)
    {
        try {
            $driver = $request->user()->driver;
            
            $transaction = $this->transactionService->createTransaction($driver, $request->validated());

            return ResponseHelper::success($transaction, 'Transaction created successfully', 201);
        } catch (\Exception $e) {
            return ResponseHelper::error('Failed to create transaction: ' . $e->getMessage(), 500);
        }
    }

    /**
     * Show specific transaction
     */
    public function show(Request $request, $id)
    {
        try {
            $driver = $request->user()->driver;
            $transaction = Transaction::where('driver_id', $driver->id)
                                    ->with('device', 'receipt')
                                    ->findOrFail($id);

            return ResponseHelper::success($transaction, 'Transaction retrieved successfully');
        } catch (\Exception $e) {
            return ResponseHelper::error('Transaction not found', 404);
        }
    }

    /**
     * Update transaction
     */
    public function update(TransactionRequest $request, $id)
    {
        try {
            $driver = $request->user()->driver;
            $transaction = Transaction::where('driver_id', $driver->id)->findOrFail($id);

            // Only allow updates for pending transactions
            if ($transaction->status !== 'pending') {
                return ResponseHelper::error('Only pending transactions can be updated', 400);
            }

            $updatedTransaction = $this->transactionService->updateTransaction($transaction, $request->validated());

            return ResponseHelper::success($updatedTransaction, 'Transaction updated successfully');
        } catch (\Exception $e) {
            return ResponseHelper::error('Failed to update transaction: ' . $e->getMessage(), 500);
        }
    }

    /**
     * Delete transaction
     */
    public function destroy(Request $request, $id)
    {
        try {
            $driver = $request->user()->driver;
            $transaction = Transaction::where('driver_id', $driver->id)->findOrFail($id);

            // Only allow deletion for pending transactions
            if ($transaction->status !== 'pending') {
                return ResponseHelper::error('Only pending transactions can be deleted', 400);
            }

            $transaction->delete();

            return ResponseHelper::success(null, 'Transaction deleted successfully');
        } catch (\Exception $e) {
            return ResponseHelper::error('Failed to delete transaction: ' . $e->getMessage(), 500);
        }
    }

    /**
     * Update transaction status
     */
    public function updateStatus(Request $request, $id)
    {
        try {
            $request->validate([
                'status' => 'required|in:pending,completed,cancelled',
            ]);

            $driver = $request->user()->driver;
            $transaction = Transaction::where('driver_id', $driver->id)->findOrFail($id);

            $transaction->update([
                'status' => $request->status,
            ]);

            return ResponseHelper::success($transaction, 'Transaction status updated successfully');
        } catch (\Exception $e) {
            return ResponseHelper::error('Failed to update transaction status: ' . $e->getMessage(), 500);
        }
    }

    /**
     * Get transaction summary
     */
    public function summary(Request $request)
    {
        try {
            $driver = $request->user()->driver;
            $period = $request->get('period', 'month'); // today, week, month, year

            $summary = $this->transactionService->getTransactionSummary($driver, $period);

            return ResponseHelper::success($summary, 'Transaction summary retrieved successfully');
        } catch (\Exception $e) {
            return ResponseHelper::error('Failed to retrieve transaction summary: ' . $e->getMessage(), 500);
        }
    }

    /**
     * Get transactions by device
     */
    public function byDevice(Request $request, $deviceId)
    {
        try {
            $driver = $request->user()->driver;
            $perPage = $request->get('per_page', 15);

            // Verify device belongs to driver
            $device = $driver->devices()->findOrFail($deviceId);

            $transactions = Transaction::where('device_id', $deviceId)
                                     ->with('device')
                                     ->orderBy('created_at', 'desc')
                                     ->paginate($perPage);

            return ResponseHelper::success($transactions, 'Device transactions retrieved successfully');
        } catch (\Exception $e) {
            return ResponseHelper::error('Failed to retrieve device transactions: ' . $e->getMessage(), 500);
        }
    }
}