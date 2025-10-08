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
Schema::create('debt_records', function (Blueprint $table) {
            $table->id();
            // Use UUID for driver_id; FK omitted to be compatible with existing data types
            $table->uuid('driver_id');
            $table->date('earning_date');
            $table->decimal('expected_amount', 10, 2); // Expected daily return
            $table->decimal('paid_amount', 10, 2)->default(0); // Amount actually paid
            $table->boolean('is_paid')->default(false);
            // payments.id is bigint
            $table->foreignId('payment_id')->nullable()->constrained('payments')->onDelete('set null');
            $table->timestamp('paid_at')->nullable();
            $table->integer('days_overdue')->default(0);
            $table->text('notes')->nullable();
            $table->timestamps();
            
            // Unique constraint to prevent duplicate records
            $table->unique(['driver_id', 'earning_date']);
            
            // Indexes for performance
            $table->index(['driver_id', 'is_paid']);
            $table->index(['earning_date']);
            $table->index(['is_paid']);
            $table->index(['days_overdue']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('debt_records');
    }
};