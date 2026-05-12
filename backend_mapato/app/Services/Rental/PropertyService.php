<?php

namespace App\Services\Rental;

use App\Models\Rental\Property;
use App\Models\Rental\House;
use Illuminate\Support\Facades\DB;

class PropertyService
{
    protected ?string $ownerId = null;

    public function setOwner(string $ownerId): self
    {
        $this->ownerId = $ownerId;
        return $this;
    }

    protected function getOwnerId(): string
    {
        return $this->ownerId ?? auth()->id();
    }

    /**
     * Get all properties for a landlord with pagination and filters.
     */
    public function getAll(array $filters, int $perPage = 15)
    {
        $ownerId = $this->getOwnerId();
        
        $query = Property::with(['blocks', 'houses', 'caretaker'])
            ->where('owner_id', $ownerId);

        // Search filter
        if (!empty($filters['search'])) {
            $search = $filters['search'];
            $query->where(function($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('address', 'like', "%{$search}%")
                  ->orWhere('region', 'like', "%{$search}%")
                  ->orWhere('district', 'like', "%{$search}%");
            });
        }

        // Status filter
        if (!empty($filters['status'])) {
            $query->where('status', $filters['status']);
        }

        // Property type filter
        if (!empty($filters['property_type'])) {
            $query->where('property_type', $filters['property_type']);
        }

        // Sorting
        $sortBy = $filters['sort_by'] ?? 'created_at';
        $sortOrder = $filters['sort_order'] ?? 'desc';
        $query->orderBy($sortBy, $sortOrder);

        return $query->paginate($perPage);
    }

    /**
     * Get single property with full details.
     */
    public function getById(string $id): Property
    {
        return Property::with(['blocks', 'houses', 'caretaker'])
            ->where('owner_id', $this->getOwnerId())
            ->findOrFail($id);
    }

    /**
     * Create a new property.
     */
    public function create(array $data): Property
    {
        return DB::transaction(function() use ($data) {
            $property = Property::create(array_merge($data, [
                'owner_id' => $this->getOwnerId(),
                'status' => $data['status'] ?? 'active',
                'default_currency' => $data['currency'] ?? 'TZS',
                'default_billing_cycle' => $data['billing_cycle'] ?? 'monthly',
                'number_of_blocks' => $data['number_of_blocks'] ?? 1,
                'total_units' => $data['total_units'] ?? 0,
            ]));

            return $property;
        });
    }

    /**
     * Update an existing property.
     */
    public function update(string $id, array $data): Property
    {
        $property = $this->getById($id);

        $property->update($data);

        return $property->fresh(['blocks', 'houses', 'caretaker']);
    }

    /**
     * Delete a property (soft delete).
     */
    public function delete(string $id): bool
    {
        $property = $this->getById($id);

        // Check if property has houses
        if ($property->houses()->count() > 0) {
            throw new \Exception('Cannot delete property with houses. Remove houses first.');
        }

        // Check if property has blocks
        if ($property->blocks()->count() > 0) {
            throw new \Exception('Cannot delete property with blocks. Remove blocks first.');
        }

        $property->delete();

        return true;
    }

    /**
     * Get property statistics.
     */
    public function getStatistics(): array
    {
        $properties = Property::where('owner_id', $this->getOwnerId())->get();
        
        $totalProperties = $properties->count();
        $totalUnits = $properties->sum('total_units');
        
        $occupiedUnits = House::whereHas('property', function($query) {
            $query->where('owner_id', $this->getOwnerId());
        })->where('status', 'occupied')->count();

        $vacantUnits = $totalUnits - $occupiedUnits;
        
        $activeProperties = $properties->where('status', 'active')->count();
        $maintenanceProperties = $properties->where('status', 'under_maintenance')->count();

        return [
            'total_properties' => $totalProperties,
            'total_units' => $totalUnits,
            'occupied_units' => $occupiedUnits,
            'vacant_units' => $vacantUnits,
            'occupancy_rate' => $totalUnits > 0 ? round(($occupiedUnits / $totalUnits) * 100, 1) : 0,
            'active_properties' => $activeProperties,
            'maintenance_properties' => $maintenanceProperties,
        ];
    }

    /**
     * Restore a soft-deleted property.
     */
    public function restore(string $id): Property
    {
        $property = Property::withTrashed()
            ->where('owner_id', $this->getOwnerId())
            ->findOrFail($id);

        $property->restore();

        return $property;
    }

    /**
     * Get deleted properties.
     */
    public function getDeleted()
    {
        return Property::onlyTrashed()
            ->where('owner_id', $this->getOwnerId())
            ->get();
    }
}