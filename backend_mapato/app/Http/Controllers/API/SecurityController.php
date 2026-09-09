<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\LoginActivity;
use App\Services\Inventory\AuditTrail;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;
use Illuminate\Validation\Rules\Password;
use Illuminate\Validation\ValidationException;

class SecurityController extends Controller
{
    public function __construct(private readonly AuditTrail $audit) {}

    /**
     * POST /auth/change-password
     *
     * Hardening:
     *  - Minimum 8 chars (Password::min(8)) — rejects the app's weak default if user hasn't changed it.
     *  - New password must not be the same as the current one.
     *  - Wrong current password returns 422 (not 401) so the client shows
     *    inline field error, not a session-expired redirect.
     *  - All existing tokens are revoked after a successful change so every
     *    other device is forced to re-authenticate with the new password.
     *  - Action is audit-logged (security-critical event).
     */
    public function changePassword(Request $request)
    {
        try {
            $validated = $request->validate([
                'current_password' => 'required|string',
                'new_password'     => ['required', 'confirmed', Password::min(8)],
            ]);

            $user = $request->user();

            if (!Hash::check($validated['current_password'], $user->password)) {
                return response()->json([
                    'success' => false,
                    'message' => 'Current password is incorrect.',
                    'errors'  => ['current_password' => ['The current password you entered is wrong.']],
                ], 422);
            }

            // Reject a no-op change — same password re-submitted.
            if (Hash::check($validated['new_password'], $user->password)) {
                return response()->json([
                    'success' => false,
                    'message' => 'New password must be different from the current password.',
                    'errors'  => ['new_password' => ['Choose a different password.']],
                ], 422);
            }

            $user->password = Hash::make($validated['new_password']);
            $user->save();

            // Revoke every token so all other devices must re-login.
            try {
                $user->tokens()->delete();
            } catch (\Exception $e) {
                Log::warning('Failed revoking tokens after password change', [
                    'user_id' => $user->id,
                    'error'   => $e->getMessage(),
                ]);
            }

            $this->audit->record(
                $request, 'security', null, 'password_changed', null, null,
                "{$user->name} changed their password — all sessions revoked",
            );

            Log::info('Password changed', [
                'user_id'    => $user->id,
                'ip_address' => $request->ip(),
                'at'         => now()->toISOString(),
            ]);

            return response()->json([
                'success'      => true,
                'message'      => 'Password changed successfully. Please log in again.',
                'force_logout' => true,
            ]);
        } catch (ValidationException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed.',
                'errors'  => $e->errors(),
            ], 422);
        } catch (\Exception $e) {
            Log::error('Password change failed', [
                'user_id' => $request->user()?->id,
                'error'   => $e->getMessage(),
            ]);
            return response()->json([
                'success' => false,
                'message' => 'Failed to change password. Please try again.',
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
     * POST /auth/two-factor
     * Enable or disable two-factor authentication for the current user.
     */
    public function setTwoFactor(Request $request)
    {
        try {
            $validated = $request->validate([
                'enabled' => 'required|boolean',
            ]);

            $user = $request->user();
            $enabling = (bool) $validated['enabled'];
            $user->two_factor_enabled = $enabling;

            if (!$enabling) {
                $user->two_factor_secret        = null;
                $user->two_factor_confirmed_at  = null;
            }
            $user->save();

            $this->audit->record(
                $request, 'security', null, $enabling ? '2fa_enabled' : '2fa_disabled',
                null, null,
                "{$user->name} " . ($enabling ? 'enabled' : 'disabled') . ' two-factor authentication',
            );

            return response()->json([
                'success' => true,
                'message' => 'Two-factor setting updated.',
                'data'    => ['two_factor_enabled' => $enabling],
            ]);
        } catch (ValidationException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed.',
                'errors'  => $e->errors(),
            ], 422);
        } catch (\Exception $e) {
            Log::error('Updating 2FA failed', [
                'user_id' => $request->user()?->id,
                'error'   => $e->getMessage(),
            ]);
            return response()->json([
                'success' => false,
                'message' => 'Failed to update two-factor setting.',
            ], 500);
        }
    }

    /**
     * DELETE /auth/login-history
     * Clear the current user's login activity history.
     */
    public function clearLoginHistory(Request $request): \Illuminate\Http\JsonResponse
    {
        $user = $request->user();
        $deleted = LoginActivity::where('user_id', $user->id)->delete();

        $this->audit->record(
            $request, 'security', null, 'login_history_cleared',
            null, null,
            "{$user->name} cleared their login history ({$deleted} entries removed)",
        );

        return response()->json([
            'success' => true,
            'message' => 'Login history cleared.',
            'data'    => ['deleted_count' => $deleted],
        ]);
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