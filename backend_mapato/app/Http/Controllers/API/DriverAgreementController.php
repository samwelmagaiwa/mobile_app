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
                // Accept any id shape; resolve to actual driver below
                'driver_id' => 'required',
                'agreement_type' => 'required|in:kwa_mkataba,dei_waka',
                'start_date' => 'required|date',
                'end_date' => 'sometimes|nullable|date|after:start_date',
                'weekends_countable' => 'boolean',
                'saturday_included' => 'boolean',
                'sunday_included' => 'boolean',
                'payment_frequencies' => 'required|array|min:1',
                // Accept both Swahili and English frequency tokens
                'payment_frequencies.*' => [
                    Rule::in(['kila_siku','kila_wiki','kila_mwezi','daily','weekly','monthly'])
                ],
                'notes' => 'nullable|string',
                // Accept either detailed contract fields OR a single agreed amount
                'vehicle_payment' => 'sometimes|numeric|min:0',
                'daily_target' => 'sometimes|numeric|min:0',
                'contract_period_months' => 'sometimes|integer|min:1',
                // Daily work fields (dei_waka)
                'salary_amount' => 'sometimes|numeric|min:0',
                'bonus_amount' => 'nullable|numeric|min:0',
                // Alternate amount field from mobile app
                'kiasi_cha_makubaliano' => 'sometimes|numeric|min:0',
                'agreed_amount' => 'sometimes|numeric|min:0',
                'total_profit' => 'sometimes|numeric|min:0',
            ]);
            
            // Resolve driver id: accept drivers.id or users.id
            $inputDriverId = (string) $validatedData['driver_id'];
            $resolvedDriver = Driver::where('id', $inputDriverId)
                ->orWhere('user_id', $inputDriverId)
                ->first();
            if (!$resolvedDriver) {
                return response()->json([
                    'success' => false,
                    'message' => 'The selected driver id is invalid.',
                    'errors' => ['driver_id' => ['The selected driver id is invalid.']],
                ], 422);
            }
            $validatedData['driver_id'] = $resolvedDriver->id;

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

            // Normalize payment frequencies to kila_* tokens
            $freqs = collect($request->input('payment_frequencies', []))->map(function($f) {
                return match(strtolower((string)$f)) {
                    'daily' => 'kila_siku',
                    'weekly' => 'kila_wiki',
                    'monthly' => 'kila_mwezi',
                    default => strtolower((string)$f),
                };
            })->unique()->values()->all();
            $validatedData['payment_frequencies'] = $freqs;
            
            // Calculate kiasi_cha_makubaliano based on agreement type, accepting alternate fields
            if ($validatedData['agreement_type'] === 'kwa_mkataba') {
                // Prefer explicit daily_target; fall back to agreed_amount/kiasi_cha_makubaliano
                $validatedData['kiasi_cha_makubaliano'] = $validatedData['daily_target']
                    ?? $validatedData['kiasi_cha_makubaliano']
                    ?? $request->input('agreed_amount', 0);

                // If end_date provided by app, use it; otherwise compute from contract_period_months
                if (!empty($validatedData['end_date'])) {
                    $endDate = Carbon::parse($validatedData['end_date']);
                } else {
                    $startDate = Carbon::parse($validatedData['start_date']);
                    $contractMonths = $validatedData['contract_period_months'] ?? 1;
                    $endDate = $startDate->copy()->addMonths($contractMonths);
                    $validatedData['end_date'] = $endDate->format('Y-m-d');
                }
                $validatedData['mwaka_atamaliza'] = Carbon::parse($validatedData['end_date'])->format('Y');
            } else {
                // Dei waka: prefer salary_amount; fallback to agreed_amount/kiasi_cha_makubaliano
                $validatedData['kiasi_cha_makubaliano'] = $validatedData['salary_amount']
                    ?? $validatedData['kiasi_cha_makubaliano']
                    ?? $request->input('agreed_amount', 0);
            }
            
            // Set created_by to current authenticated user or best available fallback
            $creatorId = Auth::id();
            if (!$creatorId && method_exists($resolvedDriver, 'user')) {
                $creatorId = optional($resolvedDriver->user)->created_by;
            }
            // Final fallback for dev/test environments where auth is not enabled
            $validatedData['created_by'] = $creatorId ?: 1;
            
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

            // Return 200 with null data if no active agreement instead of 404
            if (!$agreement) {
                return response()->json([
                    'success' => true,
                    'data' => null,
                    'message' => 'No active agreement found for this driver'
                ], 200);
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
