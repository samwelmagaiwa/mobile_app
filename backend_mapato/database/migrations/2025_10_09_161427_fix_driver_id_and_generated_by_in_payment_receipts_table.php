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
        Schema::table('payment_receipts', function (Blueprint $table) {
            // Change driver_id from bigint to char(36) for UUID
            $table->char('driver_id', 36)->change();
            
            // Change generated_by from bigint to char(36) for UUID
            $table->char('generated_by', 36)->nullable()->change();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('payment_receipts', function (Blueprint $table) {
            // Drop foreign keys
            $table->dropForeign(['driver_id']);
            $table->dropForeign(['generated_by']);
            
            // Revert to bigint
            $table->bigInteger('driver_id')->unsigned()->change();
            $table->bigInteger('generated_by')->unsigned()->nullable()->change();
            
            // Re-add foreign keys (this won't work with UUIDs, but for completeness)
            // $table->foreign('driver_id')->references('id')->on('drivers');
            // $table->foreign('generated_by')->references('id')->on('users');
        });
    }
};
