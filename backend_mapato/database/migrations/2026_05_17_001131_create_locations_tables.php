<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('states', function (Blueprint $table) {
            $table->id();
            $table->string('country_code', 10)->default('TZ');
            $table->string('name');
            $table->timestamps();
            $table->unique(['name', 'country_code']);
        });

        Schema::create('lgas', function (Blueprint $table) {
            $table->id();
            $table->foreignId('state_id')->constrained('states')->onDelete('cascade');
            $table->string('name');
            $table->timestamps();
            $table->unique(['name', 'state_id']);
        });

        Schema::create('wards', function (Blueprint $table) {
            $table->id();
            $table->foreignId('lga_id')->constrained('lgas')->onDelete('cascade');
            $table->string('name');
            $table->timestamps();
            $table->unique(['name', 'lga_id']);
        });

        Schema::create('villages', function (Blueprint $table) {
            $table->id();
            $table->foreignId('ward_id')->constrained('wards')->onDelete('cascade');
            $table->string('name');
            $table->timestamps();
            $table->unique(['name', 'ward_id']);
        });

        Schema::create('places', function (Blueprint $table) {
            $table->id();
            $table->foreignId('village_id')->constrained('villages')->onDelete('cascade');
            $table->string('name');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('places');
        Schema::dropIfExists('villages');
        Schema::dropIfExists('wards');
        Schema::dropIfExists('lgas');
        Schema::dropIfExists('states');
    }
};
