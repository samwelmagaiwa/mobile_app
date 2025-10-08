<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('payments') && !Schema::hasColumn('payments', 'receipt_status')) {
            Schema::table('payments', function (Blueprint $table) {
                $table->enum('receipt_status', ['pending', 'generated', 'issued'])
                      ->default('pending')
                      ->after('status');
            });
        }
    }

    public function down(): void
    {
        if (Schema::hasTable('payments') && Schema::hasColumn('payments', 'receipt_status')) {
            Schema::table('payments', function (Blueprint $table) {
                $table->dropColumn('receipt_status');
            });
        }
    }
};
