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
        Schema::create('transactions', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('driver_id');
            $table->uuid('device_id');
            $table->decimal('amount', 15, 2);
            $table->enum('type', ['income', 'expense']);
            $table->string('category', 100);
            $table->text('description');
            $table->string('customer_name')->nullable();
            $table->string('customer_phone', 20)->nullable();
            $table->enum('status', ['pending', 'completed', 'cancelled'])->default('pending');
            $table->text('notes')->nullable();
            $table->datetime('transaction_date');
            $table->string('reference_number')->unique();
            $table->enum('payment_method', ['cash', 'mobile_money', 'bank_transfer', 'card'])->default('cash');
            $table->string('payment_reference')->nullable();
            $table->decimal('tax_amount', 10, 2)->default(0.00);
            $table->decimal('commission', 10, 2)->default(0.00);
            $table->string('location')->nullable();
            $table->decimal('latitude', 10, 8)->nullable();
            $table->decimal('longitude', 11, 8)->nullable();
            $table->timestamps();

            // Indexes
            $table->index('driver_id');
            $table->index('device_id');
            $table->index('type');
            $table->index('status');
            $table->index('category');
            $table->index('transaction_date');
            $table->index('reference_number');
            $table->index('payment_method');
            $table->index(['driver_id', 'transaction_date']);
            $table->index(['device_id', 'transaction_date']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('transactions');
    }
};