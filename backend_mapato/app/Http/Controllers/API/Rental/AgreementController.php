<?php

namespace App\Http\Controllers\API\Rental;

use App\Http\Controllers\Controller;
use App\Models\Rental\RentalAgreement;
use App\Models\Rental\House;
use App\Models\User;
use App\Services\Rental\RentalService;
use App\Helpers\ResponseHelper;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class AgreementController extends Controller
{
    protected RentalService $rentalService;

    public function __construct(RentalService $rentalService)
    {
        $this->rentalService = $rentalService;
    }

    /**
     * List all agreements for the landlord's properties.
     */
    public function index(Request $request)
    {
        $query = RentalAgreement::whereHas('house.property', function($q) use ($request) {
            $q->where('owner_id', $request->user()->id);
        })->with('tenant', 'house.property', 'house.block');

        // Filter by status
        if ($request->status) {
            $query->where('status', $request->status);
        }

        // Search by tenant name or house number
        if ($request->search) {
            $search = $request->search;
            $query->where(function($q) use ($search) {
                $q->whereHas('tenant', function($sq) use ($search) {
                    $sq->where('name', 'like', "%{$search}%");
                })->orWhereHas('house', function($sq) use ($search) {
                    $sq->where('house_number', 'like', "%{$search}%");
                });
            });
        }

        // Expiring soon filter
        if ($request->expiring_soon) {
            $query->where('status', 'active')
                  ->where('end_date', '>=', now())
                  ->where('end_date', '<=', now()->addDays(30));
        }

        $perPage = $request->get('per_page', 15);
        return ResponseHelper::paginate($query->orderBy('created_at', 'desc')->paginate($perPage));
    }

    /**
     * Get single agreement with full details.
     */
    public function show(Request $request, string $id)
    {
        $agreement = RentalAgreement::whereHas('house.property', function($q) use ($request) {
            $q->where('owner_id', $request->user()->id);
        })->with('tenant', 'tenant.profile', 'house.property', 'house.block', 'bills', 'payments.receipt')->findOrFail($id);

        return ResponseHelper::success($agreement);
    }

    /**
     * Create a new agreement.
     */
    public function store(Request $request)
    {
        $request->validate([
            'tenant_id' => 'required|exists:users,id',
            'house_id' => 'required|exists:rental_houses,id',
            'start_date' => 'required|date',
            'end_date' => 'required|date|after:start_date',
            'rent_amount' => 'required|numeric|min:0',
            'deposit_paid' => 'sometimes|numeric|min:0',
            'rent_cycle' => 'sometimes|in:monthly,quarterly,yearly',
            'terms' => 'nullable|string|max:2000',
            'notes' => 'nullable|string|max:1000',
            'notice_period_days' => 'sometimes|integer|min:0',
            'auto_renew' => 'sometimes|boolean',
            'penalty_per_day' => 'sometimes|numeric|min:0',
        ]);

        // Verify property ownership
        $house = House::whereHas('property', function($q) use ($request) {
            $q->where('owner_id', $request->user()->id);
        })->findOrFail($request->house_id);

        if ($house->status !== 'vacant') {
            return ResponseHelper::error('House is not vacant', 400);
        }

        $agreement = DB::transaction(function () use ($request, $house) {
            $agreement = RentalAgreement::create([
                'tenant_id' => $request->tenant_id,
                'house_id' => $request->house_id,
                'start_date' => $request->start_date,
                'end_date' => $request->end_date,
                'rent_amount' => $request->rent_amount,
                'deposit_paid' => $request->deposit_paid ?? 0,
                'rent_cycle' => $request->rent_cycle ?? 'monthly',
                'status' => 'active',
                'terms' => $request->terms,
                'notes' => $request->notes,
                'notice_period_days' => $request->notice_period_days ?? 30,
                'auto_renew' => $request->auto_renew ?? false,
                'penalty_per_day' => $request->penalty_per_day ?? 0,
            ]);

            // Mark house as occupied
            $house->update([
                'status' => 'occupied',
                'current_tenant_id' => $request->tenant_id,
            ]);

            // Generate first bill
            $this->rentalService->generateBillForAgreement($agreement);

            return $agreement;
        });

        return ResponseHelper::success($agreement->load('tenant', 'house'), 'Agreement created', 201);
    }

    /**
     * Renew an agreement (extend end date).
     */
    public function renew(Request $request, string $id)
    {
        $agreement = RentalAgreement::whereHas('house.property', function($q) use ($request) {
            $q->where('owner_id', $request->user()->id);
        })->findOrFail($id);

        $request->validate([
            'new_end_date' => 'required|date|after:end_date',
            'new_rent_amount' => 'sometimes|numeric|min:0',
        ]);

        $agreement->update([
            'status' => 'active',
            'end_date' => $request->new_end_date,
            'rent_amount' => $request->new_rent_amount ?? $agreement->rent_amount,
            'renewal_date' => now(),
        ]);

        return ResponseHelper::success($agreement, 'Agreement renewed successfully');
    }

    /**
     * Terminate an agreement early.
     */
    public function terminate(Request $request, string $id)
    {
        $agreement = RentalAgreement::whereHas('house.property', function($q) use ($request) {
            $q->where('owner_id', $request->user()->id);
        })->findOrFail($id);

        $request->validate([
            'termination_reason' => 'required|string|max:500',
        ]);

        DB::transaction(function () use ($agreement, $request) {
            $agreement->update([
                'status' => 'terminated',
                'notes' => $request->termination_reason . ($agreement->notes ? "\n" . $agreement->notes : ''),
            ]);

            // Free up the house
            $agreement->house->update([
                'status' => 'vacant',
                'current_tenant_id' => null,
            ]);
        });

        return ResponseHelper::success($agreement, 'Agreement terminated');
    }

    /**
     * Upload document to an agreement.
     */
    public function uploadDocument(Request $request, string $id)
    {
        $agreement = RentalAgreement::whereHas('house.property', function($q) use ($request) {
            $q->where('owner_id', $request->user()->id);
        })->findOrFail($id);

        $request->validate([
            'document' => 'required|file|mimes:pdf,jpg,png|max:10240',
            'document_type' => 'required|in:signed_contract,id_card,receipt,other',
        ]);

        // Store the document
        $path = $request->file('document')->store('agreements/' . $agreement->id, 'public');

        $documents = $agreement->documents ?? [];
        $documents[] = [
            'type' => $request->document_type,
            'path' => $path,
            'name' => $request->file('document')->getClientOriginalName(),
            'uploaded_at' => now()->toDateTimeString(),
        ];

        $agreement->update(['documents' => $documents]);

        return ResponseHelper::success($agreement, 'Document uploaded');
    }

    /**
     * Get expiring agreements for notifications.
     */
    public function getExpiring(Request $request)
    {
        $agreements = RentalAgreement::whereHas('house.property', function($q) use ($request) {
            $q->where('owner_id', $request->user()->id);
        })->where('status', 'active')
          ->where('end_date', '>=', now())
          ->where('end_date', '<=', now()->addDays(30))
          ->with('tenant', 'house')
          ->get();

        return ResponseHelper::success($agreements);
    }
}