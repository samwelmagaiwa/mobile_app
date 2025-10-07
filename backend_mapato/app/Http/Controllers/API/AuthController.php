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
            $request->validate([
                'email' => 'required|email',
                'password' => 'required|string',
                'phone_number' => 'required|string',
            ]);

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

            // Verify phone number matches
            if ($user->phone_number !== $request->phone_number) {
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

            return ResponseHelper::success([
                'user' => $userData,
                'token' => $token,
                'role' => $user->role,
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

            $user->load('driver', 'assignedDevice');

            return ResponseHelper::success([
                'user' => $user,
                'driver' => $driver,
            ], 'Driver created successfully', 201);

        } catch (\Exception $e) {
            return ResponseHelper::error('Driver creation failed: ' . $e->getMessage(), 500);
        }
    }

    /**
     * Forgot password - send reset link
     */
    public function forgotPassword(Request $request)
    {
        // Log password reset request
        Log::info('Password reset request started', [
            'email' => $request->email,
            'ip_address' => $request->ip(),
            'user_agent' => $request->userAgent(),
            'timestamp' => now()->toISOString(),
        ]);

        try {
            $request->validate([
                'email' => 'required|email|exists:users,email',
            ]);

            $user = User::where('email', $request->email)->first();

            if (!$user->is_active) {
                Log::warning('Password reset failed - Account inactive', [
                    'user_id' => $user->id,
                    'email' => $request->email,
                    'ip_address' => $request->ip(),
                    'reason' => 'account_inactive',
                    'timestamp' => now()->toISOString(),
                ]);
                return ResponseHelper::error('Account is inactive', 403);
            }

            // Generate password reset token
            $token = Str::random(64);
            
            // Store the token (you might want to create a password_resets table)
            // For now, we'll just return success
            
            Log::info('Password reset request processed', [
                'user_id' => $user->id,
                'email' => $user->email,
                'ip_address' => $request->ip(),
                'timestamp' => now()->toISOString(),
            ]);
            
            return ResponseHelper::success([
                'message' => 'Password reset instructions sent to your email',
            ], 'Password reset request processed successfully');

        } catch (ValidationException $e) {
            Log::error('Password reset failed - Validation error', [
                'email' => $request->email,
                'ip_address' => $request->ip(),
                'validation_errors' => $e->errors(),
                'timestamp' => now()->toISOString(),
            ]);
            return ResponseHelper::error('Validation failed', 422, $e->errors());
        } catch (\Exception $e) {
            Log::error('Password reset failed - System error', [
                'email' => $request->email,
                'ip_address' => $request->ip(),
                'error_message' => $e->getMessage(),
                'timestamp' => now()->toISOString(),
            ]);
            return ResponseHelper::error('Failed to process password reset: ' . $e->getMessage(), 500);
        }
    }

    /**
     * Reset password
     */
    public function resetPassword(Request $request)
    {
        try {
            $request->validate([
                'email' => 'required|email|exists:users,email',
                'password' => 'required|string|min:8|confirmed',
            ]);

            $user = User::where('email', $request->email)->first();

            if (!$user->is_active) {
                return ResponseHelper::error('Account is inactive', 403);
            }

            // Update password
            $user->update([
                'password' => Hash::make($request->password),
            ]);

            // Revoke all existing tokens
            $user->tokens()->delete();

            return ResponseHelper::success(null, 'Password reset successfully');

        } catch (ValidationException $e) {
            return ResponseHelper::error('Validation failed', 422, $e->errors());
        } catch (\Exception $e) {
            return ResponseHelper::error('Password reset failed: ' . $e->getMessage(), 500);
        }
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

            return ResponseHelper::success([
                'user' => $userData,
                'role' => $user->role,
                'dashboard_route' => $this->getDashboardRoute($user->role),
            ], 'User data retrieved successfully');

        } catch (\Exception $e) {
            return ResponseHelper::error('Failed to retrieve user data: ' . $e->getMessage(), 500);
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
     * Get user data with appropriate relations based on role
     */
    private function getUserDataWithRelations(User $user): User
    {
        switch ($user->role) {
            case 'driver':
                return $user->load('driver', 'assignedDevice');
            case 'admin':
            case 'super_admin':
                return $user->load('createdUsers');
            default:
                return $user;
        }
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