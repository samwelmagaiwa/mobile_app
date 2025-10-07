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
        Schema::create('drivers', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('user_id');
            $table->string('license_number')->unique();
            $table->date('license_expiry');
            $table->text('address')->nullable();
            $table->string('emergency_contact', 20)->nullable();
            $table->string('national_id', 20)->nullable();
            $table->date('date_of_birth')->nullable();
            $table->string('profile_image')->nullable();
            $table->boolean('is_active')->default(true);
            $table->decimal('rating', 3, 2)->default(0.00);
            $table->integer('total_trips')->default(0);
            $table->decimal('total_earnings', 15, 2)->default(0.00);
            $table->timestamps();

            // Indexes
            $table->index('user_id');
            $table->index('license_number');
            $table->index('is_active');
            $table->index('license_expiry');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('drivers');
    }
};