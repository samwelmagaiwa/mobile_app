<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Area 2 — Products, units & pricing.
 *
 * Adds the catalog backbone: categories, brands, per-product selling units
 * (bottle / pack / crate) with their own prices, tiered pricing
 * (retail / wholesale / special) and an immutable price-change log.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('inventory_categories', function (Blueprint $table) {
            $table->id();
            $table->string('name')->unique();
            $table->string('description')->nullable();
            $table->enum('status', ['active', 'inactive'])->default('active')->index();
            $table->unsignedBigInteger('created_by')->nullable();
            $table->timestamps();
        });

        Schema::create('inventory_brands', function (Blueprint $table) {
            $table->id();
            $table->string('name')->unique();
            $table->string('description')->nullable();
            $table->enum('status', ['active', 'inactive'])->default('active')->index();
            $table->unsignedBigInteger('created_by')->nullable();
            $table->timestamps();
        });

        Schema::table('inventory_products', function (Blueprint $table) {
            $table->foreignId('category_id')->nullable()->after('category')
                ->constrained('inventory_categories')->nullOnDelete();
            $table->foreignId('brand_id')->nullable()->after('category_id')
                ->constrained('inventory_brands')->nullOnDelete();
        });

        // A product is stocked in one base unit but may be sold as bottle, pack
        // or crate. `factor` is how many base units this selling unit contains.
        Schema::create('inventory_product_units', function (Blueprint $table) {
            $table->id();
            $table->foreignId('product_id')->constrained('inventory_products')->cascadeOnDelete();
            $table->string('name', 32);
            $table->unsignedInteger('factor')->default(1);
            $table->boolean('is_base')->default(false);
            $table->string('barcode')->nullable()->index();
            $table->enum('status', ['active', 'inactive'])->default('active')->index();
            $table->timestamps();
            $table->unique(['product_id', 'name']);
        });

        // Current price per unit per tier. `customer_id` is only used by the
        // `special` tier, to price one unit for one customer.
        Schema::create('inventory_product_prices', function (Blueprint $table) {
            $table->id();
            $table->foreignId('product_unit_id')->constrained('inventory_product_units')->cascadeOnDelete();
            $table->enum('tier', ['retail', 'wholesale', 'special'])->index();
            $table->foreignId('customer_id')->nullable()->constrained('inventory_customers')->cascadeOnDelete();
            $table->decimal('price', 12, 2)->default(0);
            $table->date('effective_from')->nullable();
            $table->unsignedBigInteger('created_by')->nullable();
            $table->timestamps();
            $table->unique(['product_unit_id', 'tier', 'customer_id'], 'inv_price_unique');
        });

        // Append-only: every price write leaves a row here. Never updated.
        Schema::create('inventory_price_changes', function (Blueprint $table) {
            $table->id();
            $table->foreignId('product_unit_id')->constrained('inventory_product_units')->cascadeOnDelete();
            $table->enum('tier', ['retail', 'wholesale', 'special'])->index();
            $table->unsignedBigInteger('customer_id')->nullable();
            $table->decimal('old_price', 12, 2)->nullable();
            $table->decimal('new_price', 12, 2);
            $table->string('reason')->nullable();
            $table->unsignedBigInteger('changed_by')->nullable();
            $table->timestamp('created_at')->useCurrent();
            $table->index(['product_unit_id', 'created_at']);
        });

        // Backs SkuGenerator: one row per category code, locked on write so
        // two concurrent product creations in the same category never
        // collide on the same sequence number.
        Schema::create('inventory_sku_sequences', function (Blueprint $table) {
            $table->string('category_code', 6)->primary();
            $table->unsignedInteger('last_seq')->default(0);
            $table->timestamps();
        });

        $this->backfillBaseUnits();
    }

    /**
     * Existing products predate units, so give each one a base selling unit
     * carrying its current selling price as the retail tier. Without this the
     * POS would find no sellable unit for stock that already exists.
     */
    private function backfillBaseUnits(): void
    {
        $products = DB::table('inventory_products')->get(['id', 'unit', 'selling_price']);

        foreach ($products as $product) {
            $unitId = DB::table('inventory_product_units')->insertGetId([
                'product_id' => $product->id,
                'name' => $product->unit ?: 'pcs',
                'factor' => 1,
                'is_base' => true,
                'status' => 'active',
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            DB::table('inventory_product_prices')->insert([
                'product_unit_id' => $unitId,
                'tier' => 'retail',
                'customer_id' => null,
                'price' => $product->selling_price,
                'effective_from' => now()->toDateString(),
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('inventory_sku_sequences');
        Schema::dropIfExists('inventory_price_changes');
        Schema::dropIfExists('inventory_product_prices');
        Schema::dropIfExists('inventory_product_units');

        Schema::table('inventory_products', function (Blueprint $table) {
            $table->dropConstrainedForeignId('brand_id');
            $table->dropConstrainedForeignId('category_id');
        });

        Schema::dropIfExists('inventory_brands');
        Schema::dropIfExists('inventory_categories');
    }
};
