<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        // 1. Vendors/Handymen
        Schema::create('rental_vendors', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('user_id')->nullable();
            $table->string('name');
            $table->string('business_name')->nullable();
            $table->string('phone');
            $table->string('email')->nullable();
            $table->string('specialty')->nullable(); // plumbing, electrical, etc.
            $table->text('address')->nullable();
            $table->boolean('is_active')->default(true);
            $table->timestamps();

            $table->foreign('user_id')->references('id')->on('users')->onDelete('set null');
        });

        // 2. Maintenance Requests
        Schema::create('rental_maintenance_requests', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('property_id');
            $table->uuid('house_id')->nullable();
            $table->uuid('tenant_id')->nullable();
            $table->string('category'); // Plumbing, Electrical, Structural, Appliance, etc.
            $table->enum('priority', ['low', 'medium', 'high', 'emergency'])->default('medium');
            $table->text('description');
            $table->string('photo_url')->nullable();
            $table->enum('status', ['open', 'pending', 'in_progress', 'resolved', 'cancelled'])->default('open');
            $table->timestamp('resolved_at')->nullable();
            $table->timestamps();

            $table->foreign('property_id')->references('id')->on('rental_properties')->onDelete('cascade');
            $table->foreign('house_id')->references('id')->on('rental_houses')->onDelete('cascade');
            $table->foreign('tenant_id')->references('id')->on('users')->onDelete('set null');
        });

        // 3. Work Orders
        Schema::create('rental_work_orders', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('maintenance_request_id')->nullable();
            $table->uuid('vendor_id')->nullable();
            $table->string('title');
            $table->text('instructions')->nullable();
            $table->decimal('estimated_cost', 15, 2)->default(0);
            $table->decimal('actual_cost', 15, 2)->default(0);
            $table->enum('status', ['draft', 'scheduled', 'in_progress', 'completed', 'cancelled'])->default('draft');
            $table->date('scheduled_date')->nullable();
            $table->date('completion_date')->nullable();
            $table->timestamps();

            $table->foreign('maintenance_request_id')->references('id')->on('rental_maintenance_requests')->onDelete('cascade');
            $table->foreign('vendor_id')->references('id')->on('rental_vendors')->onDelete('set null');
        });

        // 4. Preventive Maintenance
        Schema::create('rental_preventive_maintenance', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('property_id');
            $table->uuid('house_id')->nullable();
            $table->string('description');
            $table->enum('frequency', ['monthly', 'quarterly', 'semi_annual', 'annual'])->default('annual');
            $table->date('last_run')->nullable();
            $table->date('next_run')->nullable();
            $table->boolean('is_active')->default(true);
            $table->timestamps();

            $table->foreign('property_id')->references('id')->on('rental_properties')->onDelete('cascade');
            $table->foreign('house_id')->references('id')->on('rental_houses')->onDelete('cascade');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('rental_preventive_maintenance');
        Schema::dropIfExists('rental_work_orders');
        Schema::dropIfExists('rental_maintenance_requests');
        Schema::dropIfExists('rental_vendors');
    }
};
