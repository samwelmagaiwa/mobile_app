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
        Schema::create('payment_receipts', function (Blueprint $table) {
            $table->id();
            $table->string('receipt_number')->unique();
            $table->foreignId('payment_id')->constrained('payments')->onDelete('cascade');
            $table->foreignId('driver_id')->constrained('drivers')->onDelete('cascade');
            $table->foreignId('generated_by')->constrained('users')->onDelete('cascade');
            $table->decimal('amount', 10, 2);
            $table->string('payment_period'); // e.g., "5 siku", "2 wiki", "1 mwezi"
            $table->text('covered_days'); // JSON array of covered dates
            $table->enum('status', ['generated', 'sent', 'delivered'])->default('generated');
            $table->timestamp('generated_at');
            $table->timestamp('sent_at')->nullable();
            $table->string('sent_via')->nullable(); // whatsapp, email, system
            $table->text('receipt_data'); // JSON with full receipt details
            $table->timestamps();
            
            $table->index(['driver_id', 'status']);
            $table->index(['payment_id']);
            $table->index(['generated_by']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('payment_receipts');
    }
};