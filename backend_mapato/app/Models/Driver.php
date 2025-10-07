<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use App\Traits\HasUuid;

class Driver extends Model
{
    use HasFactory, HasUuid;

    /**
     * The attributes that are mass assignable.
     */
    protected $fillable = [
        'user_id',
        'license_number',
        'license_expiry',
        'address',
        'emergency_contact',
        'is_active',
        'profile_image',
        'date_of_birth',
        'national_id',
    ];

    /**
     * The attributes that should be cast.
     */
    protected $casts = [
        'license_expiry' => 'date',
        'date_of_birth' => 'date',
        'is_active' => 'boolean',
    ];

    /**
     * Get the user that owns the driver profile.
     */
    public function user()
    {
        return $this->belongsTo(User::class);
    }

    /**
     * Get the devices for the driver.
     */
    public function devices()
    {
        return $this->hasMany(Device::class);
    }

    /**
     * Get the transactions for the driver.
     */
    public function transactions()
    {
        return $this->hasMany(Transaction::class);
    }

    /**
     * Get the reminders for the driver.
     */
    public function reminders()
    {
        return $this->hasMany(Reminder::class);
    }

    /**
     * Get active devices for the driver.
     */
    public function activeDevices()
    {
        return $this->devices()->where('is_active', true);
    }

    /**
     * Get completed transactions for the driver.
     */
    public function completedTransactions()
    {
        return $this->transactions()->where('status', 'completed');
    }

    /**
     * Get income transactions for the driver.
     */
    public function incomeTransactions()
    {
        return $this->transactions()->where('type', 'income')->where('status', 'completed');
    }

    /**
     * Get expense transactions for the driver.
     */
    public function expenseTransactions()
    {
        return $this->transactions()->where('type', 'expense')->where('status', 'completed');
    }

    /**
     * Calculate total revenue for the driver.
     */
    public function getTotalRevenueAttribute()
    {
        return $this->incomeTransactions()->sum('amount');
    }

    /**
     * Calculate total expenses for the driver.
     */
    public function getTotalExpensesAttribute()
    {
        return $this->expenseTransactions()->sum('amount');
    }

    /**
     * Calculate net profit for the driver.
     */
    public function getNetProfitAttribute()
    {
        return $this->total_revenue - $this->total_expenses;
    }

    /**
     * Check if license is expired or expiring soon.
     */
    public function isLicenseExpiringSoon($days = 30): bool
    {
        return $this->license_expiry && $this->license_expiry->diffInDays(now()) <= $days;
    }

    /**
     * Check if license is expired.
     */
    public function isLicenseExpired(): bool
    {
        return $this->license_expiry && $this->license_expiry->isPast();
    }

    /**
     * Scope to get active drivers.
     */
    public function scopeActive($query)
    {
        return $query->where('is_active', true);
    }

    /**
     * Scope to get drivers with expiring licenses.
     */
    public function scopeWithExpiringLicenses($query, $days = 30)
    {
        return $query->whereDate('license_expiry', '<=', now()->addDays($days));
    }
}