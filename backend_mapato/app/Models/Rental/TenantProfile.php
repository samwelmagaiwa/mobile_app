<?php

namespace App\Models\Rental;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use App\Traits\HasUuid;
use App\Models\User;

class TenantProfile extends Model
{
    use HasFactory, HasUuid;

    protected $table = 'rental_tenant_profiles';

    protected $fillable = [
        'user_id',
        'gender',
        'dob',
        'id_number',
        'id_state',
        'id_expiration',
        'occupation',
        'emergency_contact_name',
        'emergency_contact_phone',
        'employment',
        'history',
        'occupants',
        'pets',
        'photo_url',
        'contract_url',
        'notes',
    ];

    protected $casts = [
        'dob' => 'date',
        'id_expiration' => 'date',
        'employment' => 'array',
        'history' => 'array',
        'occupants' => 'array',
        'pets' => 'array',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
