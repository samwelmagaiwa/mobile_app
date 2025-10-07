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
        Schema::create('reminders', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('driver_id');
            $table->uuid('device_id')->nullable();
            $table->string('title');
            $table->text('message');
            $table->enum('reminder_type', [
                'license_renewal',
                'insurance_renewal', 
                'service_maintenance',
                'payment_due',
                'fuel_reminder',
                'custom'
            ]);
            $table->date('reminder_date');
            $table->datetime('reminder_time');
            $table->boolean('is_recurring')->default(false);
            $table->enum('recurrence_pattern', [
                'daily',
                'weekly', 
                'monthly',
                'quarterly',
                'yearly'
            ])->nullable();
            $table->enum('status', ['active', 'completed', 'cancelled', 'expired'])->default('active');
            $table->boolean('is_sent')->default(false);
            $table->datetime('sent_at')->nullable();
            $table->enum('priority', ['low', 'medium', 'high', 'urgent'])->default('medium');
            $table->json('notification_channels')->nullable(); // ['email', 'sms', 'push']
            $table->integer('snooze_count')->default(0);
            $table->datetime('snoozed_until')->nullable();
            $table->json('metadata')->nullable(); // For storing additional reminder data
            $table->timestamps();

            // Indexes
            $table->index('driver_id');
            $table->index('device_id');
            $table->index('reminder_type');
            $table->index('reminder_date');
            $table->index('reminder_time');
            $table->index('status');
            $table->index('priority');
            $table->index('is_sent');
            $table->index(['driver_id', 'reminder_date']);
            $table->index(['status', 'reminder_time']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('reminders');
    }
};