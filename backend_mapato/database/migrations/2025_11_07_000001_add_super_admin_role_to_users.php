<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        // Extend the enum to include super_admin
        DB::statement("ALTER TABLE users MODIFY COLUMN role ENUM('super_admin','admin','driver') NOT NULL DEFAULT 'driver'");
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        // Revert the enum to original values
        DB::statement("ALTER TABLE users MODIFY COLUMN role ENUM('admin','driver') NOT NULL DEFAULT 'driver'");
    }
};
