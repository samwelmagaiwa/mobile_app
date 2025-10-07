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
        // Add foreign key constraints to users table
        Schema::table('users', function (Blueprint $table) {
            $table->foreign('created_by')->references('id')->on('users')->onDelete('set null');
            $table->foreign('device_id')->references('id')->on('devices')->onDelete('set null');
        });

        // Add foreign key constraints to drivers table
        Schema::table('drivers', function (Blueprint $table) {
            $table->foreign('user_id')->references('id')->on('users')->onDelete('cascade');
        });

        // Add foreign key constraints to devices table
        Schema::table('devices', function (Blueprint $table) {
            $table->foreign('driver_id')->references('id')->on('drivers')->onDelete('cascade');
        });

        // Add foreign key constraints to transactions table
        Schema::table('transactions', function (Blueprint $table) {
            $table->foreign('driver_id')->references('id')->on('drivers')->onDelete('cascade');
            $table->foreign('device_id')->references('id')->on('devices')->onDelete('cascade');
        });

        // Add foreign key constraints to receipts table
        Schema::table('receipts', function (Blueprint $table) {
            $table->foreign('transaction_id')->references('id')->on('transactions')->onDelete('cascade');
        });

        // Add foreign key constraints to reminders table
        Schema::table('reminders', function (Blueprint $table) {
            $table->foreign('driver_id')->references('id')->on('drivers')->onDelete('cascade');
            $table->foreign('device_id')->references('id')->on('devices')->onDelete('cascade');
        });

        // Add foreign key constraints to otp_codes table
        Schema::table('otp_codes', function (Blueprint $table) {
            $table->foreign('user_id')->references('id')->on('users')->onDelete('cascade');
        });

        // Add foreign key constraints to sessions table
        Schema::table('sessions', function (Blueprint $table) {
            $table->foreign('user_id')->references('id')->on('users')->onDelete('cascade');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        // Drop foreign key constraints in reverse order
        Schema::table('sessions', function (Blueprint $table) {
            $table->dropForeign(['user_id']);
        });

        Schema::table('otp_codes', function (Blueprint $table) {
            $table->dropForeign(['user_id']);
        });

        Schema::table('reminders', function (Blueprint $table) {
            $table->dropForeign(['driver_id']);
            $table->dropForeign(['device_id']);
        });

        Schema::table('receipts', function (Blueprint $table) {
            $table->dropForeign(['transaction_id']);
        });

        Schema::table('transactions', function (Blueprint $table) {
            $table->dropForeign(['driver_id']);
            $table->dropForeign(['device_id']);
        });

        Schema::table('devices', function (Blueprint $table) {
            $table->dropForeign(['driver_id']);
        });

        Schema::table('drivers', function (Blueprint $table) {
            $table->dropForeign(['user_id']);
        });

        Schema::table('users', function (Blueprint $table) {
            $table->dropForeign(['created_by']);
            $table->dropForeign(['device_id']);
        });
    }
};