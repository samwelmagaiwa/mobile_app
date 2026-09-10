<?php

namespace App\Services\Inventory;

use Illuminate\Support\Facades\DB;
use InvalidArgumentException;
use RuntimeException;

/**
 * Area 8 — crates and empties, as a double-entry ledger.
 *
 * Every movement posts exactly two rows — two "legs" — whose signed
 * quantities always sum to zero. That is enforced here, not just assumed, so
 * a bug can never silently create or destroy crates. Adapted from the
 * container-ledger design evaluated alongside this system.
 */
class CrateLedgerService
{
    /** party_type, customer_id, signed quantity for each leg of a movement. */
    private const LEGS = [
        // Depot hands crates out: depot loses, customer now holds them.
        'issued' => ['depot' => -1, 'customer' => 1],
        // Customer brings crates back: depot regains, customer holds fewer.
        'returned' => ['depot' => 1, 'customer' => -1],
        // Broken while with the customer: gone for good. The customer's
        // "must return" balance drops, and write_off absorbs the loss -
        // depot's own count never held these, so depot is not a leg here.
        'broken' => ['customer' => -1, 'write_off' => 1],
        // Customer keeps the crate for good: same shape as broken, just a
        // different reason it leaves the "held, must return" ledger.
        'purchased' => ['customer' => -1, 'write_off' => 1],
    ];

    /**
     * Post one crate movement as its two balancing legs.
     *
     * @return array<int> the ids of the two rows inserted
     */
    public function post(
        int $crateTypeId,
        string $movementType,
        int $quantity,
        ?int $customerId,
        ?string $reference,
        ?string $note,
        int|string|null $userId,
    ): array {
        if ($quantity <= 0) {
            throw new InvalidArgumentException('Quantity must be greater than zero.');
        }
        if (! isset(self::LEGS[$movementType])) {
            throw new InvalidArgumentException("Unknown movement: {$movementType}");
        }
        if (in_array($movementType, ['returned', 'broken', 'purchased'], true) && $customerId === null) {
            throw new InvalidArgumentException('This movement needs a customer.');
        }

        $legs = self::LEGS[$movementType];
        $sign = array_sum($legs);
        if ($sign !== 0) {
            // Guards the invariant at the source: a movement type whose legs
            // don't cancel is a bug in this class, not a runtime data issue.
            throw new RuntimeException("Movement legs for {$movementType} do not sum to zero.");
        }

        $depositValue = (float) DB::table('inventory_crate_types')
            ->where('id', $crateTypeId)->value('deposit_value');

        return DB::transaction(function () use (
            $crateTypeId, $movementType, $quantity, $customerId,
            $legs, $depositValue, $reference, $note, $userId,
        ) {
            $ids = [];
            foreach ($legs as $partyType => $direction) {
                $partyCustomerId = $partyType === 'customer' ? $customerId : null;
                $ids[] = $this->postLeg(
                    $crateTypeId,
                    $partyType,
                    $partyCustomerId,
                    $movementType,
                    $direction * $quantity,
                    $depositValue,
                    $reference,
                    $note,
                    $userId,
                );
            }

            return $ids;
        });
    }

    private function postLeg(
        int $crateTypeId,
        string $partyType,
        ?int $customerId,
        string $movementType,
        int $signedQuantity,
        float $depositValue,
        ?string $reference,
        ?string $note,
        int|string|null $userId,
    ): int {
        $currentBalance = $this->balanceFor($crateTypeId, $partyType, $customerId);
        $newBalance = $currentBalance + $signedQuantity;

        return (int) DB::table('inventory_crate_movements')->insertGetId([
            'crate_type_id' => $crateTypeId,
            'party_type' => $partyType,
            'customer_id' => $customerId,
            'movement_type' => $movementType,
            'quantity' => $signedQuantity,
            'balance_after' => $newBalance,
            'deposit_value' => $depositValue * abs($signedQuantity),
            'reference' => $reference,
            'note' => $note,
            'created_by' => $userId,
            'created_at' => now(),
        ]);
    }

    public function balanceFor(int $crateTypeId, string $partyType, ?int $customerId): int
    {
        $query = DB::table('inventory_crate_movements')
            ->where('crate_type_id', $crateTypeId)
            ->where('party_type', $partyType);

        $query = $customerId === null
            ? $query->whereNull('customer_id')
            : $query->where('customer_id', $customerId);

        return (int) $query->sum('quantity');
    }

