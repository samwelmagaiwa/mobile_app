<?php

namespace App\Http\Controllers\API\Rental;

use App\Http\Controllers\Controller;
use App\Models\Rental\MaintenanceRequest;
use App\Models\Rental\WorkOrder;
use App\Models\Rental\Vendor;
use App\Models\Rental\PreventiveMaintenance;
use App\Models\Rental\Property;
use App\Http\Resources\MaintenanceRequestResource;
use App\Http\Resources\WorkOrderResource;
use App\Http\Resources\VendorResource;
use App\Helpers\ResponseHelper;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Carbon;

class MaintenanceController extends Controller
{
    /**
     * List all maintenance requests.
     */
    public function index(Request $request)
    {
        $user = $request->user();
        $query = MaintenanceRequest::with(['property', 'house', 'tenant', 'workOrder.vendor']);

        // Landlord/Admin see their properties' requests
        if ($user->role === 'admin') {
            $query->whereHas('property', function ($q) use ($user) {
                $q->where('owner_id', $user->id);
            });
        } else {
            // Tenants see only their requests
            $query->where('tenant_id', $user->id);
        }

        if ($request->has('status')) {
            $query->where('status', $request->status);
        }

        if ($request->has('property_id')) {
            $query->where('property_id', $request->property_id);
        }

        $requests = $query->latest()->paginate($request->get('per_page', 15));

        return ResponseHelper::paginate($requests, MaintenanceRequestResource::class);
    }

    /**
     * Store a new maintenance request.
     */
    public function store(Request $request)
    {
        $request->validate([
            'property_id' => 'required|exists:rental_properties,id',
            'house_id' => 'nullable|exists:rental_houses,id',
            'category' => 'required|string',
            'priority' => 'required|in:low,medium,high,emergency',
            'description' => 'required|string',
            'photo' => 'nullable|image|max:5120', // 5MB max
        ]);

        $data = $request->all();
        $data['tenant_id'] = $request->user()->id;
        $data['status'] = 'open';

        if ($request->hasFile('photo')) {
            $path = $request->file('photo')->store('maintenance', 'public');
            $data['photo_url'] = $path;
        }

        $maintenanceRequest = MaintenanceRequest::create($data);

        return ResponseHelper::success(
            new MaintenanceRequestResource($maintenanceRequest),
            'Ombi la matengenezo limepokelewa',
            201
        );
    }

    /**
     * Show a single maintenance request.
     */
    public function show(string $id)
    {
        $maintenanceRequest = MaintenanceRequest::with(['property', 'house', 'tenant', 'workOrder.vendor'])
            ->findOrFail($id);

        return ResponseHelper::success(new MaintenanceRequestResource($maintenanceRequest));
    }

    /**
     * Assign a vendor and create a work order.
     */
    public function assign(Request $request, string $id)
    {
        $maintenanceRequest = MaintenanceRequest::findOrFail($id);

        $request->validate([
            'vendor_id' => 'required|exists:rental_vendors,id',
            'title' => 'required|string',
            'instructions' => 'nullable|string',
            'estimated_cost' => 'nullable|numeric|min:0',
            'scheduled_date' => 'nullable|date',
        ]);

        $workOrder = WorkOrder::updateOrCreate(
            ['maintenance_request_id' => $id],
            [
                'vendor_id' => $request->vendor_id,
                'title' => $request->title,
                'instructions' => $request->instructions,
                'estimated_cost' => $request->estimated_cost ?? 0,
                'scheduled_date' => $request->scheduled_date,
                'status' => 'scheduled',
            ]
        );

        $maintenanceRequest->update(['status' => 'pending']);

        return ResponseHelper::success(
            new WorkOrderResource($workOrder->load('vendor')),
            'Fundi amepangiwa kazi'
        );
    }

    /**
     * Update request/work order status.
     */
    public function updateStatus(Request $request, string $id)
    {
        $maintenanceRequest = MaintenanceRequest::findOrFail($id);

        $request->validate([
            'status' => 'required|in:open,pending,in_progress,resolved,cancelled',
            'actual_cost' => 'nullable|numeric|min:0',
            'completion_date' => 'nullable|date',
        ]);

        $maintenanceRequest->update([
            'status' => $request->status,
            'resolved_at' => $request->status === 'resolved' ? now() : $maintenanceRequest->resolved_at,
        ]);

        if ($maintenanceRequest->workOrder) {
            $woStatus = match ($request->status) {
                'resolved' => 'completed',
                'cancelled' => 'cancelled',
                'in_progress' => 'in_progress',
                default => $maintenanceRequest->workOrder->status
            };

            $maintenanceRequest->workOrder->update([
                'status' => $woStatus,
                'actual_cost' => $request->actual_cost ?? $maintenanceRequest->workOrder->actual_cost,
                'completion_date' => $request->completion_date ?? $maintenanceRequest->workOrder->completion_date,
            ]);
        }

        return ResponseHelper::success(
            new MaintenanceRequestResource($maintenanceRequest->load('workOrder')),
            'Hali imesasishwa'
        );
    }

    /**
     * Vendor management methods.
     */
    public function getVendors(Request $request)
    {
        $vendors = Vendor::where('is_active', true)->get();
        return ResponseHelper::success(VendorResource::collection($vendors));
    }

    public function storeVendor(Request $request)
    {
        $request->validate([
            'name' => 'required|string',
            'phone' => 'required|string',
            'specialty' => 'nullable|string',
            'business_name' => 'nullable|string',
        ]);

        $vendor = Vendor::create($request->all());
        return ResponseHelper::success(new VendorResource($vendor), 'Fundi ameongezwa', 201);
    }

    /**
     * Preventive Maintenance methods.
     */
    public function getPreventive(Request $request)
    {
        $ownerId = $request->user()->id;
        $schedules = PreventiveMaintenance::whereHas('property', function ($q) use ($ownerId) {
            $q->where('owner_id', $ownerId);
        })->with(['property', 'house'])->get();

        return ResponseHelper::success($schedules);
    }

    public function storePreventive(Request $request)
    {
        $request->validate([
            'property_id' => 'required|exists:rental_properties,id',
            'house_id' => 'nullable|exists:rental_houses,id',
            'description' => 'required|string',
            'frequency' => 'required|in:monthly,quarterly,semi_annual,annual',
            'next_run' => 'required|date',
        ]);

        $pm = PreventiveMaintenance::create($request->all());
        return ResponseHelper::success($pm, 'Ratiba imepangwa', 201);
    }
}
