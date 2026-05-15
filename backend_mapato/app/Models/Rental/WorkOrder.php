<?php

namespace App\Models\Rental;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class WorkOrder extends Model
{
    use HasFactory, HasUuids;

    protected $table = 'rental_work_orders';

    protected $fillable = [
        'maintenance_request_id',
        'vendor_id',
        'title',
        'instructions',
        'estimated_cost',
        'actual_cost',
        'status',
        'scheduled_date',
        'completion_date',
    ];

    protected $casts = [
        'scheduled_date' => 'date',
        'completion_date' => 'date',
    ];

    public function maintenanceRequest()
    {
        return $this->belongsTo(MaintenanceRequest::class);
    }

    public function vendor()
    {
        return $this->belongsTo(Vendor::class);
    }
}
