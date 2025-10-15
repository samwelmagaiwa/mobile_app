<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->boolean('two_factor_enabled')->default(false)->after('phone_verified');
            $table->string('two_factor_secret')->nullable()->after('two_factor_enabled');
            $table->timestamp('two_factor_confirmed_at')->nullable()->after('two_factor_secret');
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn(['two_factor_enabled', 'two_factor_secret', 'two_factor_confirmed_at']);
        });
    }
};