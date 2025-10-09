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
        Schema::table('driver_agreements', function (Blueprint $table) {
            // Add contract-specific fields
            $table->decimal('vehicle_payment', 15, 2)->nullable()->after('kiasi_cha_makubaliano');
            $table->decimal('daily_target', 15, 2)->nullable()->after('vehicle_payment');
            $table->integer('contract_period_months')->nullable()->after('daily_target');
            
            // Add daily work fields  
            $table->decimal('salary_amount', 15, 2)->nullable()->after('contract_period_months');
            $table->decimal('bonus_amount', 15, 2)->nullable()->after('salary_amount');
            
            // Add notes field
            $table->text('notes')->nullable()->after('payment_frequencies');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('driver_agreements', function (Blueprint $table) {
            $table->dropColumn([
                'vehicle_payment',
                'daily_target', 
                'contract_period_months',
                'salary_amount',
                'bonus_amount',
                'notes'
            ]);
        });
    }
};
