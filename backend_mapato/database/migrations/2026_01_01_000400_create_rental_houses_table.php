<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('rental_houses', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('property_id');
            $table->uuid('block_id')->nullable();
            $table->string('house_number');
            $table->enum('type', ['apartment', 'room', 'commercial', 'studio'])->default('room');
            $table->decimal('rent_amount', 15, 2);
            $table->decimal('deposit_amount', 15, 2)->default(0);
            $table->string('electricity_meter')->nullable();
            $table->string('water_meter')->nullable();
            $table->enum('status', ['vacant', 'occupied', 'maintenance', 'reserved'])->default('vacant');
            $table->uuid('current_tenant_id')->nullable(); // Reference to User
            $table->timestamps();

            $table->foreign('property_id')->references('id')->on('rental_properties')->onDelete('cascade');
            $table->foreign('block_id')->references('id')->on('rental_blocks')->onDelete('set null');
            // current_tenant_id FK added in later migration to avoid circular dependency
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('rental_houses');
    }
};
