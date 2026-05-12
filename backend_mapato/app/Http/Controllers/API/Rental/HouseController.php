<?php

namespace App\Http\Controllers\API\Rental;

use App\Http\Controllers\Controller;
use App\Models\Rental\House;
use App\Helpers\ResponseHelper;
use Illuminate\Http\Request;

class HouseController extends Controller
{
    public function index(Request $request)
    {
        $query = House::query();
        
        // Filter by property if provided
        if ($request->property_id) {
            $query->where('property_id', $request->property_id);
        }
        
        // Filter by block if provided
        if ($request->block_id) {
            $query->where('block_id', $request->block_id);
        }
        
        // Filter by status
        if ($request->status) {
            $query->where('status', $request->status);
        }
        
        $houses = $query->with('property', 'block', 'currentTenant')->get();
        
        return ResponseHelper::success($houses);
    }

    public function show($id)
    {
        $house = House::with('property', 'block', 'currentTenant', 'agreements.tenant')->findOrFail($id);
        return ResponseHelper::success($house);
    }

    public function update(Request $request, $id)
    {
        $house = House::findOrFail($id);
        
        $request->validate([
            'house_number' => 'sometimes|string',
            'type' => 'sometimes|in:apartment,room,commercial,studio',
            'rent_amount' => 'sometimes|numeric',
            'deposit_amount' => 'sometimes|numeric',
            'electricity_meter' => 'nullable|string',
            'water_meter' => 'nullable|string',
            'status' => 'sometimes|in:vacant,occupied,maintenance,reserved',
        ]);

        $house->update($request->only([
            'house_number', 'type', 'rent_amount', 'deposit_amount',
            'electricity_meter', 'water_meter', 'status'
        ]));
        
        return ResponseHelper::success($house, 'House updated successfully');
    }

    public function destroy($id)
    {
        $house = House::findOrFail($id);
        
        if ($house->status === 'occupied') {
            return ResponseHelper::error('Cannot delete occupied house. Move out tenant first.', 400);
        }
        
        $house->delete();
        
        return ResponseHelper::success(null, 'House deleted successfully');
    }
}