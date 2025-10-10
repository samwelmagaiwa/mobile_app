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
        Schema::create('communications', function (Blueprint $table) {
            $table->id();
            
            // Foreign key relationship to drivers table
            $table->unsignedBigInteger('driver_id');
            $table->foreign('driver_id')->references('id')->on('drivers')->onDelete('cascade');
            
            // Denormalized driver name for easier queries and display
            $table->string('driver_name');
            
            // Communication details
            $table->datetime('message_date');
            $table->text('message_content');
            $table->text('response')->nullable();
            
            // Communication mode: sms, call, whatsapp, system_note
            $table->enum('mode', ['sms', 'call', 'whatsapp', 'system_note'])
                  ->default('system_note');
            
            // Additional metadata
            $table->string('initiated_by')->nullable(); // 'owner', 'driver', 'system'
            $table->string('priority')->default('normal'); // 'low', 'normal', 'high', 'urgent'
            $table->boolean('is_resolved')->default(false);
            $table->datetime('resolved_at')->nullable();
            
            // Standard timestamps
            $table->timestamps();
            
            // Indexes for better query performance
            $table->index(['driver_id', 'message_date']);
            $table->index(['mode', 'message_date']);
            $table->index(['is_resolved', 'message_date']);
            $table->index('message_date');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('communications');
    }
};