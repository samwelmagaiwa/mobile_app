<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

/**
 * The users.role enum was only ever widened for super_admin/landlord/
 * caretaker/tenant/vendor, but the app's own validators and role dropdowns
 * have offered 'manager', 'operator' and 'viewer' for a while -- creating
 * one of those would fail at the DB with a truncated-enum error. Adds
 * those plus the new 'sales_officer' role (already permitted by every
 * inventory route's role_any:admin,manager,sales_officer middleware, but
 * never actually assignable to a user).
 */
return new class extends Migration
{
    public function up(): void
    {
        if (DB::getDriverName() !== 'sqlite') {
            DB::statement("ALTER TABLE users MODIFY COLUMN role ENUM('super_admin','admin','manager','operator','viewer','sales_officer','driver','landlord','caretaker','tenant','vendor') NOT NULL DEFAULT 'driver'");
        }
    }

    public function down(): void
    {
        if (DB::getDriverName() !== 'sqlite') {
            DB::statement("ALTER TABLE users MODIFY COLUMN role ENUM('super_admin','admin','driver','landlord','caretaker','tenant','vendor') NOT NULL DEFAULT 'driver'");
        }
    }
};
