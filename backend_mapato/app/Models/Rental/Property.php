<?php

namespace App\Models\Rental;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use App\Traits\HasUuid;
use App\Models\User;

class Property extends Model
{
    use HasFactory, HasUuid;

    protected $table = 'rental_properties';

    protected $fillable = [
        'owner_id',
        'name',
        'location',
        'address',
        'city',
        'description',
        'image_url',
    ];

    public function owner()
    {
        return $this->belongsTo(User::class, 'owner_id');
    }

    public function blocks()
    {
        return $this->hasMany(Block::class);
    }

    public function houses()
    {
        return $this->hasMany(House::class);
    }
}
