<?php

namespace App\Services\Inventory;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

/**
 * Area 13 — the permanent record.
 *
 * Every sale, price change, stock adjustment and payment lands here with the
 * user, the time and the before/after state. Rows are only ever inserted.
 */
class AuditTrail
{
    public function record(
        ?Request $request,
        string $entityType,
        ?int $entityId,
        string $action,
        ?array $before = null,
        ?array $after = null,
        ?string $summary = null,
    ): void {
        $user = $request?->user();

        DB::table('inventory_audit_log')->insert([
            'entity_type' => $entityType,
            'entity_id' => $entityId,
            'action' => $action,
            'before' => $before !== null ? json_encode($this->clean($before)) : null,
            'after' => $after !== null ? json_encode($this->clean($after)) : null,
            'summary' => $summary,
            'user_id' => $user?->id,
            'user_name' => $user?->name,
            'created_at' => now(),
        ]);
    }

    /** Keep secrets and noise out of the log. */
    private function clean(array $data): array
    {
        unset($data['password'], $data['token'], $data['_token']);

        return $data;
    }
}
