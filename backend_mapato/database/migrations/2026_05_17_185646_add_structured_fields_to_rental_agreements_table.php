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
        Schema::table('rental_agreements', function (Blueprint $table) {
            $table->string('agreement_number')->unique()->nullable()->after('id');
            $table->uuid('property_id')->nullable()->after('tenant_id');
            $table->decimal('deposit_amount', 15, 2)->default(0)->after('rent_amount');
            $table->integer('due_day')->default(5)->after('deposit_paid');
            $table->integer('grace_period_days')->default(0)->after('due_day');
            $table->enum('late_fee_type', ['percentage', 'fixed', 'none'])->default('none')->after('grace_period_days');
            $table->decimal('late_fee_amount', 15, 2)->default(0)->after('late_fee_type');
            $table->json('utility_charges')->nullable()->after('late_fee_amount');
            $table->json('rules')->nullable()->after('utility_charges');
            $table->uuid('created_by')->nullable()->after('notes');

            $table->foreign('property_id')->references('id')->on('rental_properties')->onDelete('set null');
            $table->foreign('created_by')->references('id')->on('users')->onDelete('set null');
        });
    }

    public function down(): void
    {
        Schema::table('rental_agreements', function (Blueprint $table) {
            $table->dropForeign(['property_id']);
            $table->dropForeign(['created_by']);
            $table->dropColumn([
                'agreement_number',
                'property_id',
                'deposit_amount',
                'due_day',
                'grace_period_days',
                'late_fee_type',
                'late_fee_amount',
                'utility_charges',
                'rules',
                'created_by'
            ]);
        });
    }
};
