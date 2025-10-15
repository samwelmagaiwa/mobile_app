<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Admin\UserManagementController;

/*
|--------------------------------------------------------------------------
| User Management API Routes
|--------------------------------------------------------------------------
|
| These routes handle user management for the Flutter app.
| Add these to your routes/api.php file.
|
*/

Route::middleware(['auth:api', 'admin'])->prefix('admin')->group(function () {
    
    // User management endpoints
    Route::get('users', [UserManagementController::class, 'index']);
    Route::post('users', [UserManagementController::class, 'store']);
    Route::put('users/{id}', [UserManagementController::class, 'update']);
    Route::delete('users/{id}', [UserManagementController::class, 'destroy']);
    Route::post('users/{id}/reset-password', [UserManagementController::class, 'resetPassword']);
    
    // Alternative routes for compatibility
    Route::get('users/mine', [UserManagementController::class, 'index'])->defaults('created_by', 'me');
    Route::post('users/{id}/password/reset', [UserManagementController::class, 'resetPassword']);
});

// Alternative route structure (if not using middleware groups)
/*
Route::middleware('auth:api')->group(function () {
    Route::get('api/admin/users', [UserManagementController::class, 'index']);
    Route::post('api/admin/users', [UserManagementController::class, 'store']);
    Route::put('api/admin/users/{id}', [UserManagementController::class, 'update']);
    Route::delete('api/admin/users/{id}', [UserManagementController::class, 'destroy']);
    Route::post('api/admin/users/{id}/reset-password', [UserManagementController::class, 'resetPassword']);
});
*/