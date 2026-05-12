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
        Schema::table('rental_tenant_profiles', function (Blueprint $table) {
            $table->string('gender')->nullable()->after('user_id');
            $table->date('dob')->nullable()->after('gender');
            $table->string('id_state')->nullable()->after('id_number');
            $table->date('id_expiration')->nullable()->after('id_state');
            
            // Complex data stored as JSON
            $table->json('employment')->nullable()->after('emergency_contact_phone');
            $table->json('history')->nullable()->after('employment');
            $table->json('occupants')->nullable()->after('history');
            $table->json('pets')->nullable()->after('occupants');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('rental_tenant_profiles', function (Blueprint $table) {
            $table->dropColumn([
                'gender', 'dob', 'id_state', 'id_expiration',
                'employment', 'history', 'occupants', 'pets'
            ]);
        });
    }
};
