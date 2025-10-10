<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\Communication;
use App\Models\Driver;
use App\Helpers\ResponseHelper;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;
use Illuminate\Database\QueryException;

class CommunicationController extends Controller
{
    /**
     * Display a listing of communications
     */
    public function index(Request $request)
    {
        try {
            $perPage = $request->get('per_page', 15);
            $search = $request->get('search');
            $mode = $request->get('mode');
            $status = $request->get('status'); // 'answered' or 'unanswered'
            $driverId = $request->get('driver_id');

            $query = Communication::with('driver.user')
                ->orderBy('message_date', 'desc');

            // Apply search filter
            if ($search) {
                $query->search($search);
            }

            // Apply mode filter
            if ($mode && $mode !== 'all') {
                $query->byMode($mode);
            }

            // Apply status filter
            if ($status && $status !== 'all') {
                if ($status === 'answered') {
                    $query->answered();
                } elseif ($status === 'unanswered') {
                    $query->unanswered();
                }
            }

            // Apply driver filter
            if ($driverId) {
                $query->where('driver_id', $driverId);
            }

            $communications = $query->paginate($perPage);

            // Transform the data to match Flutter model expectations
            $communications->getCollection()->transform(function ($communication) {
                return [
                    'id' => $communication->id,
                    'driver_id' => $communication->driver_id,
                    'driver_name' => $communication->driver_name,
                    'message_date' => $communication->message_date->toISOString(),
                    'message_content' => $communication->message_content,
                    'response' => $communication->response,
                    'mode' => $communication->mode,
                    'created_at' => $communication->created_at->toISOString(),
                    'updated_at' => $communication->updated_at->toISOString(),
                    // Additional formatted fields for display
                    'has_response' => $communication->has_response,
                    'truncated_content' => $communication->truncated_content,
                    'truncated_response' => $communication->truncated_response,
                    'formatted_message_date' => $communication->formatted_message_date,
                    'formatted_date_time' => $communication->formatted_date_time,
                    'mode_display_name' => $communication->mode_display_name,
                    'mode_icon' => $communication->mode_icon,
                ];
            });

            return ResponseHelper::paginated($communications, 'Communications retrieved successfully');

        } catch (\Exception $e) {
            return ResponseHelper::serverError('Failed to retrieve communications: ' . $e->getMessage());
        }
    }

    /**
     * Store a newly created communication
     */
    public function store(Request $request)
    {
        try {
            $request->validate([
                'driver_id' => 'required|string|exists:drivers,id',
                'driver_name' => 'required|string|max:255',
                'message_date' => 'required|date',
                'message_content' => 'required|string',
                'mode' => 'required|in:sms,call,whatsapp,system_note',
                'response' => 'nullable|string',
            ]);

            // Verify driver exists and get the driver name from the database
            $driver = Driver::with('user')->find($request->driver_id);
            if (!$driver) {
                return ResponseHelper::notFound('Driver not found');
            }

            $communication = Communication::create([
                'driver_id' => $request->driver_id,
                'driver_name' => $driver->name ?? $request->driver_name,
                'message_date' => $request->message_date,
                'message_content' => $request->message_content,
                'response' => $request->response,
                'mode' => $request->mode,
            ]);

            $communication->load('driver.user');

            return ResponseHelper::success([
                'id' => $communication->id,
                'driver_id' => $communication->driver_id,
                'driver_name' => $communication->driver_name,
                'message_date' => $communication->message_date->toISOString(),
                'message_content' => $communication->message_content,
                'response' => $communication->response,
                'mode' => $communication->mode,
                'created_at' => $communication->created_at->toISOString(),
                'updated_at' => $communication->updated_at->toISOString(),
                'has_response' => $communication->has_response,
                'mode_display_name' => $communication->mode_display_name,
                'mode_icon' => $communication->mode_icon,
            ], 'Communication created successfully', 201);

        } catch (ValidationException $e) {
            return ResponseHelper::validationError($e->errors(), 'Validation failed');
        } catch (QueryException $e) {
            return ResponseHelper::error('Database error occurred while creating communication', 500);
        } catch (\Exception $e) {
            return ResponseHelper::serverError('Failed to create communication: ' . $e->getMessage());
        }
    }

    /**
     * Display the specified communication
     */
    public function show($id)
    {
        try {
            $communication = Communication::with('driver.user')->find($id);

            if (!$communication) {
                return ResponseHelper::notFound('Communication not found');
            }

            return ResponseHelper::success([
                'id' => $communication->id,
                'driver_id' => $communication->driver_id,
                'driver_name' => $communication->driver_name,
                'message_date' => $communication->message_date->toISOString(),
                'message_content' => $communication->message_content,
                'response' => $communication->response,
                'mode' => $communication->mode,
                'created_at' => $communication->created_at->toISOString(),
                'updated_at' => $communication->updated_at->toISOString(),
                'has_response' => $communication->has_response,
                'formatted_message_date' => $communication->formatted_message_date,
                'formatted_date_time' => $communication->formatted_date_time,
                'mode_display_name' => $communication->mode_display_name,
                'mode_icon' => $communication->mode_icon,
                'driver' => $communication->driver ? [
                    'id' => $communication->driver->id,
                    'name' => $communication->driver->name,
                    'email' => $communication->driver->email,
                    'phone' => $communication->driver->phone,
                ] : null,
            ], 'Communication retrieved successfully');

        } catch (\Exception $e) {
            return ResponseHelper::serverError('Failed to retrieve communication: ' . $e->getMessage());
        }
    }

