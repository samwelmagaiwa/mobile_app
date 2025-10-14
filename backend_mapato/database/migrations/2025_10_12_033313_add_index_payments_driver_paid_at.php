<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('payments', function (Blueprint $table) {
            if (!Schema::hasColumn('payments', 'paid_at') && Schema::hasColumn('payments', 'payment_date')) {
                // In case column is named payment_date, add a computed index using that name
                $table->index(['driver_id', 'payment_date'], 'payments_driver_paymentdate_idx');
            } else {
                $table->index(['driver_id', 'paid_at'], 'payments_driver_paid_at_idx');
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('payments', function (Blueprint $table) {
            $table->dropIndex('payments_driver_paid_at_idx');
            $table->dropIndex('payments_driver_paymentdate_idx');
        });
    }
};
