<?php

namespace App\Http\Controllers\Inventory;

use App\Services\Inventory\StockLedger;
use Illuminate\Http\Request;
use Illuminate\Routing\Controller;
use Illuminate\Support\Facades\DB;
use RuntimeException;

/**
 * Area 3 — batches and expiry dates.
 */
class BatchController extends Controller
{
    public function __construct(private readonly StockLedger $ledger)
    {
    }

    /** Batches, newest first. Filterable by product, status and expiry window. */
    public function index(Request $request)
    {
        $query = DB::table('inventory_batches as b')
            ->join('inventory_products as p', 'p.id', '=', 'b.product_id')
            ->select(
                'b.*',
                'p.name as product_name',
                'p.sku as product_sku',
                'p.unit as product_unit',
            );

        if ($productId = $request->query('product_id')) {
            $query->where('b.product_id', (int) $productId);
        }
        if ($status = $request->query('status')) {
            $query->where('b.status', $status);
        }
        if ($request->boolean('in_stock')) {
            $query->where('b.quantity', '>', 0);
        }
        if ($days = $request->query('expiring_in_days')) {
            $query->whereNotNull('b.expiry_date')
                ->whereDate('b.expiry_date', '<=', now()->addDays((int) $days)->toDateString())
                ->where('b.quantity', '>', 0);
        }
        if ($request->boolean('expired')) {
            $query->whereNotNull('b.expiry_date')
                ->whereDate('b.expiry_date', '<', now()->toDateString())
                ->where('b.quantity', '>', 0);
        }
        if ($q = $request->query('q')) {
            $query->where(function ($w) use ($q) {
                $w->where('b.batch_number', 'like', "%{$q}%")
                    ->orWhere('p.name', 'like', "%{$q}%")
                    ->orWhere('p.sku', 'like', "%{$q}%");
            });
        }

        $rows = $query
            ->orderByRaw('CASE WHEN b.expiry_date IS NULL THEN 1 ELSE 0 END')
            ->orderBy('b.expiry_date')
            ->orderByDesc('b.id')
            ->paginate((int) $request->query('per_page', 50));

        return response()->json([
            'data' => $rows->items(),
            'meta' => [
                'current_page' => $rows->currentPage(),
                'last_page' => $rows->lastPage(),
                'per_page' => $rows->perPage(),
                'total' => $rows->total(),
            ],
        ]);
    }

    /** Receive stock into a batch. Creates the batch when the number is new. */
    public function store(Request $request)
    {
        $data = $request->validate([
            'product_id' => 'required|integer|exists:inventory_products,id',
            'batch_number' => 'required|string|max:64',
            'quantity' => 'required|integer|min:1',
            'expiry_date' => 'nullable|date',
            'cost_price' => 'nullable|numeric|min:0',
            'reference' => 'nullable|string|max:255',
        ]);

        try {
            $batchId = DB::transaction(fn () => $this->ledger->receive(
                (int) $data['product_id'],
                (int) $data['quantity'],
                $data['batch_number'],
                $data['expiry_date'] ?? null,
                isset($data['cost_price']) ? (float) $data['cost_price'] : null,
                $data['reference'] ?? null,
                optional($request->user())->id,
            ));
        } catch (RuntimeException $e) {
            return response()->json(['message' => $e->getMessage()], 422);
        }

        return response()->json([
            'message' => 'Stock received',
            'data' => ['id' => $batchId],
        ], 201);
    }

    public function update(Request $request, int $id)
    {
        if (! DB::table('inventory_batches')->where('id', $id)->exists()) {
            return response()->json(['message' => 'Not found'], 404);
        }

        $data = $request->validate([
            'expiry_date' => 'nullable|date',
            'status' => 'sometimes|required|in:active,depleted,quarantined',
            'reference' => 'nullable|string|max:255',
        ]);

        DB::table('inventory_batches')->where('id', $id)
            ->update(array_merge($data, ['updated_at' => now()]));

        return response()->json(['message' => 'Batch updated']);
    }

    /** Counts for the alert badges: expired and expiring within N days. */
    public function expirySummary(Request $request)
    {
        $days = (int) $request->query('days', 30);
        $today = now()->toDateString();
        $horizon = now()->addDays($days)->toDateString();

        $base = fn () => DB::table('inventory_batches')
            ->where('quantity', '>', 0)
            ->whereNotNull('expiry_date');

        return response()->json(['data' => [
            'expired' => (clone $base())->whereDate('expiry_date', '<', $today)->count(),
            'expiring_soon' => (clone $base())
                ->whereDate('expiry_date', '>=', $today)
                ->whereDate('expiry_date', '<=', $horizon)
                ->count(),
            'days' => $days,
        ]]);
    }
}
