<?php

namespace App\Http\Controllers\API\Inventory;

use App\Services\Inventory\AuditTrail;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Routing\Controller;
use OpenApi\Attributes as OA;

class CustomerController extends Controller
{
    public function __construct(private readonly AuditTrail $audit)
    {
    }

    #[OA\Get(

        path: '/customers',

        summary: 'List resources',

        security: [['bearerAuth' => []]],

        tags: ['Inventory / Customer'],
        parameters: [
            new OA\Parameter(name: 'q', in: 'query', schema: new OA\Schema(type: 'string')),
        ],

        responses: [new OA\Response(response: 200, description: 'Success')],

    )]

    public function index(Request $request)
    {
        $q = $request->query('q');
        $query = DB::table('inventory_customers');
        if ($q) {
            $query->where(function($w) use ($q) {
                $w->where('name','like',"%$q%")
                  ->orWhere('phone','like',"%$q%");
            });
        }
        $customers = $query->orderByDesc('id')->paginate(20);
        return response()->json([
            'data' => $customers->items(),
            'meta' => [
                'current_page' => $customers->currentPage(),
                'last_page' => $customers->lastPage(),
                'per_page' => $customers->perPage(),
                'total' => $customers->total(),
            ],
        ]);
    }

    #[OA\Post(

        path: '/inventory/customers',

        summary: 'Create a resource',

        security: [['bearerAuth' => []]],

        tags: ['Inventory / Customer'],

                requestBody: new OA\RequestBody(
            required: true,
            content: new OA\JsonContent(
            required: ['name', 'phone'],
                properties: [
                new OA\Property(property: 'name', type: 'string'),
                new OA\Property(property: 'phone', type: 'string'),
                new OA\Property(property: 'address', type: 'string', nullable: true),
                ],
            ),
        ),
responses: [new OA\Response(response: 200, description: 'Success')],

    )]

    public function store(Request $request)
    {
        $data = $request->validate([
            'name' => 'required|string|max:255',
            'phone' => 'required|string|max:32',
            'address' => 'nullable|string|max:255',
        ]);
        $id = DB::table('inventory_customers')->insertGetId([
            'name' => $data['name'],
            'phone' => $data['phone'],
            'address' => $data['address'] ?? null,
            'created_at' => now(),
            'updated_at' => now(),
        ]);
        return response()->json(['message' => 'Customer created', 'data' => ['id' => (int)$id]], 201);
    }

    #[OA\Put(

        path: '/inventory/customers/{id}',

        summary: 'Update a resource',

        security: [['bearerAuth' => []]],

        tags: ['Inventory / Customer'],

        parameters: [

            new OA\Parameter(name: 'id', in: 'path', required: true, schema: new OA\Schema(type: 'string')),

        ],

                requestBody: new OA\RequestBody(
            required: true,
            content: new OA\JsonContent(
            required: ['name', 'phone'],
                properties: [
                new OA\Property(property: 'name', type: 'string'),
                new OA\Property(property: 'phone', type: 'string'),
                new OA\Property(property: 'address', type: 'string', nullable: true),
                ],
            ),
        ),
responses: [new OA\Response(response: 200, description: 'Success')],

    )]

    public function update(Request $request, int $id)
    {
        $exists = DB::table('inventory_customers')->where('id', $id)->exists();
        if (!$exists) return response()->json(['message' => 'Not found'], 404);

        $data = $request->validate([
            'name' => 'sometimes|required|string|max:255',
            'phone' => 'sometimes|required|string|max:32',
            'address' => 'nullable|string|max:255',
        ]);
        DB::table('inventory_customers')->where('id', $id)->update(array_merge($data, [
            'updated_at' => now(),
        ]));
        $this->audit->record($request, 'customer', $id, 'updated', [], $data, $data['name'] ?? '');
        return response()->json(['message' => 'Customer updated']);
    }

    /**
     * DELETE /inventory/customers/{id}
     *
     * Blocked if the customer has any active sales (debt/partial).
     * Pass ?force=1 (admin-only) to override.
     */
    #[OA\Delete(
        path: '/inventory/customers/{id}',
        summary: 'Delete a resource',
        security: [['bearerAuth' => []]],
        tags: ['Inventory / Customer'],
        parameters: [
            new OA\Parameter(name: 'id', in: 'path', required: true, schema: new OA\Schema(type: 'string')),
        ],
        responses: [new OA\Response(response: 200, description: 'Success')],
    )]
    public function destroy(Request $request, int $id)
    {
        $existing = DB::table('inventory_customers')->where('id', $id)->first();
        if (! $existing) {
            return response()->json(['message' => 'Not found'], 404);
        }

        $force       = filter_var($request->query('force', false), FILTER_VALIDATE_BOOLEAN);
        $hasOpenDebt = DB::table('inventory_sales')
            ->where('customer_id', $id)
            ->whereIn('payment_status', ['debt', 'partial'])
            ->whereNull('cancelled_at')
            ->exists();

        if ($hasOpenDebt && ! $force) {
            return response()->json([
                'message' => 'Customer has outstanding debt. Settle all balances first, or pass ?force=1.',
            ], 422);
        }

        if ($force) {
            $user = $request->user();
            if (! $user || ! ($user->isSuperAdmin() || in_array($user->role, ['admin', 'manager']) || $user->full_access)) {
                return response()->json(['message' => 'Only admins may force-delete a customer with open debt.'], 403);
            }
        }

        // Nullify FK on sales (keep sale records, customer becomes anonymous)
        DB::table('inventory_sales')->where('customer_id', $id)->update([
            'customer_id'            => null,
            'customer_name_override' => $existing->name,
            'customer_phone_override'=> $existing->phone,
            'updated_at'             => now(),
        ]);
        DB::table('inventory_customers')->where('id', $id)->delete();

        $this->audit->record($request, 'customer', $id, 'deleted', (array) $existing, null, $existing->name);

        return response()->json(['message' => 'Customer deleted']);
    }
}
