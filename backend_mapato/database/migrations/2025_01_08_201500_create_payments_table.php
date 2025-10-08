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
if (!Schema::hasTable('payments')) {
            Schema::create('payments', function (Blueprint $table) {
            $table->id();
            $table->string('reference_number')->unique();
            // Use UUIDs for related models to match existing schema; omit FKs for compatibility
            $table->uuid('driver_id');
            $table->decimal('amount', 12, 2);
            $table->enum('payment_channel', ['cash', 'mpesa', 'bank', 'mobile', 'other'])->default('cash');
            $table->text('remarks')->nullable();
            $table->json('covers_days'); // Array of dates this payment covers
            $table->enum('status', ['pending', 'completed', 'cancelled'])->default('completed');
            $table->timestamp('payment_date')->useCurrent();
            $table->uuid('recorded_by');
            $table->timestamps();
            
            // Indexes for better performance
            $table->index(['driver_id', 'payment_date']);
            $table->index(['reference_number']);
            $table->index(['status']);
        });
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('payments');
    }
};