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
        Schema::create('devices', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('driver_id');
            $table->string('name');
            $table->enum('type', ['bajaji', 'pikipiki', 'gari']);
            $table->string('plate_number', 20)->unique();
            $table->text('description')->nullable();
            $table->boolean('is_active')->default(true);
            $table->date('purchase_date')->nullable();
            $table->decimal('purchase_price', 15, 2)->nullable();
            $table->date('insurance_expiry')->nullable();
            $table->string('insurance_company')->nullable();
            $table->date('last_service_date')->nullable();
            $table->integer('mileage')->nullable();
            $table->string('engine_number')->nullable();
            $table->string('chassis_number')->nullable();
            $table->string('color', 50)->nullable();
            $table->year('manufacture_year')->nullable();
            $table->string('brand', 100)->nullable();
            $table->string('model', 100)->nullable();
            $table->timestamps();

            // Indexes
            $table->index('driver_id');
            $table->index('plate_number');
            $table->index('type');
            $table->index('is_active');
            $table->index('insurance_expiry');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('devices');
    }
};