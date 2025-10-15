<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;
use App\Models\User;

class UserManagementController extends Controller
{
    /**
     * Get all users (paginated)
     */
    public function index(Request $request)
    {
        try {
            $query = User::query();
            
            // Filter by search query
            if ($request->has('q') && $request->q) {
                $search = $request->q;
                $query->where(function($q) use ($search) {
                    $q->where('name', 'LIKE', "%{$search}%")
                      ->orWhere('email', 'LIKE', "%{$search}%");
                });
            }
            
            // Filter by creator if requested
            if ($request->has('created_by') && $request->created_by === 'me') {
                $query->where('created_by', auth()->id());
            }
            
            $users = $query->paginate($request->get('limit', 50));
            
            return response()->json([
                'success' => true,
                'data' => [
                    'users' => $users->items(),
                    'meta' => [
                        'current_page' => $users->currentPage(),
                        'per_page' => $users->perPage(),
                        'total' => $users->total(),
                        'last_page' => $users->lastPage(),
                    ]
                ]
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to load users',
                'error' => $e->getMessage()
            ], 500);
        }
    }
    
    /**
     * Create a new user
     */
    public function store(Request $request)
    {
        try {
            // Validate the request
            $validator = Validator::make($request->all(), [
                'name' => 'required|string|max:255',
                'email' => 'required|string|email|max:255|unique:users',
                'phone_number' => 'nullable|string|max:20',
                'role' => 'required|string|in:admin,manager,operator,viewer,driver',
                'is_active' => 'boolean',
                'password' => 'required|string|min:6',
                'password_confirmation' => 'required|string|same:password',
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Validation failed',
                    'errors' => $validator->errors()
                ], 422);
            }

            // Create the user
            $user = User::create([
                'name' => $request->name,
                'email' => $request->email,
                'phone_number' => $request->phone_number,
                'role' => $request->role,
                'is_active' => $request->get('is_active', true),
                'password' => Hash::make($request->password),
                'created_by' => auth()->id(), // Track who created this user
            ]);

            return response()->json([
                'success' => true,
                'message' => 'User created successfully',
                'data' => [
                    'user' => $user->only(['id', 'name', 'email', 'phone_number', 'role', 'is_active', 'created_at'])
                ]
            ], 201);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to create user',
                'error' => $e->getMessage()
            ], 500);
        }
    }
    
    /**
     * Update an existing user
     */
    public function update(Request $request, $id)
    {
        try {
            $user = User::findOrFail($id);
            
            // Check if user can edit this user (only creator or super admin)
            if (!auth()->user()->isSuperAdmin() && $user->created_by !== auth()->id()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Unauthorized to edit this user'
                ], 403);
            }
            
            $validator = Validator::make($request->all(), [
                'name' => 'sometimes|string|max:255',
                'email' => 'sometimes|string|email|max:255|unique:users,email,' . $id,
                'phone_number' => 'nullable|string|max:20',
                'role' => 'sometimes|string|in:admin,manager,operator,viewer,driver',
                'is_active' => 'sometimes|boolean',
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Validation failed',
                    'errors' => $validator->errors()
                ], 422);
            }

            $user->update($request->only(['name', 'email', 'phone_number', 'role', 'is_active']));

            return response()->json([
                'success' => true,
                'message' => 'User updated successfully',
                'data' => [
                    'user' => $user->only(['id', 'name', 'email', 'phone_number', 'role', 'is_active', 'updated_at'])
                ]
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to update user',
                'error' => $e->getMessage()
            ], 500);
        }
    }
    
    /**
     * Delete a user
     */
    public function destroy($id)
    {
        try {
            $user = User::findOrFail($id);
            
            // Check if user can delete this user
            if (!auth()->user()->isSuperAdmin() && $user->created_by !== auth()->id()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Unauthorized to delete this user'
                ], 403);
            }
            
            // Don't allow deleting yourself
            if ($user->id === auth()->id()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Cannot delete your own account'
                ], 422);
            }
            
            $user->delete();

            return response()->json([
                'success' => true,
                'message' => 'User deleted successfully'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to delete user',
                'error' => $e->getMessage()
            ], 500);
        }
    }
    
    /**
     * Reset user password
     */
    public function resetPassword(Request $request, $id)
    {
        try {
            $user = User::findOrFail($id);
            
            // Check permissions
            if (!auth()->user()->isSuperAdmin() && $user->created_by !== auth()->id()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Unauthorized to reset this user password'
                ], 403);
            }
            
            $validator = Validator::make($request->all(), [
                'password' => 'required|string|min:6',
                'password_confirmation' => 'required|string|same:password',
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Validation failed',
                    'errors' => $validator->errors()
                ], 422);
            }

            $user->update([
                'password' => Hash::make($request->password)
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Password reset successfully'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to reset password',
                'error' => $e->getMessage()
            ], 500);
        }
    }
}