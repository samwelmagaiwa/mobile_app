<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('rental_properties', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('owner_id'); // Landlord
            $table->string('name');
            $table->string('location')->nullable();
            $table->string('address')->nullable();
            $table->string('city')->nullable();
            $table->text('description')->nullable();
            $table->string('image_url')->nullable();
            $table->timestamps();

            $table->foreign('owner_id')->references('id')->on('users')->onDelete('cascade');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('rental_properties');
    }
};
