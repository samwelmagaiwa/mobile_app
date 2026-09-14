<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Lets a product's unit carry a custom quantity (e.g. "per 5 KG" instead of
 * always "per 1 KG"), set once at product creation/edit and mirrored onto
 * the product's base row in inventory_product_units.factor.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('inventory_products', function (Blueprint $table) {
            $table->unsignedInteger('unit_factor')->default(1)->after('unit');
        });
    }

    public function down(): void
    {
        Schema::table('inventory_products', function (Blueprint $table) {
            $table->dropColumn('unit_factor');
        });
    }
};
