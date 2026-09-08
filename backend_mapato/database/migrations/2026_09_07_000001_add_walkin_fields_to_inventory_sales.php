<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('inventory_sales', function (Blueprint $table) {
            // Walk-in customer details captured at point of sale
            $table->string('customer_name_override')->nullable()->after('customer_id');
            $table->string('customer_phone_override')->nullable()->after('customer_name_override');
        });
    }

    public function down(): void
    {
        Schema::table('inventory_sales', function (Blueprint $table) {
            $table->dropColumn(['customer_name_override', 'customer_phone_override']);
        });
    }
};
