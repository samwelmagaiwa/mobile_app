<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('debt_records', function (Blueprint $table) {
            if (!Schema::hasColumn('debt_records', 'license_number')) {
                $table->string('license_number')->nullable()->after('notes');
            }
        });

        // Attempt to backfill license numbers from drivers table when possible
        try {
            DB::statement('UPDATE debt_records dr JOIN drivers d ON dr.driver_id = d.id SET dr.license_number = d.license_number WHERE dr.license_number IS NULL');
        } catch (\Throwable $e) {
            // ignore if DB driver doesn't support the JOIN update
        }
    }

    public function down(): void
    {
        Schema::table('debt_records', function (Blueprint $table) {
            if (Schema::hasColumn('debt_records', 'license_number')) {
                $table->dropColumn('license_number');
            }
        });
    }
};