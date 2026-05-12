<?php

namespace App\Models\Rental;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use App\Traits\HasUuid;
use App\Models\User;

class RentalAgreement extends Model
{
    use HasFactory, HasUuid;

    protected $table = 'rental_agreements';

    protected $fillable = [
        'tenant_id',
        'house_id',
        'start_date',
        'end_date',
        'rent_cycle',
        'rent_amount',
        'deposit_paid',
        'status',
        'terms',
    ];

    protected $casts = [
        'start_date' => 'date',
        'end_date' => 'date',
    ];

    public function tenant()
    {
        return $this->belongsTo(User::class, 'tenant_id');
    }

    public function house()
    {
        return $this->belongsTo(House::class);
    }

    public function bills()
    {
        return $this->hasMany(RentBill::class, 'agreement_id');
    }
}
