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
        Schema::create('driver_performance_metrics', function (Blueprint $table) {
            $table->id();
            $table->uuid('driver_id')->unique();
            
            // Payment consistency metrics
            $table->enum('payment_consistency_rating', ['excellent', 'good', 'fair', 'poor', 'critical'])->default('fair');
            $table->integer('average_payment_delay_days')->default(0);
            $table->decimal('payment_punctuality_percentage', 5, 2)->default(100.00);
            
            // Financial performance metrics
            $table->decimal('total_amount_submitted', 15, 2)->default(0);
            $table->decimal('total_outstanding_debt', 15, 2)->default(0);
            $table->decimal('total_debts_recorded', 15, 2)->default(0);
            $table->decimal('total_paid_amount', 15, 2)->default(0);
            $table->decimal('debt_to_earnings_ratio', 5, 2)->default(0.00);
            
            // Trip performance metrics
            $table->integer('total_completed_trips')->default(0);
            $table->integer('total_cancelled_trips')->default(0);
            $table->decimal('trip_completion_rate', 5, 2)->default(100.00);
            $table->decimal('average_trip_rating', 3, 2)->default(0.00);
            $table->integer('total_ratings_count')->default(0);
            
            // Time-based metrics
            $table->date('first_trip_date')->nullable();
            $table->date('last_trip_date')->nullable();
            $table->date('last_payment_date')->nullable();
            $table->integer('days_since_last_payment')->default(0);
            $table->integer('consecutive_late_payments')->default(0);
            $table->integer('consecutive_ontime_payments')->default(0);
            
            // Performance scores (calculated)
            $table->decimal('overall_performance_score', 5, 2)->default(0.00); // 0-100
            $table->enum('performance_grade', ['A', 'B', 'C', 'D', 'F'])->default('C');
            $table->boolean('is_at_risk')->default(false);
            $table->text('performance_notes')->nullable();
            
            // Metadata
            $table->timestamp('last_calculated_at')->nullable();
            $table->json('calculation_metadata')->nullable();
            $table->timestamps();
            
            // Indexes
            $table->index(['driver_id']);
            $table->index(['payment_consistency_rating']);
            $table->index(['performance_grade']);
            $table->index(['is_at_risk']);
            $table->index(['last_calculated_at']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('driver_performance_metrics');
    }
};