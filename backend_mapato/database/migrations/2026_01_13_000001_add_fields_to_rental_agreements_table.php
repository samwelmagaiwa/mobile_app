<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('rental_agreements', function (Blueprint $table) {
            $table->json('documents')->nullable()->after('terms');
            $table->string('signed_pdf_url')->nullable()->after('documents');
            $table->integer('notice_period_days')->default(30)->after('signed_pdf_url');
            $table->boolean('auto_renew')->default(false)->after('notice_period_days');
            $table->date('renewal_date')->nullable()->after('auto_renew');
            $table->decimal('penalty_per_day', 10, 2)->default(0)->after('renewal_date');
            $table->text('notes')->nullable()->after('penalty_per_day');
            $table->softDeletes()->after('notes');
        });
    }

    public function down(): void
    {
        Schema::table('rental_agreements', function (Blueprint $table) {
            $table->dropColumn([
                'documents', 'signed_pdf_url', 'notice_period_days',
                'auto_renew', 'renewal_date', 'penalty_per_day',
                'notes', 'deleted_at',
            ]);
        });
    }
};