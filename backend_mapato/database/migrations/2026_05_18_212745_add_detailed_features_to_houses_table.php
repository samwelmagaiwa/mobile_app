<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::table('rental_houses', function (Blueprint $table) {
            $table->boolean('has_fence')->default(false);
            $table->boolean('has_tiles')->default(false);
            $table->boolean('has_sitting_room')->default(false);
            $table->boolean('has_master_bedroom')->default(false);
            $table->boolean('has_kitchen')->default(false);
            $table->string('kitchen_location')->nullable(); // 'inside' or 'outside'
            $table->string('distance_from_road')->nullable();

            $table->string('electricity_type')->nullable(); // 'independent' or 'shared'
            $table->integer('electricity_sharing_count')->nullable(); // number of neighbors

            $table->string('water_type')->nullable(); // 'independent' or 'shared'
            $table->integer('water_sharing_count')->nullable(); // number of neighbors

            $table->boolean('landlord_lives_present')->default(false);
            $table->json('images')->nullable();
        });
    }

    public function down(): void
    {
        Schema::table('rental_houses', function (Blueprint $table) {
            $table->dropColumn([
                'has_fence',
                'has_tiles',
                'has_sitting_room',
                'has_master_bedroom',
                'has_kitchen',
                'kitchen_location',
                'distance_from_road',
                'electricity_type',
                'electricity_sharing_count',
                'water_type',
                'water_sharing_count',
                'landlord_lives_present',
                'images'
            ]);
        });
    }
};
