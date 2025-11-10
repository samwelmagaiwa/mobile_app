<?php

namespace App\Http\Controllers\Inventory;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Routing\Controller;

class ProductController extends Controller
{
    public function index(Request $request)
    {
        $q = $request->query('q');
        $status = $request->query('status');
        $lowStock = (bool) $request->query('low_stock', false);

        $query = DB::table('inventory_products');
        if ($q) {
            $query->where(function($w) use ($q) {
                $w->where('name','like',"%$q%")
                  ->orWhere('sku','like',"%$q%")
                  ->orWhere('barcode','like',"%$q%");
            });
        }
        if ($status) {
            $query->where('status', $status);
        }
        if ($lowStock) {
            $query->whereColumn('quantity','<','min_stock');
        }

        $products = $query->orderByDesc('id')->paginate(20);
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
            'sku' => 'required|string|max:255|unique:inventory_products,sku',
            'category' => 'nullable|string|max:255',
            'cost_price' => 'required|numeric|min:0',
            'selling_price' => 'required|numeric|min:0',
            'unit' => 'nullable|string|max:32',
            'quantity' => 'required|integer|min:0',
            'min_stock' => 'required|integer|min:0',
            'status' => 'required|in:active,inactive',
            'barcode' => 'nullable|string|max:255',
        ]);

        $id = DB::table('inventory_products')->insertGetId([
            'name' => $data['name'],
            'sku' => $data['sku'],
            'category' => $data['category'] ?? null,
            'cost_price' => $data['cost_price'],
            'selling_price' => $data['selling_price'],
            'unit' => $data['unit'] ?? 'pcs',
            'quantity' => $data['quantity'],
            'min_stock' => $data['min_stock'],
            'status' => $data['status'],
            'barcode' => $data['barcode'] ?? null,
            'created_by' => optional($request->user())->id,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        return response()->json(['message' => 'Product created', 'data' => ['id' => (int)$id]], 201);
    }

    public function update(Request $request, int $id)
    {
        $exists = DB::table('inventory_products')->where('id', $id)->exists();
        if (!$exists) return response()->json(['message' => 'Not found'], 404);

        $data = $request->validate([
            'name' => 'sometimes|required|string|max:255',
            'sku' => 'sometimes|required|string|max:255|unique:inventory_products,sku,'.$id,
            'category' => 'nullable|string|max:255',
            'cost_price' => 'sometimes|required|numeric|min:0',
            'selling_price' => 'sometimes|required|numeric|min:0',
            'unit' => 'nullable|string|max:32',
            'quantity' => 'sometimes|required|integer|min:0',
            'min_stock' => 'sometimes|required|integer|min:0',
            'status' => 'sometimes|required|in:active,inactive',
            'barcode' => 'nullable|string|max:255',
        ]);

        DB::table('inventory_products')->where('id', $id)->update(array_merge($data, [
            'updated_at' => now(),
        ]));

        return response()->json(['message' => 'Product updated']);
    }
}
