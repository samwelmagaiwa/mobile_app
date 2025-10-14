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
        Schema::create('driver_prediction_caches', function (Blueprint $table) {
            $table->id();
            $table->uuid('driver_id')->index();
            $table->date('start_date')->nullable();
            $table->date('contract_end')->nullable();
            $table->decimal('total_amount', 14, 2)->default(0);
            $table->decimal('total_paid', 14, 2)->default(0);
            $table->decimal('balance', 14, 2)->default(0);
            $table->unsignedInteger('days_passed')->default(0);
            $table->unsignedInteger('total_days')->nullable();
            $table->boolean('on_track')->default(false);
            $table->date('predicted_date')->nullable();
            $table->unsignedInteger('estimated_delay_days')->default(0);
            $table->string('model', 20)->nullable();
            $table->decimal('r2', 6, 4)->nullable();
            $table->boolean('weekends_countable')->default(true);
            $table->boolean('saturday_included')->default(true);
            $table->boolean('sunday_included')->default(true);
            $table->timestamp('calculated_at')->nullable();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('driver_prediction_caches');
    }
};
