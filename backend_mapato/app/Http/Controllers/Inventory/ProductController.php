<?php

namespace App\Http\Controllers\Inventory;

use App\Services\Inventory\SkuGenerator;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Routing\Controller;

class ProductController extends Controller
{
    public function __construct(private readonly SkuGenerator $skuGenerator)
    {
    }

    public function index(Request $request)
    {
        $q = $request->query('q');
        $status = $request->query('status');
        $lowStock = (bool) $request->query('low_stock', false);

        $query = DB::table('inventory_products as p')
            ->leftJoin('inventory_categories as c', 'c.id', '=', 'p.category_id')
            ->leftJoin('inventory_brands as b', 'b.id', '=', 'p.brand_id')
            ->select(
                'p.*',
                'c.name as category_name',
                'b.name as brand_name',
                DB::raw('(p.cost_price * p.quantity) as total_cost_price'),
                DB::raw('(p.selling_price * p.quantity) as total_selling_price'),
                DB::raw('((p.selling_price - p.cost_price) * p.quantity) as total_expected_profit')
            );
        if ($q) {
            $query->where(function ($w) use ($q) {
                $w->where('p.name', 'like', "%$q%")
                    ->orWhere('p.sku', 'like', "%$q%")
                    ->orWhere('p.barcode', 'like', "%$q%");
            });
        }
        if ($status) {
            $query->where('p.status', $status);
        }
        if ($lowStock) {
            $query->whereColumn('p.quantity', '<', 'p.min_stock');
        }
        if ($categoryId = $request->query('category_id')) {
            $query->where('p.category_id', (int) $categoryId);
        }
        if ($brandId = $request->query('brand_id')) {
            $query->where('p.brand_id', (int) $brandId);
        }

        $products = $query->orderByDesc('p.id')->paginate(20);
        return response()->json([
            'data' => $products->items(),
            'meta' => [
                'current_page' => $products->currentPage(),
                'last_page' => $products->lastPage(),
                'per_page' => $products->perPage(),
                'total' => $products->total(),
            ],
        ]);
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'name' => 'required|string|max:255',
            'description' => 'nullable|string|max:1000',
            // Leave blank to have the depot generate one automatically.
            'sku' => 'nullable|string|max:255|unique:inventory_products,sku',
            'category' => 'nullable|string|max:255',
            'category_id' => 'nullable|integer|exists:inventory_categories,id',
            'brand_id' => 'nullable|integer|exists:inventory_brands,id',
            'cost_price' => 'required|numeric|min:0',
            'selling_price' => 'required|numeric|min:0',
            'unit' => 'nullable|string|max:32',
            'quantity' => 'required|integer|min:0',
            'min_stock' => 'required|integer|min:0',
            'status' => 'required|in:active,inactive',
            'barcode' => 'nullable|string|max:255',
            'price_tier' => 'nullable|in:retail,wholesale',
        ]);

        $created = DB::transaction(function () use ($data, $request) {
            $sku = $data['sku'] ?? $this->generateSku($data);
            $id = DB::table('inventory_products')->insertGetId([
                'name' => $data['name'],
                'description' => $data['description'] ?? null,
                'sku' => $sku,
                'category' => $data['category'] ?? null,
                'category_id' => $data['category_id'] ?? null,
                'brand_id' => $data['brand_id'] ?? null,
                'cost_price' => $data['cost_price'],
                'selling_price' => $data['selling_price'],
                'unit' => $data['unit'] ?? 'pcs',
                'quantity' => $data['quantity'],
                'min_stock' => $data['min_stock'],
                'status' => $data['status'],
                'barcode' => $data['barcode'] ?? null,
                'price_tier' => $data['price_tier'] ?? 'retail',
                'created_by' => optional($request->user())->id,
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            // Every product needs a base selling unit so it can be priced and sold.
            $unitId = DB::table('inventory_product_units')->insertGetId([
                'product_id' => $id,
                'name' => $data['unit'] ?? 'pcs',
                'factor' => 1,
                'is_base' => true,
                'barcode' => $data['barcode'] ?? null,
                'status' => 'active',
                'created_at' => now(),
                'updated_at' => now(),
            ]);
            $priceTier = $data['price_tier'] ?? 'retail';
            DB::table('inventory_product_prices')->insert([
                'product_unit_id' => $unitId,
                'tier' => $priceTier,
                'customer_id' => null,
                'price' => $data['selling_price'],
                'effective_from' => now()->toDateString(),
                'created_by' => optional($request->user())->id,
                'created_at' => now(),
                'updated_at' => now(),
            ]);
            DB::table('inventory_price_changes')->insert([
                'product_unit_id' => $unitId,
                'tier' => $priceTier,
                'customer_id' => null,
                'old_price' => null,
                'new_price' => $data['selling_price'],
                'reason' => 'Product created',
                'changed_by' => optional($request->user())->id,
                'created_at' => now(),
            ]);

            return ['id' => $id, 'sku' => $sku];
        });

        return response()->json([
            'message' => 'Product created',
            'data' => ['id' => (int) $created['id'], 'sku' => $created['sku']],
        ], 201);
    }

    /** Auto-generate a SKU from the product name. */
    private function generateSku(array $data): string
    {
        return $this->skuGenerator->generate($data['name']);
    }

    public function update(Request $request, int $id)
    {
        $exists = DB::table('inventory_products')->where('id', $id)->exists();
        if (!$exists)
            return response()->json(['message' => 'Not found'], 404);

        $data = $request->validate([
            'name' => 'sometimes|required|string|max:255',
            'description' => 'nullable|string|max:1000',
            'sku' => 'sometimes|required|string|max:255|unique:inventory_products,sku,' . $id,
            'category' => 'nullable|string|max:255',
            'category_id' => 'nullable|integer|exists:inventory_categories,id',
            'brand_id' => 'nullable|integer|exists:inventory_brands,id',
            'cost_price' => 'sometimes|required|numeric|min:0',
            'selling_price' => 'sometimes|required|numeric|min:0',
            'unit' => 'nullable|string|max:32',
            'quantity' => 'sometimes|required|integer|min:0',
            'min_stock' => 'sometimes|required|integer|min:0',
            'status' => 'sometimes|required|in:active,inactive',
            'barcode' => 'nullable|string|max:255',
            'price_tier' => 'nullable|in:retail,wholesale',
        ]);

        DB::table('inventory_products')->where('id', $id)->update(array_merge($data, [
            'updated_at' => now(),
        ]));

        return response()->json(['message' => 'Product updated']);
    }

    public function destroy(int $id)
    {
        $sold = DB::table('inventory_sale_items')->where('product_id', $id)->exists();
        if ($sold) {
            return response()->json(['message' => 'Product has sales history and cannot be deleted'], 422);
        }

        $deleted = DB::table('inventory_products')->where('id', $id)->delete();

        return $deleted
            ? response()->json(['message' => 'Product deleted'])
            : response()->json(['message' => 'Not found'], 404);
    }
}
