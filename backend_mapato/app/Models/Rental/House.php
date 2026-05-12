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
    ];

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
}
