<?php

namespace App\Http\Controllers\API\Inventory;

use App\Services\Inventory\AuditTrail;
use App\Services\Inventory\SkuGenerator;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Routing\Controller;
use OpenApi\Attributes as OA;

#[OA\Tag(name: 'Inventory / Products', description: 'Product catalog: create, list, price, and retire products.')]
class ProductController extends Controller
{
    public function __construct(
        private readonly SkuGenerator $skuGenerator,
        private readonly AuditTrail   $audit,
    ) {
    }

    #[OA\Get(
        path: '/inventory/products',
        summary: 'List products',
        description: 'Paginated product list with search, status, and low-stock filters.',
        security: [['bearerAuth' => []]],
        tags: ['Inventory / Products'],
        parameters: [
            new OA\Parameter(name: 'q', in: 'query', description: 'Search name/SKU/barcode', schema: new OA\Schema(type: 'string')),
            new OA\Parameter(name: 'status', in: 'query', schema: new OA\Schema(type: 'string', enum: ['active', 'inactive'])),
            new OA\Parameter(name: 'low_stock', in: 'query', schema: new OA\Schema(type: 'boolean')),
            new OA\Parameter(name: 'category_id', in: 'query', schema: new OA\Schema(type: 'integer')),
            new OA\Parameter(name: 'brand_id', in: 'query', schema: new OA\Schema(type: 'integer')),
        ],
        responses: [
            new OA\Response(
                response: 200,
                description: 'Paginated product list',
                content: new OA\JsonContent(properties: [
                    new OA\Property(property: 'data', type: 'array', items: new OA\Items(type: 'object')),
                    new OA\Property(property: 'meta', ref: '#/components/schemas/PaginationMeta'),
                ], type: 'object'),
            ),
        ],
    )]
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

    #[OA\Post(
        path: '/inventory/products',
        summary: 'Create a product',
        description: 'SKU auto-generates from name/brand/unit when left blank. `unit_factor` sets '
            . 'how many of `unit` the cost/selling price cover (e.g. 5 for "per 5 KG").',
        security: [['bearerAuth' => []]],
        tags: ['Inventory / Products'],
        requestBody: new OA\RequestBody(
            required: true,
            content: new OA\JsonContent(
                required: ['name', 'cost_price', 'selling_price', 'quantity', 'min_stock', 'status'],
                properties: [
                    new OA\Property(property: 'name', type: 'string', example: 'Coca-Cola 350ml'),
                    new OA\Property(property: 'description', type: 'string', nullable: true),
                    new OA\Property(property: 'sku', type: 'string', nullable: true, description: 'Leave blank to auto-generate'),
                    new OA\Property(property: 'category_id', type: 'integer', nullable: true),
                    new OA\Property(property: 'brand_id', type: 'integer', nullable: true),
                    new OA\Property(property: 'cost_price', type: 'number', format: 'float', example: 20000),
                    new OA\Property(property: 'selling_price', type: 'number', format: 'float', example: 25000),
                    new OA\Property(property: 'unit', type: 'string', example: 'crate'),
                    new OA\Property(property: 'unit_factor', type: 'integer', example: 1, description: 'How many of `unit` the prices above cover'),
                    new OA\Property(property: 'quantity', type: 'integer', example: 100),
                    new OA\Property(property: 'min_stock', type: 'integer', example: 10),
                    new OA\Property(property: 'status', type: 'string', enum: ['active', 'inactive']),
                    new OA\Property(property: 'barcode', type: 'string', nullable: true),
                    new OA\Property(property: 'price_tier', type: 'string', enum: ['retail', 'wholesale'], nullable: true),
                ],
            ),
        ),
        responses: [
            new OA\Response(response: 201, description: 'Product created', content: new OA\JsonContent(properties: [
                new OA\Property(property: 'message', type: 'string', example: 'Product created'),
                new OA\Property(property: 'data', properties: [
                    new OA\Property(property: 'id', type: 'integer'),
                    new OA\Property(property: 'sku', type: 'string'),
                ], type: 'object'),
            ], type: 'object')),
            new OA\Response(response: 422, description: 'Validation failed', content: new OA\JsonContent(ref: '#/components/schemas/ValidationErrorResponse')),
        ],
    )]
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
            // How many of this unit the cost/selling price cover, e.g. "per 5 KG".
            'unit_factor' => 'nullable|integer|min:1',
            'quantity' => 'required|integer|min:0',
            'min_stock' => 'required|integer|min:0',
            'status' => 'required|in:active,inactive',
            'barcode' => 'nullable|string|max:255',
            'price_tier' => 'nullable|in:retail,wholesale',
        ]);

        $created = DB::transaction(function () use ($data, $request) {
            $sku = $data['sku'] ?? $this->generateSku($data);
            $unitFactor = $data['unit_factor'] ?? 1;
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
                'unit_factor' => $unitFactor,
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
                'factor' => $unitFactor,
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

        $this->audit->record($request, 'product', (int) $created['id'], 'created', null, [
            'name' => $data['name'],
            'sku'  => $created['sku'],
        ], $data['name']);

        return response()->json([
            'message' => 'Product created',
            'data' => ['id' => (int) $created['id'], 'sku' => $created['sku']],
        ], 201);
    }

    /** Auto-generate a structured SKU: BRAND-PRODUCT-SIZE-UNIT. */
    private function generateSku(array $data): string
    {
        return $this->skuGenerator->generate(
            $data['name'],
            $data['brand_id'] ?? null,
            $data['unit'] ?? null,
        );
    }

    public function update(Request $request, int $id)
    {
        $existing = DB::table('inventory_products')->where('id', $id)->first();
        if (! $existing)
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
            'unit_factor' => 'nullable|integer|min:1',
            'quantity' => 'sometimes|required|integer|min:0',
            'min_stock' => 'sometimes|required|integer|min:0',
            'status' => 'sometimes|required|in:active,inactive',
            'barcode' => 'nullable|string|max:255',
            'price_tier' => 'nullable|in:retail,wholesale',
        ]);

        DB::transaction(function () use ($id, $data) {
            DB::table('inventory_products')->where('id', $id)->update(array_merge($data, [
                'updated_at' => now(),
            ]));

            // Mirror unit/unit_factor onto the base selling unit so the
            // per-unit pricing table (inventory_product_units) stays in sync.
            if (isset($data['unit']) || isset($data['unit_factor'])) {
                $baseUpdate = ['updated_at' => now()];
                if (isset($data['unit'])) {
                    $baseUpdate['name'] = $data['unit'];
                }
                if (isset($data['unit_factor'])) {
                    $baseUpdate['factor'] = $data['unit_factor'];
                }
                DB::table('inventory_product_units')
                    ->where('product_id', $id)
                    ->where('is_base', true)
                    ->update($baseUpdate);
            }

            // Keep price-tier rows in sync: when the product's mode changes,
            // flip the tier on every base-unit price row so the app reads real data.
            if (isset($data['price_tier'])) {
                $newTier = $data['price_tier'];
                $oldTier = $newTier === 'wholesale' ? 'retail' : 'wholesale';
                $baseUnitIds = DB::table('inventory_product_units')
                    ->where('product_id', $id)
                    ->where('is_base', true)
                    ->pluck('id');
                if ($baseUnitIds->isNotEmpty()) {
                    DB::table('inventory_product_prices')
                        ->whereIn('product_unit_id', $baseUnitIds)
                        ->where('tier', $oldTier)
                        ->whereNull('customer_id')
                        ->update(['tier' => $newTier, 'updated_at' => now()]);
                }
            }
        });

        $this->audit->record($request, 'product', $id, 'updated', (array) $existing, $data, $existing->name);

        return response()->json(['message' => 'Product updated']);
    }

    /**
     * DELETE /inventory/products/{id}
     *
     * Hard-delete when no sales history exists.
     * Pass ?force=1 (admin-only) to archive (status=inactive) instead
     * of deleting a product that has sales history.
     */
    public function destroy(Request $request, int $id)
    {
        $existing = DB::table('inventory_products')->where('id', $id)->first();
        if (! $existing) {
            return response()->json(['message' => 'Not found'], 404);
        }

        $force = filter_var($request->query('force', false), FILTER_VALIDATE_BOOLEAN);
        $sold  = DB::table('inventory_sale_items')->where('product_id', $id)->exists();

        if ($sold && ! $force) {
            return response()->json([
                'message'     => 'Product has sales history. Pass ?force=1 to archive (deactivate) instead.',
                'sales_count' => DB::table('inventory_sale_items')->where('product_id', $id)->count(),
            ], 422);
        }

        if ($sold && $force) {
            $user = $request->user();
            if (! $user || ! ($user->isSuperAdmin() || in_array($user->role, ['admin', 'manager']) || $user->full_access)) {
                return response()->json(['message' => 'Only admins may force-archive a product with sales history.'], 403);
            }
            // Archive rather than hard-delete to preserve financial integrity
            DB::table('inventory_products')->where('id', $id)->update([
                'status'     => 'inactive',
                'updated_at' => now(),
            ]);
            $this->audit->record($request, 'product', $id, 'archived', (array) $existing, ['status' => 'inactive'], $existing->name);
            return response()->json(['message' => 'Product archived (has sales history — cannot be hard-deleted)']);
        }

        DB::table('inventory_products')->where('id', $id)->delete();
        $this->audit->record($request, 'product', $id, 'deleted', (array) $existing, null, $existing->name);

        return response()->json(['message' => 'Product deleted']);
    }
}
