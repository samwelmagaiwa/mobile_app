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
        Schema::create('receipts', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('transaction_id');
            $table->string('receipt_number')->unique();
            $table->string('customer_name');
            $table->string('customer_phone', 20)->nullable();
            $table->text('service_description');
            $table->decimal('amount', 15, 2);
            $table->text('notes')->nullable();
            $table->string('file_path')->nullable();
            $table->datetime('issued_at');
            $table->boolean('is_printed')->default(false);
            $table->datetime('printed_at')->nullable();
            $table->boolean('is_emailed')->default(false);
            $table->datetime('emailed_at')->nullable();
            $table->string('email_address')->nullable();
            $table->enum('format', ['pdf', 'thermal', 'a4'])->default('pdf');
            $table->json('metadata')->nullable(); // For storing additional receipt data
            $table->timestamps();

            // Indexes
            $table->index('transaction_id');
            $table->index('receipt_number');
            $table->index('issued_at');
            $table->index('is_printed');
            $table->index('customer_name');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('receipts');
    }
};