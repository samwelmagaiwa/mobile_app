<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('rental_blocks', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('property_id');
            $table->string('name'); // e.g. Block A, Wing B
            $table->text('description')->nullable();
            $table->timestamps();

            $table->foreign('property_id')->references('id')->on('rental_properties')->onDelete('cascade');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('rental_blocks');
    }
};
