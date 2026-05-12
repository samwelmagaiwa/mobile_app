<?php

namespace App\Http\Controllers\API\Rental;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\Rental\TenantProfile;
use App\Models\Rental\RentalAgreement;
use App\Models\Rental\RentBill;
use App\Models\Rental\RentalPayment;
use App\Models\Rental\RentalReceipt;
use App\Models\Rental\House;
use App\Services\Rental\RentalService;
use App\Services\SmsService;
use App\Helpers\ResponseHelper;
use Illuminate\Http\Request;

class TenantController extends Controller
{
    protected $rentalService;

    public function __construct(RentalService $rentalService)
    {
        $this->rentalService = $rentalService;
    }

    /**
     * List all tenants for landlord's properties.
     */
    public function index(Request $request)
    {
        $user = $request->user();
        
        $agreements = RentalAgreement::whereHas('house.property', function($query) use ($user) {
            $query->where('owner_id', $user->id);
        })->with('tenant.profile', 'house.property', 'house.block')->get();
        
        $tenants = $agreements->map(function($agreement) {
            return [
                'id' => $agreement->tenant->id,
                'name' => $agreement->tenant->name,
                'email' => $agreement->tenant->email,
                'phone_number' => $agreement->tenant->phone_number,
                'profile' => $agreement->tenant->profile,
                'house' => [
                    'id' => $agreement->house->id,
                    'house_number' => $agreement->house->house_number,
                    'property_name' => $agreement->house->property->name,
                    'block_name' => $agreement->house->block?->name,
                    'rent_amount' => $agreement->rent_amount,
                ],
                'agreement' => [
                    'id' => $agreement->id,
                    'start_date' => $agreement->start_date,
                    'end_date' => $agreement->end_date,
                    'rent_cycle' => $agreement->rent_cycle,
                    'status' => $agreement->status,
                    'rent_amount' => $agreement->rent_amount,
                ],
            ];
        });
        
        return ResponseHelper::success($tenants);
    }

    /**
     * Show single tenant details.
     */
    public function show(Request $request, $id)
    {
        $agreement = RentalAgreement::whereHas('house.property', function($query) use ($request) {
            $query->where('owner_id', $request->user()->id);
        })->where('tenant_id', $id)
        ->with('tenant.profile', 'house.property', 'house.block', 'bills', 'payments.receipt')
        ->firstOrFail();
        
        return ResponseHelper::success([
            'tenant' => $agreement->tenant,
            'profile' => $agreement->tenant->profile,
            'house' => $agreement->house,
            'agreement' => $agreement,
            'bills' => $agreement->bills,
            'payments' => $agreement->payments,
        ]);
    }

    /**
     * Onboard a new tenant.
     */
    public function onboard(Request $request)
    {
        $request->validate([
            'name' => 'required|string',
            'email' => 'required|email',
            'phone_number' => 'required|string',
            'house_id' => 'required|exists:rental_houses,id',
            'rent_amount' => 'required|numeric',
            'rent_cycle' => 'sometimes|in:monthly,quarterly,semi_annual,annual',
            'start_date' => 'sometimes|date',
            'deposit_paid' => 'sometimes|numeric',
            'id_number' => 'nullable|string',
            'occupation' => 'nullable|string',
            'emergency_contact_name' => 'nullable|string',
            'emergency_contact_phone' => 'nullable|string',
        ]);

        try {
            $result = $this->rentalService->onboardTenant($request->all());
            
            // Send welcome SMS
            $house = House::find($request->house_id);
            SmsService::sendTenantWelcome($result['user'], $house);
            
            return ResponseHelper::success($result, 'Tenant onboarded successfully', 201);
        } catch (\Exception $e) {
            return ResponseHelper::error($e->getMessage(), 500);
        }
    }

    /**
     * Update tenant status (active, notice, terminated, defaulter).
     */
    public function updateStatus(Request $request, $id)
    {
        $request->validate([
            'status' => 'required|in:active,notice,terminated,defaulter',
        ]);

        $agreement = RentalAgreement::whereHas('house.property', function($query) use ($request) {
            $query->where('owner_id', $request->user()->id);
        })->where('tenant_id', $id)->firstOrFail();

        $agreement->update(['status' => $request->status]);
        
        // If terminated, free up the house
        if ($request->status === 'terminated') {
            $agreement->house->update(['status' => 'vacant', 'current_tenant_id' => null]);
        }
        
        return ResponseHelper::success($agreement, 'Tenant status updated');
    }

    /**
     * Terminate tenant (delete agreement).
     */
    public function terminate(Request $request, $id)
    {
        $agreement = RentalAgreement::whereHas('house.property', function($query) use ($request) {
            $query->where('owner_id', $request->user()->id);
        })->where('tenant_id', $id)->firstOrFail();

        // Free up the house
        $agreement->house->update(['status' => 'vacant', 'current_tenant_id' => null]);
        
        // Delete the agreement
        $agreement->delete();
        
        return ResponseHelper::success(null, 'Tenant terminated successfully');
    }

    // ========== Tenant Self-Service Endpoints ==========

    /**
     * Get tenant's own bills.
     */
    public function myBills(Request $request)
    {
        $bills = RentBill::whereHas('agreement', function($query) use ($request) {
            $query->where('tenant_id', $request->user()->id);
        })->with('agreement.house.property')->get();
        
        return ResponseHelper::success($bills);
    }

    /**
     * Get tenant's own payments.
     */
    public function myPayments(Request $request)
    {
        $payments = RentalPayment::where('tenant_id', $request->user()->id)
            ->with('bill.agreement.house', 'receipt', 'collector')
            ->orderBy('payment_date', 'desc')
            ->get();
        
        return ResponseHelper::success($payments);
    }

    /**
     * Get tenant's own receipts.
     */
    public function myReceipts(Request $request)
    {
        $receipts = RentalReceipt::whereHas('payment', function($query) use ($request) {
            $query->where('tenant_id', $request->user()->id);
        })->orderBy('created_at', 'desc')->get();
        
        return ResponseHelper::success($receipts);
    }
}