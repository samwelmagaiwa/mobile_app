<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->string('service_type')->nullable()->after('role');
        });

        // Set backend defaults for existing users based on roles
        \Illuminate\Support\Facades\DB::table('users')
            ->whereIn('role', ['landlord', 'caretaker', 'tenant'])
            ->update(['service_type' => 'rental']);

        \Illuminate\Support\Facades\DB::table('users')
            ->whereIn('role', ['driver', 'operator'])
            ->update(['service_type' => 'transport']);
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn('service_type');
        });
    }
};
