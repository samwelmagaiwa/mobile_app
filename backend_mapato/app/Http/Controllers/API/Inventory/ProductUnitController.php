<?php

namespace App\Http\Controllers\Inventory;

use Illuminate\Http\Request;
use Illuminate\Routing\Controller;
use Illuminate\Support\Facades\DB;

/**
 * Area 2 — selling units (bottle / pack / crate) and their tiered prices.
 *
 * Every price write goes through setPrice(), which is the only place allowed to
 * touch inventory_product_prices, so the change log can never be bypassed.
 */
class ProductUnitController extends Controller
{
    /** All units of one product, each with its retail / wholesale / special prices. */
    public function index(int $productId)
    {
        if (! DB::table('inventory_products')->where('id', $productId)->exists()) {
            return response()->json(['message' => 'Product not found'], 404);
        }

        $units = DB::table('inventory_product_units')
            ->where('product_id', $productId)
            ->orderByDesc('is_base')
            ->orderBy('factor')
            ->get();

        $prices = DB::table('inventory_product_prices')
            ->whereIn('product_unit_id', $units->pluck('id'))
            ->get()
            ->groupBy('product_unit_id');

        $data = $units->map(function ($unit) use ($prices) {
            $unit->prices = array_values(($prices[$unit->id] ?? collect())->all());

            return $unit;
        });

        return response()->json(['data' => $data]);
    }

