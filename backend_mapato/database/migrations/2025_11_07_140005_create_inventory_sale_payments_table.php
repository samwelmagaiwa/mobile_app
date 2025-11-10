<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('inventory_sale_payments', function (Blueprint $table) {
            $table->id();
            $table->foreignId('sale_id')->constrained('inventory_sales')->cascadeOnDelete();
            $table->decimal('amount', 12, 2);
            $table->enum('method', ['cash','mobile_money','bank_transfer'])->default('cash');
            $table->string('reference')->nullable();
            $table->timestamp('paid_at')->useCurrent();
            $table->timestamps();
            $table->index(['sale_id','paid_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('inventory_sale_payments');
    }
};
