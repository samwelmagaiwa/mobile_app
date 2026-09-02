<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('rental_houses', function (Blueprint $table) {
            $table->enum('billing_cycle', ['monthly', 'quarterly', 'yearly'])->default('monthly')->after('status');
            $table->string('currency', 10)->default('TZS')->after('billing_cycle');
            $table->boolean('utility_billing_enabled')->default(false)->after('currency');
            $table->text('ownership_notes')->nullable()->after('description');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('rental_houses', function (Blueprint $table) {
            $table->dropColumn(['billing_cycle', 'currency', 'utility_billing_enabled', 'ownership_notes']);
        });
    }
};
