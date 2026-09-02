<?php

namespace App\Services\Inventory;

use Illuminate\Support\Facades\DB;
use RuntimeException;

/**
 * Area 3 — the single place stock quantities change.
 *
 * Issues are allocated FEFO (first-expiring, first-out) across batches, so the
 * stock nearest its expiry date always leaves first. Every call writes both the
 * batch rows and a stock movement, and must run inside a transaction.
 */
class StockLedger
{
    /**
     * Take `quantity` out of a product, consuming batches by expiry order.
     *
     * @return array<int, array{batch_id:int, quantity:int, cost_price:float}>
     *         What was taken from each batch, for costing the caller's document.
     *
     * @throws RuntimeException when there is not enough stock.
     */
    public function issue(
        int $productId,
        int $quantity,
        ?string $reference = null,
        ?string $reason = null,
        int|string|null $userId = null,
        ?int $batchId = null,
    ): array {
        if ($quantity < 1) {
            throw new RuntimeException('Quantity must be at least 1');
        }

        $product = DB::table('inventory_products')->lockForUpdate()->find($productId);
        if (!$product) {
            throw new RuntimeException('Product not found');
        }
        if ($product->quantity < $quantity) {
            throw new RuntimeException('Insufficient stock');
        }

        $batches = $this->issuableBatches($productId, $batchId);

        $remaining = $quantity;
        $allocations = [];

        $previousQty = (int) $product->quantity;
        $runningQty = $previousQty;

        foreach ($batches as $batch) {
            if ($remaining < 1) {
                break;
            }
            $take = (int) min($remaining, $batch->quantity);
            if ($take < 1) {
                continue;
            }

            $left = (int) $batch->quantity - $take;
            DB::table('inventory_batches')->where('id', $batch->id)->update([
                'quantity' => $left,
                'status' => $left === 0 ? 'depleted' : $batch->status,
                'updated_at' => now(),
            ]);

            $allocations[] = [
                'batch_id' => (int) $batch->id,
                'quantity' => $take,
                'cost_price' => (float) $batch->cost_price,
            ];

            $newQty = max(0, $runningQty - $take);
            $this->recordMovement($productId, 'out', $take, $runningQty, $newQty, $reference ?? "Mzigo umetolewa: -{$take} units (Zilizokuwepo: {$runningQty}, zikabaki: {$newQty}).", $reason, $userId, (int) $batch->id);
            $runningQty = $newQty;
            $remaining -= $take;
        }

        if ($remaining > 0) {
            // Stock exists on the product but not in any batch — record the
            // shortfall against no batch rather than silently under-issuing.
            $newQty = max(0, $runningQty - $remaining);
            $this->recordMovement($productId, 'out', $remaining, $runningQty, $newQty, $reference ?? "Mzigo umetolewa: -{$remaining} units (Zilizokuwepo: {$runningQty}, zikabaki: {$newQty}).", $reason, $userId, null);
            $allocations[] = [
                'batch_id' => 0,
                'quantity' => $remaining,
                'cost_price' => (float) $product->cost_price,
            ];
            $runningQty = $newQty;
        }

        DB::table('inventory_products')->where('id', $productId)->update([
            'quantity' => max(0, $previousQty - $quantity),
            'updated_at' => now(),
        ]);

        return $allocations;
    }

