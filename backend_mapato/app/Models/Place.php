<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Place extends Model
{
    protected $fillable = ['village_id', 'name'];

    public function village()
    {
        return $this->belongsTo(Village::class);
    }
}