    /**
     * Update the specified communication
     */
    public function update(Request $request, $id)
    {
        try {
            $communication = Communication::find($id);

            if (!$communication) {
                return ResponseHelper::notFound('Communication not found');
            }

            $request->validate([
                'response' => 'required|string',
            ]);

            $communication->update([
                'response' => $request->response,
            ]);

            $communication->load('driver.user');

            return ResponseHelper::success([
                'id' => $communication->id,
                'driver_id' => $communication->driver_id,
                'driver_name' => $communication->driver_name,
                'message_date' => $communication->message_date->toISOString(),
                'message_content' => $communication->message_content,
                'response' => $communication->response,
                'mode' => $communication->mode,
                'created_at' => $communication->created_at->toISOString(),
                'updated_at' => $communication->updated_at->toISOString(),
                'has_response' => $communication->has_response,
                'mode_display_name' => $communication->mode_display_name,
                'mode_icon' => $communication->mode_icon,
            ], 'Communication updated successfully');

        } catch (ValidationException $e) {
            return ResponseHelper::validationError($e->errors(), 'Validation failed');
        } catch (\Exception $e) {
            return ResponseHelper::serverError('Failed to update communication: ' . $e->getMessage());
        }
    }

    /**
     * Remove the specified communication
     */
    public function destroy($id)
    {
        try {
            $communication = Communication::find($id);

            if (!$communication) {
                return ResponseHelper::notFound('Communication not found');
            }

            $communication->delete();

            return ResponseHelper::success(null, 'Communication deleted successfully');

        } catch (\Exception $e) {
            return ResponseHelper::serverError('Failed to delete communication: ' . $e->getMessage());
        }
    }

    /**
     * Get communication summary statistics
     */
    public function summary(Request $request)
    {
        try {
            $period = $request->get('period', 'all'); // 'all', 'week', 'month', 'year'
            
            $query = Communication::query();

            // Apply period filter if specified
            switch ($period) {
                case 'week':
                    $query->where('message_date', '>=', now()->startOfWeek());
                    break;
                case 'month':
                    $query->where('message_date', '>=', now()->startOfMonth());
                    break;
                case 'year':
                    $query->where('message_date', '>=', now()->startOfYear());
                    break;
                default:
                    // 'all' - no additional filter
                    break;
            }

            $total = $query->count();
            $unanswered = (clone $query)->unanswered()->count();
            $recent = Communication::recent()->count(); // Always last 7 days for "recent"
            
            $byMode = [];
            foreach (array_keys(Communication::MODES) as $mode) {
                $byMode[$mode] = (clone $query)->byMode($mode)->count();
            }
            
            $lastCommunication = Communication::latest('message_date')->first();
            $responseRate = $total > 0 ? round((($total - $unanswered) / $total) * 100) : 0;

            return ResponseHelper::success([
                'total_communications' => $total,
                'unanswered_communications' => $unanswered,
                'recent_communications' => $recent,
                'communications_by_mode' => $byMode,
                'last_communication_date' => $lastCommunication ? $lastCommunication->message_date->toISOString() : null,
                'response_rate' => $responseRate,
                'period' => $period,
            ], 'Communication summary retrieved successfully');

        } catch (\Exception $e) {
            return ResponseHelper::serverError('Failed to retrieve communication summary: ' . $e->getMessage());
        }
    }

    /**
     * Get communications for a specific driver
     */
    public function byDriver($driverId, Request $request)
    {
        try {
            $driver = Driver::find($driverId);
            if (!$driver) {
                return ResponseHelper::notFound('Driver not found');
            }

            $perPage = $request->get('per_page', 15);
            
            $communications = Communication::where('driver_id', $driverId)
                ->with('driver.user')
                ->orderBy('message_date', 'desc')
                ->paginate($perPage);

            // Transform the data
            $communications->getCollection()->transform(function ($communication) {
                return [
                    'id' => $communication->id,
                    'driver_id' => $communication->driver_id,
                    'driver_name' => $communication->driver_name,
                    'message_date' => $communication->message_date->toISOString(),
                    'message_content' => $communication->message_content,
                    'response' => $communication->response,
                    'mode' => $communication->mode,
                    'created_at' => $communication->created_at->toISOString(),
                    'updated_at' => $communication->updated_at->toISOString(),
                    'has_response' => $communication->has_response,
                    'formatted_message_date' => $communication->formatted_message_date,
                    'mode_display_name' => $communication->mode_display_name,
                    'mode_icon' => $communication->mode_icon,
                ];
            });

            return ResponseHelper::paginated($communications, 'Driver communications retrieved successfully');

        } catch (\Exception $e) {
            return ResponseHelper::serverError('Failed to retrieve driver communications: ' . $e->getMessage());
        }
    }

    /**
     * Get available communication modes
     */
    public function modes()
    {
        try {
            $modes = collect(Communication::MODES)->map(function ($displayName, $value) {
                return [
                    'value' => $value,
                    'display_name' => $displayName,
                    'icon' => (new Communication(['mode' => $value]))->mode_icon,
                ];
            })->values();

            return ResponseHelper::success($modes, 'Communication modes retrieved successfully');

        } catch (\Exception $e) {
            return ResponseHelper::serverError('Failed to retrieve communication modes: ' . $e->getMessage());
        }
    }
}