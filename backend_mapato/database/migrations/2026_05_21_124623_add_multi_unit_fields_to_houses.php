<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::table('rental_houses', function (Blueprint $table) {
            $table->integer('units_count')->default(0)->after('type');
            $table->json('unit_names')->nullable()->after('units_count');
        });
    }

    public function down(): void
    {
        Schema::table('rental_houses', function (Blueprint $table) {
            $table->dropColumn(['units_count', 'unit_names']);
        });
    }
};
