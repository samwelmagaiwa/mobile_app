<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;
use App\Traits\HasUuid;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable, HasUuid;

    /**
     * The attributes that are mass assignable.
     */
    protected $fillable = [
        'name',
        'email',
        'password',
        'phone_number',
        'role',
        'created_by',
        'device_id',
        'is_active',
        'email_verified',
'phone_verified',
        'avatar_url',
        'email_verified_at',
        'last_login_at',
        'two_factor_enabled',
        'two_factor_secret',
        'two_factor_confirmed_at',
    ];

    /**
     * The attributes that should be hidden for serialization.
     */
    protected $hidden = [
        'password',
        'remember_token',
    ];

    /**
     * The attributes that should be cast.
     */
    protected $casts = [
        'email_verified_at' => 'datetime',
        'last_login_at' => 'datetime',
        'two_factor_confirmed_at' => 'datetime',
        'password' => 'hashed',
        'is_active' => 'boolean',
        'email_verified' => 'boolean',
        'phone_verified' => 'boolean',
        'two_factor_enabled' => 'boolean',
    ];

    /**
     * Get the driver profile associated with the user.
     */
    public function driver()
    {
        return $this->hasOne(Driver::class);
    }

    /**
     * Check if user has a driver profile
     */
    public function hasDriverProfile(): bool
    {
        return $this->driver()->exists();
    }

    /**
     * Check if user is an active driver
     */
    public function isActiveDriver(): bool
    {
        return $this->hasDriverProfile() && $this->driver->is_active;
    }

    /**
     * User roles
     */
    const ROLES = [
        'super_admin' => 'Super Admin',
        'admin' => 'Admin',
        'driver' => 'Driver',
    ];

    /**
     * Get the user who created this user
     */
    public function creator()
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    /**
     * Get users created by this user
     */
    public function createdUsers()
    {
        return $this->hasMany(User::class, 'created_by');
    }

    /**
     * Get the device assigned to this user
     */
    public function assignedDevice()
    {
        return $this->belongsTo(Device::class, 'device_id');
    }



    /**
     * Check if user has specific role
     */
    public function hasRole(string $role): bool
    {
        return $this->role === $role;
    }

    /**
     * Check if user is super admin
     */
    public function isSuperAdmin(): bool
    {
        return $this->hasRole('super_admin');
    }

    /**
     * Check if user is admin
     */
    public function isAdmin(): bool
    {
        return $this->hasRole('admin');
    }

    /**
     * Check if user is driver
     */
    public function isDriver(): bool
    {
        return $this->hasRole('driver');
    }

    /**
     * Check if user can create other users
     */
    public function canCreateUsers(): bool
    {
        return $this->isSuperAdmin() || $this->isAdmin();
    }

    /**
     * Check if user can manage drivers
     */
    public function canManageDrivers(): bool
    {
        return $this->isSuperAdmin() || $this->isAdmin();
    }

    /**
     * Get role display name
     */
    public function getRoleDisplayAttribute(): string
    {
        return self::ROLES[$this->role] ?? $this->role;
    }

    /**
     * Update last login timestamp
     */
    public function updateLastLogin(): void
    {
        $this->update(['last_login_at' => now()]);
    }

    /**
     * Scope to get users by role
     */
    public function scopeByRole($query, string $role)
    {
        return $query->where('role', $role);
    }

    /**
     * Scope to get active users
     */
    public function scopeActive($query)
    {
        return $query->where('is_active', true);
    }

    /**
     * Scope to get drivers
     */
    public function scopeDrivers($query)
    {
        return $query->byRole('driver');
    }

    /**
     * Scope to get admins
     */
    public function scopeAdmins($query)
    {
        return $query->whereIn('role', ['super_admin', 'admin']);
    }
}