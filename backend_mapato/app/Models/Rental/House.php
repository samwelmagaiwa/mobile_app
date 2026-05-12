<?php

namespace App\Models\Rental;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use App\Traits\HasUuid;
use App\Models\User;

class House extends Model
{
    use HasFactory, HasUuid;

    protected $table = 'rental_houses';

    protected $fillable = [
        'property_id',
        'block_id',
        'house_number',
        'type',
        'rent_amount',
        'deposit_amount',
        'electricity_meter',
        'water_meter',
        'status',
        'current_tenant_id',
        'floor',
        'bedrooms',
        'bathrooms',
        'square_meters',
        'description',
    ];

    protected $casts = [
        'rent_amount' => 'decimal:2',
        'deposit_amount' => 'decimal:2',
        'bedrooms' => 'integer',
        'bathrooms' => 'integer',
        'square_meters' => 'integer',
    ];

    /**
     * House type options.
     */
    public static function houseTypes(): array
    {
        return [
            'apartment' => 'Apartment',
            'room' => 'Room',
            'commercial' => 'Commercial',
            'studio' => 'Studio',
            'bedroom' => 'Bedroom',
            'single_room' => 'Single Room',
            'bedsitter' => 'Bedsitter',
            'one_bedroom' => '1 Bedroom',
            'two_bedroom' => '2 Bedroom',
            'three_bedroom' => '3 Bedroom',
        ];
    }

    /**
     * Status options.
     */
    public static function statuses(): array
    {
        return [
            'vacant' => 'Vacant',
            'occupied' => 'Occupied',
            'maintenance' => 'Under Maintenance',
            'reserved' => 'Reserved',
        ];
    }

    public function property()
    {
        return $this->belongsTo(Property::class);
    }

    public function block()
    {
        return $this->belongsTo(Block::class);
    }

    public function currentTenant()
    {
        return $this->belongsTo(User::class, 'current_tenant_id');
    }

    public function agreements()
    {
        return $this->hasMany(RentalAgreement::class);
    }

    public function activeAgreement()
    {
        return $this->hasOne(RentalAgreement::class)->where('status', 'active');
    }

    public function bills()
    {
        return $this->hasManyThrough(RentBill::class, RentalAgreement::class);
    }

    public function payments()
    {
        return $this->hasManyThrough(RentalPayment::class, RentalAgreement::class);
    }

    /**
     * Check if house is vacant.
     */
    public function getIsVacantAttribute(): bool
    {
        return $this->status === 'vacant';
    }

    /**
     * Get display identifier.
     */
    public function getDisplayNameAttribute(): string
    {
        $parts = array_filter([
            $this->property?->name,
            $this->block?->name,
            $this->house_number,
        ]);
        return implode(' - ', $parts);
    }
}