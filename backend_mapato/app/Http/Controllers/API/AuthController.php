<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Http\Requests\LoginRequest;
use App\Http\Requests\RegisterDriverRequest;
use App\Models\User;
use App\Models\Driver;
use App\Models\Device;
use App\Helpers\ResponseHelper;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Password;
use Illuminate\Validation\ValidationException;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

class AuthController extends Controller
{

    /**
     * Login with credentials (direct authentication)
     */
    public function login(Request $request)
    {
        // Log login attempt start
        Log::info('Login attempt started', [
            'email' => $request->email,
            'ip_address' => $request->ip(),
            'user_agent' => $request->userAgent(),
            'timestamp' => now()->toISOString(),
        ]);

        try {
            $request->validate(
                [
                    'email' => 'required|email',
                    'password' => 'required|string',
                    'phone_number' => ['required', 'regex:/^(0\d{9}|\+\d{9,15})$/'],
                ],
                [
                    'phone_number.required' => 'Namba ya simu inahitajika',
                    'phone_number.regex' => 'Namba ya simu si sahihi. Tumia namba ya ndani (mfano: 0743519100) au ya kimataifa (mfano: +255743519100).',
                ]
            );

            // Find user by email
            $user = User::where('email', $request->email)->first();

            if (!$user) {
                Log::warning('Login failed - User not found', [
                    'email' => $request->email,
                    'ip_address' => $request->ip(),
                    'user_agent' => $request->userAgent(),
                    'reason' => 'user_not_found',
                    'timestamp' => now()->toISOString(),
                ]);
                return ResponseHelper::error('Invalid credentials', 401);
            }

            // Verify password
            if (!Hash::check($request->password, $user->password)) {
                Log::warning('Login failed - Invalid password', [
                    'user_id' => $user->id,
                    'email' => $request->email,
                    'ip_address' => $request->ip(),
                    'user_agent' => $request->userAgent(),
                    'reason' => 'invalid_password',
                    'timestamp' => now()->toISOString(),
                ]);
                return ResponseHelper::error('Invalid credentials', 401);
            }

            // Check if user is active
            if (!$user->is_active) {
                Log::warning('Login failed - Account inactive', [
                    'user_id' => $user->id,
                    'email' => $request->email,
                    'ip_address' => $request->ip(),
                    'user_agent' => $request->userAgent(),
                    'reason' => 'account_inactive',
                    'timestamp' => now()->toISOString(),
                ]);
                return ResponseHelper::error('Account is inactive', 403);
            }

            // Verify phone number matches (comparing last 9 digits for maximum compatibility)
            if (!$this->phoneMatches($user, $request->phone_number)) {
                Log::warning('Login failed - Phone number mismatch', [
                    'user_id' => $user->id,
                    'email' => $request->email,
                    'provided_phone' => $request->phone_number,
                    'registered_phone' => $user->phone_number,
                    'ip_address' => $request->ip(),
                    'user_agent' => $request->userAgent(),
                    'reason' => 'phone_mismatch',
                    'timestamp' => now()->toISOString(),
                ]);
                return ResponseHelper::error('Phone number does not match our records', 400);
            }

            // Update last login
            $user->updateLastLogin();

            // Record login activity
            try {
                \App\Models\LoginActivity::create([
                    'user_id' => $user->id,
                    'ip_address' => $request->ip(),
                    'user_agent' => $request->userAgent(),
                    'login_at' => now(),
                    'success' => true,
                ]);
            } catch (\Exception $e) {
                Log::warning('Failed to record login activity', [
                    'user_id' => $user->id,
                    'error' => $e->getMessage(),
                ]);
            }

            // Revoke existing tokens
            $tokensRevoked = $user->tokens()->count();
            $user->tokens()->delete();

            // Create new token
            $token = $user->createToken('auth_token')->plainTextToken;

            // Load relationships based on role
            $userData = $this->getUserDataWithRelations($user);

            // Log successful login
            Log::info('Login successful', [
                'user_id' => $user->id,
                'email' => $user->email,
                'name' => $user->name,
                'role' => $user->role,
                'phone_number' => $user->phone_number,
                'ip_address' => $request->ip(),
                'user_agent' => $request->userAgent(),
                'tokens_revoked' => $tokensRevoked,
                'dashboard_route' => $this->getDashboardRoute($user->role),
                'last_login_at' => $user->last_login_at,
                'timestamp' => now()->toISOString(),
            ]);

            // Build UI badges and gating flags
            $badges = [];
            if (method_exists($user, 'isSuperAdmin') && $user->isSuperAdmin()) {
                $badges[] = 'Super Admin';
            }

            $can = [
                'manage_all' => method_exists($user, 'isSuperAdmin') ? $user->isSuperAdmin() : false,
                'create_users' => method_exists($user, 'canCreateUsers') ? $user->canCreateUsers() : false,
                'manage_drivers' => method_exists($user, 'canManageDrivers') ? $user->canManageDrivers() : false,
            ];

            return ResponseHelper::success([
                'user' => $userData,
                'token' => $token,
                'role' => $user->role,
                'role_display' => $user->role_display ?? $user->role,
                'badges' => $badges,
                'can' => $can,
                'dashboard_route' => $this->getDashboardRoute($user->role),
            ], 'Login successful');

        } catch (ValidationException $e) {
            Log::error('Login failed - Validation error', [
                'email' => $request->email,
                'ip_address' => $request->ip(),
                'user_agent' => $request->userAgent(),
                'validation_errors' => $e->errors(),
                'reason' => 'validation_failed',
                'timestamp' => now()->toISOString(),
            ]);
            return ResponseHelper::error('Validation failed', 422, $e->errors());
        } catch (\Exception $e) {
            Log::error('Login failed - System error', [
                'email' => $request->email,
                'ip_address' => $request->ip(),
                'user_agent' => $request->userAgent(),
                'error_message' => $e->getMessage(),
                'error_file' => $e->getFile(),
                'error_line' => $e->getLine(),
                'reason' => 'system_error',
                'timestamp' => now()->toISOString(),
            ]);
            return ResponseHelper::error('Login failed: ' . $e->getMessage(), 500);
        }
    }



