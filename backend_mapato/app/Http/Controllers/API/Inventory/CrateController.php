<?php

namespace App\Http\Controllers\API\Inventory;

use App\Services\Inventory\AuditTrail;
use App\Services\Inventory\CrateLedgerService;
use Illuminate\Http\Request;
use Illuminate\Routing\Controller;
use Illuminate\Support\Facades\DB;
use InvalidArgumentException;
use OpenApi\Attributes as OA;

/**
 * Area 8 — crates and empty bottles.
 *
 * A double-entry ledger (see CrateLedgerService), kept entirely separate from
 * money owed: a customer holding 20 crates is not the same as a customer
 * owing cash.
 */
class CrateController extends Controller
{
    public function __construct(
        private readonly AuditTrail $audit,
        private readonly CrateLedgerService $ledger,
    ) {
    }

    #[OA\Get(

        path: '/inventory/crate-types',

        summary: 'Types',

        security: [['bearerAuth' => []]],

        tags: ['Inventory / Crate'],

        responses: [new OA\Response(response: 200, description: 'Success')],

    )]

    public function types()
    {
        return response()->json([
            'data' => DB::table('inventory_crate_types')->orderBy('name')->get(),
        ]);
    }

    #[OA\Post(

        path: '/inventory/crate-types',

        summary: 'Store type',

        security: [['bearerAuth' => []]],

        tags: ['Inventory / Crate'],

                requestBody: new OA\RequestBody(
            required: true,
            content: new OA\JsonContent(
            required: ['name', 'deposit_value'],
                properties: [
                new OA\Property(property: 'name', type: 'string'),
                new OA\Property(property: 'deposit_value', type: 'number'),
                new OA\Property(property: 'status', type: 'string', enum: ['active', 'inactive'], nullable: true),
                ],
            ),
        ),
