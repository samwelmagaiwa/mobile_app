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
        Schema::create('driver_trips', function (Blueprint $table) {
            $table->id();
            $table->uuid('driver_id');
            $table->date('trip_date');
            $table->time('start_time')->nullable();
            $table->time('end_time')->nullable();
            $table->string('pickup_location')->nullable();
            $table->string('destination')->nullable();
            $table->decimal('distance_km', 8, 2)->nullable();
            $table->decimal('fare_amount', 10, 2)->default(0);
            $table->decimal('commission_amount', 10, 2)->default(0);
            $table->decimal('driver_earnings', 10, 2)->default(0);
            $table->enum('trip_status', ['completed', 'cancelled', 'ongoing'])->default('completed');
            $table->enum('payment_status', ['paid', 'pending', 'overdue'])->default('pending');
            $table->integer('rating')->nullable()->comment('1-5 rating from passenger');
            $table->text('trip_notes')->nullable();
            $table->json('trip_metadata')->nullable(); // For storing additional trip data
            $table->timestamps();
            
            // Indexes for better performance
            $table->index(['driver_id', 'trip_date']);
            $table->index(['trip_date']);
            $table->index(['trip_status']);
            $table->index(['payment_status']);
            $table->index(['driver_id', 'payment_status']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('driver_trips');
    }
};