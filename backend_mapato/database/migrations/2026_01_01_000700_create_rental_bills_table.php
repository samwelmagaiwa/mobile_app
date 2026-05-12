<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('rental_bills', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('agreement_id');
            $table->string('month_year'); // e.g. "05-2026"
            $table->decimal('amount_due', 15, 2);
            $table->decimal('balance', 15, 2);
            $table->date('due_date');
            $table->enum('status', ['unpaid', 'partial', 'paid', 'overdue'])->default('unpaid');
            $table->text('notes')->nullable();
            $table->timestamps();

            $table->foreign('agreement_id')->references('id')->on('rental_agreements')->onDelete('cascade');
            $table->unique(['agreement_id', 'month_year']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('rental_bills');
    }
};
