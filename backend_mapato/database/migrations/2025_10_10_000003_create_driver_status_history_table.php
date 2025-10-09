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
        Schema::create('driver_status_history', function (Blueprint $table) {
            $table->id();
            $table->uuid('driver_id');
            $table->enum('previous_status', ['active', 'inactive', 'suspended', 'terminated', 'pending'])->nullable();
            $table->enum('new_status', ['active', 'inactive', 'suspended', 'terminated', 'pending']);
            $table->uuid('changed_by'); // User ID who made the change
            $table->text('reason')->nullable();
            $table->json('additional_data')->nullable(); // Store any additional context
            $table->timestamp('changed_at')->useCurrent();
            $table->timestamps();
            
            // Indexes
            $table->index(['driver_id', 'changed_at']);
            $table->index(['new_status']);
            $table->index(['changed_by']);
            $table->index(['changed_at']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('driver_status_history');
    }
};