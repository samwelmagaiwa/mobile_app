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
        } else if (!$user->isSuperAdmin() && !$user->full_access) {
            $query->where('created_by', $user->id);
        }

        if ($serviceType = $request->query('service_type')) {
            $query->where('service_type', $serviceType);
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
        $items = $query->orderByDesc('created_at')
            ->skip(($page - 1) * $limit)
            ->take($limit)
            ->get(['id', 'name', 'email', 'phone_number', 'role', 'is_active', 'service_type', 'full_access', 'permissions', 'created_at']);

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
        $data = $request->only(['name', 'email', 'password', 'password_confirmation', 'phone_number', 'role', 'is_active', 'service_type', 'full_access', 'permissions']);

        $validator = Validator::make($data, [
            'name' => 'required|string|max:255',
            'email' => 'required|email|unique:users,email',
            'password' => 'required|string|min:6|confirmed',
            'phone_number' => 'nullable|string|max:50',
            'role' => 'nullable|string|in:super_admin,admin,driver,landlord,caretaker,tenant,viewer,manager,operator',
            'is_active' => 'nullable|boolean',
            'service_type' => 'nullable|string|in:rental,transport,inventory',
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

        $user = new User();
        $user->name = $data['name'];
        $user->email = $data['email'];
        $user->password = Hash::make($data['password']);
        $user->phone_number = $data['phone_number'] ?? null;
        $user->role = $data['role'] ?? 'driver';
        $user->service_type = $data['service_type'] ?? null;
        $user->full_access = array_key_exists('full_access', $data) ? (bool) $data['full_access'] : false;
        $user->permissions = $data['permissions'] ?? [];
        $user->is_active = array_key_exists('is_active', $data) ? (bool) $data['is_active'] : true;
        $user->created_by = $auth->id;
        $user->save();

        return response()->json([
            'success' => true,
            'message' => 'User created',
            'data' => ['user' => $user->only(['id', 'name', 'email', 'phone_number', 'role', 'is_active', 'service_type', 'full_access', 'permissions'])],
        ], 201);
    }

    // Update user (only fields allowed)
    public function update(Request $request, string $id)
    {
        $auth = $request->user();
        $user = User::where('id', $id)->firstOrFail();
        if (!$auth->isSuperAdmin() && $user->created_by !== $auth->id) {
            abort(403, 'Unauthorized action.');
        }

        $data = $request->only(['name', 'email', 'phone_number', 'role', 'is_active', 'service_type', 'full_access', 'permissions']);
        $validator = Validator::make($data, [
            'name' => 'sometimes|string|max:255',
            'email' => 'sometimes|email|unique:users,email,' . $user->id . ',id',
            'phone_number' => 'nullable|string|max:50',
            'role' => 'sometimes|string|in:super_admin,admin,driver,landlord,caretaker,tenant,viewer,manager,operator',
            'is_active' => 'sometimes|boolean',
            'service_type' => 'nullable|string|in:rental,transport,inventory',
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

        $user->fill($validator->validated());
        $user->save();

        return response()->json([
            'success' => true,
            'message' => 'User updated',
            'data' => ['user' => $user->only(['id', 'name', 'email', 'phone_number', 'role', 'is_active', 'service_type', 'full_access', 'permissions'])],
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