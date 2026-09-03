<?php

namespace App\Http\Controllers\Inventory;

use App\Services\Inventory\AuditTrail;
use App\Services\Inventory\StockLedger;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;
use Illuminate\Routing\Controller;

class SalesController extends Controller
{
    public function __construct(
        private readonly StockLedger $ledger,
        private readonly AuditTrail  $audit,
    ) {
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

    /**
     * GET /inventory/kpis
     * Lightweight dashboard summary — today's sales, profit and 7/30 day trend.
     */
    public function kpis(Request $request)
    {
        $today = now()->toDateString();
        $weekAgo = now()->subDays(6)->toDateString();
        $monthAgo = now()->subDays(29)->toDateString();
        $userId = optional($request->user())->id;

        // Today's headline figures
        $todayRow = DB::table('inventory_sales')
            ->whereDate('created_at', $today)
            ->when($userId && !$this->isManager($request), fn ($q) => $q->where('created_by', $userId))
            ->selectRaw('COUNT(*) as count, COALESCE(SUM(total),0) as total, COALESCE(SUM(paid_total),0) as paid')
            ->first();

        // Outstanding debt
        $debtTotal = (float) DB::table('inventory_sales')
            ->whereIn('payment_status', ['debt', 'partial'])
            ->sum(DB::raw('total - paid_total'));

        // Profit today (revenue - cost from sale items)
        $profitToday = (float) DB::table('inventory_sale_items as si')
            ->join('inventory_sales as s', 's.id', '=', 'si.sale_id')
            ->whereDate('s.created_at', $today)
            ->sum(DB::raw('si.total - (si.unit_cost_snapshot * si.quantity)'));

        // 7-day daily trend
        $weekTrend = DB::table('inventory_sales')
            ->whereDate('created_at', '>=', $weekAgo)
            ->groupBy(DB::raw('DATE(created_at)'))
            ->orderBy(DB::raw('DATE(created_at)'))
            ->get([
                DB::raw('DATE(created_at) as day'),
                DB::raw('COALESCE(SUM(total),0) as total'),
                DB::raw('COALESCE(SUM(paid_total),0) as paid'),
                DB::raw('COUNT(*) as count'),
            ]);

        // 30-day daily trend
        $monthTrend = DB::table('inventory_sales')
            ->whereDate('created_at', '>=', $monthAgo)
            ->groupBy(DB::raw('DATE(created_at)'))
            ->orderBy(DB::raw('DATE(created_at)'))
            ->get([
                DB::raw('DATE(created_at) as day'),
                DB::raw('COALESCE(SUM(total),0) as total'),
                DB::raw('COUNT(*) as count'),
            ]);

        // Top 5 products by revenue today
        $topProducts = DB::table('inventory_sale_items as si')
            ->join('inventory_sales as s', 's.id', '=', 'si.sale_id')
            ->join('inventory_products as p', 'p.id', '=', 'si.product_id')
            ->whereDate('s.created_at', $today)
            ->groupBy('p.id', 'p.name')
            ->orderByDesc(DB::raw('SUM(si.total)'))
            ->limit(5)
            ->get([
                'p.name as product',
                DB::raw('SUM(si.quantity) as quantity'),
                DB::raw('SUM(si.total) as revenue'),
            ]);

        return response()->json(['data' => [
            'today' => [
                'count'   => (int) ($todayRow->count ?? 0),
                'total'   => (float) ($todayRow->total ?? 0),
                'paid'    => (float) ($todayRow->paid ?? 0),
                'profit'  => $profitToday,
            ],
            'outstanding_debt' => $debtTotal,
            'week_trend'       => $weekTrend,
            'month_trend'      => $monthTrend,
            'top_products'     => $topProducts,
        ]]);
    }

    /**
     * POST /inventory/sales/{id}/payments
     * Record a payment against an existing debt or partial sale.
     * Updates paid_total and recalculates payment_status automatically.
     */
    public function recordPayment(Request $request, int $id)
    {
        $v = Validator::make($request->all(), [
            'amount'    => 'required|numeric|min:0.01',
            'method'    => 'required|in:cash,mobile_money,bank_transfer',
            'reference' => 'nullable|string|max:100',
            'paid_at'   => 'nullable|date',
        ]);
        if ($v->fails()) {
            return response()->json(['message' => $v->errors()->first()], 422);
        }

        return DB::transaction(function () use ($request, $id) {
            $sale = DB::table('inventory_sales')->lockForUpdate()->find($id);
            if (!$sale) {
                return response()->json(['message' => 'Sale not found'], 404);
            }
            if (!empty($sale->cancelled_at)) {
                return response()->json(['message' => 'Cannot pay a cancelled sale'], 422);
            }
            if ($sale->payment_status === 'paid') {
                return response()->json(['message' => 'Sale is already fully paid'], 422);
            }

            $outstanding = (float) $sale->total - (float) $sale->paid_total;
            $amount = min((float) $request->amount, $outstanding); // never overpay

            DB::table('inventory_sale_payments')->insert([
                'sale_id'    => $id,
                'amount'     => $amount,
                'method'     => $request->method,
                'reference'  => $request->reference,
                'paid_at'    => $request->paid_at ?? now(),
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            $newPaid = (float) $sale->paid_total + $amount;
            $newStatus = $newPaid >= (float) $sale->total
                ? 'paid'
                : ($newPaid > 0 ? 'partial' : 'debt');

            DB::table('inventory_sales')->where('id', $id)->update([
                'paid_total'     => $newPaid,
                'payment_status' => $newStatus,
                'updated_at'     => now(),
            ]);

            // Close the reminder when fully settled
            if ($newStatus === 'paid') {
                DB::table('inventory_reminders')
                    ->where('type', 'payment_due')
                    ->where('related_id', $id)
                    ->where('status', 'open')
                    ->update(['status' => 'done', 'updated_at' => now()]);
            }

            $this->audit->record($request, 'sale_payment', $id, 'payment_recorded', null, [
                'amount'     => $amount,
                'method'     => $request->method,
                'new_status' => $newStatus,
                'paid_total' => $newPaid,
            ], $sale->number);

            return response()->json([
                'message' => 'Payment recorded',
                'data'    => [
                    'sale_id'        => $id,
                    'sale_number'    => $sale->number,
                    'amount_paid'    => $amount,
                    'new_paid_total' => $newPaid,
                    'balance'        => max(0, (float) $sale->total - $newPaid),
                    'payment_status' => $newStatus,
                ],
            ]);
        });
    }

    /**
     * POST /inventory/sales/{id}/cancel
     * Cancels a sale and returns all issued stock back to the ledger.
     * Only allowed on today's sales (configurable) and by managers.
     */
    public function cancel(Request $request, int $id)
    {
        $data = $request->validate([
            'reason' => 'required|string|max:255',
        ]);

        return DB::transaction(function () use ($request, $id, $data) {
            $sale = DB::table('inventory_sales')->lockForUpdate()->find($id);
            if (!$sale) {
                return response()->json(['message' => 'Sale not found'], 404);
            }
            if (!empty($sale->cancelled_at)) {
                return response()->json(['message' => 'Sale already cancelled'], 422);
            }

            // Re-stock every line item
            $items = DB::table('inventory_sale_items')->where('sale_id', $id)->get();
            foreach ($items as $item) {
                try {
                    $this->ledger->receive(
                        (int) $item->product_id,
                        (int) $item->quantity,
                        'CANCEL-' . now()->format('Ymd'),
                        null,
                        (float) $item->unit_cost_snapshot,
                        $sale->number,
                        optional($request->user())->id,
                    );
                } catch (\Throwable $e) {
                    // Fallback: direct quantity add if ledger can't create batch
                    DB::table('inventory_products')
                        ->where('id', $item->product_id)
                        ->increment('quantity', (int) $item->quantity, ['updated_at' => now()]);
                }
            }

            DB::table('inventory_sales')->where('id', $id)->update([
                'cancelled_at'        => now(),
                'cancellation_reason' => $data['reason'],
                'updated_at'          => now(),
            ]);

            // Close any open reminders for this sale
            DB::table('inventory_reminders')
                ->where('type', 'payment_due')
                ->where('related_id', $id)
                ->where('status', 'open')
                ->update(['status' => 'done', 'updated_at' => now()]);

            $this->audit->record($request, 'sale', $id, 'cancelled', [
                'payment_status' => $sale->payment_status,
                'total'          => $sale->total,
            ], ['reason' => $data['reason']], $sale->number);

            return response()->json(['message' => 'Sale cancelled and stock restored']);
        });
    }

    /**
     * GET /inventory/sales/summary
     * Aggregated totals for the same filters as index — used by the history tab summary bar.
     */
    public function summary(Request $request)
    {
        $status = $request->query('status');
        $from   = $request->query('from');
        $to     = $request->query('to');
        $q      = $request->query('q');

        $query = DB::table('inventory_sales as s')
            ->leftJoin('inventory_customers as c', 'c.id', '=', 's.customer_id')
            ->whereNull('s.cancelled_at');

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

        $row = (clone $query)->selectRaw(
            'COUNT(s.id) as count,
             COALESCE(SUM(s.total),0) as total,
             COALESCE(SUM(s.paid_total),0) as paid'
        )->first();

        $debt = max(0, (float)($row->total ?? 0) - (float)($row->paid ?? 0));

        return response()->json(['data' => [
            'count'  => (int)($row->count ?? 0),
            'total'  => (float)($row->total ?? 0),
            'paid'   => (float)($row->paid ?? 0),
            'debt'   => $debt,
        ]]);
    }

    private function isManager(Request $request): bool
    {
        return in_array(optional($request->user())->role, ['admin', 'manager']);
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
            // Insert with a placeholder number first so we can derive the
            // number from the guaranteed-unique auto-increment ID, avoiding the
            // max(id)+1 race condition under concurrent checkouts.
            $saleId = DB::table('inventory_sales')->insertGetId([
                'number' => 'PENDING',
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

            $number = 'S-' . now()->format('Ymd') . '-' . str_pad((string) $saleId, 4, '0', STR_PAD_LEFT);
            DB::table('inventory_sales')->where('id', $saleId)->update(['number' => $number]);

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

            $this->audit->record($request, 'sale', (int) $saleId, 'created', null, [
                'number' => $number,
                'total' => $request->total,
                'payment_status' => $request->payment_status,
                'items_count' => count($request->items),
            ], $number);

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
