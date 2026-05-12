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
    public function index(Request $request)
    {
        $properties = Property::where('owner_id', $request->user()->id)
            ->with(['blocks', 'houses'])
            ->get();
        return ResponseHelper::success($properties);
    }

    public function store(Request $request)
    {
        $request->validate([
            'name' => 'required|string',
            'location' => 'required|string',
        ]);

        $property = Property::create([
            'owner_id' => $request->user()->id,
            'name' => $request->name,
            'location' => $request->location,
            'address' => $request->address,
        ]);

        return ResponseHelper::success($property, 'Property created successfully', 201);
    }

    public function addHouse(Request $request, $propertyId)
    {
        $request->validate([
            'house_number' => 'required|string',
            'rent_amount' => 'required|numeric',
        ]);

        $house = House::create([
            'property_id' => $propertyId,
            'block_id' => $request->block_id,
            'house_number' => $request->house_number,
            'type' => $request->type ?? 'room',
            'rent_amount' => $request->rent_amount,
        ]);

        return ResponseHelper::success($house, 'House added successfully', 201);
    }
}
