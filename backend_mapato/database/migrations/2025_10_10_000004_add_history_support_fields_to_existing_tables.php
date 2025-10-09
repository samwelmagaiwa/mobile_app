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
        // Add additional fields to drivers table for better history tracking
        Schema::table('drivers', function (Blueprint $table) {
            // Add fields if they don't already exist
            if (!Schema::hasColumn('drivers', 'vehicle_number')) {
                $table->string('vehicle_number')->nullable()->after('total_earnings');
            }
            if (!Schema::hasColumn('drivers', 'vehicle_type')) {
                $table->enum('vehicle_type', ['bajaji', 'pikipiki', 'gari'])->nullable()->after('vehicle_number');
            }
            if (!Schema::hasColumn('drivers', 'status_changed_at')) {
                $table->timestamp('status_changed_at')->nullable()->after('is_active');
            }
            if (!Schema::hasColumn('drivers', 'status_changed_by')) {
                $table->uuid('status_changed_by')->nullable()->after('status_changed_at');
            }
            if (!Schema::hasColumn('drivers', 'last_trip_date')) {
                $table->date('last_trip_date')->nullable()->after('total_trips');
            }
            if (!Schema::hasColumn('drivers', 'performance_score')) {
                $table->decimal('performance_score', 5, 2)->default(0.00)->after('rating');
            }
        });

        // Add additional fields to payments table if not already present
        Schema::table('payments', function (Blueprint $table) {
            if (!Schema::hasColumn('payments', 'receipt_generated')) {
                $table->boolean('receipt_generated')->default(false)->after('status');
            }
            if (!Schema::hasColumn('payments', 'receipt_sent')) {
                $table->boolean('receipt_sent')->default(false)->after('receipt_generated');
            }
            if (!Schema::hasColumn('payments', 'payment_delay_days')) {
                $table->integer('payment_delay_days')->default(0)->after('payment_date');
            }
            if (!Schema::hasColumn('payments', 'transaction_reference')) {
                $table->string('transaction_reference')->nullable()->after('payment_channel');
            }
        });

        // Add additional fields to debt_records table for better tracking
        Schema::table('debt_records', function (Blueprint $table) {
            if (!Schema::hasColumn('debt_records', 'created_by')) {
                $table->uuid('created_by')->nullable()->after('notes');
            }
            if (!Schema::hasColumn('debt_records', 'updated_by')) {
                $table->uuid('updated_by')->nullable()->after('created_by');
            }
            if (!Schema::hasColumn('debt_records', 'debt_category')) {
                $table->enum('debt_category', ['daily_return', 'maintenance', 'penalty', 'other'])->default('daily_return')->after('expected_amount');
            }
            if (!Schema::hasColumn('debt_records', 'priority_level')) {
                $table->enum('priority_level', ['low', 'medium', 'high', 'critical'])->default('medium')->after('days_overdue');
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        // Remove added fields from drivers table
        Schema::table('drivers', function (Blueprint $table) {
            $table->dropColumn([
                'vehicle_number', 
                'vehicle_type', 
                'status_changed_at', 
                'status_changed_by',
                'last_trip_date',
                'performance_score'
            ]);
        });

        // Remove added fields from payments table
        Schema::table('payments', function (Blueprint $table) {
            $table->dropColumn([
                'receipt_generated', 
                'receipt_sent', 
                'payment_delay_days',
                'transaction_reference'
            ]);
        });

        // Remove added fields from debt_records table
        Schema::table('debt_records', function (Blueprint $table) {
            $table->dropColumn([
                'created_by', 
                'updated_by', 
                'debt_category',
                'priority_level'
            ]);
        });
    }
};