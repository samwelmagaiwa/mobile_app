<?php

namespace App\Http\Controllers\Inventory;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Log;
use Illuminate\Routing\Controller;
use Illuminate\Support\Facades\DB as Database;

class SalesController extends Controller
{
    public function index(Request $request)
    {
        $status = $request->query('status');
        $from = $request->query('from');
        $to = $request->query('to');

        $query = DB::table('inventory_sales')->orderByDesc('id');
        if ($status && in_array($status, ['paid','debt','partial'])) {
            $query->where('payment_status', $status);
        }
        if ($from) {
            $query->whereDate('created_at', '>=', $from);
        }
        if ($to) {
            $query->whereDate('created_at', '<=', $to);
        }
        $sales = $query->paginate(20);
        return response()->json([
            'data' => $sales->items(),
            'meta' => [
                'current_page' => $sales->currentPage(),
                'last_page' => $sales->lastPage(),
                'per_page' => $sales->perPage(),
                'total' => $sales->total(),
            ],
        ]);
    }

    public function store(Request $request)
    {
        $v = Validator::make($request->all(), [
            'customer_id' => 'nullable|exists:inventory_customers,id',
            'payment_status' => 'required|in:paid,debt,partial',
            'subtotal' => 'required|numeric|min:0',
            'discount' => 'nullable|numeric|min:0',
            'tax' => 'nullable|numeric|min:0',
            'total' => 'required|numeric|min:0',
            'paid_total' => 'required|numeric|min:0',
            'due_date' => 'nullable|date',
            'items' => 'required|array|min:1',
            'items.*.product_id' => 'required|exists:inventory_products,id',
            'items.*.quantity' => 'required|integer|min:1',
            'items.*.unit_price' => 'required|numeric|min:0',
            'items.*.unit_cost_snapshot' => 'required|numeric|min:0',
            'payments' => 'sometimes|array',
            'payments.*.amount' => 'required|numeric|min:0.01',
            'payments.*.method' => 'required|in:cash,mobile_money,bank_transfer',
            'payments.*.reference' => 'nullable|string',
            'payments.*.paid_at' => 'nullable|date',
        ]);
        if ($v->fails()) {
            return response()->json(['message' => $v->errors()->first()], 422);
        }

        // Enforce customer for debt/partial
        if (in_array($request->payment_status, ['debt','partial']) && empty($request->customer_id)) {
            return response()->json(['message' => 'Customer required for debt/partial'], 422);
        }

        return Database::transaction(function () use ($request) {
            // Generate sale number
            $nextId = (DB::table('inventory_sales')->max('id') ?? 0) + 1;
            $number = 'S'.str_pad((string)$nextId, 5, '0', STR_PAD_LEFT);

            // Create sale
            $saleId = DB::table('inventory_sales')->insertGetId([
                'number' => $number,
                'customer_id' => $request->customer_id,
                'payment_status' => $request->payment_status,
                'subtotal' => $request->subtotal,
                'discount' => $request->discount ?? 0,
                'tax' => $request->tax ?? 0,
                'total' => $request->total,
                'paid_total' => $request->paid_total,
                'due_date' => $request->payment_status === 'paid' ? null : $request->due_date,
                'created_by' => optional($request->user())->id,
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            // Insert items and deduct stock (prevent negative)
            foreach ($request->items as $item) {
                $product = DB::table('inventory_products')->lockForUpdate()->find($item['product_id']);
                if (!$product) {
                    throw new \RuntimeException('Product not found');
                }
                if (($product->quantity - (int)$item['quantity']) < 0) {
                    return response()->json(['message' => 'Insufficient stock for product '.$product->name], 422);
                }
                // Deduct
                DB::table('inventory_products')->where('id', $product->id)->update([
                    'quantity' => $product->quantity - (int)$item['quantity'],
                ]);
                // Record item
                DB::table('inventory_sale_items')->insert([
                    'sale_id' => (int)$saleId,
                    'product_id' => (int)$item['product_id'],
                    'quantity' => (int)$item['quantity'],
                    'unit_price' => (float)$item['unit_price'],
                    'unit_cost_snapshot' => (float)$item['unit_cost_snapshot'],
                    'total' => (float)$item['unit_price'] * (int)$item['quantity'],
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);
            }

            // Payments
            if (is_array($request->payments)) {
                foreach ($request->payments as $p) {
                    DB::table('inventory_sale_payments')->insert([
                        'sale_id' => (int)$saleId,
                        'amount' => (float)$p['amount'],
                        'method' => $p['method'] ?? 'cash',
                        'reference' => $p['reference'] ?? null,
                        'paid_at' => $p['paid_at'] ?? now(),
                        'created_at' => now(),
                        'updated_at' => now(),
                    ]);
                }
            }

            // Reminder (server-side) if partial or debt
            if (in_array($request->payment_status, ['debt','partial'])) {
                DB::table('inventory_reminders')->insert([
                    'type' => 'payment_due',
                    'related_id' => (int)$saleId,
                    'title' => 'Payment Due',
                    'description' => 'Outstanding balance for sale '.$number,
                    'due_at' => $request->due_date ?? now()->addDays(7),
                    'status' => 'open',
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);
            }

            return response()->json([
                'message' => 'Sale created',
                'data' => [ 'id' => (int)$saleId, 'number' => $number ],
            ], 201);
        });
    }
}
