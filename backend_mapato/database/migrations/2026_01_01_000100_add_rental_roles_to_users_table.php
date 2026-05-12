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
        // Extend the enum to include rental roles
        DB::statement("ALTER TABLE users MODIFY COLUMN role ENUM('super_admin','admin','driver','landlord','caretaker','tenant') NOT NULL DEFAULT 'driver'");
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        // Revert the enum to previous values
        DB::statement("ALTER TABLE users MODIFY COLUMN role ENUM('super_admin','admin','driver') NOT NULL DEFAULT 'driver'");
    }
};
