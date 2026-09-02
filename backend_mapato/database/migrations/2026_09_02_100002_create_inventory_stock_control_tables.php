<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Area 3 — Stock control & inventory.
 *
 * Batches with expiry dates (issued oldest-expiring first), physical stock
 * counts with variance, and write-offs for damages / breakages / expired goods
 * that need approval before they touch stock.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('inventory_batches', function (Blueprint $table) {
            $table->id();
            $table->foreignId('product_id')->constrained('inventory_products')->cascadeOnDelete();
            $table->string('batch_number', 64);
            $table->date('expiry_date')->nullable()->index();
            $table->unsignedInteger('quantity')->default(0);
            $table->unsignedInteger('received_quantity')->default(0);
            $table->decimal('cost_price', 12, 2)->default(0);
            $table->date('received_at')->nullable();
            $table->string('reference')->nullable();
            $table->enum('status', ['active', 'depleted', 'quarantined'])->default('active')->index();
            $table->unsignedBigInteger('created_by')->nullable();
            $table->timestamps();
            $table->unique(['product_id', 'batch_number']);
            // FEFO reads this: oldest expiry first, among batches with stock.
            $table->index(['product_id', 'status', 'expiry_date'], 'inv_batch_fefo');
        });

        Schema::table('inventory_stock_movements', function (Blueprint $table) {
            $table->foreignId('batch_id')->nullable()->after('product_id')
                ->constrained('inventory_batches')->nullOnDelete();
            $table->string('reason', 64)->nullable()->after('quantity');
        });

        // A physical count: opened, lines captured, then posted so variances
        // become stock adjustments. Nothing moves until it is posted.
        Schema::create('inventory_stock_counts', function (Blueprint $table) {
            $table->id();
            $table->string('reference', 64)->unique();
            $table->enum('status', ['draft', 'posted', 'cancelled'])->default('draft')->index();
            $table->string('note')->nullable();
            $table->unsignedBigInteger('counted_by')->nullable();
            $table->unsignedBigInteger('posted_by')->nullable();
            $table->timestamp('posted_at')->nullable();
            $table->timestamps();
        });

        Schema::create('inventory_stock_count_lines', function (Blueprint $table) {
            $table->id();
            $table->foreignId('stock_count_id')->constrained('inventory_stock_counts')->cascadeOnDelete();
            $table->foreignId('product_id')->constrained('inventory_products')->restrictOnDelete();
            $table->foreignId('batch_id')->nullable()->constrained('inventory_batches')->nullOnDelete();
            $table->integer('system_quantity')->default(0);
            $table->integer('counted_quantity')->default(0);
            $table->integer('variance')->default(0);
            $table->string('note')->nullable();
            $table->timestamps();
            $table->unique(['stock_count_id', 'product_id', 'batch_id'], 'inv_count_line_unique');
        });

        // Damages, breakages and expired goods. Stock only moves on approval.
        Schema::create('inventory_write_offs', function (Blueprint $table) {
            $table->id();
            $table->string('reference', 64)->unique();
            $table->foreignId('product_id')->constrained('inventory_products')->restrictOnDelete();
            $table->foreignId('batch_id')->nullable()->constrained('inventory_batches')->nullOnDelete();
            $table->enum('reason', ['damage', 'breakage', 'expiry', 'theft', 'other'])->index();
            $table->unsignedInteger('quantity');
            $table->decimal('cost_value', 12, 2)->default(0);
            $table->string('note')->nullable();
            $table->enum('status', ['pending', 'approved', 'rejected'])->default('pending')->index();
            $table->unsignedBigInteger('requested_by')->nullable();
            $table->unsignedBigInteger('approved_by')->nullable();
            $table->timestamp('approved_at')->nullable();
            $table->string('decision_note')->nullable();
            $table->timestamps();
        });

        $this->backfillOpeningBatches();
    }

    /**
     * Products already holding stock have no batch. Give each one an opening
     * batch so FEFO has something to issue from and valuations balance.
     */
    private function backfillOpeningBatches(): void
    {
        $products = DB::table('inventory_products')
            ->where('quantity', '>', 0)
            ->get(['id', 'quantity', 'cost_price']);

        foreach ($products as $product) {
            DB::table('inventory_batches')->insert([
                'product_id' => $product->id,
                'batch_number' => 'OPENING',
                'expiry_date' => null,
                'quantity' => $product->quantity,
                'received_quantity' => $product->quantity,
                'cost_price' => $product->cost_price,
                'received_at' => now()->toDateString(),
                'reference' => 'Opening balance',
                'status' => 'active',
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('inventory_write_offs');
        Schema::dropIfExists('inventory_stock_count_lines');
        Schema::dropIfExists('inventory_stock_counts');

        Schema::table('inventory_stock_movements', function (Blueprint $table) {
            $table->dropConstrainedForeignId('batch_id');
            $table->dropColumn('reason');
        });

        Schema::dropIfExists('inventory_batches');
    }
};
