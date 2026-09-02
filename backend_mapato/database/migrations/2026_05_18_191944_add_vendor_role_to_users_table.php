<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration {
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        if (DB::getDriverName() !== 'sqlite') {
            DB::statement("ALTER TABLE users MODIFY COLUMN role ENUM('super_admin','admin','driver','landlord','caretaker','tenant','vendor') NOT NULL DEFAULT 'driver'");
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        if (DB::getDriverName() !== 'sqlite') {
            // On rollback, this could technically fail if there are active 'vendor' users, but for schema consistency:
            DB::statement("ALTER TABLE users MODIFY COLUMN role ENUM('super_admin','admin','driver','landlord','caretaker','tenant') NOT NULL DEFAULT 'driver'");
        }
    }
};
