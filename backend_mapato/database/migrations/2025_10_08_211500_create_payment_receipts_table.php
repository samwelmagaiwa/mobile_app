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
if (!Schema::hasTable('payment_receipts')) {
            Schema::create('payment_receipts', function (Blueprint $table) {
            $table->id();
            $table->string('receipt_number')->unique();
            // payments.id is bigint
            $table->foreignId('payment_id')->constrained('payments')->onDelete('cascade');
            // drivers.id is UUID
            $table->uuid('driver_id');
            $table->foreign('driver_id')->references('id')->on('drivers')->onDelete('cascade');
            // users.id is UUID
            $table->uuid('generated_by')->nullable();
            $table->foreign('generated_by')->references('id')->on('users')->onDelete('set null');
            $table->decimal('amount', 12, 2);
            $table->string('payment_period')->nullable();
            $table->json('covered_days')->nullable();
            $table->enum('status', ['generated', 'sent', 'delivered'])->default('generated');
            $table->timestamp('generated_at')->useCurrent();
            $table->timestamp('sent_at')->nullable();
            $table->string('sent_via')->nullable();
            $table->json('receipt_data')->nullable();
            $table->timestamps();

            $table->index(['driver_id']);
            $table->index(['payment_id']);
            $table->index(['status']);
            $table->index(['generated_at']);
        });
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('payment_receipts');
    }
};
