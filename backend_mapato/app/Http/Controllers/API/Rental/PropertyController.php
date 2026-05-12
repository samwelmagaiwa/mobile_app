<?php

namespace App\Http\Controllers\API\Rental;

use App\Http\Controllers\Controller;
use App\Models\Rental\Property;
use App\Models\Rental\House;
use App\Helpers\ResponseHelper;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class PropertyController extends Controller
{
    /**
     * List all properties for the landlord.
     */
    public function index(Request $request)
    {
        $properties = Property::where('owner_id', $request->user()->id)
            ->with(['blocks', 'houses'])
            ->get();
        return ResponseHelper::success($properties);
    }

    /**
     * Show single property with all houses.
     */
    public function show(Request $request, $id)
    {
        $property = Property::where('owner_id', $request->user()->id)
            ->with(['blocks', 'houses'])
            ->findOrFail($id);
        return ResponseHelper::success($property);
    }

    /**
     * Create a new property.
     */
    public function store(Request $request)
    {
        $request->validate([
            'name' => 'required|string',
            'location' => 'required|string',
            'address' => 'nullable|string',
            'city' => 'nullable|string',
            'description' => 'nullable|string',
        ]);

        $property = Property::create([
            'owner_id' => $request->user()->id,
            'name' => $request->name,
            'location' => $request->location,
            'address' => $request->address,
            'city' => $request->city,
            'description' => $request->description,
        ]);

        return ResponseHelper::success($property, 'Property created successfully', 201);
    }

    /**
     * Update a property.
     */
    public function update(Request $request, $id)
    {
        $property = Property::where('owner_id', $request->user()->id)->findOrFail($id);

        $request->validate([
            'name' => 'sometimes|string',
            'location' => 'sometimes|string',
            'address' => 'nullable|string',
            'city' => 'nullable|string',
            'description' => 'nullable|string',
        ]);

        $property->update($request->only([
            'name', 'location', 'address', 'city', 'description'
        ]));

        return ResponseHelper::success($property, 'Property updated successfully');
    }

    /**
     * Delete a property (only if no houses).
     */
    public function destroy(Request $request, $id)
    {
        $property = Property::where('owner_id', $request->user()->id)->findOrFail($id);

        if ($property->houses()->count() > 0) {
            return ResponseHelper::error('Cannot delete property with houses. Remove houses first.', 400);
        }

        $property->delete();

        return ResponseHelper::success(null, 'Property deleted successfully');
    }

    /**
     * Add a house to a property.
     */
    public function addHouse(Request $request, $propertyId)
    {
        $property = Property::where('owner_id', $request->user()->id)->findOrFail($propertyId);

        $request->validate([
            'house_number' => 'required|string',
            'rent_amount' => 'required|numeric',
            'type' => 'sometimes|in:apartment,room,commercial,studio',
            'deposit_amount' => 'sometimes|numeric',
            'block_id' => 'nullable|exists:rental_blocks,id',
            'electricity_meter' => 'nullable|string',
            'water_meter' => 'nullable|string',
        ]);

        $house = House::create([
            'property_id' => $propertyId,
            'block_id' => $request->block_id,
            'house_number' => $request->house_number,
            'type' => $request->type ?? 'room',
            'rent_amount' => $request->rent_amount,
            'deposit_amount' => $request->deposit_amount ?? 0,
            'electricity_meter' => $request->electricity_meter,
            'water_meter' => $request->water_meter,
            'status' => 'vacant',
        ]);

        return ResponseHelper::success($house, 'House added successfully', 201);
    }
}