    public function store(Request $request, int $productId)
    {
        if (! DB::table('inventory_products')->where('id', $productId)->exists()) {
            return response()->json(['message' => 'Product not found'], 404);
        }

        $data = $request->validate([
            'name' => 'required|string|max:32',
            'factor' => 'required|integer|min:1',
            'is_base' => 'nullable|boolean',
            'barcode' => 'nullable|string|max:255',
            'status' => 'nullable|in:active,inactive',
            'retail_price' => 'nullable|numeric|min:0',
            'wholesale_price' => 'nullable|numeric|min:0',
        ]);

        $duplicate = DB::table('inventory_product_units')
            ->where('product_id', $productId)
            ->where('name', $data['name'])
            ->exists();
        if ($duplicate) {
            return response()->json(['message' => 'That unit already exists for this product'], 422);
        }

        $userId = optional($request->user())->id;

        $unitId = DB::transaction(function () use ($productId, $data, $userId) {
            $isBase = (bool) ($data['is_base'] ?? false);
            if ($isBase) {
                DB::table('inventory_product_units')
                    ->where('product_id', $productId)
                    ->update(['is_base' => false, 'updated_at' => now()]);
            }

            $unitId = DB::table('inventory_product_units')->insertGetId([
                'product_id' => $productId,
                'name' => $data['name'],
                'factor' => $isBase ? 1 : $data['factor'],
                'is_base' => $isBase,
                'barcode' => $data['barcode'] ?? null,
                'status' => $data['status'] ?? 'active',
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            foreach (['retail' => 'retail_price', 'wholesale' => 'wholesale_price'] as $tier => $field) {
                if (isset($data[$field])) {
                    $this->writePrice($unitId, $tier, null, (float) $data[$field], 'Unit created', $userId);
                }
            }

            return $unitId;
        });

        return response()->json(['message' => 'Unit created', 'data' => ['id' => (int) $unitId]], 201);
    }

    public function update(Request $request, int $productId, int $unitId)
    {
        $unit = DB::table('inventory_product_units')
            ->where('id', $unitId)->where('product_id', $productId)->first();
        if (! $unit) {
            return response()->json(['message' => 'Not found'], 404);
        }

        $data = $request->validate([
            'name' => 'sometimes|required|string|max:32',
            'factor' => 'sometimes|required|integer|min:1',
            'barcode' => 'nullable|string|max:255',
            'status' => 'sometimes|required|in:active,inactive',
        ]);

        if (isset($data['name'])) {
            $duplicate = DB::table('inventory_product_units')
                ->where('product_id', $productId)
                ->where('name', $data['name'])
                ->where('id', '!=', $unitId)
                ->exists();
            if ($duplicate) {
                return response()->json(['message' => 'That unit already exists for this product'], 422);
            }
        }

        if ($unit->is_base) {
            // The base unit is the measure everything else converts to.
            unset($data['factor']);
        }

        DB::table('inventory_product_units')->where('id', $unitId)
            ->update(array_merge($data, ['updated_at' => now()]));

        return response()->json(['message' => 'Unit updated']);
    }

    public function destroy(int $productId, int $unitId)
    {
        $unit = DB::table('inventory_product_units')
            ->where('id', $unitId)->where('product_id', $productId)->first();
        if (! $unit) {
            return response()->json(['message' => 'Not found'], 404);
        }
        if ($unit->is_base) {
            return response()->json(['message' => 'The base unit cannot be removed'], 422);
        }

        DB::table('inventory_product_units')->where('id', $unitId)->delete();

        return response()->json(['message' => 'Unit deleted']);
    }

    /** Set one tier's price for one unit. Logs the change. */
    public function setPrice(Request $request, int $productId, int $unitId)
    {
        $exists = DB::table('inventory_product_units')
            ->where('id', $unitId)->where('product_id', $productId)->exists();
        if (! $exists) {
            return response()->json(['message' => 'Not found'], 404);
        }

        $data = $request->validate([
            'tier' => 'required|in:retail,wholesale,special',
            'customer_id' => 'nullable|integer|exists:inventory_customers,id',
            'price' => 'required|numeric|min:0',
            'effective_from' => 'nullable|date',
            'reason' => 'nullable|string|max:255',
        ]);

        if ($data['tier'] === 'special' && empty($data['customer_id'])) {
            return response()->json(['message' => 'A special price needs a customer'], 422);
        }
        if ($data['tier'] !== 'special') {
            $data['customer_id'] = null;
        }

        DB::transaction(function () use ($unitId, $data, $request) {
            $this->writePrice(
                $unitId,
                $data['tier'],
                $data['customer_id'] ?? null,
                (float) $data['price'],
                $data['reason'] ?? null,
                optional($request->user())->id,
                $data['effective_from'] ?? null,
            );
        });

        return response()->json(['message' => 'Price saved']);
    }

    /** Price change history for one unit, newest first. */
    public function priceHistory(Request $request, int $productId, int $unitId)
    {
        $exists = DB::table('inventory_product_units')
            ->where('id', $unitId)->where('product_id', $productId)->exists();
        if (! $exists) {
            return response()->json(['message' => 'Not found'], 404);
        }

        $rows = DB::table('inventory_price_changes as pc')
            ->leftJoin('users as u', 'u.id', '=', 'pc.changed_by')
            ->where('pc.product_unit_id', $unitId)
            ->select('pc.*', 'u.name as changed_by_name')
            ->orderByDesc('pc.created_at')
            ->limit((int) $request->query('limit', 50))
            ->get();

        return response()->json(['data' => $rows]);
    }

    /**
     * Upsert the current price and append to the immutable change log.
     * Must be called inside a transaction.
     */
    private function writePrice(
        int $unitId,
        string $tier,
        ?int $customerId,
        float $price,
        ?string $reason,
        int|string|null $userId,
        ?string $effectiveFrom = null,
    ): void {
        $current = DB::table('inventory_product_prices')
            ->where('product_unit_id', $unitId)
            ->where('tier', $tier)
            ->where(fn ($w) => $customerId === null
                ? $w->whereNull('customer_id')
                : $w->where('customer_id', $customerId))
            ->first();

        if ($current && (float) $current->price === $price) {
            return; // nothing changed, keep the log clean
        }

        $payload = [
            'price' => $price,
            'effective_from' => $effectiveFrom ?? now()->toDateString(),
            'created_by' => $userId,
            'updated_at' => now(),
        ];

        if ($current) {
            DB::table('inventory_product_prices')->where('id', $current->id)->update($payload);
        } else {
            DB::table('inventory_product_prices')->insert(array_merge($payload, [
                'product_unit_id' => $unitId,
                'tier' => $tier,
                'customer_id' => $customerId,
                'created_at' => now(),
            ]));
        }

        DB::table('inventory_price_changes')->insert([
            'product_unit_id' => $unitId,
            'tier' => $tier,
            'customer_id' => $customerId,
            'old_price' => $current->price ?? null,
            'new_price' => $price,
            'reason' => $reason,
            'changed_by' => $userId,
            'created_at' => now(),
        ]);
    }
}
