<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        // First drop foreign key constraints that reference payments
        if (Schema::hasTable('debt_records')) {
            Schema::table('debt_records', function (Blueprint $table) {
                // Some DBs name FKs implicitly; using column array form is safest
                try { $table->dropForeign(['payment_id']); } catch (\Throwable $e) {}
            });
        }

        // Drop Simamia Malipo related tables
        if (Schema::hasTable('payment_receipts')) {
            Schema::drop('payment_receipts');
        }
        if (Schema::hasTable('payments')) {
            Schema::drop('payments');
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        // Recreate payments table
        if (!Schema::hasTable('payments')) {
            Schema::create('payments', function (Blueprint $table) {
                $table->id();
                $table->string('reference_number')->unique();
                $table->uuid('driver_id');
                $table->decimal('amount', 12, 2);
                $table->enum('payment_channel', ['cash', 'mpesa', 'bank', 'mobile', 'other'])->default('cash');
                $table->text('remarks')->nullable();
                $table->json('covers_days');
                $table->enum('status', ['pending', 'completed', 'cancelled'])->default('completed');
                $table->timestamp('payment_date')->useCurrent();
                $table->uuid('recorded_by');
                $table->string('receipt_status')->nullable();
                $table->timestamps();
                $table->index(['driver_id', 'payment_date']);
                $table->index(['reference_number']);
                $table->index(['status']);
            });
        }

        // Recreate payment_receipts table
        if (!Schema::hasTable('payment_receipts')) {
            Schema::create('payment_receipts', function (Blueprint $table) {
                $table->id();
                $table->string('receipt_number')->unique();
                $table->foreignId('payment_id')->constrained('payments')->onDelete('cascade');
                $table->uuid('driver_id');
                $table->foreign('driver_id')->references('id')->on('drivers')->onDelete('cascade');
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

        // Re-add FK on debt_records.payment_id
        if (Schema::hasTable('debt_records')) {
            // Clean up any invalid references before adding FK
            try {
                DB::statement('UPDATE debt_records SET payment_id = NULL WHERE payment_id IS NOT NULL AND payment_id NOT IN (SELECT id FROM payments)');
            } catch (\Throwable $e) {}
            Schema::table('debt_records', function (Blueprint $table) {
                try { $table->foreign('payment_id')->references('id')->on('payments')->nullOnDelete(); } catch (\Throwable $e) {}
            });
        }
    }
};
