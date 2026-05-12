<?php

namespace App\Models\Rental;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use App\Traits\HasUuid;

class RentalReceipt extends Model
{
    use HasFactory, HasUuid;

    protected $table = 'rental_receipts';

    protected $fillable = [
        'payment_id',
        'receipt_number',
        'details',
    ];

    protected $casts = [
        'details' => 'array',
    ];

    public function payment()
    {
        return $this->belongsTo(RentalPayment::class, 'payment_id');
    }
}
