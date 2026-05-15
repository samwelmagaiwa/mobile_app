<?php

namespace App\Models\Rental;

use App\Models\User;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class MaintenanceRequest extends Model
{
    use HasFactory, HasUuids;

    protected $table = 'rental_maintenance_requests';

    protected $fillable = [
        'property_id',
        'house_id',
        'tenant_id',
        'category',
        'priority',
        'description',
        'photo_url',
        'status',
        'resolved_at',
    ];

    protected $casts = [
        'resolved_at' => 'datetime',
    ];

    public function property()
    {
        return $this->belongsTo(Property::class);
    }

    public function house()
    {
        return $this->belongsTo(House::class);
    }

    public function tenant()
    {
        return $this->belongsTo(User::class, 'tenant_id');
    }

    public function workOrder()
    {
        return $this->hasOne(WorkOrder::class);
    }
}
