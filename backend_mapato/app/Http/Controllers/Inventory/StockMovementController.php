<?php

namespace App\Http\Controllers\Inventory;

use App\Services\Inventory\StockLedger;
use Illuminate\Http\Request;
use Illuminate\Routing\Controller;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;
use RuntimeException;

class StockMovementController extends Controller
{
    public function __construct(private readonly StockLedger $ledger)
    {
    }

    /**
     * List stock movement audit logs with optional filters (product_id, type, dates).
     */
    public function index(Request $request)
    {
        $query = DB::table('inventory_stock_movements as sm')
            ->leftJoin('inventory_products as p', 'sm.product_id', '=', 'p.id')
            ->leftJoin('inventory_batches as b', 'sm.batch_id', '=', 'b.id')
            ->leftJoin('users as u', 'sm.user_id', '=', 'u.id')
            ->select([
                'sm.id',
                'sm.product_id',
                'p.name as product_name',
                'p.sku as product_sku',
                'sm.batch_id',
                'b.batch_number',
                'sm.type',
                'sm.quantity',
                'sm.previous_quantity',
                'sm.new_quantity',
                'sm.reason',
                'sm.reference',
                'sm.user_id',
                'u.name as user_name',
                'sm.created_at',
            ]);

        if ($request->filled('product_id')) {
            $query->where('sm.product_id', (int) $request->product_id);
        }

        if ($request->filled('type')) {
            $query->where('sm.type', $request->type);
        }

        if ($request->filled('date_from')) {
            $query->whereDate('sm.created_at', '>=', $request->date_from);
        }

        if ($request->filled('date_to')) {
            $query->whereDate('sm.created_at', '<=', $request->date_to);
        }

        $movements = $query->orderBy('sm.created_at', 'desc')
            ->orderBy('sm.id', 'desc')
            ->limit(200)
            ->get();

        return response()->json([
            'success' => true,
            'data' => $movements,
        ]);
    }

    /**
     * Stock in / out. Goes through the ledger so batches and the movement log
     * stay consistent: issues are allocated first-expiring-first (Area 3).
     */
    public function store(Request $request)
    {
        $v = Validator::make($request->all(), [
            'product_id' => 'required|exists:inventory_products,id',
            'type' => 'required|in:in,out',
            'quantity' => 'required|integer|min:1',
            'reference' => 'nullable|string',
            'batch_id' => 'nullable|integer|exists:inventory_batches,id',
            'batch_number' => 'nullable|string|max:64',
            'expiry_date' => 'nullable|date',
            'cost_price' => 'nullable|numeric|min:0',
        ]);
        if ($v->fails()) {
            return response()->json(['message' => $v->errors()->first()], 422);
        }

        $productId = (int) $request->product_id;
        $quantity = (int) $request->quantity;
        $userId = optional($request->user())->id;

        try {
            DB::transaction(function () use ($request, $productId, $quantity, $userId) {
                if ($request->type === 'in') {
                    $this->ledger->receive(
                        $productId,
                        $quantity,
                        $request->input('batch_number') ?: 'ADJ-' . now()->format('Ymd'),
                        $request->input('expiry_date'),
                        $request->filled('cost_price') ? (float) $request->input('cost_price') : null,
                        $request->input('reference'),
                        $userId,
                    );

                    return;
                }

                $this->ledger->issue(
                    $productId,
                    $quantity,
                    $request->input('reference'),
                    'adjustment',
                    $userId,
                    $request->filled('batch_id') ? (int) $request->input('batch_id') : null,
                );
            });
        } catch (RuntimeException $e) {
            return response()->json(['message' => $e->getMessage()], 422);
        }

        return response()->json(['message' => 'Stock updated'], 201);
    }
}

