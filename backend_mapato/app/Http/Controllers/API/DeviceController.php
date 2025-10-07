<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Http\Requests\DeviceRequest;
use App\Models\Device;
use App\Helpers\ResponseHelper;
use Illuminate\Http\Request;

class DeviceController extends Controller
{
    /**
     * Get all devices for authenticated driver
     */
    public function index(Request $request)
    {
        try {
            $driver = $request->user()->driver;
            $devices = Device::where('driver_id', $driver->id)
                           ->orderBy('created_at', 'desc')
                           ->get();

            return ResponseHelper::success($devices, 'Devices retrieved successfully');
        } catch (\Exception $e) {
            return ResponseHelper::error('Failed to retrieve devices: ' . $e->getMessage(), 500);
        }
    }

    /**
     * Store a new device
     */
    public function store(DeviceRequest $request)
    {
        try {
            $driver = $request->user()->driver;

            $device = Device::create([
                'driver_id' => $driver->id,
                'name' => $request->name,
                'type' => $request->type,
                'plate_number' => strtoupper($request->plate_number),
                'description' => $request->description,
                'is_active' => true,
            ]);

            return ResponseHelper::success($device, 'Device created successfully', 201);
        } catch (\Exception $e) {
            return ResponseHelper::error('Failed to create device: ' . $e->getMessage(), 500);
        }
    }

    /**
     * Show specific device
     */
    public function show(Request $request, $id)
    {
        try {
            $driver = $request->user()->driver;
            $device = Device::where('driver_id', $driver->id)->findOrFail($id);

            return ResponseHelper::success($device, 'Device retrieved successfully');
        } catch (\Exception $e) {
            return ResponseHelper::error('Device not found', 404);
        }
    }

    /**
     * Update device
     */
    public function update(DeviceRequest $request, $id)
    {
        try {
            $driver = $request->user()->driver;
            $device = Device::where('driver_id', $driver->id)->findOrFail($id);

            $device->update([
                'name' => $request->name,
                'type' => $request->type,
                'plate_number' => strtoupper($request->plate_number),
                'description' => $request->description,
            ]);

            return ResponseHelper::success($device, 'Device updated successfully');
        } catch (\Exception $e) {
            return ResponseHelper::error('Failed to update device: ' . $e->getMessage(), 500);
        }
    }

    /**
     * Delete device
     */
    public function destroy(Request $request, $id)
    {
        try {
            $driver = $request->user()->driver;
            $device = Device::where('driver_id', $driver->id)->findOrFail($id);

            // Check if device has transactions
            if ($device->transactions()->count() > 0) {
                return ResponseHelper::error('Cannot delete device with existing transactions', 400);
            }

            $device->delete();

            return ResponseHelper::success(null, 'Device deleted successfully');
        } catch (\Exception $e) {
            return ResponseHelper::error('Failed to delete device: ' . $e->getMessage(), 500);
        }
    }

    /**
     * Toggle device status
     */
    public function toggleStatus(Request $request, $id)
    {
        try {
            $driver = $request->user()->driver;
            $device = Device::where('driver_id', $driver->id)->findOrFail($id);

            $device->update([
                'is_active' => !$device->is_active,
            ]);

            $status = $device->is_active ? 'activated' : 'deactivated';
            return ResponseHelper::success($device, "Device {$status} successfully");
        } catch (\Exception $e) {
            return ResponseHelper::error('Failed to toggle device status: ' . $e->getMessage(), 500);
        }
    }

    /**
     * Get device statistics
     */
    public function statistics(Request $request, $id)
    {
        try {
            $driver = $request->user()->driver;
            $device = Device::where('driver_id', $driver->id)->findOrFail($id);

            $stats = [
                'total_transactions' => $device->transactions()->count(),
                'total_revenue' => $device->transactions()
                    ->where('type', 'income')
                    ->where('status', 'completed')
                    ->sum('amount'),
                'total_expenses' => $device->transactions()
                    ->where('type', 'expense')
                    ->where('status', 'completed')
                    ->sum('amount'),
                'today_revenue' => $device->transactions()
                    ->where('type', 'income')
                    ->where('status', 'completed')
                    ->whereDate('created_at', today())
                    ->sum('amount'),
                'this_month_revenue' => $device->transactions()
                    ->where('type', 'income')
                    ->where('status', 'completed')
                    ->whereMonth('created_at', now()->month)
                    ->whereYear('created_at', now()->year)
                    ->sum('amount'),
            ];

            return ResponseHelper::success($stats, 'Device statistics retrieved successfully');
        } catch (\Exception $e) {
            return ResponseHelper::error('Failed to retrieve device statistics: ' . $e->getMessage(), 500);
        }
    }
}