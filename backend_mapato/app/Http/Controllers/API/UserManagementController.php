<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;

class UserManagementController extends Controller
{
    // List users created by the authenticated admin
    public function myUsers(Request $request)
    {
        $user = $request->user();
        $query = User::query();

        if ($request->query('created_by') === 'me') {
            $query->where('created_by', $user->id);
        } else if ($request->query('role') === 'super_admin') {
            // Allow fetching superadmin for support contact purposes
            $query->where('role', 'super_admin');
        } else if (!$user->isSuperAdmin() && !$user->full_access) {
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
        $items = $query->with('services')
            ->orderByDesc('created_at')
            ->skip(($page - 1) * $limit)
            ->take($limit)
            ->get(['id', 'name', 'email', 'phone_number', 'role', 'is_active', 'service_type', 'full_access', 'permissions', 'created_at'])
            ->each(function ($u) {
                $u->service_types = $u->services->pluck('service_type')->all();
                unset($u->services);
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

    // Create a user (created_by = auth id)
    public function store(Request $request)
    {
        $auth = $request->user();
        $data = $request->only(['name', 'email', 'password', 'password_confirmation', 'phone_number', 'role', 'is_active', 'service_type', 'service_types', 'full_access', 'permissions']);

        $validator = Validator::make($data, [
            'name' => 'required|string|max:255',
            'email' => 'required|email|unique:users,email',
            'password' => 'required|string|min:6|confirmed',
            'phone_number' => 'nullable|string|max:50',
            'role' => 'nullable|string|in:super_admin,admin,driver,landlord,caretaker,tenant,viewer,manager,operator',
            'is_active' => 'nullable|boolean',
            // Legacy single value - still accepted for old clients.
            'service_type' => 'nullable|string|in:rental,transport,inventory',
            // Preferred: a user can be bound to more than one service.
            'service_types' => 'nullable|array',
            'service_types.*' => 'string|in:rental,transport,inventory',
            'full_access' => 'nullable|boolean',
            'permissions' => 'nullable|array',
        ]);
        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors(),
            ], 422);
        }

        $serviceTypes = $this->resolveServiceTypes($data);

        $user = new User();
        $user->name = $data['name'];
        $user->email = $data['email'];
        $user->password = Hash::make($data['password']);
        $user->phone_number = $data['phone_number'] ?? null;
        $user->role = $data['role'] ?? 'driver';
        $user->service_type = $serviceTypes[0] ?? null;
        $user->full_access = array_key_exists('full_access', $data) ? (bool) $data['full_access'] : false;
        $user->permissions = $data['permissions'] ?? [];
        $user->is_active = array_key_exists('is_active', $data) ? (bool) $data['is_active'] : true;
        $user->created_by = $auth->id;
        $user->save();

        $this->syncServiceTypes($user, $serviceTypes);

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

    private function userPayload(User $user): array
    {
        $payload = $user->only(['id', 'name', 'email', 'phone_number', 'role', 'is_active', 'service_type', 'full_access', 'permissions']);
        $payload['service_types'] = $user->services()->pluck('service_type')->all();
        return $payload;
    }

    // Update user (only fields allowed)
    public function update(Request $request, string $id)
    {
        $auth = $request->user();
        $user = User::where('id', $id)->firstOrFail();
        if (!$auth->isSuperAdmin() && $user->created_by !== $auth->id) {
            abort(403, 'Unauthorized action.');
        }

        $data = $request->only(['name', 'email', 'phone_number', 'role', 'is_active', 'service_type', 'service_types', 'full_access', 'permissions']);
        $validator = Validator::make($data, [
            'name' => 'sometimes|string|max:255',
            'email' => 'sometimes|email|unique:users,email,' . $user->id . ',id',
            'phone_number' => 'nullable|string|max:50',
            'role' => 'sometimes|string|in:super_admin,admin,driver,landlord,caretaker,tenant,viewer,manager,operator',
            'is_active' => 'sometimes|boolean',
            'service_type' => 'nullable|string|in:rental,transport,inventory',
            'service_types' => 'nullable|array',
            'service_types.*' => 'string|in:rental,transport,inventory',
            'full_access' => 'sometimes|boolean',
            'permissions' => 'nullable|array',
        ]);
        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors(),
            ], 422);
        }

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
        if (!$auth->isSuperAdmin() && $user->created_by !== $auth->id) {
            abort(403, 'Unauthorized action.');
        }
        $user->delete();

        return response()->json([
            'success' => true,
            'message' => 'User deleted',
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
            'password' => 'required|string|min:6|confirmed',
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

        return response()->json([
            'success' => true,
            'message' => 'Password reset successfully',
        ]);
    }
}