    /**
     * Create driver account (Admin only)
     */
    public function createDriver(RegisterDriverRequest $request)
    {
        try {
            $admin = $request->user();

            // Check if user can create drivers
            if (!$admin->canManageDrivers()) {
                return ResponseHelper::error('Insufficient permissions', 403);
            }

            // Create user account
            $user = User::create([
                'name' => $request->name,
                'email' => $request->email,
                'password' => Hash::make($request->password),
                'phone_number' => $request->phone_number,
                'role' => 'driver',
                'created_by' => $admin->id,
                'device_id' => $request->device_id,
                'is_active' => true,
            ]);

            // Create driver profile
            $driver = Driver::create([
                'user_id' => $user->id,
                'license_number' => $request->license_number,
                'license_expiry' => $request->license_expiry,
                'address' => $request->address,
                'emergency_contact' => $request->emergency_contact,
                'national_id' => $request->national_id,
                'is_active' => true,
            ]);

            // Update device assignment if provided
            if ($request->device_id) {
                Device::where('id', $request->device_id)->update(['driver_id' => $driver->id]);
            }

            // Bind driver to transport service so they only see that module on login
            $user->services()->delete();
            $user->services()->create(['service_type' => 'transport']);

            $user->load('driver', 'assignedDevice', 'services');

            return ResponseHelper::success([
                'user' => $user,
                'driver' => $driver,
            ], 'Driver created successfully', 201);

        } catch (\Exception $e) {
            return ResponseHelper::error('Driver creation failed: ' . $e->getMessage(), 500);
        }
    }

