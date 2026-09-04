<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * A user can be bound to more than one service (e.g. transport +
 * inventory), so `users.service_type` — a single nullable string — can't
 * represent that. This table replaces it as the source of truth; the old
 * column is left in place (still written to, for anything not yet
 * migrated to read from here) but is no longer authoritative.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('user_services', function (Blueprint $table) {
            $table->id();
            $table->foreignUuid('user_id')->constrained('users')->cascadeOnDelete();
            $table->enum('service_type', ['rental', 'transport', 'inventory']);
            $table->timestamps();
            $table->unique(['user_id', 'service_type']);
        });

        // Backfill from the existing single-value column so nobody who
        // already had a service assigned loses it.
        DB::table('users')
            ->whereNotNull('service_type')
            ->select('id', 'service_type')
            ->orderBy('id')
            ->each(function ($user) {
                DB::table('user_services')->insert([
                    'user_id' => $user->id,
                    'service_type' => $user->service_type,
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);
            });
    }

    public function down(): void
    {
        Schema::dropIfExists('user_services');
    }
};
