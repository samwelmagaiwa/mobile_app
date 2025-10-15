<?php

namespace App\Models;

use App\Traits\HasUuid;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class LoginActivity extends Model
{
    use HasFactory, HasUuid;

    protected $table = 'login_activities';

    protected $fillable = [
        'user_id',
        'ip_address',
        'user_agent',
        'login_at',
        'logout_at',
        'success',
        'location',
    ];

    protected $casts = [
        'login_at' => 'datetime',
        'logout_at' => 'datetime',
        'success' => 'boolean',
    ];
}