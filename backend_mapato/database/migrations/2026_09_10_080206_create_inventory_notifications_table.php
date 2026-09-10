<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * In-app approval notifications: a submitter's write-off/return request
 * notifies whoever can approve it, and the decision notifies the submitter
 * back. `user_id` is the recipient. Uses uuid() to match users.id -- every
 * other inventory table that skipped this (unsignedBigInteger) had to be
 * patched later once a real UUID user id hit it in production (see
 * 2026_09_07_130000_fix_inventory_user_reference_column_types.php).
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('inventory_notifications', function (Blueprint $table) {
            $table->id();
            $table->uuid('user_id');
            $table->string('type', 64);
            $table->string('title');
            $table->text('body')->nullable();
            $table->json('data')->nullable();
            $table->timestamp('read_at')->nullable();
            $table->timestamps();

            $table->foreign('user_id')->references('id')->on('users')->cascadeOnDelete();
            $table->index(['user_id', 'read_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('inventory_notifications');
    }
};
