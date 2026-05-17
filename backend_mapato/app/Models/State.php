<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class State extends Model
{
    protected $fillable = ['country_code', 'name'];

    public function lgas()
    {
        return $this->hasMany(Lga::class);
    }
}
