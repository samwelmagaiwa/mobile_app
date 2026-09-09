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
        'service_type',
        'full_access',
        'permissions',
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
        'full_access' => 'boolean',
        'permissions' => 'array',
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
        'super_admin'   => 'Super Admin',
        'admin'         => 'Admin',
        'manager'       => 'Manager',
        'sales_officer' => 'Sales Officer',
        'operator'      => 'Operator',
        'viewer'        => 'Viewer',
        'driver'        => 'Driver',
        'landlord'      => 'Landlord',
        'caretaker'     => 'Caretaker',
        'tenant'        => 'Tenant',
    ];

    /** All known inventory permission keys. Used to validate explicit grants. */
    const INV_PERMISSIONS = [
        'inv_view_products',   'inv_manage_products',
        'inv_manage_stock',    'inv_create_sales',
        'inv_manage_sales',    'inv_view_reminders',
        'inv_view_purchasing', 'inv_view_credit',
        'inv_view_cash',       'inv_view_crates',
        'inv_view_reports',    'inv_view_expenses',
        'inv_manage_expenses', 'inv_manage_settings',
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
     * Services this user is bound to (rental/transport/inventory). A user
     * can hold more than one - see user_services migration for why this
     * replaced the old single `service_type` column as the source of truth.
     */
    public function services()
    {
        return $this->hasMany(\App\Models\UserService::class);
    }

    /** Plain list of service_type strings this user is bound to. */
    public function serviceTypes(): array
    {
        return $this->services->pluck('service_type')->all();
    }



    // ── Inventory role defaults ──────────────────────────────────────────────
    // Mirrors UserPermissions._getPermissionsForRole() in Flutter so the
    // server-side and client-side checks are always in sync.
    private static array $INV_ROLE_DEFAULTS = [
        'super_admin'  => null, // null = unrestricted
        'admin'        => null,
        'administrator'=> null,
        'manager'      => [
            'inv_view_products','inv_manage_products','inv_manage_stock',
            'inv_create_sales','inv_manage_sales','inv_view_reminders',
            'inv_view_purchasing','inv_view_credit','inv_view_cash',
            'inv_view_crates','inv_view_reports','inv_view_expenses',
            'inv_manage_expenses',
        ],
        // Point-of-sale only -- deliberately excludes catalog management,
        // physical stock control, sales management/returns, purchasing,
        // reports, and the expense ledger. Mirrors the narrowed set in
        // UserPermissions._getPermissionsForRole() (Flutter), which was
        // scoped down from a broader default after an admin reported a
        // sales_officer account seeing near-admin-level quick menus.
        'sales_officer'=> [
            'inv_view_products','inv_create_sales','inv_view_reminders',
            'inv_view_credit','inv_view_cash','inv_view_crates',
        ],
        'operator'     => [
            'inv_view_products','inv_manage_products',
            'inv_create_sales','inv_view_reminders',
        ],
        'viewer'       => ['inv_view_products'],
    ];

    /**
     * Check whether this user has a given inventory permission.
     *
     * Resolution order:
     *  1. super_admin / admin / full_access → always yes
     *  2. Explicit per-user grant in users.permissions
     *  3. Role default set (INV_ROLE_DEFAULTS)
     */
    public function hasInventoryPermission(string $permission): bool
    {
        // Unrestricted roles
        $role = strtolower($this->role ?? '');
        if ($this->full_access || in_array($role, ['super_admin', 'admin', 'administrator'], true)) {
            return true;
        }

        // Explicit per-user grant
        $explicit = is_array($this->permissions) ? $this->permissions : [];
        if (in_array($permission, $explicit, true)) {
            return true;
        }

        // Role defaults
        $defaults = self::$INV_ROLE_DEFAULTS[$role] ?? [];
        if ($defaults === null) return true; // unrestricted role
        return in_array($permission, $defaults, true);
    }

    /**
     * Returns the merged effective inventory permission set for this user:
     * role defaults ∪ explicit grants. Used in the auth/user response so
     * the Flutter client always gets the resolved list.
     */
    public function effectiveInventoryPermissions(): array
    {
        $role = strtolower($this->role ?? '');
        if ($this->full_access || in_array($role, ['super_admin', 'admin', 'administrator'], true)) {
            // Sentinel for "unrestricted" -- the Flutter client strips this
            // value out and relies on isSuperAdmin/isAdmin/fullAccess
            // instead, so nothing here should return actual permission
            // strings for an unrestricted role (a prior version accidentally
            // returned the *role names* from INV_ROLE_DEFAULTS's keys via a
            // botched array union with ['__all__'], e.g. "manager",
            // "sales_officer" -- meaningless as permission strings, and the
            // union silently dropped the sentinel itself).
            return ['__all__'];
        }
        $defaults = self::$INV_ROLE_DEFAULTS[$role] ?? [];
        if ($defaults === null) return ['__all__'];
        $explicit = is_array($this->permissions) ? $this->permissions : [];
        return array_values(array_unique(array_merge($defaults, $explicit)));
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
     * Check if user is landlord
     */
    public function isLandlord(): bool
    {
        return $this->hasRole('landlord');
    }

    /**
     * Check if user is caretaker
     */
    public function isCaretaker(): bool
    {
        return $this->hasRole('caretaker');
    }

    /**
     * Check if user is tenant
     */
    public function isTenant(): bool
    {
        return $this->hasRole('tenant');
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
     * Get the profile associated with the user (alias for tenantProfile).
     */
    public function profile()
    {
        return $this->tenantProfile();
    }

    /**
     * Get the tenant profile associated with the user.
     */
    public function tenantProfile()
    {
        return $this->hasOne(\App\Models\Rental\TenantProfile::class, 'user_id');
    }

    /**
     * Get properties owned by the landlord.
     */
    public function ownedProperties()
    {
        return $this->hasMany(\App\Models\Rental\Property::class, 'owner_id');
    }

    /**
     * Get agreements for the tenant.
     */
    public function rentalAgreements()
    {
        return $this->hasMany(\App\Models\Rental\RentalAgreement::class, 'tenant_id');
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

    /**
     * Get the external service vendors saved to this user's (landlord) roster.
     */
    public function savedVendors()
    {
        return $this->belongsToMany(\App\Models\Rental\Vendor::class, 'landlord_vendor', 'landlord_id', 'vendor_id')->withTimestamps();
    }
}