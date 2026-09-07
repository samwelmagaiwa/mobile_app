<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('inventory_expenses', function (Blueprint $table) {
            $table->id();
            $table->string('category');          // rent, salary, transport, utilities, other …
            $table->string('description');
            $table->decimal('amount', 15, 2);
            $table->date('expense_date');
            $table->unsignedBigInteger('created_by')->nullable();
            $table->foreign('created_by')->references('id')->on('users')->nullOnDelete();
            $table->timestamps();

            $table->index('expense_date');
            $table->index('category');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('inventory_expenses');
    }
};