responses: [new OA\Response(response: 200, description: 'Success')],

    )]

    public function storeType(Request $request)
    {
        $data = $request->validate([
            'name' => 'required|string|max:255|unique:inventory_crate_types,name',
            'deposit_value' => 'required|numeric|min:0',
            'status' => 'nullable|in:active,inactive',
        ]);

        $id = DB::table('inventory_crate_types')->insertGetId([
            'name' => $data['name'],
            'deposit_value' => $data['deposit_value'],
            'status' => $data['status'] ?? 'active',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        return response()->json(['message' => 'Crate type created', 'data' => ['id' => (int) $id]], 201);
    }

    /** Record crates going out, coming back, broken, or bought outright. */
    #[OA\Post(
        path: '/inventory/crate-movements',
        summary: 'Move',
        security: [['bearerAuth' => []]],
        tags: ['Inventory / Crate'],
                requestBody: new OA\RequestBody(
            required: true,
            content: new OA\JsonContent(
            required: ['crate_type_id', 'direction', 'quantity'],
                properties: [
                new OA\Property(property: 'crate_type_id', type: 'integer'),
                new OA\Property(property: 'customer_id', type: 'integer', nullable: true),
                new OA\Property(property: 'direction', type: 'string', enum: ['issued', 'returned', 'broken', 'purchased']),
                new OA\Property(property: 'quantity', type: 'integer'),
                new OA\Property(property: 'reference', type: 'string', nullable: true),
                new OA\Property(property: 'note', type: 'string', nullable: true),
                ],
            ),
        ),
responses: [new OA\Response(response: 200, description: 'Success')],
    )]
    public function move(Request $request)
    {
        $data = $request->validate([
            'crate_type_id' => 'required|integer|exists:inventory_crate_types,id',
            'customer_id' => 'nullable|integer|exists:inventory_customers,id',
            'direction' => 'required|in:issued,returned,broken,purchased',
            'quantity' => 'required|integer|min:1',
            'reference' => 'nullable|string|max:255',
            'note' => 'nullable|string|max:255',
        ]);

        try {
            $ids = $this->ledger->post(
                $data['crate_type_id'],
                $data['direction'],
                $data['quantity'],
                $data['customer_id'] ?? null,
                $data['reference'] ?? null,
                $data['note'] ?? null,
                optional($request->user())->id,
            );
        } catch (InvalidArgumentException $e) {
            return response()->json(['message' => $e->getMessage()], 422);
        }

        $this->audit->record($request, 'crate_movement', $ids[0], $data['direction'], null, $data);

        return response()->json(['message' => 'Crate movement recorded', 'data' => ['ids' => $ids]], 201);
    }

    #[OA\Get(

        path: '/inventory/crate-movements',

        summary: 'Movements',

        security: [['bearerAuth' => []]],

        tags: ['Inventory / Crate'],
        parameters: [
            new OA\Parameter(name: 'customer_id', in: 'query', schema: new OA\Schema(type: 'string')),
            new OA\Parameter(name: 'direction', in: 'query', schema: new OA\Schema(type: 'string')),
        ],

        responses: [new OA\Response(response: 200, description: 'Success')],

    )]

    public function movements(Request $request)
    {
        $query = DB::table('inventory_crate_movements as m')
            ->join('inventory_crate_types as t', 't.id', '=', 'm.crate_type_id')
            ->leftJoin('inventory_customers as c', 'c.id', '=', 'm.customer_id')
            ->where('m.party_type', 'customer')
            ->select('m.*', 't.name as crate_type_name', 'c.name as customer_name');

        if ($customerId = $request->query('customer_id')) {
            $query->where('m.customer_id', (int) $customerId);
        }
        if ($direction = $request->query('direction')) {
            $query->where('m.movement_type', $direction);
        }

        return response()->json(['data' => $query->orderByDesc('m.id')->limit(200)->get()]);
    }

    /**
     * What each customer is holding, per crate type. Held is the customer
     * party's own running balance — issued adds, returned/broken/purchased
     * subtract, by construction of the ledger legs.
     */
    #[OA\Get(
        path: '/inventory/crate-balances',
        summary: 'Customer balances',
        security: [['bearerAuth' => []]],
        tags: ['Inventory / Crate'],
        parameters: [
            new OA\Parameter(name: 'customer_id', in: 'query', schema: new OA\Schema(type: 'string')),
        ],
        responses: [new OA\Response(response: 200, description: 'Success')],
    )]
    public function customerBalances(Request $request)
    {
        $rows = DB::table('inventory_crate_movements as m')
            ->join('inventory_crate_types as t', 't.id', '=', 'm.crate_type_id')
            ->leftJoin('inventory_customers as c', 'c.id', '=', 'm.customer_id')
            ->where('m.party_type', 'customer')
            ->select(
                'm.customer_id',
                'c.name as customer_name',
                'm.crate_type_id',
                't.name as crate_type_name',
                't.deposit_value',
                DB::raw("SUM(CASE WHEN m.movement_type = 'issued' THEN m.quantity ELSE 0 END) as issued"),
                DB::raw("SUM(CASE WHEN m.movement_type = 'returned' THEN -m.quantity ELSE 0 END) as returned"),
                DB::raw("SUM(CASE WHEN m.movement_type = 'broken' THEN -m.quantity ELSE 0 END) as broken"),
                DB::raw("SUM(CASE WHEN m.movement_type = 'purchased' THEN -m.quantity ELSE 0 END) as purchased"),
                DB::raw('SUM(m.quantity) as held'),
            )
            ->groupBy(
                'm.customer_id', 'c.name', 'm.crate_type_id',
                't.name', 't.deposit_value',
            )
            ->havingRaw('SUM(m.quantity) != 0')
            ->get();

        $data = $rows->map(function ($row) {
            $row->held = (int) $row->held;
            $row->deposit_at_risk = max(0, $row->held) * (float) $row->deposit_value;

            return $row;
        });

        if ($customerId = $request->query('customer_id')) {
            $data = $data->where('customer_id', (int) $customerId)->values();
        }

        return response()->json([
            'data' => $data,
            'meta' => [
                'total_held' => $data->sum('held'),
                'total_deposit_at_risk' => $data->sum('deposit_at_risk'),
            ],
        ]);
    }

    /** The depot's own position, with the reconciliation identity checked. */
    #[OA\Get(
        path: '/inventory/crate-position',
        summary: 'Depot position',
        security: [['bearerAuth' => []]],
        tags: ['Inventory / Crate'],
        responses: [new OA\Response(response: 200, description: 'Success')],
    )]
    public function depotPosition()
    {
        $types = DB::table('inventory_crate_types')->orderBy('name')->get();
        // One grouped aggregate over the whole ledger instead of 5 SUM
        // queries per crate type (see depotPositionAll() for why).
        $positions = $this->ledger->depotPositionAll();
        $zero = [
            'held_by_depot' => 0, 'issued' => 0, 'returned' => 0,
            'out_with_customers' => 0, 'broken_or_purchased' => 0,
            'reconciliation_valid' => true,
        ];

        $rows = $types->map(function ($type) use ($positions, $zero) {
            // A crate type with no ledger movements yet simply has no row
            // in the aggregate -- treat it as all zeros rather than null.
            $position = $positions->get($type->id, $zero);
            // The Flutter client's InvCrateBalance.fromJson reads
            // crate_type_id off each row -- depotPositionAll() doesn't
            // include it since it's already the collection's key.
            $position['crate_type_id'] = $type->id;
            // Keep the response shape the app already expects: `broken` as
            // the combined broken+purchased write-off count.
            $position['broken'] = $position['broken_or_purchased'];
            $position['crate_type_name'] = $type->name;
            $position['deposit_value'] = (float) $type->deposit_value;
            $position['deposit_at_risk'] = $position['out_with_customers'] * (float) $type->deposit_value;

            return $position;
        });

        return response()->json([
            'data' => $rows,
            'meta' => [
                'total_out' => $rows->sum('out_with_customers'),
                'total_broken' => $rows->sum('broken'),
                'total_deposit_at_risk' => $rows->sum('deposit_at_risk'),
                'all_reconciled' => $rows->every(fn ($r) => $r['reconciliation_valid']),
            ],
        ]);
    }
}
