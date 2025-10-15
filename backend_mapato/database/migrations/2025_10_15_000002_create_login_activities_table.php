<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('login_activities', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('user_id')->index();
            $table->string('ip_address', 45)->nullable();
            $table->text('user_agent')->nullable();
            $table->timestamp('login_at')->nullable();
            $table->timestamp('logout_at')->nullable();
            $table->boolean('success')->default(true);
            $table->string('location')->nullable();
            $table->timestamps();
            $table->index(['user_id', 'login_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('login_activities');
    }
};