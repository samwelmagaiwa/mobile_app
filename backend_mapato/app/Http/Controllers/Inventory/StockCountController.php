<?php

namespace App\Http\Controllers\Inventory;

use App\Services\Inventory\StockLedger;
use Illuminate\Http\Request;
use Illuminate\Routing\Controller;
use Illuminate\Support\Facades\DB;
use RuntimeException;

/**
 * Area 3 — physical stock counts with variance.
 *
 * A count is captured as a draft; nothing moves until it is posted, and once
 * posted it is frozen.
 */
class StockCountController extends Controller
{
    public function __construct(private readonly StockLedger $ledger)
    {
    }

    public function index(Request $request)
    {
        $query = DB::table('inventory_stock_counts as sc')
            ->leftJoin('users as u', 'u.id', '=', 'sc.counted_by')
            ->leftJoin('inventory_stock_count_lines as l', 'l.stock_count_id', '=', 'sc.id')
            ->select(
                'sc.*',
                'u.name as counted_by_name',
                DB::raw('COUNT(l.id) as lines_count'),
                DB::raw('COALESCE(SUM(ABS(l.variance)), 0) as total_variance'),
            )
            ->groupBy(
                'sc.id', 'sc.reference', 'sc.status', 'sc.note', 'sc.counted_by',
                'sc.posted_by', 'sc.posted_at', 'sc.created_at', 'sc.updated_at', 'u.name',
            );

        if ($status = $request->query('status')) {
            $query->where('sc.status', $status);
        }

        return response()->json(['data' => $query->orderByDesc('sc.id')->limit(100)->get()]);
    }

    public function show(int $id)
    {
        $count = DB::table('inventory_stock_counts')->find($id);
        if (! $count) {
            return response()->json(['message' => 'Not found'], 404);
        }

        $count->lines = DB::table('inventory_stock_count_lines as l')
            ->join('inventory_products as p', 'p.id', '=', 'l.product_id')
            ->leftJoin('inventory_batches as b', 'b.id', '=', 'l.batch_id')
            ->where('l.stock_count_id', $id)
            ->select(
                'l.*',
                'p.name as product_name',
                'p.sku as product_sku',
                'b.batch_number',
            )
            ->orderBy('p.name')
            ->get();

        return response()->json(['data' => $count]);
    }

