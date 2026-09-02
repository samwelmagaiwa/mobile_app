<?php

namespace App\Http\Controllers\Inventory;

use Illuminate\Http\Request;
use Illuminate\Routing\Controller;
use Illuminate\Support\Facades\DB;

/**
 * Area 2 — product categories.
 */
class CategoryController extends Controller
{
    public function index(Request $request)
    {
        $query = DB::table('inventory_categories as c')
            ->leftJoin('inventory_products as p', 'p.category_id', '=', 'c.id')
            ->select('c.*', DB::raw('COUNT(p.id) as products_count'))
            ->groupBy('c.id', 'c.name', 'c.description', 'c.status', 'c.created_by', 'c.created_at', 'c.updated_at');

        if ($q = $request->query('q')) {
            $query->where('c.name', 'like', "%{$q}%");
        }
        if ($status = $request->query('status')) {
            $query->where('c.status', $status);
        }

        return response()->json(['data' => $query->orderBy('c.name')->get()]);
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'name' => 'required|string|max:255|unique:inventory_categories,name',
            'description' => 'nullable|string|max:255',
            'status' => 'nullable|in:active,inactive',
        ]);

        $id = DB::table('inventory_categories')->insertGetId([
            'name' => $data['name'],
            'description' => $data['description'] ?? null,
            'status' => $data['status'] ?? 'active',
            'created_by' => optional($request->user())->id,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        return response()->json(['message' => 'Category created', 'data' => ['id' => (int) $id]], 201);
    }

    public function update(Request $request, int $id)
    {
        if (! DB::table('inventory_categories')->where('id', $id)->exists()) {
            return response()->json(['message' => 'Not found'], 404);
        }

        $data = $request->validate([
            'name' => 'sometimes|required|string|max:255|unique:inventory_categories,name,' . $id,
            'description' => 'nullable|string|max:255',
            'status' => 'sometimes|required|in:active,inactive',
        ]);

        DB::transaction(function () use ($id, $data) {
            DB::table('inventory_categories')->where('id', $id)
                ->update(array_merge($data, ['updated_at' => now()]));

            // Keep the legacy denormalised string on products in step.
            if (isset($data['name'])) {
                DB::table('inventory_products')->where('category_id', $id)
                    ->update(['category' => $data['name'], 'updated_at' => now()]);
            }
        });

        return response()->json(['message' => 'Category updated']);
    }

    public function destroy(int $id)
    {
        $inUse = DB::table('inventory_products')->where('category_id', $id)->exists();
        if ($inUse) {
            return response()->json(['message' => 'Category is in use by products'], 422);
        }

        $deleted = DB::table('inventory_categories')->where('id', $id)->delete();

        return $deleted
            ? response()->json(['message' => 'Category deleted'])
            : response()->json(['message' => 'Not found'], 404);
    }
}
