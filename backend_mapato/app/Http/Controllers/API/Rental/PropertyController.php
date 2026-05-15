<?php

namespace App\Http\Controllers\API\Rental;

use App\Http\Controllers\Controller;
use App\Http\Requests\StorePropertyRequest;
use App\Http\Requests\UpdatePropertyRequest;
use App\Http\Resources\PropertyResource;
use App\Services\Rental\PropertyService;
use App\Models\Rental\Property;
use App\Models\Rental\House;
use App\Helpers\ResponseHelper;
use Illuminate\Http\Request;

class PropertyController extends Controller
{
    protected PropertyService $propertyService;

    public function __construct(PropertyService $propertyService)
    {
        $this->propertyService = $propertyService;
    }

    /**
     * Get all properties with pagination and filters.
     * GET /rental/properties
     */
    public function index(Request $request)
    {
        $filters = $request->only(['search', 'status', 'property_type', 'sort_by', 'sort_order']);
        $perPage = $request->get('per_page', 15);

        $properties = $this->propertyService
            ->setOwner($request->user()->id)
            ->getAll($filters, $perPage);

        return ResponseHelper::paginate($properties, PropertyResource::class);
    }

    /**
     * Get property statistics.
     * GET /rental/properties/stats
     */
    public function stats(Request $request)
    {
        $stats = $this->propertyService
            ->setOwner($request->user()->id)
            ->getStatistics();

        return ResponseHelper::success($stats);
    }

    /**
     * Show single property.
     * GET /rental/properties/{id}
     */
    public function show(Request $request, string $id)
    {
        $property = $this->propertyService
            ->setOwner($request->user()->id)
            ->getById($id);

        return ResponseHelper::success(new PropertyResource($property));
    }

    /**
     * Create a new property.
     * POST /rental/properties
     */
    public function store(StorePropertyRequest $request)
    {
        try {
            $property = $this->propertyService
                ->setOwner($request->user()->id)
                ->create($request->validated());

            return ResponseHelper::success(
                new PropertyResource($property->load(['blocks', 'houses', 'caretaker'])),
                'Mali imeundwa vizuri',
                201
            );
        } catch (\Exception $e) {
            return ResponseHelper::error($e->getMessage(), 500);
        }
    }

    /**
     * Update a property.
     * PUT /rental/properties/{id}
     */
    public function update(UpdatePropertyRequest $request, string $id)
    {
        try {
            $property = $this->propertyService
                ->setOwner($request->user()->id)
                ->update($id, $request->validated());

            return ResponseHelper::success(
                new PropertyResource($property),
                'Mali imesasurwa vizuri'
            );
        } catch (\Exception $e) {
            return ResponseHelper::error($e->getMessage(), 500);
        }
    }

    /**
     * Delete a property (soft delete).
     * DELETE /rental/properties/{id}
     */
    public function destroy(Request $request, string $id)
    {
        try {
            $this->propertyService
                ->setOwner($request->user()->id)
                ->delete($id);

            return ResponseHelper::success(null, 'Mali imefutwa');
        } catch (\Exception $e) {
            return ResponseHelper::error($e->getMessage(), 400);
        }
    }

    /**
     * Restore a deleted property.
     * POST /rental/properties/{id}/restore
     */
    public function restore(Request $request, string $id)
    {
        try {
            $property = $this->propertyService
                ->setOwner($request->user()->id)
                ->restore($id);

            return ResponseHelper::success(
                new PropertyResource($property),
                'Mali imerejeshwa'
            );
        } catch (\Exception $e) {
            return ResponseHelper::error($e->getMessage(), 500);
        }
    }

    /**
     * Get deleted properties.
     * GET /rental/properties/trashed
     */
    public function trashed(Request $request)
    {
        $properties = $this->propertyService
            ->setOwner($request->user()->id)
            ->getDeleted();

        return ResponseHelper::success(PropertyResource::collection($properties));
    }

    /**
     * Add a house to a property.
     * POST /rental/properties/{id}/houses
     */
    public function addHouse(Request $request, string $propertyId)
    {
        $property = Property::where('owner_id', $request->user()->id)->findOrFail($propertyId);

        $request->validate([
            'house_number' => 'required|string|max:50',
            'rent_amount' => 'required|numeric|min:0',
            'type' => 'sometimes|in:apartment,room,commercial,studio,bedsitter,one_bedroom,two_bedroom',
            'deposit_amount' => 'sometimes|numeric|min:0',
            'block_id' => 'nullable|exists:rental_blocks,id',
            'electricity_meter' => 'nullable|string|max:50',
            'water_meter' => 'nullable|string|max:50',
            'bedrooms' => 'nullable|integer|min:0',
            'bathrooms' => 'nullable|integer|min:0',
            'floor' => 'nullable|integer|min:0',
            'status' => 'sometimes|in:vacant,occupied,maintenance,reserved',
        ]);

        $house = House::create(array_merge($request->all(), [
            'property_id' => $propertyId,
            'status' => $request->status ?? 'vacant',
            'deposit_amount' => $request->deposit_amount ?? ($property->default_deposit_amount ?? 0),
        ]));

        $property->increment('total_units');

        return ResponseHelper::success($house, 'Nyumba imeongezwa', 201);
    }
}