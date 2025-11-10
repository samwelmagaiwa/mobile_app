<?php

namespace App\Http\Controllers\Inventory;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Routing\Controller;

class CustomerController extends Controller
{
    public function index(Request $request)
    {
        $q = $request->query('q');
        $query = DB::table('inventory_customers');
        if ($q) {
            $query->where(function($w) use ($q) {
                $w->where('name','like',"%$q%")
                  ->orWhere('phone','like',"%$q%");
            });
        }
        $customers = $query->orderByDesc('id')->paginate(20);
        return response()->json([
            'data' => $customers->items(),
            'meta' => [
                'current_page' => $customers->currentPage(),
                'last_page' => $customers->lastPage(),
                'per_page' => $customers->perPage(),
                'total' => $customers->total(),
            ],
        ]);
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'name' => 'required|string|max:255',
            'phone' => 'required|string|max:32',
            'address' => 'nullable|string|max:255',
        ]);
        $id = DB::table('inventory_customers')->insertGetId([
            'name' => $data['name'],
            'phone' => $data['phone'],
            'address' => $data['address'] ?? null,
            'created_at' => now(),
            'updated_at' => now(),
        ]);
        return response()->json(['message' => 'Customer created', 'data' => ['id' => (int)$id]], 201);
    }

    public function update(Request $request, int $id)
    {
        $exists = DB::table('inventory_customers')->where('id', $id)->exists();
        if (!$exists) return response()->json(['message' => 'Not found'], 404);

        $data = $request->validate([
            'name' => 'sometimes|required|string|max:255',
            'phone' => 'sometimes|required|string|max:32',
            'address' => 'nullable|string|max:255',
        ]);
        DB::table('inventory_customers')->where('id', $id)->update(array_merge($data, [
            'updated_at' => now(),
        ]));
        return response()->json(['message' => 'Customer updated']);
    }
}
