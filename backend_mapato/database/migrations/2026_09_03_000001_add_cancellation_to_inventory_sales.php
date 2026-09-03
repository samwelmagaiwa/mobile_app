<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('inventory_sales', function (Blueprint $table) {
            $table->timestamp('cancelled_at')->nullable()->after('due_date');
            $table->string('cancellation_reason', 255)->nullable()->after('cancelled_at');
            $table->index('cancelled_at');
        });
    }

    public function down(): void
    {
        Schema::table('inventory_sales', function (Blueprint $table) {
            $table->dropIndex(['cancelled_at']);
            $table->dropColumn(['cancelled_at', 'cancellation_reason']);
        });
    }
};
