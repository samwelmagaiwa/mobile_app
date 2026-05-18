<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('landlord_vendor', function (Blueprint $table) {
            $table->id();
            $table->uuid('landlord_id')->index();
            $table->uuid('vendor_id')->index();
            $table->timestamps();

            // Foreign keys mapping to UUID systems
            $table->foreign('landlord_id')->references('id')->on('users')->onDelete('cascade');
            $table->foreign('vendor_id')->references('id')->on('rental_vendors')->onDelete('cascade');

            // Ensure no duplicate saves
            $table->unique(['landlord_id', 'vendor_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('landlord_vendor');
    }
};
