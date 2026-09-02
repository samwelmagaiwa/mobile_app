<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Areas 4, 6, 7 and 8.
 *
 * 4 — suppliers, purchase orders, goods receiving, supplier invoices.
 * 6 — customer credit limits, terms and blocking.
 * 7 — payment allocation across invoices and daily cash sessions.
 * 8 — crates and empties tracked separately from money owed.
 */
return new class extends Migration
{
    public function up(): void
    {
        // ---------------------------------------------------------- Area 4
        Schema::create('inventory_suppliers', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('phone', 32)->nullable()->index();
            $table->string('email')->nullable();
            $table->string('address')->nullable();
            $table->string('contact_person')->nullable();
            $table->unsignedSmallInteger('payment_terms_days')->default(0);
            $table->enum('status', ['active', 'inactive'])->default('active')->index();
            $table->unsignedBigInteger('created_by')->nullable();
            $table->timestamps();
        });

        Schema::create('inventory_purchase_orders', function (Blueprint $table) {
            $table->id();
            $table->string('number', 64)->unique();
            $table->foreignId('supplier_id')->constrained('inventory_suppliers')->restrictOnDelete();
            $table->enum('status', ['draft', 'sent', 'partial', 'received', 'cancelled'])
                ->default('draft')->index();
            $table->date('expected_at')->nullable();
            $table->decimal('total', 14, 2)->default(0);
            $table->string('note')->nullable();
            $table->unsignedBigInteger('created_by')->nullable();
            $table->timestamps();
        });

        Schema::create('inventory_purchase_order_lines', function (Blueprint $table) {
            $table->id();
            $table->foreignId('purchase_order_id')->constrained('inventory_purchase_orders')->cascadeOnDelete();
            $table->foreignId('product_id')->constrained('inventory_products')->restrictOnDelete();
            $table->unsignedInteger('quantity');
            $table->unsignedInteger('received_quantity')->default(0);
            $table->decimal('unit_cost', 12, 2)->default(0);
            $table->decimal('total', 14, 2)->default(0);
            $table->timestamps();
            $table->index(['purchase_order_id', 'product_id'], 'inv_po_line_idx');
        });

        Schema::create('inventory_goods_receipts', function (Blueprint $table) {
            $table->id();
            $table->string('reference', 64)->unique();
            $table->foreignId('purchase_order_id')->nullable()
                ->constrained('inventory_purchase_orders')->nullOnDelete();
            $table->foreignId('supplier_id')->constrained('inventory_suppliers')->restrictOnDelete();
            $table->date('received_on');
            $table->decimal('total_cost', 14, 2)->default(0);
            $table->string('note')->nullable();
            $table->unsignedBigInteger('received_by')->nullable();
            $table->timestamps();
        });

        Schema::create('inventory_goods_receipt_lines', function (Blueprint $table) {
            $table->id();
            $table->foreignId('goods_receipt_id')->constrained('inventory_goods_receipts')->cascadeOnDelete();
            $table->foreignId('product_id')->constrained('inventory_products')->restrictOnDelete();
            $table->foreignId('batch_id')->nullable()->constrained('inventory_batches')->nullOnDelete();
            $table->unsignedInteger('quantity');
            $table->decimal('unit_cost', 12, 2)->default(0);
            $table->decimal('total', 14, 2)->default(0);
            $table->timestamps();
        });

        Schema::create('inventory_supplier_invoices', function (Blueprint $table) {
            $table->id();
            $table->string('number', 64);
            $table->foreignId('supplier_id')->constrained('inventory_suppliers')->restrictOnDelete();
            $table->foreignId('goods_receipt_id')->nullable()
                ->constrained('inventory_goods_receipts')->nullOnDelete();
            $table->date('invoice_date');
            $table->date('due_date')->nullable();
            $table->decimal('amount', 14, 2)->default(0);
            $table->decimal('paid_amount', 14, 2)->default(0);
            $table->enum('status', ['open', 'part_paid', 'paid', 'cancelled'])
                ->default('open')->index();
            $table->timestamps();
            $table->unique(['supplier_id', 'number']);
        });

        Schema::create('inventory_supplier_payments', function (Blueprint $table) {
            $table->id();
            $table->foreignId('supplier_id')->constrained('inventory_suppliers')->restrictOnDelete();
            $table->foreignId('supplier_invoice_id')->nullable()
                ->constrained('inventory_supplier_invoices')->nullOnDelete();
            $table->decimal('amount', 14, 2);
            $table->enum('method', ['cash', 'mobile_money', 'bank_transfer', 'cheque'])->default('cash');
            $table->string('reference')->nullable();
            $table->date('paid_on');
            $table->unsignedBigInteger('created_by')->nullable();
            $table->timestamps();
        });

        // ---------------------------------------------------------- Area 6
        Schema::table('inventory_customers', function (Blueprint $table) {
            $table->decimal('credit_limit', 14, 2)->default(0)->after('address');
            $table->unsignedSmallInteger('payment_terms_days')->default(0)->after('credit_limit');
            $table->boolean('is_blocked')->default(false)->after('payment_terms_days');
            $table->string('block_reason')->nullable()->after('is_blocked');
        });

        // ---------------------------------------------------------- Area 7
        // One payment can settle several invoices; allocations record how much
        // of it went where, so a sale's balance is always derivable.
        Schema::create('inventory_payment_allocations', function (Blueprint $table) {
            $table->id();
            $table->foreignId('sale_payment_id')->constrained('inventory_sale_payments')->cascadeOnDelete();
            $table->foreignId('sale_id')->constrained('inventory_sales')->cascadeOnDelete();
            $table->decimal('amount', 14, 2);
            $table->timestamps();
            $table->index(['sale_id', 'sale_payment_id']);
        });

        Schema::create('inventory_cash_sessions', function (Blueprint $table) {
            $table->id();
            $table->string('reference', 64)->unique();
            $table->unsignedBigInteger('user_id');
            $table->date('business_date')->index();
            $table->decimal('opening_float', 14, 2)->default(0);
            $table->decimal('expected_cash', 14, 2)->default(0);
            $table->decimal('counted_cash', 14, 2)->default(0);
            $table->decimal('expenses_total', 14, 2)->default(0);
            $table->decimal('difference', 14, 2)->default(0);
            $table->string('difference_reason')->nullable();
            $table->enum('status', ['open', 'closed'])->default('open')->index();
            $table->timestamp('closed_at')->nullable();
            $table->timestamps();
        });

        Schema::create('inventory_cash_expenses', function (Blueprint $table) {
            $table->id();
            $table->foreignId('cash_session_id')->constrained('inventory_cash_sessions')->cascadeOnDelete();
            $table->string('description');
            $table->decimal('amount', 14, 2);
            $table->unsignedBigInteger('created_by')->nullable();
            $table->timestamps();
        });

        // ---------------------------------------------------------- Area 8
        Schema::create('inventory_crate_types', function (Blueprint $table) {
            $table->id();
            $table->string('name')->unique();
            $table->decimal('deposit_value', 12, 2)->default(0);
            $table->enum('status', ['active', 'inactive'])->default('active')->index();
            $table->timestamps();
        });

        // Double-entry ledger: every real-world event posts two rows - a depot
        // leg and a counterparty leg - whose signed quantities must sum to
        // zero. That invariant is enforced in CrateLedgerService, not just
        // assumed, so a bug can never silently create or destroy crates.
        // A customer's balance is the sum of their party rows; the depot's
        // position is the sum of its own, and the two must reconcile.
        Schema::create('inventory_crate_movements', function (Blueprint $table) {
            $table->id();
            $table->foreignId('crate_type_id')->constrained('inventory_crate_types')->restrictOnDelete();
            $table->enum('party_type', ['depot', 'customer', 'write_off'])->index();
            $table->foreignId('customer_id')->nullable()
                ->constrained('inventory_customers')->nullOnDelete();
            $table->enum('movement_type', ['issued', 'returned', 'broken', 'purchased'])->index();
            // Signed: +qty grows this party's holding, -qty shrinks it.
            $table->integer('quantity');
            $table->integer('balance_after')->default(0);
            $table->decimal('deposit_value', 12, 2)->default(0);
            $table->string('reference')->nullable();
            $table->string('note')->nullable();
            $table->unsignedBigInteger('created_by')->nullable();
            $table->timestamp('created_at')->useCurrent();
            $table->index(['customer_id', 'crate_type_id']);
            $table->index(['party_type', 'crate_type_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('inventory_crate_movements');
        Schema::dropIfExists('inventory_crate_types');
        Schema::dropIfExists('inventory_cash_expenses');
        Schema::dropIfExists('inventory_cash_sessions');
        Schema::dropIfExists('inventory_payment_allocations');

        Schema::table('inventory_customers', function (Blueprint $table) {
            $table->dropColumn([
                'credit_limit', 'payment_terms_days', 'is_blocked', 'block_reason',
            ]);
        });

        Schema::dropIfExists('inventory_supplier_payments');
        Schema::dropIfExists('inventory_supplier_invoices');
        Schema::dropIfExists('inventory_goods_receipt_lines');
        Schema::dropIfExists('inventory_goods_receipts');
        Schema::dropIfExists('inventory_purchase_order_lines');
        Schema::dropIfExists('inventory_purchase_orders');
        Schema::dropIfExists('inventory_suppliers');
    }
};
