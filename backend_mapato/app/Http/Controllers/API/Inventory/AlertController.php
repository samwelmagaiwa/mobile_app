<?php

namespace App\Http\Controllers\Inventory;

use Illuminate\Http\Request;
use Illuminate\Routing\Controller;
use Illuminate\Support\Facades\DB;

/**
 * Areas 12 and 13 — alerts, the audit trail viewer and depot settings.
 */
class AlertController extends Controller
{
    public function index(Request $request)
    {
        if ($request->boolean('refresh', true)) {
            $this->rebuild();
        }

        $query = DB::table('inventory_alerts');
        if ($status = $request->query('status', 'open')) {
            $query->where('status', $status);
        }
        if ($type = $request->query('type')) {
            $query->where('type', $type);
        }

        // A portable severity ordering (FIELD() is MySQL-only and breaks
        // under the sqlite connection tests run against).
        $rows = $query->orderByRaw(
            "CASE severity WHEN 'critical' THEN 0 WHEN 'warning' THEN 1 ELSE 2 END",
        )->orderByDesc('created_at')->limit(200)->get();

        return response()->json([
            'data' => $rows,
            'meta' => [
                'open' => DB::table('inventory_alerts')->where('status', 'open')->count(),
                'critical' => DB::table('inventory_alerts')
                    ->where('status', 'open')->where('severity', 'critical')->count(),
            ],
        ]);
    }

    /**
     * Recompute the alert set from live data. Alerts are keyed on
     * type + entity, so a repeat run refreshes rather than duplicates, and a
     * condition that has cleared is resolved automatically.
     */
    public function rebuild(): int
    {
        $settings = DB::table('inventory_settings')->pluck('value', 'key');
        $expiryDays = (int) ($settings['expiry_alert_days'] ?? 30);
        $overdueDays = (int) ($settings['overdue_alert_days'] ?? 7);

        $found = [];

        foreach ($this->lowStock() as $alert) {
            $found[] = $this->upsert($alert);
        }
        foreach ($this->nearExpiry($expiryDays) as $alert) {
            $found[] = $this->upsert($alert);
        }
        foreach ($this->overCreditLimit() as $alert) {
            $found[] = $this->upsert($alert);
        }
        foreach ($this->overdueInvoices($overdueDays) as $alert) {
            $found[] = $this->upsert($alert);
        }
        foreach ($this->pendingApprovals() as $alert) {
            $found[] = $this->upsert($alert);
        }

        // Anything previously open that no longer applies has been dealt with.
        $stale = DB::table('inventory_alerts')->where('status', 'open');
        if ($found !== []) {
            $stale->whereNotIn('id', $found);
        }
        $stale->update(['status' => 'resolved', 'resolved_at' => now()]);

        return count($found);
    }

    private function upsert(array $alert): int
    {
        $existing = DB::table('inventory_alerts')
            ->where('type', $alert['type'])
            ->where('entity_type', $alert['entity_type'])
            ->where('entity_id', $alert['entity_id'])
            ->first();

        if ($existing) {
            DB::table('inventory_alerts')->where('id', $existing->id)->update([
                'title' => $alert['title'],
                'body' => $alert['body'],
                'severity' => $alert['severity'],
                'status' => 'open',
                'resolved_at' => null,
            ]);

            return (int) $existing->id;
        }

        return (int) DB::table('inventory_alerts')->insertGetId($alert + [
            'status' => 'open',
            'created_at' => now(),
        ]);
    }

    private function lowStock(): array
    {
        return DB::table('inventory_products')
            ->whereColumn('quantity', '<', 'min_stock')
            ->where('status', 'active')
            ->get(['id', 'name', 'quantity', 'min_stock'])
            ->map(fn ($p) => [
                'type' => 'low_stock',
                'severity' => $p->quantity <= 0 ? 'critical' : 'warning',
                'title' => "Low stock: {$p->name}",
                'body' => "{$p->quantity} left, minimum is {$p->min_stock}",
                'entity_type' => 'product',
                'entity_id' => (int) $p->id,
            ])->all();
    }

    private function nearExpiry(int $days): array
    {
        return DB::table('inventory_batches as b')
            ->join('inventory_products as p', 'p.id', '=', 'b.product_id')
            ->where('b.quantity', '>', 0)
            ->whereNotNull('b.expiry_date')
            ->whereDate('b.expiry_date', '<=', now()->addDays($days)->toDateString())
            ->get(['b.id', 'b.batch_number', 'b.expiry_date', 'b.quantity', 'p.name'])
            ->map(function ($b) {
                $expired = $b->expiry_date < now()->toDateString();

                return [
                    'type' => $expired ? 'expired' : 'near_expiry',
                    'severity' => $expired ? 'critical' : 'warning',
                    'title' => ($expired ? 'Expired: ' : 'Expiring soon: ') . $b->name,
                    'body' => "Batch {$b->batch_number}, {$b->quantity} units, {$b->expiry_date}",
                    'entity_type' => 'batch',
                    'entity_id' => (int) $b->id,
                ];
            })->all();
    }