    /**
     * Add `quantity` into a batch, creating it when the batch number is new.
     *
     * @return int The batch id the stock landed in.
     */
    public function receive(
        int $productId,
        int $quantity,
        string $batchNumber,
        ?string $expiryDate = null,
        ?float $costPrice = null,
        ?string $reference = null,
        int|string|null $userId = null,
    ): int {
        if ($quantity < 1) {
            throw new RuntimeException('Quantity must be at least 1');
        }

        $product = DB::table('inventory_products')->lockForUpdate()->find($productId);
        if (!$product) {
            throw new RuntimeException('Product not found');
        }

        $cost = $costPrice ?? (float) $product->cost_price;

        $batch = DB::table('inventory_batches')
            ->where('product_id', $productId)
            ->where('batch_number', $batchNumber)
            ->lockForUpdate()
            ->first();

        if ($batch) {
            $batchId = (int) $batch->id;
            DB::table('inventory_batches')->where('id', $batchId)->update([
                'quantity' => (int) $batch->quantity + $quantity,
                'received_quantity' => (int) $batch->received_quantity + $quantity,
                'expiry_date' => $expiryDate ?? $batch->expiry_date,
                'cost_price' => $cost,
                'status' => 'active',
                'updated_at' => now(),
            ]);
        } else {
            $batchId = (int) DB::table('inventory_batches')->insertGetId([
                'product_id' => $productId,
                'batch_number' => $batchNumber,
                'expiry_date' => $expiryDate,
                'quantity' => $quantity,
                'received_quantity' => $quantity,
                'cost_price' => $cost,
                'received_at' => now()->toDateString(),
                'reference' => $reference,
                'status' => 'active',
                'created_by' => $userId,
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }

        $previousQty = (int) $product->quantity;
        $newQty = $previousQty + $quantity;

        DB::table('inventory_products')->where('id', $productId)->update([
            'quantity' => $newQty,
            'cost_price' => $cost,
            'updated_at' => now(),
        ]);

        $defaultRef = $reference;
        if (empty($defaultRef)) {
            $defaultRef = $previousQty == 0
                ? "Mzigo mpya umeingia: {$quantity} units."
                : "Mzigo umeongezwa: +{$quantity} units (Zilizokuwepo: {$previousQty}, Total: {$newQty}).";
        }

        $this->recordMovement(
            $productId,
            'in',
            $quantity,
            $previousQty,
            $newQty,
            $defaultRef,
            'receipt',
            $userId,
            $batchId
        );

        return $batchId;
    }

    /**
     * Force a product (and optionally one batch) to an exact quantity.
     * Used when posting a stock count variance.
     */
    public function adjustTo(
        int $productId,
        int $countedQuantity,
        ?int $batchId,
        ?string $reference,
        int|string|null $userId,
    ): int {
        $product = DB::table('inventory_products')->lockForUpdate()->find($productId);
        if (!$product) {
            throw new RuntimeException('Product not found');
        }

        $previousQty = (int) $product->quantity;

        if ($batchId !== null) {
            $batch = DB::table('inventory_batches')->lockForUpdate()->find($batchId);
            if (!$batch) {
                throw new RuntimeException('Batch not found');
            }
            $variance = $countedQuantity - (int) $batch->quantity;
            if ($variance === 0) {
                return 0;
            }

            $newQty = max(0, $previousQty + $variance);

            DB::table('inventory_batches')->where('id', $batchId)->update([
                'quantity' => max(0, $countedQuantity),
                'status' => $countedQuantity === 0 ? 'depleted' : 'active',
                'updated_at' => now(),
            ]);
            DB::table('inventory_products')->where('id', $productId)->update([
                'quantity' => $newQty,
                'updated_at' => now(),
            ]);
            $this->recordMovement(
                $productId,
                $variance > 0 ? 'in' : 'out',
                abs($variance),
                $previousQty,
                $newQty,
                $reference ?? "Marekebisho ya stoo (Stock Count Adjustment). Zilizokuwepo: {$previousQty}, Mpya: {$newQty}.",
                'stock_count',
                $userId,
                $batchId,
            );

            return $variance;
        }

        $variance = $countedQuantity - $previousQty;
        if ($variance === 0) {
            return 0;
        }

        $newQty = max(0, $countedQuantity);

        DB::table('inventory_products')->where('id', $productId)->update([
            'quantity' => $newQty,
            'updated_at' => now(),
        ]);
        $this->recordMovement(
            $productId,
            $variance > 0 ? 'in' : 'out',
            abs($variance),
            $previousQty,
            $newQty,
            $reference ?? "Marekebisho ya stoo (Stock Count Adjustment). Zilizokuwepo: {$previousQty}, Mpya: {$newQty}.",
            'stock_count',
            $userId,
            null,
        );

        return $variance;
    }

    /** Batches that can be issued from, first-expiring first. */
    private function issuableBatches(int $productId, ?int $batchId)
    {
        $query = DB::table('inventory_batches')
            ->where('product_id', $productId)
            ->where('quantity', '>', 0)
            ->where('status', '!=', 'quarantined')
            ->lockForUpdate();

        if ($batchId !== null) {
            $query->where('id', $batchId);
        }

        // NULL expiry sorts last: dated stock leaves before undated stock.
        return $query
            ->orderByRaw('CASE WHEN expiry_date IS NULL THEN 1 ELSE 0 END')
            ->orderBy('expiry_date')
            ->orderBy('id')
            ->get();
    }

    private function recordMovement(
        int $productId,
        string $type,
        int $quantity,
        int $previousQuantity,
        int $newQuantity,
        ?string $reference,
        ?string $reason,
        int|string|null $userId,
        ?int $batchId,
    ): void {
        DB::table('inventory_stock_movements')->insert([
            'product_id' => $productId,
            'batch_id' => $batchId,
            'type' => $type,
            'quantity' => $quantity,
            'previous_quantity' => $previousQuantity,
            'new_quantity' => $newQuantity,
            'reason' => $reason,
            'reference' => $reference,
            'user_id' => $userId,
            'created_at' => now(),
        ]);
    }
}
