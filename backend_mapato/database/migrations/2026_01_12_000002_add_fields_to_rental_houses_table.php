<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('rental_houses', function (Blueprint $table) {
            // Additional details
            $table->integer('floor')->nullable()->after('house_number');
            $table->integer('bedrooms')->nullable()->after('floor');
            $table->integer('bathrooms')->nullable()->after('bedrooms');
            $table->integer('square_meters')->nullable()->after('bathrooms');
            $table->text('description')->nullable()->after('square_meters');
            
            // Extend type enum
            $table->enum('type', [
                'apartment', 'room', 'commercial', 'studio', 
                'bedroom', 'single_room', 'bedsitter', 
                'one_bedroom', 'two_bedroom', 'three_bedroom'
            ])->default('room')->change();
        });
    }

    public function down(): void
    {
        Schema::table('rental_houses', function (Blueprint $table) {
            $table->dropColumn([
                'floor',
                'bedrooms',
                'bathrooms',
                'square_meters',
                'description',
            ]);
            
            // Revert type enum
            $table->enum('type', ['apartment', 'room', 'commercial', 'studio'])->default('room')->change();
        });
    }
};