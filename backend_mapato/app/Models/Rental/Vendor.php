<?php

namespace App\Models\Rental;

use App\Models\User;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class Vendor extends Model
{
    use HasFactory, HasUuids;

    protected $table = 'rental_vendors';

    protected $fillable = [
        'user_id',
        'name',
        'business_name',
        'phone',
        'email',
        'specialty',
        'address',
        'is_active',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function workOrders()
    {
        return $this->hasMany(WorkOrder::class);
    }
}
