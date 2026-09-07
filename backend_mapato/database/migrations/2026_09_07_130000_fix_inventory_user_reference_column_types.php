<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Every inventory_* table that records "which user did this" was created
 * with unsignedBigInteger, but users.id is a uuid. MySQL's strict mode
 * rejects inserting a real UUID into an integer column ("Incorrect integer
 * value"), so any of these columns fails the moment a real logged-in user's
 * id is written -- first caught on inventory_crate_movements.created_by,
 * but the same migrations show every column below has the identical bug.
 *
 * Raw SQL rather than Schema::table(...)->change() since this app doesn't
 * have doctrine/dbal installed.
 */
return new class extends Migration
{
    /** @var array<int, array{0: string, 1: string}> [table, column] */
    private array $columns = [
        ['inventory_products', 'created_by'],
        ['inventory_sales', 'created_by'],
        ['inventory_stock_movements', 'user_id'],
        ['inventory_categories', 'created_by'],
        ['inventory_brands', 'created_by'],
        ['inventory_product_prices', 'created_by'],
        ['inventory_batches', 'created_by'],
        ['inventory_stock_counts', 'counted_by'],
        ['inventory_stock_counts', 'posted_by'],
        ['inventory_write_offs', 'requested_by'],
        ['inventory_write_offs', 'approved_by'],
        ['inventory_suppliers', 'created_by'],
        ['inventory_purchase_orders', 'created_by'],
        ['inventory_goods_receipts', 'received_by'],
        ['inventory_supplier_payments', 'created_by'],
        ['inventory_cash_sessions', 'user_id'],
        ['inventory_cash_expenses', 'created_by'],
        ['inventory_crate_movements', 'created_by'],
        ['inventory_sale_returns', 'requested_by'],
        ['inventory_sale_returns', 'approved_by'],
        ['inventory_dispatches', 'created_by'],
        ['inventory_audit_log', 'user_id'],
    ];

    public function up(): void
    {
        foreach ($this->columns as [$table, $column]) {
            if (!Schema::hasTable($table) || !Schema::hasColumn($table, $column)) {
                continue;
            }
            DB::statement("ALTER TABLE `{$table}` MODIFY `{$column}` CHAR(36) NULL");
        }
    }

    public function down(): void
    {
        foreach ($this->columns as [$table, $column]) {
            if (!Schema::hasTable($table) || !Schema::hasColumn($table, $column)) {
                continue;
            }
            DB::statement("ALTER TABLE `{$table}` MODIFY `{$column}` BIGINT UNSIGNED NULL");
        }
    }
};
