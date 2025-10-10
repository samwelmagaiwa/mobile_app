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
            $table->uuid('driver_id');
            $table->string('driver_name');
            $table->timestamp('message_date');
            $table->text('message_content');
            $table->text('response')->nullable();
            $table->enum('mode', ['sms', 'call', 'whatsapp', 'system_note'])->default('system_note');
            $table->timestamps();

            // Add indexes for performance
            $table->index('driver_id');
            $table->index('message_date');
            $table->index('mode');
            $table->index('created_at');

            // Add foreign key constraint
            $table->foreign('driver_id')->references('id')->on('drivers')->onDelete('cascade');
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