<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('rental_agreements', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('tenant_id'); // User ID
            $table->uuid('house_id');
            $table->date('start_date');
            $table->date('end_date')->nullable();
            $table->enum('rent_cycle', ['monthly', 'quarterly', 'semi_annual', 'annual'])->default('monthly');
            $table->decimal('rent_amount', 15, 2); // Captured at time of agreement
            $table->decimal('deposit_paid', 15, 2)->default(0);
            $table->enum('status', ['active', 'notice', 'terminated', 'defaulter'])->default('active');
            $table->text('terms')->nullable();
            $table->timestamps();

            $table->foreign('tenant_id')->references('id')->on('users')->onDelete('cascade');
            $table->foreign('house_id')->references('id')->on('rental_houses')->onDelete('cascade');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('rental_agreements');
    }
};
