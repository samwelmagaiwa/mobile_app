<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\DB;
use App\Models\Driver;
use App\Models\DebtRecord;

class DebtsController extends Controller
{
    /**
     * List all drivers with debt summary (including zero-debt)
     */
    public function listDrivers(Request $request): JsonResponse
    {
        try {
            $page = max((int) $request->get('page', 1), 1);
            $limit = min((int) $request->get('limit', 50), 100);
            $search = trim((string) $request->get('q', ''));

            $drivers = Driver::with(['user', 'debtRecords' => function ($q) {
                $q->where('is_paid', false)->orderBy('earning_date');
            }])
            ->when($search !== '', function ($q) use ($search) {
                $q->whereHas('user', function ($uq) use ($search) {
                    $uq->where('name', 'like', "%$search%")
                       ->orWhere('email', 'like', "%$search%")
                       ->orWhere('phone_number', 'like', "%$search%");
                });
            })
            ->get();

            $formatted = $drivers->map(function ($driver) {
                $unpaid = $driver->debtRecords ?? collect();
                $totalDebt = (float) $unpaid->sum(fn ($r) => (float) $r->remaining_amount);
                $dueDates = $unpaid->pluck('earning_date')->map(function ($d) {
                    return $d ? date('Y-m-d', strtotime((string) $d)) : null;
                })->filter()->values();
                return [
                    'id' => (string) $driver->id,
                    'name' => (string) ($driver->name ?? optional($driver->user)->name ?? ''),
                    'phone' => (string) ($driver->phone ?? optional($driver->user)->phone_number ?? ''),
                    'email' => (string) ($driver->email ?? optional($driver->user)->email ?? ''),
                    'license_number' => (string) ($driver->license_number ?? ''),
                    'vehicle_number' => $driver->vehicle_number,
                    'total_debt' => $totalDebt,
                    'unpaid_days' => $unpaid->count(),
                    'due_dates' => $dueDates, // multiple dates supported
                    'payment_status' => $totalDebt > 0 ? 'Ana deni' : 'Hana deni',
                ];
            });

            // Sort: debtors first, larger debt first, then name
            $sorted = $formatted->sortBy([
                ['total_debt', 'desc'],
                ['name', 'asc'],
            ])->values();

            // Manual pagination
            $total = $sorted->count();
            $offset = ($page - 1) * $limit;
            $paged = $sorted->slice($offset, $limit)->values();

            return response()->json([
                'success' => true,
                'message' => 'Drivers listed successfully',
                'data' => [
                    'drivers' => $paged,
                    'pagination' => [
                        'current_page' => $page,
                        'per_page' => $limit,
                        'total' => $total,
                        'total_pages' => (int) ceil(max(1, $total / $limit)),
                    ],
                ],
            ]);
        } catch (\Throwable $e) {
            Log::error('Error listing drivers for debts: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Failed to list drivers',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Create multiple debt records for selected dates
     */
    public function bulkCreate(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'driver_id' => 'required|exists:drivers,id',
            // Support either items[] (date+amount) OR dates[] + amount
            'items' => 'sometimes|array|min:1',
            'items.*.date' => 'required_with:items|date',
            'items.*.amount' => 'required_with:items|numeric|min:0.01',
            'dates' => 'sometimes|array|min:1',
            'dates.*' => 'required_with:dates|date',
            'amount' => 'sometimes|numeric|min:0.01',
            'notes' => 'nullable|string|max:1000',
            'promised_to_pay' => 'sometimes|boolean',
            'promise_to_pay_at' => 'nullable|date',
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
            $driverId = $request->driver_id;
            $driver = Driver::findOrFail($driverId);
            $license = $driver->license_number;
            $created = [];

            if ($request->filled('items')) {
                foreach ($request->items as $item) {
                    $dt = $item['date'];
                    $amt = (float) $item['amount'];
                    $record = DebtRecord::firstOrCreate(
                        [
                            'driver_id' => $driverId,
                            'earning_date' => date('Y-m-d', strtotime($dt)),
                        ],
                        [
                            'expected_amount' => $amt,
                            'paid_amount' => 0,
                            'is_paid' => false,
                            'notes' => $request->notes,
                            'license_number' => $license,
                        ]
                    );

                    // update promise fields if provided
                    if ($request->boolean('promised_to_pay', false)) {
                        $record->promised_to_pay = true;
                        $record->promise_to_pay_at = $request->promise_to_pay_at ? date('Y-m-d', strtotime($request->promise_to_pay_at)) : null;
                        $record->save();
                    }
                    $created[] = $record->toApiResponse();
                }
            } else {
                $amount = (float) $request->amount;
                $dates = $request->dates;
                foreach ($dates as $dt) {
                    $record = DebtRecord::firstOrCreate(
                        [
                            'driver_id' => $driverId,
                            'earning_date' => date('Y-m-d', strtotime($dt)),
                        ],
                        [
                            'expected_amount' => $amount,
                            'paid_amount' => 0,
                            'is_paid' => false,
                            'notes' => $request->notes,
                            'license_number' => $license,
                        ]
                    );

                    // update promise fields if provided
                    if ($request->boolean('promised_to_pay', false)) {
                        $record->promised_to_pay = true;
                        $record->promise_to_pay_at = $request->promise_to_pay_at ? date('Y-m-d', strtotime($request->promise_to_pay_at)) : null;
                        $record->save();
                    }

                    $created[] = $record->toApiResponse();
                }
            }


            DB::commit();
            return response()->json([
                'success' => true,
                'message' => 'Debt records created successfully',
                'data' => [
                    'created' => $created,
                    'count' => count($created),
                ],
            ], 201);
        } catch (\Throwable $e) {
            DB::rollBack();
            Log::error('Error creating debt records: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Failed to create debt records',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * List debt records for a driver
     */
    public function listDriverRecords(string $driverId, Request $request): JsonResponse
    {
        try {
            $unpaidOnly = $request->boolean('unpaid_only', false);
            $month = $request->get('month'); // 1-12
            $year = $request->get('year');

            $q = DebtRecord::byDriver($driverId)->orderBy('earning_date', 'desc');
            if ($unpaidOnly) $q->unpaid();
            if ($month && $year) {
                $q->whereMonth('earning_date', (int) $month)
                  ->whereYear('earning_date', (int) $year);
            }

            $records = $q->get();

            return response()->json([
                'success' => true,
                'message' => 'Debt records loaded',
                'data' => [
                    'debt_records' => $records->map->toApiResponse(),
                    'count' => $records->count(),
                ],
            ]);
        } catch (\Throwable $e) {
            Log::error('Error listing driver debt records: '.$e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Failed to load debt records',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Update an existing debt record
     */
    public function updateRecord(int $id, Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'earning_date' => 'sometimes|date',
            'expected_amount' => 'sometimes|numeric|min:0.01',
            'notes' => 'nullable|string|max:1000',
            'promised_to_pay' => 'sometimes|boolean',
'promise_to_pay_at' => 'nullable|date',
            'license_number' => 'sometimes|string|max:191',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors(),
            ], 422);
        }

        try {
            $record = DebtRecord::findOrFail($id);
            if ($record->is_paid) {
                return response()->json([
                    'success' => false,
                    'message' => 'Cannot edit a paid debt record',
                ], 400);
            }

            $updates = [];
            if ($request->filled('earning_date')) {
                $updates['earning_date'] = date('Y-m-d', strtotime($request->earning_date));
            }
            if ($request->filled('expected_amount')) {
                $updates['expected_amount'] = (float) $request->expected_amount;
            }
            if ($request->exists('notes')) {
                $updates['notes'] = $request->notes;
            }
            if ($request->exists('license_number')) {
                $updates['license_number'] = $request->license_number;
            }
            if ($request->has('promised_to_pay')) {
                $updates['promised_to_pay'] = (bool) $request->promised_to_pay;
            }
            if ($request->exists('promise_to_pay_at')) {
                $updates['promise_to_pay_at'] = $request->promise_to_pay_at ? date('Y-m-d', strtotime($request->promise_to_pay_at)) : null;
            }

            $record->update($updates);

            return response()->json([
                'success' => true,
                'message' => 'Debt record updated successfully',
                'data' => $record->toApiResponse(),
            ]);
        } catch (\Throwable $e) {
            Log::error('Error updating debt record: '.$e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Failed to update debt record',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Delete an existing debt record (only if not paid)
     */
    public function deleteRecord(int $id): JsonResponse
    {
        try {
            $record = DebtRecord::findOrFail($id);
            if ($record->is_paid || $record->payment_id) {
                return response()->json([
                    'success' => false,
                    'message' => 'Cannot delete a paid debt record',
                ], 400);
            }
            $record->delete();
            return response()->json([
                'success' => true,
                'message' => 'Debt record deleted successfully',
            ]);
        } catch (\Throwable $e) {
            Log::error('Error deleting debt record: '.$e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Failed to delete debt record',
                'error' => $e->getMessage(),
            ], 500);
        }
    }
}