    /**
     * Depot-wide totals for every crate type in ONE pass over the ledger,
     * instead of the 5 SUM queries per type that depotPosition() below
     * needs when called one type at a time. The crates_position report
     * calls this for its full-table view — with N crate types the
     * per-type loop was issuing 1 + 5N queries (50+ for a modest catalog);
     * this reduces that to a single grouped aggregate query.
     *
     * @return \Illuminate\Support\Collection<int, array> keyed by crate_type_id
     */
    public function depotPositionAll(): \Illuminate\Support\Collection
    {
        return DB::table('inventory_crate_movements')
            ->select(
                'crate_type_id',
                DB::raw("SUM(CASE WHEN party_type = 'depot' THEN quantity ELSE 0 END) as held_by_depot"),
                DB::raw("SUM(CASE WHEN party_type = 'depot' AND movement_type = 'issued' THEN ABS(quantity) ELSE 0 END) as issued"),
                DB::raw("SUM(CASE WHEN party_type = 'depot' AND movement_type = 'returned' THEN quantity ELSE 0 END) as returned"),
                DB::raw("SUM(CASE WHEN party_type = 'customer' THEN quantity ELSE 0 END) as out_with_customers"),
                DB::raw("SUM(CASE WHEN party_type = 'write_off' THEN ABS(quantity) ELSE 0 END) as broken_or_purchased"),
            )
            ->groupBy('crate_type_id')
            ->get()
            ->keyBy('crate_type_id')
            ->map(function ($row) {
                $heldByDepot = (int) $row->held_by_depot;
                $issued = (int) $row->issued;
                $returned = (int) $row->returned;

                return [
                    'held_by_depot' => $heldByDepot,
                    'issued' => $issued,
                    'returned' => $returned,
                    'out_with_customers' => max(0, (int) $row->out_with_customers),
                    'broken_or_purchased' => (int) $row->broken_or_purchased,
                    'reconciliation_valid' => $heldByDepot === ($returned - $issued),
                ];
            });
    }

    /** Depot-wide totals, derived straight from the ledger legs. */
    public function depotPosition(int $crateTypeId): array
    {
        $heldByDepot = $this->balanceFor($crateTypeId, 'depot', null);

        $issued = (int) DB::table('inventory_crate_movements')
            ->where('crate_type_id', $crateTypeId)
            ->where('party_type', 'depot')->where('movement_type', 'issued')
            ->sum(DB::raw('ABS(quantity)'));
        $returned = (int) DB::table('inventory_crate_movements')
            ->where('crate_type_id', $crateTypeId)
            ->where('party_type', 'depot')->where('movement_type', 'returned')
            ->sum('quantity');
        $outWithCustomers = (int) DB::table('inventory_crate_movements')
            ->where('crate_type_id', $crateTypeId)
            ->where('party_type', 'customer')
            ->sum('quantity');
        $writtenOff = (int) DB::table('inventory_crate_movements')
            ->where('crate_type_id', $crateTypeId)
            ->where('party_type', 'write_off')
            ->sum(DB::raw('ABS(quantity)'));

        return [
            'crate_type_id' => $crateTypeId,
            'held_by_depot' => $heldByDepot,
            'issued' => $issued,
            'returned' => $returned,
            'out_with_customers' => max(0, $outWithCustomers),
            'broken_or_purchased' => $writtenOff,
            // held_by_depot is derived purely from depot legs (returned - issued);
            // it can never drift from that, since there is no third way to write it.
            'reconciliation_valid' => $heldByDepot === ($returned - $issued),
        ];
    }

    /**
     * Verifies the whole ledger for one crate type nets to zero across every
     * party. True by construction if every post() went through this class,
     * so a failure here means a row was written some other way.
     */
    public function assertBalanced(int $crateTypeId): void
    {
        $total = (int) DB::table('inventory_crate_movements')
            ->where('crate_type_id', $crateTypeId)
            ->sum('quantity');

        if ($total !== 0) {
            throw new RuntimeException(
                "Crate ledger for type {$crateTypeId} is unbalanced by {$total}.",
            );
        }
    }
}
