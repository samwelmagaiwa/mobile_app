<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Add missing indexes on the columns most frequently used in WHERE / JOIN
 * clauses across inventory controllers and the 12 standard reports.
 *
 * Each addIndex() call is wrapped in a try/catch so a duplicate-key error
 * (index already exists from a prior migration) does not abort the whole batch.
 */
return new class extends Migration
{
    public function up(): void
    {
        // inventory_stock_movements — filtered by created_at and joined on product_id
        $this->addIndex('inventory_stock_movements', ['created_at']);
        $this->addIndex('inventory_stock_movements', ['product_id']);
        $this->addIndex('inventory_stock_movements', ['user_id']);

        // inventory_sale_items — joined on sale_id and product_id in every detail report
        $this->addIndex('inventory_sale_items', ['sale_id']);
        $this->addIndex('inventory_sale_items', ['product_id']);

        // inventory_sale_payments — filtered on paid_at for the collections report
        $this->addIndex('inventory_sale_payments', ['paid_at']);
        $this->addIndex('inventory_sale_payments', ['sale_id']);

        // inventory_batches — joined on product_id in stock-valuation and ledger queries
        $this->addIndex('inventory_batches', ['product_id']);
        $this->addIndex('inventory_batches', ['quantity']); // WHERE quantity > 0

        // inventory_write_offs — filtered by created_at for the damages report
        $this->addIndex('inventory_write_offs', ['created_at']);
        $this->addIndex('inventory_write_offs', ['product_id']);

        // inventory_goods_receipts — filtered by received_on for the purchases report
        $this->addIndex('inventory_goods_receipts', ['received_on']);
        $this->addIndex('inventory_goods_receipts', ['supplier_id']);

        // inventory_goods_receipt_lines — joined on goods_receipt_id and product_id
        $this->addIndex('inventory_goods_receipt_lines', ['goods_receipt_id']);
        $this->addIndex('inventory_goods_receipt_lines', ['product_id']);

        // inventory_cash_sessions — filtered by business_date and user_id
        $this->addIndex('inventory_cash_sessions', ['business_date']);
        $this->addIndex('inventory_cash_sessions', ['user_id']);
        $this->addIndex('inventory_cash_sessions', ['status']);

        // inventory_stock_count_lines — joined on stock_count_id and product_id
        $this->addIndex('inventory_stock_count_lines', ['stock_count_id']);
        $this->addIndex('inventory_stock_count_lines', ['product_id']);

        // inventory_expenses — filtered by expense_date
        $this->addIndex('inventory_expenses', ['expense_date']);
        $this->addIndex('inventory_expenses', ['created_by']);

        // inventory_products — filtered by status and category_id frequently
        $this->addIndex('inventory_products', ['status']);
        $this->addIndex('inventory_products', ['category_id']);

        // inventory_reminders — filtered by status and type
        $this->addIndex('inventory_reminders', ['status']);

        // users — email lookup on login (usually already indexed by Laravel default)
        $this->addIndex('users', ['email']);
        $this->addIndex('users', ['role']);
    }

    public function down(): void
    {
        // indexes are additive performance helpers; dropping them on rollback
        // is safe — the application continues to work without them.
        $drops = [
            'inventory_stock_movements'       => [['created_at'], ['product_id'], ['user_id']],
            'inventory_sale_items'            => [['sale_id'], ['product_id']],
            'inventory_sale_payments'         => [['paid_at'], ['sale_id']],
            'inventory_batches'               => [['product_id'], ['quantity']],
            'inventory_write_offs'            => [['created_at'], ['product_id']],
            'inventory_goods_receipts'        => [['received_on'], ['supplier_id']],
            'inventory_goods_receipt_lines'   => [['goods_receipt_id'], ['product_id']],
            'inventory_cash_sessions'         => [['business_date'], ['user_id'], ['status']],
            'inventory_stock_count_lines'     => [['stock_count_id'], ['product_id']],
            'inventory_expenses'              => [['expense_date'], ['created_by']],
            'inventory_products'              => [['status'], ['category_id']],
            'inventory_reminders'             => [['status']],
            'users'                           => [['email'], ['role']],
        ];

        foreach ($drops as $table => $columnSets) {
            foreach ($columnSets as $cols) {
                try {
                    Schema::table($table, fn (Blueprint $t) => $t->dropIndex($cols));
                } catch (\Throwable) {
                    // ignore if already dropped
                }
            }
        }
    }

    private function addIndex(string $table, array $columns): void
    {
        try {
            Schema::table($table, fn (Blueprint $t) => $t->index($columns));
        } catch (\Throwable) {
            // index already exists — skip silently
        }
    }
};
