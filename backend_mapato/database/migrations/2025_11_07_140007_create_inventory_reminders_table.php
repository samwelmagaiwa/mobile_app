<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('inventory_reminders', function (Blueprint $table) {
            $table->id();
            $table->enum('type', ['payment_due','low_stock'])->index();
            $table->unsignedBigInteger('related_id')->nullable()->index();
            $table->string('title');
            $table->text('description')->nullable();
            $table->dateTime('due_at');
            $table->enum('status', ['open','snoozed','done'])->default('open')->index();
            $table->dateTime('snooze_until')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('inventory_reminders');
    }
};
