<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Web\AdminDashboardController;

// Welcome page
Route::get('/', function () {
    return view('welcome');
});

// Admin Dashboard Routes
Route::prefix('admin')->middleware(['auth:sanctum', 'role:admin'])->group(function () {
    Route::get('/dashboard', [AdminDashboardController::class, 'index'])->name('admin.dashboard');
    Route::get('/dashboard/data', [AdminDashboardController::class, 'getData'])->name('admin.dashboard.data');
    Route::get('/dashboard/revenue-chart', [AdminDashboardController::class, 'getRevenueChart'])->name('admin.dashboard.revenue-chart');
});

// Fallback route for admin (redirect to dashboard)
Route::get('/admin', function () {
    return redirect()->route('admin.dashboard');
})->middleware(['auth:sanctum', 'role:admin']);
