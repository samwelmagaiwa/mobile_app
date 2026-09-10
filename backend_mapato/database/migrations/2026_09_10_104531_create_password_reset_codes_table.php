<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Short-lived, single-use tokens for the "forgot password" flow: only the
 * sha256 hash is stored (never the raw token, mirroring how passwords
 * themselves are never stored in plaintext), and each row expires after
 * 10 minutes (enforced by forgotPassword()/resetPassword() in
 * AuthController, not by this table alone).
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('password_reset_codes', function (Blueprint $table) {
            $table->id();
            $table->uuid('user_id');
            $table->string('token_hash', 64);
            $table->timestamp('expires_at');
            $table->timestamp('used_at')->nullable();
            $table->timestamps();

            $table->foreign('user_id')->references('id')->on('users')->cascadeOnDelete();
            $table->index(['user_id', 'expires_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('password_reset_codes');
    }
};
