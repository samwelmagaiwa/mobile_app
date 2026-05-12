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
        'id_number',
        'occupation',
        'emergency_contact_name',
        'emergency_contact_phone',
        'photo_url',
        'contract_url',
        'notes',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