    private function overCreditLimit(): array
    {
        return DB::table('inventory_customers as c')
            ->join('inventory_sales as s', 's.customer_id', '=', 'c.id')
            ->whereIn('s.payment_status', ['debt', 'partial'])
            ->where('c.credit_limit', '>', 0)
            ->groupBy('c.id', 'c.name', 'c.credit_limit')
            ->havingRaw('SUM(s.total - s.paid_total) > c.credit_limit')
            ->get([
                'c.id', 'c.name', 'c.credit_limit',
                DB::raw('SUM(s.total - s.paid_total) as balance'),
            ])
            ->map(fn ($c) => [
                'type' => 'over_credit_limit',
                'severity' => 'critical',
                'title' => "Over credit limit: {$c->name}",
                'body' => 'Owes ' . number_format((float) $c->balance, 0)
                    . ' against a limit of ' . number_format((float) $c->credit_limit, 0),
                'entity_type' => 'customer',
                'entity_id' => (int) $c->id,
            ])->all();
    }

    private function overdueInvoices(int $days): array
    {
        return DB::table('inventory_sales as s')
            ->leftJoin('inventory_customers as c', 'c.id', '=', 's.customer_id')
            ->whereIn('s.payment_status', ['debt', 'partial'])
            ->whereNotNull('s.due_date')
            ->whereDate('s.due_date', '<', now()->subDays($days)->toDateString())
            ->limit(100)
            ->get(['s.id', 's.number', 's.due_date', 's.total', 's.paid_total', 'c.name'])
            ->map(fn ($s) => [
                'type' => 'overdue_invoice',
                'severity' => 'warning',
                'title' => "Overdue: {$s->number}",
                'body' => ($s->name ?? 'Walk-in') . ' owes '
                    . number_format((float) $s->total - (float) $s->paid_total, 0)
                    . ", due {$s->due_date}",
                'entity_type' => 'sale',
                'entity_id' => (int) $s->id,
            ])->all();
    }

    private function pendingApprovals(): array
    {
        $alerts = [];

        $writeOffs = DB::table('inventory_write_offs')->where('status', 'pending')->count();
        if ($writeOffs > 0) {
            $alerts[] = [
                'type' => 'pending_approval',
                'severity' => 'info',
                'title' => "{$writeOffs} write-off(s) awaiting approval",
                'body' => 'Damages, breakages or expired goods need a decision',
                'entity_type' => 'write_off',
                'entity_id' => 0,
            ];
        }

        $returns = DB::table('inventory_sale_returns')->where('status', 'pending')->count();
        if ($returns > 0) {
            $alerts[] = [
                'type' => 'pending_approval',
                'severity' => 'info',
                'title' => "{$returns} return(s) awaiting approval",
                'body' => 'Returns or cancellations need a decision',
                'entity_type' => 'sale_return',
                'entity_id' => 0,
            ];
        }

        return $alerts;
    }

    public function acknowledge(int $id)
    {
        $updated = DB::table('inventory_alerts')->where('id', $id)
            ->update(['status' => 'acknowledged']);

        return $updated
            ? response()->json(['message' => 'Alert acknowledged'])
            : response()->json(['message' => 'Not found'], 404);
    }

    // ---------------------------------------------------- Area 13: audit log

    public function auditLog(Request $request)
    {
        $query = DB::table('inventory_audit_log');

        if ($entityType = $request->query('entity_type')) {
            $query->where('entity_type', $entityType);
        }
        if ($entityId = $request->query('entity_id')) {
            $query->where('entity_id', (int) $entityId);
        }
        if ($userId = $request->query('user_id')) {
            $query->where('user_id', (int) $userId);
        }
        if ($from = $request->query('from')) {
            $query->whereDate('created_at', '>=', $from);
        }
        if ($to = $request->query('to')) {
            $query->whereDate('created_at', '<=', $to);
        }

        $rows = $query->orderByDesc('id')
            ->paginate((int) $request->query('per_page', 50));

        return response()->json([
            'data' => $rows->items(),
            'meta' => [
                'current_page' => $rows->currentPage(),
                'last_page' => $rows->lastPage(),
                'total' => $rows->total(),
            ],
        ]);
    }

    // ---------------------------------------------------- Area 13: settings

    public function settings()
    {
        return response()->json([
            'data' => DB::table('inventory_settings')->pluck('value', 'key'),
        ]);
    }

    public function updateSettings(Request $request)
    {
        $allowed = DB::table('inventory_settings')->pluck('key')->all();
        $payload = $request->all();

        $saved = [];
        foreach ($payload as $key => $value) {
            if (! in_array($key, $allowed, true)) {
                continue;
            }
            DB::table('inventory_settings')->where('key', $key)->update([
                'value' => is_scalar($value) ? (string) $value : json_encode($value),
                'updated_at' => now(),
            ]);
            $saved[] = $key;
        }

        if ($saved === []) {
            return response()->json(['message' => 'Nothing to save'], 422);
        }

        app(\App\Services\Inventory\AuditTrail::class)
            ->record($request, 'settings', null, 'updated', null, $payload);

        return response()->json(['message' => 'Settings saved', 'data' => ['saved' => $saved]]);
    }
}
