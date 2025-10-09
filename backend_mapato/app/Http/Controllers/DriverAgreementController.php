<?php

namespace App\Http\Controllers;

use App\Models\DriverAgreement;
use App\Models\Driver;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Validation\Rule;
use Illuminate\Support\Facades\Auth;
use Carbon\Carbon;

class DriverAgreementController extends Controller
{
    /**
     * Display a listing of driver agreements
     */
    public function index(Request $request): JsonResponse
    {
        try {
            $query = DriverAgreement::with(['driver', 'creator']);
            
            // Filter by driver if specified
            if ($request->has('driver_id')) {
                $query->where('driver_id', $request->driver_id);
            }
            
            // Filter by agreement type if specified
            if ($request->has('agreement_type')) {
                $query->where('agreement_type', $request->agreement_type);
            }
            
            // Filter by status if specified
            if ($request->has('status')) {
                $query->where('status', $request->status);
            }
            
            $agreements = $query->orderBy('created_at', 'desc')->paginate(20);
            
            return response()->json([
                'success' => true,
                'data' => $agreements,
                'message' => 'Driver agreements retrieved successfully'
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error retrieving driver agreements: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Store a newly created driver agreement
     */
    public function store(Request $request): JsonResponse
    {
        try {
            // Validate request data
            $validatedData = $request->validate([
                'driver_id' => 'required|uuid|exists:drivers,id',
                'agreement_type' => 'required|in:kwa_mkataba,dei_waka',
                'start_date' => 'required|date',
                'weekends_countable' => 'boolean',
                'saturday_included' => 'boolean',
                'sunday_included' => 'boolean',
                'payment_frequencies' => 'required|array|min:1',
                'payment_frequencies.*' => 'in:kila_siku,kila_wiki,kila_mwezi',
                'notes' => 'nullable|string',
                // Contract-specific fields
                'vehicle_payment' => 'required_if:agreement_type,kwa_mkataba|numeric|min:0',
                'daily_target' => 'required_if:agreement_type,kwa_mkataba|numeric|min:0',
                'contract_period_months' => 'required_if:agreement_type,kwa_mkataba|integer|min:1',
                // Daily work fields
                'salary_amount' => 'required_if:agreement_type,dei_waka|numeric|min:0',
                'bonus_amount' => 'nullable|numeric|min:0',
            ]);
            
            // Check if driver already has an active agreement
            $existingAgreement = DriverAgreement::where('driver_id', $validatedData['driver_id'])
                ->where('status', 'active')
                ->first();
                
            if ($existingAgreement) {
                return response()->json([
                    'success' => false,
                    'message' => 'Driver already has an active agreement'
                ], 422);
            }
            
            // Map frontend field names to backend field names
            $validatedData['wikendi_zinahesabika'] = $request->boolean('weekends_countable', false);
            $validatedData['jumamosi'] = $request->boolean('saturday_included', false);
            $validatedData['jumapili'] = $request->boolean('sunday_included', false);
            
            // Calculate kiasi_cha_makubaliano based on agreement type
            if ($validatedData['agreement_type'] === 'kwa_mkataba') {
                $validatedData['kiasi_cha_makubaliano'] = $validatedData['daily_target'] ?? 0;
                
                // Calculate end date and mwaka_atamaliza
                $startDate = Carbon::parse($validatedData['start_date']);
                $contractMonths = $validatedData['contract_period_months'] ?? 1;
                $endDate = $startDate->copy()->addMonths($contractMonths);
                
                $validatedData['end_date'] = $endDate->format('Y-m-d');
                $validatedData['mwaka_atamaliza'] = $endDate->format('Y');
            } else {
                $validatedData['kiasi_cha_makubaliano'] = $validatedData['salary_amount'] ?? 0;
            }
            
            // Set created_by to current authenticated user
            $validatedData['created_by'] = Auth::id();
            
            // Create the agreement
            $agreement = DriverAgreement::create($validatedData);
            
            // Load relationships
            $agreement->load(['driver', 'creator']);
            
            return response()->json([
                'success' => true,
                'data' => $agreement,
                'message' => 'Driver agreement created successfully'
            ], 201);
        } catch (\Illuminate\Validation\ValidationException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $e->errors()
            ], 422);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error creating driver agreement: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Display the specified driver agreement
     */
    public function show(string $id): JsonResponse
    {
        try {
            $agreement = DriverAgreement::with(['driver', 'creator'])->findOrFail($id);
            
            return response()->json([
                'success' => true,
                'data' => $agreement,
                'message' => 'Driver agreement retrieved successfully'
            ]);
        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Driver agreement not found'
            ], 404);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error retrieving driver agreement: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Update the specified driver agreement
     */
    public function update(Request $request, string $id): JsonResponse
    {
        try {
            $agreement = DriverAgreement::findOrFail($id);
            
            // Validate request data
            $validatedData = $request->validate([
                'agreement_type' => 'sometimes|in:kwa_mkataba,dei_waka',
                'start_date' => 'sometimes|date|after_or_equal:today',
                'end_date' => 'sometimes|nullable|date|after:start_date',
                'mwaka_atamaliza' => 'sometimes|nullable|string',
                'kiasi_cha_makubaliano' => 'sometimes|numeric|min:0',
                'wikendi_zinahesabika' => 'sometimes|boolean',
                'jumamosi' => 'sometimes|boolean',
                'jumapili' => 'sometimes|boolean',
                'payment_frequencies' => 'sometimes|array|min:1',
                'payment_frequencies.*' => 'in:kila_siku,kila_wiki,kila_mwezi',
                'status' => 'sometimes|in:active,inactive,completed,terminated',
            ]);
            
            // Update the agreement
            $agreement->update($validatedData);
            
            // Load relationships
            $agreement->load(['driver', 'creator']);
            
            return response()->json([
                'success' => true,
                'data' => $agreement,
                'message' => 'Driver agreement updated successfully'
            ]);
        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Driver agreement not found'
            ], 404);
        } catch (\Illuminate\Validation\ValidationException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $e->errors()
            ], 422);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error updating driver agreement: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Remove the specified driver agreement
     */
    public function destroy(string $id): JsonResponse
    {
        try {
            $agreement = DriverAgreement::findOrFail($id);
            $agreement->delete();
            
            return response()->json([
                'success' => true,
                'message' => 'Driver agreement deleted successfully'
            ]);
        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Driver agreement not found'
            ], 404);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error deleting driver agreement: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Get driver agreement by driver ID
     */
    public function getByDriver(string $driverId): JsonResponse
    {
        try {
            $agreement = DriverAgreement::with(['driver', 'creator'])
                ->where('driver_id', $driverId)
                ->where('status', 'active')
                ->first();
            
            if (!$agreement) {
                return response()->json([
                    'success' => false,
                    'message' => 'No active agreement found for this driver'
                ], 404);
            }
            
            return response()->json([
                'success' => true,
                'data' => $agreement,
                'message' => 'Driver agreement retrieved successfully'
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error retrieving driver agreement: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Calculate preview of faida jumla for kwa_mkataba agreements
     */
    public function calculatePreview(Request $request): JsonResponse
    {
        try {
            $validatedData = $request->validate([
                'agreement_type' => 'required|in:kwa_mkataba',
                'start_date' => 'required|date',
                'end_date' => 'required|date|after:start_date',
                'kiasi_cha_makubaliano' => 'required|numeric|min:0',
                'wikendi_zinahesabika' => 'boolean',
                'jumamosi' => 'boolean',
                'jumapili' => 'boolean',
            ]);
            
            // Create a temporary agreement to calculate faida_jumla
            $tempAgreement = new DriverAgreement($validatedData);
            $tempAgreement->calculateFaidaJumla();
            
            return response()->json([
                'success' => true,
                'data' => [
                    'faida_jumla' => $tempAgreement->faida_jumla,
                    'total_days' => Carbon::parse($validatedData['start_date'])
                        ->diffInDays(Carbon::parse($validatedData['end_date'])) + 1
                ],
                'message' => 'Faida jumla calculated successfully'
            ]);
        } catch (\Illuminate\Validation\ValidationException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $e->errors()
            ], 422);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error calculating faida jumla: ' . $e->getMessage()
            ], 500);
        }
    }
}
