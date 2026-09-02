<?php

namespace App\Http\Controllers\Inventory;

use App\Services\Inventory\StockLedger;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Log;
use Illuminate\Routing\Controller;

class SalesController extends Controller
{
    public function __construct(private readonly StockLedger $ledger)
    {
    }

    public function index(Request $request)
    {
        $status = $request->query('status');
        $from = $request->query('from');
        $to = $request->query('to');
        $q = $request->query('q');

        $query = DB::table('inventory_sales as s')
            ->leftJoin('inventory_customers as c', 'c.id', '=', 's.customer_id')
            ->select(
                's.*',
                'c.name as customer_name',
                'c.phone as customer_phone'
            )
            ->orderByDesc('s.id');

        if ($status && in_array($status, ['paid', 'debt', 'partial'])) {
            $query->where('s.payment_status', $status);
        }

        if ($from) {
            $query->whereDate('s.created_at', '>=', $from);
        }

        if ($to) {
            $query->whereDate('s.created_at', '<=', $to);
        }

        if (!empty($q)) {
            $query->where(function ($sub) use ($q) {
                $sub->where('s.number', 'like', "%{$q}%")
                    ->orWhere('c.name', 'like', "%{$q}%")
                    ->orWhere('c.phone', 'like', "%{$q}%");
            });
        }

        $sales = $query->paginate(20);
        $saleIds = collect($sales->items())->pluck('id')->filter();

        $itemsBySale = [];
        if ($saleIds->isNotEmpty()) {
            $rawItems = DB::table('inventory_sale_items as si')
                ->leftJoin('inventory_products as p', 'p.id', '=', 'si.product_id')
                ->whereIn('si.sale_id', $saleIds)
                ->select(
                    'si.*',
                    'p.name as product_name',
                    'p.sku as product_sku'
                )
                ->get()
                ->groupBy('sale_id');
            $itemsBySale = $rawItems;
        }

        $data = collect($sales->items())->map(function ($s) use ($itemsBySale) {
            $sArray = (array) $s;
            $sItems = $itemsBySale[$s->id] ?? collect();
            $sArray['items'] = $sItems->map(function ($it) {
                return [
                    'id' => (int) $it->id,
                    'product_id' => (int) $it->product_id,
                    'product_name' => $it->product_name ?? 'Product #' . $it->product_id,
                    'quantity' => (int) $it->quantity,
                    'qty' => (int) $it->quantity,
                    'unit_price' => (float) $it->unit_price,
                    'unit_cost_snapshot' => (float) $it->unit_cost_snapshot,
                    'total' => (float) $it->total,
                ];
            })->values()->all();
            return $sArray;
        });

        return response()->json([
            'data' => $data,
            'meta' => [
                'current_page' => $sales->currentPage(),
                'last_page' => $sales->lastPage(),
                'per_page' => $sales->perPage(),
                'total' => $sales->total(),
            ],
        ]);
    }

    public function show($id)
    {
        $sale = DB::table('inventory_sales as s')
            ->leftJoin('inventory_customers as c', 'c.id', '=', 's.customer_id')
            ->select(
                's.*',
                'c.name as customer_name',
                'c.phone as customer_phone',
                'c.address as customer_address'
            )
            ->where('s.id', $id)
            ->first();

        if (!$sale) {
            return response()->json(['message' => 'Sale not found'], 404);
        }

        $saleArray = (array) $sale;

        $items = DB::table('inventory_sale_items as si')
            ->leftJoin('inventory_products as p', 'p.id', '=', 'si.product_id')
            ->where('si.sale_id', $id)
            ->select('si.*', 'p.name as product_name', 'p.sku as product_sku')
            ->get();

        $saleArray['items'] = $items->map(function ($it) {
            return [
                'id' => (int) $it->id,
                'product_id' => (int) $it->product_id,
                'product_name' => $it->product_name ?? 'Product #' . $it->product_id,
                'quantity' => (int) $it->quantity,
                'qty' => (int) $it->quantity,
                'unit_price' => (float) $it->unit_price,
                'unit_cost_snapshot' => (float) $it->unit_cost_snapshot,
                'total' => (float) $it->total,
            ];
        })->values()->all();

        $payments = DB::table('inventory_sale_payments')
            ->where('sale_id', $id)
            ->orderBy('id')
            ->get();

        $saleArray['payments'] = $payments->map(function ($p) {
            return [
                'id' => (int) $p->id,
                'amount' => (float) $p->amount,
                'method' => $p->method,
                'reference' => $p->reference,
                'paid_at' => $p->paid_at,
            ];
        })->values()->all();

        return response()->json(['data' => $saleArray]);
    }

