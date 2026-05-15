<?php

namespace App\Models\Rental;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class PreventiveMaintenance extends Model
{
    use HasFactory, HasUuids;

    protected $table = 'rental_preventive_maintenance';

    protected $fillable = [
        'property_id',
        'house_id',
        'description',
        'frequency',
        'last_run',
        'next_run',
        'is_active',
    ];

    protected $casts = [
        'last_run' => 'date',
        'next_run' => 'date',
        'is_active' => 'boolean',
    ];

    public function property()
    {
        return $this->belongsTo(Property::class);
    }

    public function house()
    {
        return $this->belongsTo(House::class);
    }
}
