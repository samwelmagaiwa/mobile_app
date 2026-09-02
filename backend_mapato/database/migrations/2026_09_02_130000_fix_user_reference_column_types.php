<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

/**
 * `users.id` is a UUID (char(36)) - see
 * 2025_10_05_000001_recreate_users_table_for_boda_mapato. Every column below
 * was created as `unsignedBigInteger` to hold a user id, which is a type
 * mismatch: under MySQL's default (non-strict-for-DDL) behaviour it was
 * silently tolerated at write time, but any authenticated request passing a
 * real UUID into one of these columns throws immediately, and the earlier
 * PHP-level type hints (`?int $userId`) made that a hard TypeError before the
 * query even ran. Fixed there too (see StockLedger, CrateLedgerService,
 * ProductUnitController). This migration corrects the storage side.
 *
 * Columns that reference `inventory_customers`/`inventory_products`/etc.
 * (genuinely bigint-keyed tables) are untouched - only user references move.
 */
return new class extends Migration
{
    /** @var array<string, string[]> table => [column, ...] */
    private const COLUMNS = [
        'inventory_products' => ['created_by'],
        'inventory_sales' => ['created_by'],
        'inventory_stock_movements' => ['user_id'],
        'inventory_categories' => ['created_by'],
        'inventory_brands' => ['created_by'],
        'inventory_product_prices' => ['created_by'],
        'inventory_price_changes' => ['changed_by'],
        'inventory_batches' => ['created_by'],
        'inventory_stock_counts' => ['counted_by', 'posted_by'],
        'inventory_write_offs' => ['requested_by', 'approved_by'],
        'inventory_suppliers' => ['created_by'],
        'inventory_goods_receipts' => ['received_by'],
        'inventory_cash_sessions' => ['user_id'],
        'inventory_cash_expenses' => ['created_by'],
        'inventory_supplier_payments' => ['created_by'],
        'inventory_dispatches' => ['agent_id', 'created_by'],
        'inventory_audit_log' => ['user_id'],
        'inventory_parked_sales' => ['parked_by'],
        'inventory_sale_returns' => ['requested_by', 'approved_by'],
    ];

    public function up(): void
    {
        $this->alter('CHAR(36) NULL');
    }

    public function down(): void
    {
        $this->alter('BIGINT UNSIGNED NULL');
    }

    private function alter(string $columnDefinition): void
    {
        if (DB::getDriverName() === 'sqlite') {
            // SQLite is dynamically typed and used only for tests, which
            // never persist a real user id across this boundary in a way
            // that matters for column affinity - nothing to do.
            return;
        }

        foreach (self::COLUMNS as $table => $columns) {
            foreach ($columns as $column) {
                DB::statement("ALTER TABLE `{$table}` MODIFY COLUMN `{$column}` {$columnDefinition}");
            }
        }
    }
};
