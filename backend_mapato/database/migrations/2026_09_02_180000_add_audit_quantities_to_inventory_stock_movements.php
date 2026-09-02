<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::table('inventory_stock_movements', function (Blueprint $table) {
            $table->unsignedInteger('previous_quantity')->default(0)->after('quantity');
            $table->unsignedInteger('new_quantity')->default(0)->after('previous_quantity');
        });
    }

    public function down(): void
    {
        Schema::table('inventory_stock_movements', function (Blueprint $table) {
            $table->dropColumn(['previous_quantity', 'new_quantity']);
        });
    }
};
