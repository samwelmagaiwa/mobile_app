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
        Schema::create('driver_agreements', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('driver_id');
            $table->enum('agreement_type', ['kwa_mkataba', 'dei_waka']);
            $table->date('start_date');
            $table->date('end_date')->nullable(); // Only for 'kwa_mkataba'
            $table->string('mwaka_atamaliza')->nullable(); // Only for 'kwa_mkataba' 
            $table->decimal('kiasi_cha_makubaliano', 15, 2);
            $table->decimal('faida_jumla', 15, 2)->nullable(); // Calculated for 'kwa_mkataba'
            $table->boolean('wikendi_zinahesabika')->default(false);
            $table->boolean('jumamosi')->default(false);
            $table->boolean('jumapili')->default(false);
            $table->json('payment_frequencies'); // Array of selected frequencies: ['kila_siku', 'kila_wiki', 'kila_mwezi']
            $table->enum('status', ['active', 'inactive', 'completed', 'terminated'])->default('active');
            $table->uuid('created_by');
            $table->timestamps();
            
            // Foreign key constraints
            $table->foreign('driver_id')->references('id')->on('drivers')->onDelete('cascade');
            $table->foreign('created_by')->references('id')->on('users')->onDelete('cascade');
            
            // Indexes for performance
            $table->index(['driver_id', 'status']);
            $table->index('agreement_type');
            $table->index('start_date');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('driver_agreements');
    }
};
