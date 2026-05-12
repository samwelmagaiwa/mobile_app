<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('rental_payments', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('bill_id')->nullable(); // Can be null for advance payments
            $table->uuid('tenant_id');
            $table->decimal('amount_paid', 15, 2);
            $table->date('payment_date');
            $table->enum('payment_method', ['cash', 'bank_transfer', 'm-pesa', 'airtel_money', 'tigo_pesa'])->default('cash');
            $table->string('transaction_reference')->nullable();
            $table->uuid('collector_id'); // User ID (landlord or caretaker)
            $table->text('notes')->nullable();
            $table->timestamps();

            $table->foreign('bill_id')->references('id')->on('rental_bills')->onDelete('set null');
            $table->foreign('tenant_id')->references('id')->on('users')->onDelete('cascade');
            $table->foreign('collector_id')->references('id')->on('users')->onDelete('cascade');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('rental_payments');
    }
};
