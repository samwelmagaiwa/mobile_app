<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Areas 5, 9, 10, 12 and 13.
 *
 *  5 — parked sales, returns, cheque/bank payments, discount limits.
 *  9 — vehicle dispatch, route sales, return reconciliation.
 * 10 — barcode labels.
 * 12 — alerts.
 * 13 — audit trail and depot settings.
 */
return new class extends Migration
{
    public function up(): void
    {
        // ---------------------------------------------------------- Area 5
        Schema::table('inventory_sale_payments', function (Blueprint $table) {
            $table->string('method_extended', 32)->nullable()->after('method');
        });

        Schema::create('inventory_parked_sales', function (Blueprint $table) {
            $table->id();
            $table->string('reference', 64)->unique();
            $table->foreignId('customer_id')->nullable()
                ->constrained('inventory_customers')->nullOnDelete();
            $table->json('cart');
            $table->decimal('total', 14, 2)->default(0);
            $table->string('note')->nullable();
            $table->unsignedBigInteger('parked_by')->nullable();
            $table->enum('status', ['parked', 'resumed', 'discarded'])
                ->default('parked')->index();
            $table->timestamps();
        });

        Schema::create('inventory_sale_returns', function (Blueprint $table) {
            $table->id();
            $table->string('reference', 64)->unique();
            $table->foreignId('sale_id')->constrained('inventory_sales')->restrictOnDelete();
            $table->enum('type', ['return', 'cancellation'])->default('return')->index();
            $table->decimal('amount', 14, 2)->default(0);
            $table->string('reason')->nullable();
            $table->enum('status', ['pending', 'approved', 'rejected'])
                ->default('pending')->index();
            $table->unsignedBigInteger('requested_by')->nullable();
            $table->unsignedBigInteger('approved_by')->nullable();
            $table->timestamp('approved_at')->nullable();
            $table->timestamps();
        });

        Schema::create('inventory_sale_return_lines', function (Blueprint $table) {
            $table->id();
            $table->foreignId('sale_return_id')->constrained('inventory_sale_returns')->cascadeOnDelete();
            $table->foreignId('product_id')->constrained('inventory_products')->restrictOnDelete();
            $table->unsignedInteger('quantity');
            $table->decimal('unit_price', 12, 2)->default(0);
            $table->boolean('restock')->default(true);
            $table->timestamps();
        });

        // ---------------------------------------------------------- Area 9
        Schema::create('inventory_dispatches', function (Blueprint $table) {
            $table->id();
            $table->string('reference', 64)->unique();
            $table->string('vehicle', 64)->nullable();
            $table->unsignedBigInteger('agent_id')->nullable();
            $table->string('route')->nullable();
            $table->date('dispatch_date')->index();
            $table->enum('status', ['loading', 'on_route', 'reconciled', 'cancelled'])
                ->default('loading')->index();
            $table->decimal('cash_expected', 14, 2)->default(0);
            $table->decimal('cash_returned', 14, 2)->default(0);
            $table->string('note')->nullable();
            $table->unsignedBigInteger('created_by')->nullable();
            $table->timestamp('reconciled_at')->nullable();
            $table->timestamps();
        });

        Schema::create('inventory_dispatch_lines', function (Blueprint $table) {
            $table->id();
            $table->foreignId('dispatch_id')->constrained('inventory_dispatches')->cascadeOnDelete();
            $table->foreignId('product_id')->constrained('inventory_products')->restrictOnDelete();
            $table->foreignId('batch_id')->nullable()->constrained('inventory_batches')->nullOnDelete();
            $table->unsignedInteger('loaded_quantity');
            $table->unsignedInteger('returned_quantity')->default(0);
            $table->unsignedInteger('sold_quantity')->default(0);
            $table->decimal('unit_price', 12, 2)->default(0);
            $table->timestamps();
        });

        // ---------------------------------------------------------- Area 10
        Schema::create('inventory_barcode_labels', function (Blueprint $table) {
            $table->id();
            $table->enum('entity_type', ['product_unit', 'batch', 'crate'])->index();
            $table->unsignedBigInteger('entity_id');
            $table->string('code', 64)->unique();
            $table->unsignedInteger('printed_count')->default(0);
            $table->timestamp('last_printed_at')->nullable();
            $table->timestamps();
            $table->index(['entity_type', 'entity_id']);
        });

        // ---------------------------------------------------------- Area 12
        Schema::create('inventory_alerts', function (Blueprint $table) {
            $table->id();
            $table->string('type', 48)->index();
            $table->string('severity', 16)->default('info');
            $table->string('title');
            $table->string('body')->nullable();
            $table->string('entity_type', 48)->nullable();
            $table->unsignedBigInteger('entity_id')->nullable();
            $table->enum('status', ['open', 'acknowledged', 'resolved'])
                ->default('open')->index();
            $table->timestamp('created_at')->useCurrent();
            $table->timestamp('resolved_at')->nullable();
            $table->unique(['type', 'entity_type', 'entity_id'], 'inv_alert_unique');
        });

        // ---------------------------------------------------------- Area 13
        Schema::create('inventory_audit_log', function (Blueprint $table) {
            $table->id();
            $table->string('entity_type', 64)->index();
            $table->unsignedBigInteger('entity_id')->nullable();
            $table->string('action', 48)->index();
            $table->json('before')->nullable();
            $table->json('after')->nullable();
            $table->string('summary')->nullable();
            $table->unsignedBigInteger('user_id')->nullable()->index();
            $table->string('user_name')->nullable();
            $table->timestamp('created_at')->useCurrent();
            $table->index(['entity_type', 'entity_id']);
        });

        Schema::create('inventory_settings', function (Blueprint $table) {
            $table->string('key', 64)->primary();
            $table->text('value')->nullable();
            $table->timestamp('updated_at')->nullable();
        });

        $this->seedDefaults();
    }

    private function seedDefaults(): void
    {
        $defaults = [
            'depot_name' => 'Beverage Depot',
            'depot_phone' => '',
            'depot_address' => '',
            'invoice_prefix' => 'INV',
            'invoice_next_number' => '1',
            'tax_percent' => '0',
            'max_discount_percent' => '10',
            'low_stock_threshold' => '5',
            'expiry_alert_days' => '30',
            'overdue_alert_days' => '7',
            'large_discount_percent' => '15',
        ];

        foreach ($defaults as $key => $value) {
            DB::table('inventory_settings')->insert([
                'key' => $key,
                'value' => $value,
                'updated_at' => now(),
            ]);
        }

        foreach ([['Crate', 2000], ['Empty bottle', 100]] as [$name, $deposit]) {
            DB::table('inventory_crate_types')->insert([
                'name' => $name,
                'deposit_value' => $deposit,
                'status' => 'active',
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('inventory_settings');
        Schema::dropIfExists('inventory_audit_log');
        Schema::dropIfExists('inventory_alerts');
        Schema::dropIfExists('inventory_barcode_labels');
        Schema::dropIfExists('inventory_dispatch_lines');
        Schema::dropIfExists('inventory_dispatches');
        Schema::dropIfExists('inventory_sale_return_lines');
        Schema::dropIfExists('inventory_sale_returns');
        Schema::dropIfExists('inventory_parked_sales');

        Schema::table('inventory_sale_payments', function (Blueprint $table) {
            $table->dropColumn('method_extended');
        });
    }
};
