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
        $query = House::query()->whereHas('property', function ($q) use ($request) {
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
            'images.*' => 'nullable|image',
            'kitchen_location' => 'nullable|string',
            'distance_from_road' => 'nullable|string',
            'electricity_type' => 'nullable|string',
            'electricity_sharing_count' => 'nullable|integer',
            'water_type' => 'nullable|string',
            'water_sharing_count' => 'nullable|integer',
            'maintenance_until' => 'nullable|date|after_or_equal:today',
        ]);

        $data = $request->except('images');

        $booleanFields = ['has_fence', 'has_tiles', 'has_sitting_room', 'has_master_bedroom', 'has_kitchen', 'landlord_lives_present'];
        foreach ($booleanFields as $field) {
            if ($request->has($field)) {
                $data[$field] = filter_var($request->get($field), FILTER_VALIDATE_BOOLEAN);
            }
        }

        $imagePaths = [];
        if ($request->hasFile('images')) {
            foreach ($request->file('images') as $image) {
                $imagePaths[] = $image->store('houses', 'public');
            }
        }
        $data['images'] = $imagePaths;

        // Parse image captions (double-pipe separated string from frontend)
        if ($request->has('image_captions') && !empty($request->image_captions)) {
            $data['image_captions'] = explode('||', $request->image_captions);
        }

        $data['status'] = 'vacant';

        $house = House::create($data);

        Property::find($request->property_id)->increment('total_units');

        return ResponseHelper::success($house, 'House created successfully', 201);
    }

    /**
     * Get single house details.
     * GET /rental/houses/{id}
     */
    public function show(Request $request, $id)
    {
        $house = House::whereHas('property', function ($q) use ($request) {
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
        $house = House::whereHas('property', function ($q) use ($request) {
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
            'images.*' => 'nullable|image',
            'kitchen_location' => 'nullable|string',
            'distance_from_road' => 'nullable|string',
            'electricity_type' => 'nullable|string',
            'electricity_sharing_count' => 'nullable|integer',
            'water_type' => 'nullable|string',
            'water_sharing_count' => 'nullable|integer',
            'maintenance_until' => 'nullable|date|after_or_equal:today',
        ]);

        $data = $request->except('images');

        $booleanFields = ['has_fence', 'has_tiles', 'has_sitting_room', 'has_master_bedroom', 'has_kitchen', 'landlord_lives_present'];
        foreach ($booleanFields as $field) {
            if ($request->has($field)) {
                $data[$field] = filter_var($request->get($field), FILTER_VALIDATE_BOOLEAN);
            }
        }

        // Handle image management (deletions/reordering/re-captioning)
        $currentImages = is_array($house->images) ? $house->images : [];
        $currentCaptions = is_array($house->image_captions) ? $house->image_captions : [];

        if ($request->has('existing_images')) {
            $currentImages = is_array($request->existing_images) ? $request->existing_images : explode('||', $request->existing_images);
            // Ensure we filter out empty strings if any
            $currentImages = array_values(array_filter($currentImages));
            $data['images'] = $currentImages;
        }

        if ($request->has('existing_captions')) {
            $currentCaptions = is_array($request->existing_captions) ? $request->existing_captions : explode('||', $request->existing_captions);
            // We don't filter captions as they might be empty intentionally, but we align them
            $data['image_captions'] = $currentCaptions;
        }

        // Handle new uploads
        if ($request->hasFile('images')) {
            foreach ($request->file('images') as $image) {
                $currentImages[] = $image->store('houses', 'public');
            }
            $data['images'] = $currentImages;

            // Handle new captions if provided alongside new files
            if ($request->has('image_captions')) {
                $newCaptions = explode('||', $request->image_captions);
                $currentCaptions = array_merge($currentCaptions, $newCaptions);
                $data['image_captions'] = $currentCaptions;
            }
        }

        $house->update($data);

        return ResponseHelper::success($house, 'House updated successfully');
    }

    /**
     * Delete a house.
     * DELETE /rental/houses/{id}
     */
    public function destroy(Request $request, $id)
    {
        $house = House::whereHas('property', function ($q) use ($request) {
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

    /**
     * Public listing – no auth required.
     * Returns houses with images & features, excluding private meter data.
     * GET /api/public/houses
     */
    public function publicListing(Request $request)
    {
        $query = House::with('property:id,name,property_type,address,region,district,ward,street');

        // Filter by status (Default: Exclude occupied)
        if ($request->status) {
            $query->where('status', $request->status);
        } else {
            $query->whereIn('status', ['vacant', 'maintenance', 'reserved']);
        }

        // Filter by type
        if ($request->type) {
            $query->where('type', $request->type);
        }

        // Search
        if ($request->search) {
            $query->where(function ($q) use ($request) {
                $q->where('house_number', 'like', "%{$request->search}%")
                    ->orWhereHas('property', function ($pq) use ($request) {
                        $pq->where('name', 'like', "%{$request->search}%")
                            ->orWhere('address', 'like', "%{$request->search}%")
                            ->orWhere('region', 'like', "%{$request->search}%")
                            ->orWhere('district', 'like', "%{$request->search}%")
                            ->orWhere('ward', 'like', "%{$request->search}%")
                            ->orWhere('street', 'like', "%{$request->search}%");
                    });
            });
        }

        // Advanced Filters
        if ($request->bedrooms) {
            $query->where('bedrooms', '>=', $request->bedrooms);
        }
        if ($request->bathrooms) {
            $query->where('bathrooms', '>=', $request->bathrooms);
        }
        if ($request->max_distance) {
            $query->where('distance_from_road', '<=', $request->max_distance);
        }
        if ($request->has_fence !== null) {
            $query->where('has_fence', $request->boolean('has_fence'));
        }
        if ($request->has_tiles !== null) {
            $query->where('has_tiles', $request->boolean('has_tiles'));
        }
        if ($request->has_kitchen !== null) {
            $query->where('has_kitchen', $request->boolean('has_kitchen'));
        }
        if ($request->has_master_bedroom !== null) {
            $query->where('has_master_bedroom', $request->boolean('has_master_bedroom'));
        }
        if ($request->has_sitting_room !== null) {
            $query->where('has_sitting_room', $request->boolean('has_sitting_room'));
        }

        $perPage = $request->get('per_page', 20);
        $houses = $query->latest()->paginate($perPage);

        // Strip private meter data from each house
        $houses->getCollection()->transform(function ($house) {
            $house->makeHidden([
                'electricity_meter',
                'water_meter',
                'electricity_sharing_count',
                'water_sharing_count',
            ]);
            return $house;
        });

        return ResponseHelper::paginate($houses);
    }
}