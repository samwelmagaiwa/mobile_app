<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('rental_properties', function (Blueprint $table) {
            // Property Type
            $table->enum('property_type', [
                'apartment', 
                'rental_compound', 
                'standalone_house', 
                'hostel', 
                'commercial_building',
                'mixed_use',
                'office_space',
                'shop_units'
            ])->nullable()->after('name');
            
            // Location Information
            $table->string('region')->nullable()->after('property_type');
            $table->string('district')->nullable()->after('region');
            $table->string('ward')->nullable()->after('district');
            $table->string('street')->nullable()->after('ward');
            
            // Ownership Information
            $table->uuid('caretaker_id')->nullable()->after('owner_id');
            $table->text('ownership_notes')->nullable()->after('caretaker_id');
            
            // Property Configuration
            $table->integer('number_of_blocks')->default(1)->after('ownership_notes');
            $table->integer('total_units')->default(0)->after('number_of_blocks');
            $table->enum('default_billing_cycle', ['monthly', 'quarterly', 'yearly'])->default('monthly')->after('total_units');
            $table->string('default_currency', 10)->default('TZS')->after('default_billing_cycle');
            
            // Property Status
            $table->enum('status', ['active', 'inactive', 'under_maintenance', 'archived'])->default('active')->after('default_currency');
            
            // Financial Defaults
            $table->decimal('default_rent_amount', 15, 2)->nullable()->after('status');
            $table->decimal('default_deposit_amount', 15, 2)->nullable()->after('default_rent_amount');
            $table->boolean('utility_billing_enabled')->default(false)->after('default_deposit_amount');
            
            // GPS Coordinates (for future)
            $table->decimal('latitude', 10, 8)->nullable()->after('utility_billing_enabled');
            $table->decimal('longitude', 11, 8)->nullable()->after('latitude');
        });
    }

    public function down(): void
    {
        Schema::table('rental_properties', function (Blueprint $table) {
            $table->dropColumn([
                'property_type',
                'region',
                'district',
                'ward',
                'street',
                'caretaker_id',
                'ownership_notes',
                'number_of_blocks',
                'total_units',
                'default_billing_cycle',
                'default_currency',
                'status',
                'default_rent_amount',
                'default_deposit_amount',
                'utility_billing_enabled',
                'latitude',
                'longitude',
            ]);
        });
    }
};