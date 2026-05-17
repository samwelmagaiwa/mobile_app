<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Village extends Model
{
    protected $fillable = ['ward_id', 'name'];

    public function ward()
    {
        return $this->belongsTo(Ward::class);
    }

    public function places()
    {
        return $this->hasMany(Place::class);
    }
}
