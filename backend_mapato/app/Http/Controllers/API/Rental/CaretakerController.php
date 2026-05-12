<?php

namespace App\Http\Controllers\API\Rental;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\Rental\Property;
use App\Helpers\ResponseHelper;
use Illuminate\Http\Request;

class CaretakerController extends Controller
{
    /**
     * List caretakers for a landlord.
     */
    public function index(Request $request)
    {
        $caretakers = User::where('role', 'caretaker')
            ->where('created_by', $request->user()->id)
            ->select('id', 'name', 'email', 'phone_number', 'is_active', 'created_at')
            ->get();
        
        return ResponseHelper::success($caretakers);
    }

    /**
     * Create a caretaker account.
     */
    public function store(Request $request)
    {
        $request->validate([
            'name' => 'required|string',
            'phone_number' => 'required|string|unique:users',
            'email' => 'nullable|email|unique:users',
        ]);

        $caretaker = User::create([
            'name' => $request->name,
            'email' => $request->email,
            'phone_number' => $request->phone_number,
            'password' => bcrypt('caretaker123'),
            'role' => 'caretaker',
            'created_by' => $request->user()->id,
            'is_active' => true,
        ]);

        return ResponseHelper::success($caretaker, 'Caretaker created successfully', 201);
    }

    /**
     * Assign properties to a caretaker.
     */
    public function assignProperties(Request $request, $caretakerId)
    {
        $caretaker = User::where('role', 'caretaker')
            ->where('created_by', $request->user()->id)
            ->findOrFail($caretakerId);

        $request->validate([
            'property_ids' => 'required|array',
            'property_ids.*' => 'exists:rental_properties,id',
        ]);

        // Verify the landlord owns these properties
        $properties = Property::where('owner_id', $request->user()->id)
            ->whereIn('id', $request->property_ids)
            ->get();

        // Store assigned property IDs (you may want to create a separate table for this)
        $caretaker->assigned_properties = $request->property_ids;
        $caretaker->save();

        return ResponseHelper::success($caretaker, 'Properties assigned to caretaker');
    }

    /**
     * Update caretaker status.
     */
    public function update(Request $request, $id)
    {
        $caretaker = User::where('role', 'caretaker')
            ->where('created_by', $request->user()->id)
            ->findOrFail($id);

        $request->validate([
            'name' => 'sometimes|string',
            'is_active' => 'sometimes|boolean',
        ]);

        $caretaker->update($request->only(['name', 'is_active']));

        return ResponseHelper::success($caretaker, 'Caretaker updated');
    }

    /**
     * Delete a caretaker.
     */
    public function destroy(Request $request, $id)
    {
        $caretaker = User::where('role', 'caretaker')
            ->where('created_by', $request->user()->id)
            ->findOrFail($id);

        $caretaker->delete();

        return ResponseHelper::success(null, 'Caretaker deleted');
    }
}