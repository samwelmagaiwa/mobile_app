<?php

namespace App\Http\Controllers\API\Rental;

use App\Http\Controllers\Controller;
use App\Models\Rental\House;
use App\Models\Rental\Property;
use App\Helpers\ResponseHelper;
use Illuminate\Http\Request;

class HouseController extends Controller
{
    /**
     * Get all houses with optional filters and search.
     * GET /rental/houses
     */
    public function index(Request $request)
    {
        $query = House::query()->whereHas('property', function($q) use ($request) {
            $q->where('owner_id', $request->user()->id);
        });

        // Filter by property
        if ($request->property_id) {
            $query->where('property_id', $request->property_id);
        }

        // Filter by block
        if ($request->block_id) {
            $query->where('block_id', $request->block_id);
        }

        // Filter by status
        if ($request->status) {
            $query->where('status', $request->status);
        }

        // Search by house number
        if ($request->search) {
            $query->where('house_number', 'like', "%{$request->search}%");
        }

        // Pagination
        $perPage = $request->get('per_page', 15);
        $houses = $query->with('property', 'block', 'currentTenant')->paginate($perPage);

        return ResponseHelper::paginate($houses);
    }

    /**
     * Get houses for a specific property.
     * GET /rental/properties/{propertyId}/houses
     */
    public function getByProperty(Request $request, $propertyId)
    {
        // Verify property belongs to user
        $property = Property::where('owner_id', $request->user()->id)->findOrFail($propertyId);

        $houses = House::where('property_id', $propertyId)
            ->with('block', 'currentTenant')
            ->get();

        return ResponseHelper::success($houses);
    }

    /**
     * Create a new house.
     * POST /rental/houses
     */
    public function store(Request $request)
    {
        // Verify property belongs to user
        Property::where('owner_id', $request->user()->id)->findOrFail($request->property_id);

        $request->validate([
            'property_id' => 'required|exists:rental_properties,id',
            'block_id' => 'nullable|exists:rental_blocks,id',
            'house_number' => 'required|string|max:50',
            'type' => 'required|in:apartment,room,commercial,studio,bedsitter,one_bedroom,two_bedroom,three_bedroom',
            'rent_amount' => 'required|numeric|min:0',
            'deposit_amount' => 'nullable|numeric|min:0',
            'electricity_meter' => 'nullable|string|max:50',
            'water_meter' => 'nullable|string|max:50',
            'bedrooms' => 'nullable|integer|min:0',
            'bathrooms' => 'nullable|integer|min:0',
            'floor' => 'nullable|integer|min:0',
            'square_meters' => 'nullable|integer|min:0',
            'description' => 'nullable|string|max:500',
        ]);

        $house = House::create(array_merge($request->all(), [
            'status' => 'vacant',
        ]));

        // Update property total_units
        Property::find($request->property_id)->increment('total_units');

        return ResponseHelper::success($house, 'House created successfully', 201);
    }

    /**
     * Get single house details.
     * GET /rental/houses/{id}
     */
    public function show(Request $request, $id)
    {
        $house = House::whereHas('property', function($q) use ($request) {
            $q->where('owner_id', $request->user()->id);
        })->with('property', 'block', 'currentTenant', 'agreements.tenant', 'bills')->findOrFail($id);

        return ResponseHelper::success($house);
    }

    /**
     * Update a house.
     * PUT /rental/houses/{id}
     */
    public function update(Request $request, $id)
    {
        $house = House::whereHas('property', function($q) use ($request) {
            $q->where('owner_id', $request->user()->id);
        })->findOrFail($id);

        $request->validate([
            'house_number' => 'sometimes|string|max:50',
            'type' => 'sometimes|in:apartment,room,commercial,studio,bedsitter,one_bedroom,two_bedroom,three_bedroom',
            'rent_amount' => 'sometimes|numeric|min:0',
            'deposit_amount' => 'sometimes|numeric|min:0',
            'electricity_meter' => 'nullable|string|max:50',
            'water_meter' => 'nullable|string|max:50',
            'bedrooms' => 'nullable|integer|min:0',
            'bathrooms' => 'nullable|integer|min:0',
            'floor' => 'nullable|integer|min:0',
            'square_meters' => 'nullable|integer|min:0',
            'status' => 'sometimes|in:vacant,occupied,maintenance,reserved',
            'description' => 'nullable|string|max:500',
        ]);

        $house->update($request->only([
            'house_number', 'type', 'rent_amount', 'deposit_amount',
            'electricity_meter', 'water_meter', 'bedrooms', 'bathrooms',
            'floor', 'square_meters', 'status', 'description'
        ]));

        return ResponseHelper::success($house, 'House updated successfully');
    }

    /**
     * Delete a house.
     * DELETE /rental/houses/{id}
     */
    public function destroy(Request $request, $id)
    {
        $house = House::whereHas('property', function($q) use ($request) {
            $q->where('owner_id', $request->user()->id);
        })->findOrFail($id);

        if ($house->status === 'occupied') {
            return ResponseHelper::error('Cannot delete occupied house. Move out tenant first.', 400);
        }

        if ($house->agreements()->count() > 0) {
            return ResponseHelper::error('Cannot delete house with active agreements.', 400);
        }

        $propertyId = $house->property_id;
        $house->delete();

        // Update property total_units
        Property::find($propertyId)->decrement('total_units');

        return ResponseHelper::success(null, 'House deleted successfully');
    }
}