    /**
     * Step 1 of password recovery -- verify the account by the SAME two
     * factors login itself uses (email + registered phone number), then
     * issue a short-lived, single-use reset token.
     *
     * Deliberately returns the identical generic error whether the email
     * doesn't exist, the account is inactive, or the phone doesn't match --
     * never reveals which one failed, so this can't be used to enumerate
     * registered emails or phone numbers. Rate-limited via the `throttle`
     * middleware on the route for the same reason.
     */
    public function forgotPassword(Request $request)
    {
        Log::info('Password reset verification started', [
            'email' => $request->email,
            'ip_address' => $request->ip(),
            'user_agent' => $request->userAgent(),
            'timestamp' => now()->toISOString(),
        ]);

        try {
            $request->validate(
                [
                    'email' => 'required|email',
                    'phone_number' => ['required', 'regex:/^(0\d{9}|\+\d{9,15})$/'],
                ],
                [
                    'phone_number.required' => 'Namba ya simu inahitajika',
                    'phone_number.regex' => 'Namba ya simu si sahihi. Tumia namba ya ndani (mfano: 0743519100) au ya kimataifa (mfano: +255743519100).',
                ]
            );

            $user = User::where('email', $request->email)->first();
            $genericError = 'Barua pepe na namba ya simu havikubaliani na taarifa tulizonazo.';

            if (!$user || !$user->is_active || !$this->phoneMatches($user, $request->phone_number)) {
                Log::warning('Password reset verification failed', [
                    'email' => $request->email,
                    'ip_address' => $request->ip(),
                    'reason' => !$user ? 'user_not_found' : (!$user->is_active ? 'account_inactive' : 'phone_mismatch'),
                    'timestamp' => now()->toISOString(),
                ]);
                return ResponseHelper::error($genericError, 422);
            }

            // Clear out any earlier unused tokens for this user so only the
            // token just issued is valid -- a stale one from an abandoned
            // reset attempt can't be replayed later.
            DB::table('password_reset_codes')->where('user_id', $user->id)->delete();

            $rawToken = Str::random(64);
            DB::table('password_reset_codes')->insert([
                'user_id' => $user->id,
                'token_hash' => hash('sha256', $rawToken),
                'expires_at' => now()->addMinutes(10),
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            Log::info('Password reset token issued', [
                'user_id' => $user->id,
                'email' => $user->email,
                'ip_address' => $request->ip(),
                'timestamp' => now()->toISOString(),
            ]);

            return ResponseHelper::success([
                'reset_token' => $rawToken,
                'expires_in_minutes' => 10,
            ], 'Identity verified. Choose a new password within 10 minutes.');
        } catch (ValidationException $e) {
            return ResponseHelper::error('Validation failed', 422, $e->errors());
        } catch (\Exception $e) {
            Log::error('Password reset verification - system error', [
                'email' => $request->email,
                'ip_address' => $request->ip(),
                'error_message' => $e->getMessage(),
                'timestamp' => now()->toISOString(),
            ]);
            return ResponseHelper::error('Failed to process password reset request', 500);
        }
    }

    /**
     * Step 2 -- spend the token issued by forgotPassword() to actually set
     * a new password. Every existing session is revoked afterwards so a
     * device that had the old, possibly-compromised password stays logged
     * out until it authenticates with the new one.
     */
    public function resetPassword(Request $request)
    {
        try {
            $request->validate([
                'email' => 'required|email',
                'reset_token' => 'required|string',
                'password' => 'required|string|min:8|confirmed',
            ]);

            $user = User::where('email', $request->email)->first();
            $genericError = 'Muda wa kubadili nywila umekwisha au ombi si sahihi. Anza upya.';

            if (!$user) {
                return ResponseHelper::error($genericError, 422);
            }

            $tokenHash = hash('sha256', $request->reset_token);
            $tokenRow = DB::table('password_reset_codes')
                ->where('user_id', $user->id)
                ->where('token_hash', $tokenHash)
                ->whereNull('used_at')
                ->where('expires_at', '>', now())
                ->orderByDesc('id')
                ->first();

            if (!$tokenRow) {
                Log::warning('Password reset failed - invalid or expired token', [
                    'user_id' => $user->id,
                    'email' => $request->email,
                    'ip_address' => $request->ip(),
                    'timestamp' => now()->toISOString(),
                ]);
                return ResponseHelper::error($genericError, 422);
            }

            $user->update(['password' => Hash::make($request->password)]);

            DB::table('password_reset_codes')->where('id', $tokenRow->id)->update([
                'used_at' => now(),
                'updated_at' => now(),
            ]);

            // Force every device to sign in again with the new password.
            $user->tokens()->delete();

            Log::info('Password reset completed', [
                'user_id' => $user->id,
                'email' => $user->email,
                'ip_address' => $request->ip(),
                'timestamp' => now()->toISOString(),
            ]);

            return ResponseHelper::success(null, 'Password reset successfully');
        } catch (ValidationException $e) {
            return ResponseHelper::error('Validation failed', 422, $e->errors());
        } catch (\Exception $e) {
            Log::error('Password reset - system error', [
                'email' => $request->email,
                'ip_address' => $request->ip(),
                'error_message' => $e->getMessage(),
                'timestamp' => now()->toISOString(),
            ]);
            return ResponseHelper::error('Failed to reset password', 500);
        }
    }

    /**
     * Same last-9-digit comparison used everywhere a login-time phone check
     * happens, so login() and forgotPassword() can never silently drift
     * apart on what counts as a match.
     */
    private function phoneMatches(User $user, string $providedPhone): bool
    {
        $normalize = fn (string $number): string => preg_replace('/[^0-9]/', '', $number);

        return substr($normalize($user->phone_number ?? ''), -9)
            === substr($normalize($providedPhone), -9);
    }

    /**
     * Logout user
     */
    public function logout(Request $request)
    {
        try {
            $user = $request->user();
            
            // Log logout attempt
            Log::info('Logout attempt', [
                'user_id' => $user->id,
                'email' => $user->email,
                'name' => $user->name,
                'role' => $user->role,
                'ip_address' => $request->ip(),
                'user_agent' => $request->userAgent(),
                'timestamp' => now()->toISOString(),
            ]);
            
            $request->user()->currentAccessToken()->delete();

            // Record logout time on latest login activity
            try {
                $last = \App\Models\LoginActivity::where('user_id', $user->id)
                    ->orderByDesc('login_at')
                    ->first();
                if ($last && !$last->logout_at) {
                    $last->logout_at = now();
                    $last->save();
                }
            } catch (\Exception $e) {
                Log::warning('Failed to record logout activity', [
                    'user_id' => $user->id,
                    'error' => $e->getMessage(),
                ]);
            }

            // Log successful logout
            Log::info('Logout successful', [
                'user_id' => $user->id,
                'email' => $user->email,
                'ip_address' => $request->ip(),
                'timestamp' => now()->toISOString(),
            ]);

            return ResponseHelper::success(null, 'Logged out successfully');
        } catch (\Exception $e) {
            Log::error('Logout failed', [
                'user_id' => $request->user()?->id,
                'email' => $request->user()?->email,
                'ip_address' => $request->ip(),
                'error_message' => $e->getMessage(),
                'timestamp' => now()->toISOString(),
            ]);
            return ResponseHelper::error('Logout failed: ' . $e->getMessage(), 500);
        }
    }

    /**
     * Get authenticated user
     */
    public function user(Request $request)
    {
        try {
            $user = $request->user();
            $userData = $this->getUserDataWithRelations($user);

            // Build UI badges and gating flags
            $badges = [];
            if (method_exists($user, 'isSuperAdmin') && $user->isSuperAdmin()) {
                $badges[] = 'Super Admin';
            }

            $can = [
                'manage_all' => method_exists($user, 'isSuperAdmin') ? $user->isSuperAdmin() : false,
                'create_users' => method_exists($user, 'canCreateUsers') ? $user->canCreateUsers() : false,
                'manage_drivers' => method_exists($user, 'canManageDrivers') ? $user->canManageDrivers() : false,
            ];

            return ResponseHelper::success([
                'user' => $userData,
                'role' => $user->role,
                'role_display' => $user->role_display ?? $user->role,
                'badges' => $badges,
                'can' => $can,
                'dashboard_route' => $this->getDashboardRoute($user->role),
            ], 'User data retrieved successfully');

        } catch (\Exception $e) {
            return ResponseHelper::error('Failed to retrieve user data: ' . $e->getMessage(), 500);
        }
    }

    /**
     * Upload or update user avatar/profile photo
     */
    public function uploadAvatar(Request $request)
    {
        try {
            $user = $request->user();

            // Accept any of these field names from clients
            $file = $request->file('avatar') ?? $request->file('photo') ?? $request->file('image');
            if (!$file) {
                return ResponseHelper::error('No image file provided', 422);
            }

            // Basic validation: ensure upload is valid and size is reasonable (~2MB)
            if (!$file->isValid()) {
                return ResponseHelper::error('Invalid image upload', 422);
            }
            if (($file->getSize() ?? 0) > 2 * 1024 * 1024) {
                return ResponseHelper::error('Image too large (max 2MB)', 422);
            }

            $ext = strtolower($file->getClientOriginalExtension() ?: 'jpg');
            if (!in_array($ext, ['jpg','jpeg','png','webp'])) {
                $ext = 'jpg';
            }

            // Remove previous avatar if exists
            if (!empty($user->avatar_url)) {
                $oldPath = str_replace('/storage/', '', $user->avatar_url);
                if ($oldPath) {
                    Storage::disk('public')->delete($oldPath);
                }
            }

            // Store new avatar on public disk
            $path = $file->storeAs('avatars', $user->id.'_'.time().'.'.$ext, 'public');
            $publicUrl = '/storage/'.$path;

            // Persist path on user (requires nullable column `avatar_url`)
            if (Schema::hasColumn('users', 'avatar_url')) {
                $user->avatar_url = $publicUrl;
                $user->save();
            }

            $fresh = $this->getUserDataWithRelations($user->fresh());
            // Ensure avatar_url is present in response even if column is missing
            $fresh->setAttribute('avatar_url', $publicUrl);

            return ResponseHelper::success([
                'user' => $fresh,
            ], 'Avatar updated successfully');
        } catch (\Exception $e) {
            return ResponseHelper::error('Failed to upload avatar: '.$e->getMessage(), 500);
        }
    }

    /**
     * Refresh token
     */
    public function refresh(Request $request)
    {
        try {
            $user = $request->user();
            
            // Revoke current token
            $request->user()->currentAccessToken()->delete();
            
            // Create new token
            $token = $user->createToken('auth_token')->plainTextToken;

            return ResponseHelper::success([
                'token' => $token,
            ], 'Token refreshed successfully');

        } catch (\Exception $e) {
            return ResponseHelper::error('Token refresh failed: ' . $e->getMessage(), 500);
        }
    }

    /**
     * Get user data with appropriate relations based on role.
     * Always appends effective_permissions so the client has the fully
     * resolved list (role defaults ∪ explicit grants) without a second call.
     */
    private function getUserDataWithRelations(User $user): User
    {
        $user->load('services');

        // super_admin always has access to all services regardless of what is
        // stored in user_services — ensure the response reflects this so the
        // Flutter client shows the correct service selection options.
        if ($user->isSuperAdmin() || $user->full_access) {
            $allServices = ['inventory', 'rental', 'transport'];
            $existingTypes = $user->services->pluck('service_type')->all();
            $missing = array_diff($allServices, $existingTypes);
            if (!empty($missing)) {
                foreach ($missing as $serviceType) {
                    \App\Models\UserService::firstOrCreate([
                        'user_id'      => $user->id,
                        'service_type' => $serviceType,
                    ]);
                }
                $user->load('services'); // reload with the newly added rows
            }
        }

        switch ($user->role) {
            case 'driver':
                $user->load('driver', 'assignedDevice');
                break;
            case 'landlord':
                $user->load('ownedProperties');
                break;
            case 'tenant':
                $user->load('tenantProfile', 'rentalAgreements.house.property');
                break;
        }

        // Append resolved permission set as a virtual attribute so the app
        // knows the full effective access without calling a separate endpoint.
        $user->setAttribute('effective_permissions', $user->effectiveInventoryPermissions());

        return $user;
    }

    /**
     * Return the authenticated user's service bindings.
     *
     * Lightweight alternative to /user when the app only needs to know which
     * services the user can access (e.g. on the service selection screen).
     * super_admin always gets all three services; everyone else gets their
     * explicit bindings from the user_services table.
     */
    public function myServices(Request $request): \Illuminate\Http\JsonResponse
    {
        $user = $request->user();

        if (!$user) {
            return response()->json(['message' => 'Unauthenticated.'], 401);
        }

        $role = strtolower($user->role ?? '');

        // super_admin is unrestricted — return all services without a DB lookup.
        if ($user->full_access || $role === 'super_admin') {
            return response()->json([
                'services'    => ['inventory', 'rental', 'transport'],
                'is_unbound'  => false,
                'role'        => $user->role,
            ]);
        }

        $bound = $user->services()->pluck('service_type')->all();

        return response()->json([
            'services'    => $bound,
            'is_unbound'  => empty($bound),
            'role'        => $user->role,
            // Hint to the client: if is_unbound is true, display the
            // "no service access" screen and offer a logout button.
            'message'     => empty($bound)
                ? 'No services assigned. Contact your administrator.'
                : null,
        ]);
    }

    /**
     * Get dashboard route based on user role
     */
    private function getDashboardRoute(string $role): string
    {
        switch ($role) {
            case 'super_admin':
                return '/super-admin/dashboard';
            case 'admin':
                return '/admin/dashboard';
            case 'landlord':
                return '/landlord/dashboard';
            case 'tenant':
                return '/tenant/dashboard';
            case 'driver':
                return '/driver/dashboard';
            default:
                return '/dashboard';
        }
    }

    /**
     * Get all drivers (Admin only)
     */
    public function getDrivers(Request $request)
    {
        try {
            $admin = $request->user();

            if (!$admin->canManageDrivers()) {
                return ResponseHelper::error('Insufficient permissions', 403);
            }

            $drivers = User::drivers()
                          ->with('driver', 'assignedDevice')
                          ->paginate(15);

            return ResponseHelper::success($drivers, 'Drivers retrieved successfully');

        } catch (\Exception $e) {
            return ResponseHelper::error('Failed to retrieve drivers: ' . $e->getMessage(), 500);
        }
    }

    /**
     * Assign device to driver (Admin only)
     */
    public function assignDevice(Request $request)
    {
        try {
            $request->validate([
                'driver_id' => 'required|uuid|exists:users,id',
                'device_id' => 'required|uuid|exists:devices,id',
            ]);

            $admin = $request->user();

            if (!$admin->canManageDrivers()) {
                return ResponseHelper::error('Insufficient permissions', 403);
            }

            $driver = User::drivers()->findOrFail($request->driver_id);
            $device = Device::findOrFail($request->device_id);

            // Update user's assigned device
            $driver->update(['device_id' => $request->device_id]);

            // Update device's driver
            $device->update(['driver_id' => $driver->driver->id]);

            return ResponseHelper::success([
                'driver' => $driver->load('assignedDevice'),
                'device' => $device,
            ], 'Device assigned successfully');

        } catch (\Exception $e) {
            return ResponseHelper::error('Device assignment failed: ' . $e->getMessage(), 500);
        }
    }
}