    public function store(Request $request)
    {
        $v = Validator::make($request->all(), [
            'customer_id' => 'nullable|exists:inventory_customers,id',
            'payment_status' => 'required|in:paid,debt,partial',
            'subtotal' => 'required|numeric|min:0',
            'discount' => 'nullable|numeric|min:0',
            'tax' => 'nullable|numeric|min:0',
            'total' => 'required|numeric|min:0',
            'paid_total' => 'required|numeric|min:0',
            'due_date' => 'nullable|date',
            'items' => 'required|array|min:1',
            'items.*.product_id' => 'required|exists:inventory_products,id',
            'items.*.quantity' => 'required|integer|min:1',
            'items.*.unit_price' => 'nullable|numeric|min:0',
            'items.*.unit_cost_snapshot' => 'nullable|numeric|min:0',
            'payments' => 'sometimes|array',
            'payments.*.amount' => 'required|numeric|min:0.01',
            'payments.*.method' => 'required|in:cash,mobile_money,bank_transfer',
            'payments.*.reference' => 'nullable|string',
            'payments.*.paid_at' => 'nullable|date',
        ]);

        if ($v->fails()) {
            return response()->json(['message' => $v->errors()->first()], 422);
        }

        if (in_array($request->payment_status, ['debt', 'partial']) && empty($request->customer_id)) {
            return response()->json(['message' => 'Customer required for debt/partial'], 422);
        }

        return DB::transaction(function () use ($request) {
            $todayStr = now()->format('Ymd');
            $nextId = (DB::table('inventory_sales')->max('id') ?? 0) + 1;
            $number = 'S-' . $todayStr . '-' . str_pad((string) $nextId, 4, '0', STR_PAD_LEFT);

            $saleId = DB::table('inventory_sales')->insertGetId([
                'number' => $number,
                'customer_id' => $request->customer_id,
                'payment_status' => $request->payment_status,
                'subtotal' => $request->subtotal,
                'discount' => $request->discount ?? 0,
                'tax' => $request->tax ?? 0,
                'total' => $request->total,
                'paid_total' => $request->paid_total,
                'due_date' => $request->payment_status === 'paid' ? null : ($request->due_date ?? now()->addDays(7)),
                'created_by' => optional($request->user())->id ?? 1,
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            $insertedItems = [];
            foreach ($request->items as $item) {
                $product = DB::table('inventory_products')->find($item['product_id']);
                if (!$product) {
                    throw new \RuntimeException('Product not found: ' . $item['product_id']);
                }

                $qty = (int) $item['quantity'];
                $fallbackUnitCost = (float) ($item['unit_cost_snapshot'] ?? $product->cost_price ?? 0);

                try {
                    $allocations = $this->ledger->issue(
                        (int) $item['product_id'],
                        $qty,
                        $number,
                        'sale',
                        optional($request->user())->id ?? 1
                    );
                } catch (\Throwable $e) {
                    // Fallback to direct stock reduction if batch ledger issue is not active
                    $allocations = [];
                    $newQty = max(0, (int) $product->quantity - $qty);
                    DB::table('inventory_products')
                        ->where('id', $item['product_id'])
                        ->update(['quantity' => $newQty, 'updated_at' => now()]);
                }

                $issuedQty = array_sum(array_column($allocations, 'quantity'));
                $issuedCost = 0.0;
                foreach ($allocations as $a) {
                    $issuedCost += $a['cost_price'] * $a['quantity'];
                }

                $unitPrice = isset($item['unit_price']) ? (float) $item['unit_price'] : (float) ($product->selling_price ?? 0);
                $unitCost = $issuedQty > 0 ? ($issuedCost / $issuedQty) : $fallbackUnitCost;
                $lineTotal = $unitPrice * $qty;

                $itemId = DB::table('inventory_sale_items')->insertGetId([
                    'sale_id' => (int) $saleId,
                    'product_id' => (int) $item['product_id'],
                    'quantity' => $qty,
                    'unit_price' => $unitPrice,
                    'unit_cost_snapshot' => $unitCost,
                    'total' => $lineTotal,
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);

                $insertedItems[] = [
                    'id' => (int) $itemId,
                    'product_id' => (int) $item['product_id'],
                    'product_name' => $product->name,
                    'quantity' => $qty,
                    'qty' => $qty,
                    'unit_price' => $unitPrice,
                    'unit_cost_snapshot' => $unitCost,
                    'total' => $lineTotal,
                ];
            }

            if (is_array($request->payments)) {
                foreach ($request->payments as $p) {
                    DB::table('inventory_sale_payments')->insert([
                        'sale_id' => (int) $saleId,
                        'amount' => (float) $p['amount'],
                        'method' => $p['method'] ?? 'cash',
                        'reference' => $p['reference'] ?? null,
                        'paid_at' => $p['paid_at'] ?? now(),
                        'created_at' => now(),
                        'updated_at' => now(),
                    ]);
                }
            }

            if (in_array($request->payment_status, ['debt', 'partial'])) {
                DB::table('inventory_reminders')->insert([
                    'type' => 'payment_due',
                    'related_id' => (int) $saleId,
                    'title' => 'Payment Due',
                    'description' => 'Outstanding balance for sale ' . $number,
                    'due_at' => $request->due_date ?? now()->addDays(7),
                    'status' => 'open',
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);
            }

            return response()->json([
                'message' => 'Sale created successfully',
                'data' => [
                    'id' => (int) $saleId,
                    'number' => $number,
                    'customer_id' => $request->customer_id,
                    'payment_status' => $request->payment_status,
                    'subtotal' => (float) $request->subtotal,
                    'total' => (float) $request->total,
                    'paid_total' => (float) $request->paid_total,
                    'items' => $insertedItems,
                ],
            ], 201);
        });
    }
}
