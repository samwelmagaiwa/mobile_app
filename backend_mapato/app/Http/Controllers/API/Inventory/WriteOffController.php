<?php

namespace App\Http\Controllers\Inventory;

use App\Services\Inventory\InventoryNotifier;
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
    public function __construct(
        private readonly StockLedger $ledger,
        private readonly InventoryNotifier $notifier,
    ) {
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

        $requestedBy = optional($request->user())->id;
        $reference = 'WO-' . now()->format('Ymd-His');

        $id = DB::table('inventory_write_offs')->insertGetId([
            'reference' => $reference,
            'product_id' => $data['product_id'],
            'batch_id' => $data['batch_id'] ?? null,
            'reason' => $data['reason'],
            'quantity' => $data['quantity'],
            'cost_value' => $unitCost * $data['quantity'],
            'note' => $data['note'] ?? null,
            'status' => 'pending',
            'requested_by' => $requestedBy,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $productName = (string) DB::table('inventory_products')
            ->where('id', $data['product_id'])->value('name');

        $this->notifier->notifyByPermission(
            permissions: ['inv_manage_stock'],
            type: 'write_off_pending',
            title: 'Write-off awaiting approval',
            body: trim($productName . ' × ' . $data['quantity'] . ' (' . $data['reason'] . ') — ' . $reference),
            data: ['write_off_id' => (int) $id, 'reference' => $reference],
            excludeUserId: $requestedBy,
        );

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

        // Segregation of duties: whoever flagged the damage cannot also be
        // the one who signs off on removing the stock, even if they happen
        // to hold inv_manage_stock themselves.
        if ($writeOff->requested_by !== null && $userId !== null
            && (string) $writeOff->requested_by === (string) $userId) {
            return response()->json([
                'message' => 'You cannot approve your own write-off request',
            ], 403);
        }

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

        $this->notifier->notifyUser(
            userId: $writeOff->requested_by,
            type: 'write_off_decided',
            title: 'Write-off ' . $data['decision'],
            body: $writeOff->reference . ' was ' . $data['decision']
                . ($data['decision_note'] ?? null ? ' — ' . $data['decision_note'] : ''),
            data: ['write_off_id' => $id, 'reference' => $writeOff->reference, 'decision' => $data['decision']],
        );

        return response()->json(['message' => 'Write-off ' . $data['decision']]);
    }
}
