<?php

namespace App\Http\Controllers\Inventory;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;
use Illuminate\Routing\Controller;

class StockMovementController extends Controller
{
    public function store(Request $request)
    {
        $v = Validator::make($request->all(), [
            'product_id' => 'required|exists:inventory_products,id',
            'type' => 'required|in:in,out',
            'quantity' => 'required|integer|min:1',
            'reference' => 'nullable|string',
        ]);
        if ($v->fails()) {
            return response()->json(['message' => $v->errors()->first()], 422);
        }

        return DB::transaction(function () use ($request) {
            $product = DB::table('inventory_products')->lockForUpdate()->find($request->product_id);
            if (!$product) {
                return response()->json(['message' => 'Product not found'], 404);
            }

            $newQty = $product->quantity + ($request->type === 'in' ? (int)$request->quantity : -(int)$request->quantity);
            if ($newQty < 0) {
                return response()->json(['message' => 'Insufficient stock'], 422);
            }

            DB::table('inventory_products')->where('id', $product->id)->update(['quantity' => $newQty]);

            DB::table('inventory_stock_movements')->insert([
                'product_id' => (int)$product->id,
                'type' => $request->type,
                'quantity' => (int)$request->quantity,
                'reference' => $request->reference,
                'user_id' => optional($request->user())->id,
                'created_at' => now(),
            ]);

            return response()->json(['message' => 'Stock updated'], 201);
        });
    }
}
