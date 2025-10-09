<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('payments')) {
            // Ensure driver_id can store UUIDs
            DB::statement("ALTER TABLE `payments` MODIFY COLUMN `driver_id` CHAR(36) NOT NULL");
        }
    }

    public function down(): void
    {
        // No-op: reverting type safely is ambiguous; skip
    }
};