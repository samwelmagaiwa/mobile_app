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
        // Superseded no-op: this migration predates `payments`, `drivers` and
        // `users` (all created by later migrations) and referenced them with
        // bigint foreign keys that no longer match `users.id`, which is now a
        // UUID. It only ever "worked" because Laravel never re-runs a
        // migration once recorded, so an incrementally-built database never
        // hit this. A from-scratch `migrate` does, and fails here.
        // `2025_10_13_083551_recreate_payments_and_payment_receipts_tables`
        // is the current, correct definition of `payment_receipts` (UUID
        // driver_id/generated_by) and fully supersedes this one.
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('payment_receipts');
    }
};