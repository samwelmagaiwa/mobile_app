<?php

namespace App\Models\Rental;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use App\Traits\HasUuid;
use App\Models\User;

class Property extends Model
{
    use HasFactory, HasUuid, SoftDeletes;

    protected $table = 'rental_properties';

    protected $fillable = [
        'owner_id',
        'caretaker_id',
        'name',
        'property_type',
        'location',
        'address',
        'region',
        'district',
        'ward',
        'street',
        'city',
        'description',
        'ownership_notes',
        'number_of_blocks',
        'total_units',
        'default_billing_cycle',
        'default_currency',
        'status',
        'default_rent_amount',
        'default_deposit_amount',
        'utility_billing_enabled',
        'latitude',
        'longitude',
        'image_url',
    ];

    protected $casts = [
        'number_of_blocks' => 'integer',
        'total_units' => 'integer',
        'default_rent_amount' => 'decimal:2',
        'default_deposit_amount' => 'decimal:2',
        'utility_billing_enabled' => 'boolean',
        'latitude' => 'decimal:8',
        'longitude' => 'decimal:8',
    ];

    /**
     * Property type options for dropdowns.
     */
    public static function propertyTypes(): array
    {
        return [
            'apartment' => 'Apartment',
            'rental_compound' => 'Rental Compound',
            'standalone_house' => 'Standalone House',
            'hostel' => 'Hostel',
            'commercial_building' => 'Commercial Building',
            'mixed_use' => 'Mixed Use Building',
            'office_space' => 'Office Space',
            'shop_units' => 'Shop Units',
        ];
    }

    /**
     * Billing cycle options.
     */
    public static function billingCycles(): array
    {
        return [
            'monthly' => 'Monthly',
            'quarterly' => 'Quarterly',
            'yearly' => 'Yearly',
        ];
    }

    /**
     * Status options.
     */
    public static function statuses(): array
    {
        return [
            'active' => 'Active',
            'inactive' => 'Inactive',
            'under_maintenance' => 'Under Maintenance',
            'archived' => 'Archived',
        ];
    }

    public function owner()
    {
        return $this->belongsTo(User::class, 'owner_id');
    }

    public function caretaker()
    {
        return $this->belongsTo(User::class, 'caretaker_id');
    }

    public function blocks()
    {
        return $this->hasMany(Block::class);
    }

    public function houses()
    {
        return $this->hasMany(House::class);
    }

    /**
     * Get full address.
     */
    public function getFullAddressAttribute(): string
    {
        $parts = array_filter([
            $this->street,
            $this->ward,
            $this->district,
            $this->region,
        ]);
        return implode(', ', $parts);
    }

    /**
     * Get occupied units count.
     */
    public function getOccupiedUnitsCountAttribute(): int
    {
        return $this->houses()->where('status', 'occupied')->count();
    }

    /**
     * Get vacant units count.
     */
    public function getVacantUnitsCountAttribute(): int
    {
        $total = $this->houses()->count();
        return $total - $this->occupied_units_count;
    }

    /**
     * Get occupancy rate.
     */
    public function getOccupancyRateAttribute(): float
    {
        $total = $this->houses()->count();
        if ($total == 0) return 0;
        return round(($this->occupied_units_count / $total) * 100, 1);
    }

    /**
     * Get total revenue collected for this property.
     */
    public function getTotalRevenueAttribute(): float
    {
        return RentalPayment::whereHas('bill.agreement.house', function ($q) {
            $q->where('property_id', $this->id);
        })->sum('amount_paid');
    }

    /**
     * Get recent payments for this property.
     */
    public function recentPayments(int $limit = 5)
    {
        return RentalPayment::with(['tenant', 'bill.agreement.house'])
            ->whereHas('bill.agreement.house', function ($q) {
                $q->where('property_id', $this->id);
            })
            ->orderBy('payment_date', 'desc')
            ->limit($limit)
            ->get();
    }
}