<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\LoginActivity;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;
use Illuminate\Validation\ValidationException;

class SecurityController extends Controller
{
    /**
     * Change the authenticated user's password
     */
    public function changePassword(Request $request)
    {
        try {
            $request->validate([
                'current_password' => 'required|string',
                'new_password' => 'required|string|min:6',
            ]);

            $user = $request->user();

            if (!Hash::check($request->current_password, $user->password)) {
                return response()->json([
                    'success' => false,
                    'message' => 'Current password is incorrect',
                ], 422);
            }

            $user->password = Hash::make($request->new_password);
            $user->save();

            // Revoke all existing tokens (force re-login on all devices)
            try {
                $user->tokens()->delete();
            } catch (\Exception $e) {
                Log::warning('Failed revoking tokens after password change', [
                    'user_id' => $user->id,
                    'error' => $e->getMessage(),
                ]);
            }

            Log::info('Password changed successfully', [
                'user_id' => $user->id,
                'ip_address' => $request->ip(),
                'timestamp' => now()->toISOString(),
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Password changed successfully',
                'force_logout' => true,
            ]);
        } catch (ValidationException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $e->errors(),
            ], 422);
        } catch (\Exception $e) {
            Log::error('Password change failed', [
                'user_id' => $request->user()?->id,
                'error' => $e->getMessage(),
            ]);
            return response()->json([
                'success' => false,
                'message' => 'Failed to change password: ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Get current security settings for the authenticated user
     */
    public function getSecuritySettings(Request $request)
    {
        $user = $request->user();
        return response()->json([
            'success' => true,
            'message' => 'Security settings retrieved',
            'data' => [
                'two_factor_enabled' => (bool)($user->two_factor_enabled ?? false),
                'last_login_at' => $user->last_login_at,
            ],
        ]);
    }

    /**
     * Enable/disable two factor authentication (simple toggle)
     */
    public function setTwoFactor(Request $request)
    {
        try {
            $request->validate([
                'enabled' => 'required|boolean',
            ]);
            $user = $request->user();
            $user->two_factor_enabled = (bool)$request->enabled;
            // In a real 2FA flow, you would generate and verify a secret.
            if (!$user->two_factor_enabled) {
                $user->two_factor_secret = null;
                $user->two_factor_confirmed_at = null;
            }
            $user->save();

            return response()->json([
                'success' => true,
                'message' => 'Two-factor setting updated',
                'data' => [
                    'two_factor_enabled' => (bool)$user->two_factor_enabled,
                ],
            ]);
        } catch (ValidationException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $e->errors(),
            ], 422);
        } catch (\Exception $e) {
            Log::error('Updating 2FA failed', [
                'user_id' => $request->user()?->id,
                'error' => $e->getMessage(),
            ]);
            return response()->json([
                'success' => false,
                'message' => 'Failed to update two-factor setting',
            ], 500);
        }
    }

    /**
     * Get login history for the authenticated user
     */
    public function getLoginHistory(Request $request)
    {
        $user = $request->user();
        $page = (int)($request->get('page', 1));
        $limit = (int)($request->get('limit', 20));
        $query = LoginActivity::where('user_id', $user->id)
            ->orderByDesc('login_at');
        $paginator = $query->paginate($limit, ['*'], 'page', $page);
        return response()->json([
            'success' => true,
            'message' => 'Login history retrieved',
            'data' => $paginator->items(),
            'pagination' => [
                'current_page' => $paginator->currentPage(),
                'last_page' => $paginator->lastPage(),
                'per_page' => $paginator->perPage(),
                'total' => $paginator->total(),
                'from' => $paginator->firstItem(),
                'to' => $paginator->lastItem(),
                'has_more_pages' => $paginator->hasMorePages(),
            ],
        ]);
    }
}