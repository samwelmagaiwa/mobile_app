<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Services\Inventory\AuditTrail;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;
use Illuminate\Validation\Rules\Password;

class UserManagementController extends Controller
{
    public function __construct(private readonly AuditTrail $audit)
    {
    }

    // List users visible to the authenticated user.
    //
    // super_admin → sees everyone.
    // admin       → sees all users bound to their own service(s); if they
    //               somehow have no service binding they see only themselves
    //               (an unbound admin cannot manage staff).
    // others      → only their own created_by records.
    public function myUsers(Request $request)
    {
        $user = $request->user();
        $query = User::query();

        if ($request->query('created_by') === 'me') {
            $query->where('created_by', $user->id);
        } elseif ($request->query('role') === 'super_admin') {
            // Only super admins may enumerate other super admin accounts.
            if (!$user->isSuperAdmin()) {
                return response()->json(['success' => false, 'message' => 'Forbidden.'], 403);
            }
            $query->where('role', 'super_admin');
        } elseif ($user->isSuperAdmin() || $user->full_access) {
            // no extra filter — see everyone
        } elseif (strtolower($user->role ?? '') === 'admin' || strtolower($user->role ?? '') === 'administrator') {
            // Admin sees all users whose service bindings overlap with their own.
            $ownServices = $user->services()->pluck('service_type')->all();
            if (empty($ownServices)) {
                // Unbound admin: no service assigned yet — see only themselves.
                $query->where('id', $user->id);
            } else {
                $query->whereHas('services', fn ($q) => $q->whereIn('service_type', $ownServices));
            }
        } else {
            $query->where('created_by', $user->id);
        }

        if ($role = $request->query('role')) {
            $query->where('role', $role);
        }

        if ($serviceType = $request->query('service_type')) {
            $query->whereHas('services', fn ($q) => $q->where('service_type', $serviceType));
        }

        if ($search = $request->query('q')) {
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                    ->orWhere('email', 'like', "%{$search}%")
                    ->orWhere('phone_number', 'like', "%{$search}%");
            });
        }

        $page = max((int) $request->query('page', 1), 1);
        $limit = max((int) $request->query('limit', 20), 1);

        $total = (clone $query)->count();
        $items = $query->with(['services', 'creator:id,name,email'])
            ->orderByDesc('created_at')
            ->skip(($page - 1) * $limit)
            ->take($limit)
            ->get(['id', 'name', 'email', 'phone_number', 'role', 'is_active', 'service_type', 'full_access', 'permissions', 'created_by', 'created_at'])
            ->each(function ($u) {
                $u->service_types = $u->services->pluck('service_type')->all();
                $u->created_by_name = $u->creator->name ?? null;
                $u->created_by_email = $u->creator->email ?? null;
                unset($u->services, $u->creator);
            });

        return response()->json([
            'success' => true,
            'data' => [
                'users' => $items,
                'pagination' => [
                    'page' => $page,
                    'limit' => $limit,
                    'total' => $total,
                    'has_more_pages' => ($page * $limit) < $total,
                ],
            ],
        ]);
    }

    /**
     * Super admin only: every user grouped by service, then by the admin who
     * manages them within that service -- "see all users as per service and
     * as per admins of that service."
     */
    public function usersByService(Request $request)
    {
        $auth = $request->user();
        if (!$auth->isSuperAdmin()) {
            abort(403, 'Only super admin can view users grouped by service.');
        }

        $users = User::with(['services', 'creator:id,name,email'])
            ->orderBy('name')
            ->get(['id', 'name', 'email', 'phone_number', 'role', 'is_active', 'full_access', 'created_by', 'created_at']);

        $services = ['transport', 'rental', 'inventory'];
        $grouped = [];

        foreach ($services as $service) {
            // Admins are grouped by service via their OWN service_types
            // binding, same as staff -- an admin with no service binding at
            // all is treated as a general/company-wide admin and listed
            // separately, not duplicated under every service.
            $usersInService = $users->filter(
                fn ($u) => $u->services->pluck('service_type')->contains($service)
            );

            $byAdmin = [];
            foreach ($usersInService as $u) {
                $adminId = $u->created_by ?? 'unassigned';
                $byAdmin[$adminId]['admin'] = $u->creator
                    ? ['id' => $u->creator->id, 'name' => $u->creator->name, 'email' => $u->creator->email]
                    : null;
                $byAdmin[$adminId]['users'][] = $this->userPayload($u, $u->services->pluck('service_type')->all());
            }

            $grouped[$service] = array_values($byAdmin);
        }

        $generalAdmins = $users->filter(
            fn ($u) => in_array($u->role, ['admin', 'super_admin'], true) && $u->services->isEmpty()
        )->map(fn ($u) => $this->userPayload($u, []))->values();

        return response()->json([
            'success' => true,
            'data' => [
                'by_service' => $grouped,
                'general_admins' => $generalAdmins,
            ],
        ]);
    }

    // Create a user (created_by = auth id)
    public function store(Request $request)
    {
        $auth = $request->user();
        $data = $request->only(['name', 'email', 'password', 'password_confirmation', 'phone_number', 'role', 'is_active', 'service_type', 'service_types', 'full_access', 'permissions']);

        $validator = Validator::make($data, [
            'name' => 'required|string|max:255',
            'email' => 'required|email|unique:users,email',
            // Length-only: the app's own default-password generator
            // (surname repeated to 8 chars, e.g. "MAGAIWA" -> "MAGAIWAM")
            // is letters-only, so a letters()+numbers() complexity
            // requirement here would reject the app's own UX pattern.
            'password' => ['required', 'confirmed', Password::min(8)],
            'phone_number' => 'nullable|string|max:50|unique:users,phone_number',
            'role' => 'nullable|string|in:super_admin,admin,driver,landlord,caretaker,tenant,viewer,manager,operator,sales_officer',
            'is_active' => 'nullable|boolean',
            // Legacy single value - still accepted for old clients.
            'service_type' => 'nullable|string|in:rental,transport,inventory',
            // Preferred: a user can be bound to more than one service.
            'service_types' => 'nullable|array',
            'service_types.*' => 'string|in:rental,transport,inventory',
            'full_access' => 'nullable|boolean',
            'permissions' => 'nullable|array',
            'permissions.*' => 'string|in:' . implode(',', User::INV_PERMISSIONS),
        ]);
        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors(),
            ], 422);
        }

        // Non-super-admins cannot grant full_access flag.
        if (!$auth->isSuperAdmin() && !empty($data['full_access'])) {
            return response()->json(['success' => false, 'message' => 'Only super admin can grant full access.'], 403);
        }

        $role = $data['role'] ?? 'driver';
        $serviceTypes = $this->resolveServiceTypes($data);

        // An account bound to no service and with no admin-level role can
        // never do anything useful once created -- catch that at creation
        // time instead of shipping a silently broken login.
        if (empty($serviceTypes) && !in_array($role, ['admin', 'super_admin'], true)) {
            return response()->json([
                'success' => false,
                'message' => 'Select at least one service for this account.',
            ], 422);
        }

        if (!$auth->isSuperAdmin()) {
            // Only super admin may grant admin-level roles -- a plain admin
            // creating staff cannot escalate them to their own level or above.
            if (in_array($role, ['admin', 'super_admin'], true)) {
                return response()->json([
                    'success' => false,
                    'message' => 'Only a super admin can create admin accounts.',
                ], 403);
            }

            // Admin must have been bound to at least one service by a super_admin
            // before they can create staff. An unbound admin has no service scope
            // and therefore cannot create users for any service.
            $ownServices = $auth->services()->pluck('service_type')->all();
            if (empty($ownServices)) {
                return response()->json([
                    'success' => false,
                    'message' => 'Your account has no service assigned. Ask your super admin to bind you to a service before you can create staff.',
                ], 403);
            }

            // Admin can only create staff within their assigned service(s).
            $outOfScope = array_diff($serviceTypes, $ownServices);
            if (!empty($outOfScope)) {
                return response()->json([
                    'success' => false,
                    'message' => 'You can only create staff for your assigned service(s): ' . implode(', ', $ownServices),
                ], 403);
            }
        }

        $user = new User();
        $user->name = $data['name'];
        $user->email = $data['email'];
        $user->password = Hash::make($data['password']);
        $user->phone_number = $data['phone_number'] ?? null;
        $user->role = $role;
        $user->service_type = $serviceTypes[0] ?? null;
        $user->full_access = array_key_exists('full_access', $data) ? (bool) $data['full_access'] : false;
        $user->permissions = $data['permissions'] ?? [];
        $user->is_active = array_key_exists('is_active', $data) ? (bool) $data['is_active'] : true;
        $user->created_by = $auth->id;
        $user->save();

        $this->syncServiceTypes($user, $serviceTypes);

        $this->audit->record(
            $request, 'user', null, 'created', null,
            ['name' => $user->name, 'email' => $user->email, 'role' => $role, 'service_types' => $serviceTypes],
            "{$auth->name} created {$role} account \"{$user->name}\" ({$user->email})",
        );

        return response()->json([
            'success' => true,
            'message' => 'User created',
            'data' => ['user' => $this->userPayload($user)],
        ], 201);
    }

    /** Prefer the new `service_types` array; fall back to the legacy single value. */
    private function resolveServiceTypes(array $data): array
    {
        if (!empty($data['service_types'])) {
            return array_values(array_unique($data['service_types']));
        }
        if (!empty($data['service_type'])) {
            return [$data['service_type']];
        }
        return [];
    }

    /** Replace this user's bound services with exactly this set. */
    private function syncServiceTypes(User $user, array $serviceTypes): void
    {
        $user->services()->delete();
        foreach (array_unique($serviceTypes) as $type) {
            $user->services()->create(['service_type' => $type]);
        }
    }

    private function userPayload(User $user, ?array $serviceTypes = null): array
    {
        $payload = $user->only(['id', 'name', 'email', 'phone_number', 'role', 'is_active', 'service_type', 'full_access', 'permissions']);
        $payload['service_types'] = $serviceTypes ?? $user->services()->pluck('service_type')->all();
        return $payload;
    }

    // Update user (only fields allowed)
    public function update(Request $request, string $id)
    {
        $auth = $request->user();
        $user = User::where('id', $id)->firstOrFail();

        // Super admin can update anyone.
        // Admin can only update users they personally created AND who are not
        // admins/super_admins (peer-level accounts are super_admin territory).
        if (!$auth->isSuperAdmin()) {
            if ($user->created_by !== $auth->id) {
                abort(403, 'Unauthorized action.');
            }
            if (in_array(strtolower($user->role ?? ''), ['admin', 'administrator', 'super_admin'], true)) {
                return response()->json([
                    'success' => false,
                    'message' => 'Only a super admin can edit admin accounts.',
                ], 403);
            }
        }

        $data = $request->only(['name', 'email', 'phone_number', 'role', 'is_active', 'service_type', 'service_types', 'full_access', 'permissions']);
        $validator = Validator::make($data, [
            'name' => 'sometimes|string|max:255',
            'email' => 'sometimes|email|unique:users,email,' . $user->id . ',id',
            'phone_number' => 'nullable|string|max:50|unique:users,phone_number,' . $user->id . ',id',
            'role' => 'sometimes|string|in:super_admin,admin,driver,landlord,caretaker,tenant,viewer,manager,operator,sales_officer',
            'is_active' => 'sometimes|boolean',
            'service_type' => 'nullable|string|in:rental,transport,inventory',
            'service_types' => 'nullable|array',
            'service_types.*' => 'string|in:rental,transport,inventory',
            'full_access' => 'sometimes|boolean',
            'permissions' => 'nullable|array',
            'permissions.*' => 'string|in:' . implode(',', User::INV_PERMISSIONS),
        ]);
        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors(),
            ], 422);
        }

        // Non-super-admins cannot grant full_access flag.
        if (!$auth->isSuperAdmin() && array_key_exists('full_access', $data) && $data['full_access']) {
            return response()->json(['success' => false, 'message' => 'Only super admin can grant full access.'], 403);
        }

        // Same escalation guard as store(): a plain admin editing an existing
        // account cannot promote it to admin/super_admin either.
        if (!$auth->isSuperAdmin() && array_key_exists('role', $data)
            && in_array($data['role'], ['admin', 'super_admin'], true)
            && $user->role !== $data['role']
        ) {
            return response()->json([
                'success' => false,
                'message' => 'Only a super admin can grant admin accounts.',
            ], 403);
        }

        $before = ['is_active' => $user->is_active, 'role' => $user->role, 'name' => $user->name, 'permissions' => $user->permissions];

        $touchesServices = array_key_exists('service_types', $data) || array_key_exists('service_type', $data);
        $validated = $validator->validated();
        unset($validated['service_types']);

        if ($touchesServices) {
            $serviceTypes = $this->resolveServiceTypes($data);
            $validated['service_type'] = $serviceTypes[0] ?? null;
        }

        $user->fill($validated);
        $user->save();

        if ($touchesServices) {
            $this->syncServiceTypes($user, $this->resolveServiceTypes($data));
        }

        // Deactivating/reactivating an account is the kind of action that
        // needs a clear "who and when" trail, not just a silent flag flip.
        if (array_key_exists('is_active', $data) && $before['is_active'] !== $user->is_active) {
            $this->audit->record(
                $request, 'user', null, $user->is_active ? 'activated' : 'deactivated', $before,
                ['is_active' => $user->is_active],
                "{$auth->name} " . ($user->is_active ? 'activated' : 'deactivated') . " \"{$user->name}\" ({$user->email})",
            );
        } elseif (array_key_exists('role', $data) && $before['role'] !== $user->role) {
            $this->audit->record(
                $request, 'user', null, 'role_changed', $before,
                ['role' => $user->role],
                "{$auth->name} changed \"{$user->name}\"'s role from {$before['role']} to {$user->role}",
            );
        }

        if (array_key_exists('permissions', $data)) {
            $this->audit->record(
                $request, 'user', null, 'permissions_changed',
                ['permissions' => $before['permissions'] ?? []],
                ['permissions' => $user->permissions ?? []],
                "{$auth->name} updated explicit permissions for \"{$user->name}\"",
            );
        }

        return response()->json([
            'success' => true,
            'message' => 'User updated',
            'data' => ['user' => $this->userPayload($user)],
        ]);
    }

    // Delete user
    public function destroy(Request $request, string $id)
    {
        $auth = $request->user();
        $user = User::where('id', $id)->firstOrFail();

        if (!$auth->isSuperAdmin()) {
            if ($user->created_by !== $auth->id) {
                abort(403, 'Unauthorized action.');
            }
            if (in_array(strtolower($user->role ?? ''), ['admin', 'administrator', 'super_admin'], true)) {
                return response()->json([
                    'success' => false,
                    'message' => 'Only a super admin can delete admin accounts.',
                ], 403);
            }
        }

        $summary = "{$auth->name} deleted {$user->role} account \"{$user->name}\" ({$user->email})";
        $user->delete();

        $this->audit->record(
            $request, 'user', null, 'deleted',
            ['name' => $user->name, 'email' => $user->email, 'role' => $user->role],
            null, $summary,
        );

        return response()->json([
            'success' => true,
            'message' => 'User deleted',
        ]);
    }

    /**
     * Super admin only: replace a user's service bindings with the supplied set.
     *
     * PUT /users/{id}/services   body: { "service_types": ["inventory","rental"] }
     *
     * Passing an empty array removes all bindings (effectively locks the user out
     * of all services until re-bound). This is intentional — super_admin can use
     * this to revoke an admin's access to a service without deleting the account.
     */
    public function bindServices(Request $request, string $id)
    {
        $auth = $request->user();

        if (!$auth->isSuperAdmin()) {
            return response()->json([
                'success' => false,
                'message' => 'Only a super admin can manage service bindings.',
            ], 403);
        }

        $target = User::where('id', $id)->firstOrFail();

        $validator = Validator::make($request->all(), [
            'service_types'   => 'required|array',
            'service_types.*' => 'string|in:rental,transport,inventory',
        ]);
        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors'  => $validator->errors(),
            ], 422);
        }

        $before   = $target->services()->pluck('service_type')->all();
        $newTypes = array_values(array_unique($request->input('service_types', [])));

        $this->syncServiceTypes($target, $newTypes);

        // Keep legacy single-value column in sync for older code paths.
        $target->service_type = $newTypes[0] ?? null;
        $target->save();

        $this->audit->record(
            $request, 'user', null, 'services_changed',
            ['service_types' => $before],
            ['service_types' => $newTypes],
            "{$auth->name} updated service bindings for \"{$target->name}\" ({$target->email}): "
            . (empty($newTypes) ? 'none' : implode(', ', $newTypes)),
        );

        return response()->json([
            'success'      => true,
            'message'      => 'Service bindings updated.',
            'data'         => [
                'user'         => $this->userPayload($target, $newTypes),
                'is_unbound'   => empty($newTypes),
            ],
        ]);
    }

    // Reset password to provided value
    public function resetPassword(Request $request, string $id)
    {
        $auth = $request->user();
        $user = User::where('id', $id)->firstOrFail();
        if (!$auth->isSuperAdmin() && $user->created_by !== $auth->id) {
            abort(403, 'Unauthorized action.');
        }

        $data = $request->only(['password', 'password_confirmation']);
        $validator = Validator::make($data, [
            'password' => ['required', 'confirmed', Password::min(8)],
        ]);
        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors(),
            ], 422);
        }

        $user->password = Hash::make($data['password']);
        $user->save();

        $this->audit->record(
            $request, 'user', null, 'password_reset', null, null,
            "{$auth->name} reset the password for \"{$user->name}\" ({$user->email})",
        );

        return response()->json([
            'success' => true,
            'message' => 'Password reset successfully',
        ]);
    }
}