<?php

namespace App\Models\Rental;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use App\Traits\HasUuid;

class Block extends Model
{
    use HasFactory, HasUuid;

    protected $table = 'rental_blocks';

    protected $fillable = [
        'property_id',
        'name',
        'description',
    ];

    public function property()
    {
        return $this->belongsTo(Property::class);
    }

    public function houses()
    {
        return $this->hasMany(House::class);
    }
}
