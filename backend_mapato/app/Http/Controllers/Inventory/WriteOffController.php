<?php

namespace App\Http\Controllers\Inventory;

use App\Services\Inventory\StockLedger;
use Illuminate\Http\Request;
use Illuminate\Routing\Controller;
use Illuminate\Support\Facades\DB;
use RuntimeException;

/**
 * Area 3 — damages, breakages and expired goods.
 *
 * A write-off is a request. Stock only moves when a manager approves it.
 */
class WriteOffController extends Controller
{
    public function __construct(private readonly StockLedger $ledger)
    {
    }

    public function index(Request $request)
    {
        $query = DB::table('inventory_write_offs as w')
            ->join('inventory_products as p', 'p.id', '=', 'w.product_id')
            ->leftJoin('inventory_batches as b', 'b.id', '=', 'w.batch_id')
            ->leftJoin('users as ru', 'ru.id', '=', 'w.requested_by')
            ->leftJoin('users as au', 'au.id', '=', 'w.approved_by')
            ->select(
                'w.*',
                'p.name as product_name',
                'p.sku as product_sku',
                'b.batch_number',
                'ru.name as requested_by_name',
                'au.name as approved_by_name',
            );

        if ($status = $request->query('status')) {
            $query->where('w.status', $status);
        }
        if ($reason = $request->query('reason')) {
            $query->where('w.reason', $reason);
        }
        if ($productId = $request->query('product_id')) {
            $query->where('w.product_id', (int) $productId);
        }

        return response()->json(['data' => $query->orderByDesc('w.id')->limit(200)->get()]);
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'product_id' => 'required|integer|exists:inventory_products,id',
            'batch_id' => 'nullable|integer|exists:inventory_batches,id',
            'reason' => 'required|in:damage,breakage,expiry,theft,other',
            'quantity' => 'required|integer|min:1',
            'note' => 'nullable|string|max:255',
        ]);

        $available = $data['batch_id'] ?? null
            ? (int) DB::table('inventory_batches')->where('id', $data['batch_id'])->value('quantity')
            : (int) DB::table('inventory_products')->where('id', $data['product_id'])->value('quantity');

        if ($data['quantity'] > $available) {
            return response()->json(['message' => 'Quantity exceeds what is in stock'], 422);
        }

        $unitCost = $data['batch_id'] ?? null
            ? (float) DB::table('inventory_batches')->where('id', $data['batch_id'])->value('cost_price')
            : (float) DB::table('inventory_products')->where('id', $data['product_id'])->value('cost_price');

        $id = DB::table('inventory_write_offs')->insertGetId([
            'reference' => 'WO-' . now()->format('Ymd-His'),
            'product_id' => $data['product_id'],
            'batch_id' => $data['batch_id'] ?? null,
            'reason' => $data['reason'],
            'quantity' => $data['quantity'],
            'cost_value' => $unitCost * $data['quantity'],
            'note' => $data['note'] ?? null,
            'status' => 'pending',
            'requested_by' => optional($request->user())->id,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        return response()->json([
            'message' => 'Write-off submitted for approval',
            'data' => ['id' => (int) $id],
        ], 201);
    }

    /** Approve and remove the stock, or reject and leave it alone. */
    public function decide(Request $request, int $id)
    {
        $writeOff = DB::table('inventory_write_offs')->find($id);
        if (! $writeOff) {
            return response()->json(['message' => 'Not found'], 404);
        }
        if ($writeOff->status !== 'pending') {
            return response()->json(['message' => 'Already ' . $writeOff->status], 422);
        }

        $data = $request->validate([
            'decision' => 'required|in:approved,rejected',
            'decision_note' => 'nullable|string|max:255',
        ]);

        $userId = optional($request->user())->id;

        try {
            DB::transaction(function () use ($writeOff, $data, $userId, $id) {
                if ($data['decision'] === 'approved') {
                    $this->ledger->issue(
                        (int) $writeOff->product_id,
                        (int) $writeOff->quantity,
                        $writeOff->reference,
                        $writeOff->reason,
                        $userId,
                        $writeOff->batch_id !== null ? (int) $writeOff->batch_id : null,
                    );
                }

                DB::table('inventory_write_offs')->where('id', $id)->update([
                    'status' => $data['decision'],
                    'approved_by' => $userId,
                    'approved_at' => now(),
                    'decision_note' => $data['decision_note'] ?? null,
                    'updated_at' => now(),
                ]);
            });
        } catch (RuntimeException $e) {
            return response()->json(['message' => $e->getMessage()], 422);
        }

        return response()->json(['message' => 'Write-off ' . $data['decision']]);
    }
}
