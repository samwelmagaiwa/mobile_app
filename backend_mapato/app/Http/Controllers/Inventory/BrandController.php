<?php

namespace App\Http\Controllers\Inventory;

use Illuminate\Http\Request;
use Illuminate\Routing\Controller;
use Illuminate\Support\Facades\DB;

/**
 * Area 2 — product brands.
 */
class BrandController extends Controller
{
    public function index(Request $request)
    {
        $query = DB::table('inventory_brands as b')
            ->leftJoin('inventory_products as p', 'p.brand_id', '=', 'b.id')
            ->select('b.*', DB::raw('COUNT(p.id) as products_count'))
            ->groupBy('b.id', 'b.name', 'b.description', 'b.status', 'b.created_by', 'b.created_at', 'b.updated_at');

        if ($q = $request->query('q')) {
            $query->where('b.name', 'like', "%{$q}%");
        }
        if ($status = $request->query('status')) {
            $query->where('b.status', $status);
        }

        return response()->json(['data' => $query->orderBy('b.name')->get()]);
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'name' => 'required|string|max:255|unique:inventory_brands,name',
            'description' => 'nullable|string|max:255',
            'status' => 'nullable|in:active,inactive',
        ]);

        $id = DB::table('inventory_brands')->insertGetId([
            'name' => $data['name'],
            'description' => $data['description'] ?? null,
            'status' => $data['status'] ?? 'active',
            'created_by' => optional($request->user())->id,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        return response()->json(['message' => 'Brand created', 'data' => ['id' => (int) $id]], 201);
    }

    public function update(Request $request, int $id)
    {
        if (! DB::table('inventory_brands')->where('id', $id)->exists()) {
            return response()->json(['message' => 'Not found'], 404);
        }

        $data = $request->validate([
            'name' => 'sometimes|required|string|max:255|unique:inventory_brands,name,' . $id,
            'description' => 'nullable|string|max:255',
            'status' => 'sometimes|required|in:active,inactive',
        ]);

        DB::table('inventory_brands')->where('id', $id)
            ->update(array_merge($data, ['updated_at' => now()]));

        return response()->json(['message' => 'Brand updated']);
    }

    public function destroy(int $id)
    {
        $inUse = DB::table('inventory_products')->where('brand_id', $id)->exists();
        if ($inUse) {
            return response()->json(['message' => 'Brand is in use by products'], 422);
        }

        $deleted = DB::table('inventory_brands')->where('id', $id)->delete();

        return $deleted
            ? response()->json(['message' => 'Brand deleted'])
            : response()->json(['message' => 'Not found'], 404);
    }
}
