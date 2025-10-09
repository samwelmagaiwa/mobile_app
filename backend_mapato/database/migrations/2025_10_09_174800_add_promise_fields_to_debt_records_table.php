<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('debt_records', function (Blueprint $table) {
            if (!Schema::hasColumn('debt_records', 'promised_to_pay')) {
                $table->boolean('promised_to_pay')->default(false)->after('notes');
            }
            if (!Schema::hasColumn('debt_records', 'promise_to_pay_at')) {
                $table->date('promise_to_pay_at')->nullable()->after('promised_to_pay');
            }
        });
    }

    public function down(): void
    {
        Schema::table('debt_records', function (Blueprint $table) {
            if (Schema::hasColumn('debt_records', 'promise_to_pay_at')) {
                $table->dropColumn('promise_to_pay_at');
            }
            if (Schema::hasColumn('debt_records', 'promised_to_pay')) {
                $table->dropColumn('promised_to_pay');
            }
        });
    }
};