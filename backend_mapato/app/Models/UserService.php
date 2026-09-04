<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

/** One row = one service a user is bound to. See user_services migration. */
class UserService extends Model
{
    protected $fillable = [
        'user_id',
        'service_type',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
