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

            $receipts = \App\Models\Receipt::whereHas('transaction', function ($query) use ($driver) {
                $query->where('driver_id', $driver->id);
            })
            ->with('transaction.device')
            ->orderBy('issued_at', 'desc')
            ->paginate($perPage);

            return ResponseHelper::success($receipts, 'Receipts retrieved successfully');

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