<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('rental_receipts', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('payment_id');
            $table->string('receipt_number')->unique();
            $table->json('details'); // Snapshot of tenant name, house, period, etc.
            $table->timestamps();

            $table->foreign('payment_id')->references('id')->on('rental_payments')->onDelete('cascade');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('rental_receipts');
    }
};