    public function store(Request $request)
    {
        $data = $request->validate(['note' => 'nullable|string|max:255']);

        $id = DB::table('inventory_stock_counts')->insertGetId([
            'reference' => 'SC-' . now()->format('Ymd-His'),
            'status' => 'draft',
            'note' => $data['note'] ?? null,
            'counted_by' => optional($request->user())->id,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        return response()->json(['message' => 'Stock count opened', 'data' => ['id' => (int) $id]], 201);
    }

    /** Add or replace one counted line. System quantity is read at capture time. */
    public function saveLine(Request $request, int $id)
    {
        $count = DB::table('inventory_stock_counts')->find($id);
        if (! $count) {
            return response()->json(['message' => 'Not found'], 404);
        }
        if ($count->status !== 'draft') {
            return response()->json(['message' => 'This count is already ' . $count->status], 422);
        }

        $data = $request->validate([
            'product_id' => 'required|integer|exists:inventory_products,id',
            'batch_id' => 'nullable|integer|exists:inventory_batches,id',
            'counted_quantity' => 'required|integer|min:0',
            'note' => 'nullable|string|max:255',
        ]);

        $batchId = $data['batch_id'] ?? null;

        // A product can be counted as one whole-product line OR as one line
        // per batch, never both -- mixing them corrupts the total, since a
        // whole-product line overwrites quantity directly while a batch
        // line only adjusts by variance. Whichever mode is already in use
        // for this product in this count wins.
        $conflict = DB::table('inventory_stock_count_lines')
            ->where('stock_count_id', $id)
            ->where('product_id', $data['product_id'])
            ->where(fn ($w) => $batchId === null
                ? $w->whereNotNull('batch_id')
                : $w->whereNull('batch_id'))
            ->exists();
        if ($conflict) {
            return response()->json([
                'message' => $batchId === null
                    ? 'This product already has batch-specific lines in this count. Remove them first, or add this count by batch instead.'
                    : 'This product already has a whole-product line in this count. Remove it first, or count the whole product instead.',
            ], 422);
        }

        $systemQty = $batchId !== null
            ? (int) DB::table('inventory_batches')->where('id', $batchId)->value('quantity')
            : (int) DB::table('inventory_products')->where('id', $data['product_id'])->value('quantity');

        $counted = (int) $data['counted_quantity'];

        $existing = DB::table('inventory_stock_count_lines')
            ->where('stock_count_id', $id)
            ->where('product_id', $data['product_id'])
            ->where(fn ($w) => $batchId === null
                ? $w->whereNull('batch_id')
                : $w->where('batch_id', $batchId))
            ->first();

        $payload = [
            'system_quantity' => $systemQty,
            'counted_quantity' => $counted,
            'variance' => $counted - $systemQty,
            'note' => $data['note'] ?? null,
            'updated_at' => now(),
        ];

        if ($existing) {
            DB::table('inventory_stock_count_lines')->where('id', $existing->id)->update($payload);
        } else {
            DB::table('inventory_stock_count_lines')->insert(array_merge($payload, [
                'stock_count_id' => $id,
                'product_id' => $data['product_id'],
                'batch_id' => $batchId,
                'created_at' => now(),
            ]));
        }

        return response()->json(['message' => 'Line saved', 'data' => $payload]);
    }

    public function deleteLine(int $id, int $lineId)
    {
        $count = DB::table('inventory_stock_counts')->find($id);
        if (! $count) {
            return response()->json(['message' => 'Not found'], 404);
        }
        if ($count->status !== 'draft') {
            return response()->json(['message' => 'This count is already ' . $count->status], 422);
        }

        DB::table('inventory_stock_count_lines')
            ->where('stock_count_id', $id)->where('id', $lineId)->delete();

        return response()->json(['message' => 'Line removed']);
    }

    /** Apply every variance to stock and freeze the count. */
    public function post(Request $request, int $id)
    {
        $count = DB::table('inventory_stock_counts')->find($id);
        if (! $count) {
            return response()->json(['message' => 'Not found'], 404);
        }
        if ($count->status !== 'draft') {
            return response()->json(['message' => 'This count is already ' . $count->status], 422);
        }

        $lines = DB::table('inventory_stock_count_lines')->where('stock_count_id', $id)->get();
        if ($lines->isEmpty()) {
            return response()->json(['message' => 'Nothing counted yet'], 422);
        }

        // Defensive: a product must not have both a whole-product line and a
        // batch-specific line in the same count (see saveLine) -- posting
        // that combination would silently corrupt the product's total.
        $byProduct = $lines->groupBy('product_id');
        foreach ($byProduct as $productLines) {
            $hasWholeProduct = $productLines->contains(fn ($l) => $l->batch_id === null);
            $hasBatch = $productLines->contains(fn ($l) => $l->batch_id !== null);
            if ($hasWholeProduct && $hasBatch) {
                return response()->json([
                    'message' => 'One product has both a whole-product line and batch lines in this count. Remove one before posting.',
                ], 422);
            }
        }

        $userId = optional($request->user())->id;

        try {
            $applied = DB::transaction(function () use ($lines, $count, $userId, $id) {
                $applied = 0;
                foreach ($lines as $line) {
                    $variance = $this->ledger->adjustTo(
                        (int) $line->product_id,
                        (int) $line->counted_quantity,
                        $line->batch_id !== null ? (int) $line->batch_id : null,
                        $count->reference,
                        $userId,
                    );
                    if ($variance !== 0) {
                        $applied++;
                    }
                }

                DB::table('inventory_stock_counts')->where('id', $id)->update([
                    'status' => 'posted',
                    'posted_by' => $userId,
                    'posted_at' => now(),
                    'updated_at' => now(),
                ]);

                return $applied;
            });
        } catch (RuntimeException $e) {
            return response()->json(['message' => $e->getMessage()], 422);
        }

        return response()->json([
            'message' => 'Stock count posted',
            'data' => ['adjusted_lines' => $applied],
        ]);
    }

    public function cancel(int $id)
    {
        $count = DB::table('inventory_stock_counts')->find($id);
        if (! $count) {
            return response()->json(['message' => 'Not found'], 404);
        }
        if ($count->status !== 'draft') {
            return response()->json(['message' => 'This count is already ' . $count->status], 422);
        }

        DB::table('inventory_stock_counts')->where('id', $id)
            ->update(['status' => 'cancelled', 'updated_at' => now()]);

        return response()->json(['message' => 'Stock count cancelled']);
    }
}
