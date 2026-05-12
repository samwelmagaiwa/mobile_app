<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\User;
use App\Models\Rental\Property;
use App\Services\Rental\RentalService;
use Illuminate\Support\Str;

class RentalTestDataSeeder extends Seeder
{
    protected $rentalService;

    public function __construct(RentalService $rentalService)
    {
        $this->rentalService = $rentalService;
    }

    public function run(): void
    {
        // 1. Create a Landlord
        $landlord = User::updateOrCreate(
            ['email' => 'landlord@gmail.com'],
            [
                'name' => 'Landlord Sam',
                'password' => bcrypt('12345678'),
                'phone_number' => '0711223344',
                'role' => 'landlord',
                'is_active' => true,
            ]
        );

        // 2. Create a Property
        $property = Property::create([
            'id' => Str::uuid(),
            'owner_id' => $landlord->id,
            'name' => 'Mikocheni Executive Apartments',
            'location' => 'Mikocheni, Dar es Salaam',
            'city' => 'Dar es Salaam',
        ]);

        // 3. Create Houses
        $house1 = $property->houses()->create([
            'id' => Str::uuid(),
            'house_number' => 'APT-01',
            'type' => 'apartment',
            'rent_amount' => 500000,
            'status' => 'vacant',
        ]);

        $house2 = $property->houses()->create([
            'id' => Str::uuid(),
            'house_number' => 'APT-02',
            'type' => 'apartment',
            'rent_amount' => 450000,
            'status' => 'vacant',
        ]);

        echo "✅ Property and Houses created.\n";

        // 4. Onboard Tenant for House 1
        $onboardingResult = $this->rentalService->onboardTenant([
            'name' => 'Tenant John',
            'email' => 'tenant_john@gmail.com',
            'phone_number' => '0744556677',
            'password' => '12345678',
            'house_id' => $house1->id,
            'rent_amount' => 500000,
            'deposit_paid' => 1000000,
            'start_date' => now()->startOfMonth()->format('Y-m-d'),
            'id_number' => 'ID-123456',
            'occupation' => 'Software Engineer',
        ]);

        echo "✅ Tenant onboarded for House 1 (APT-01).\n";

        // 5. Record a partial payment
        $agreement = $onboardingResult['agreement'];
        $bill = $agreement->bills()->first();

        $this->rentalService->recordPayment([
            'bill_id' => $bill->id,
            'amount_paid' => 300000,
            'payment_method' => 'm-pesa',
            'transaction_reference' => 'MPESA123ABC',
            'collector_id' => $landlord->id,
            'notes' => 'First installment',
        ]);

        echo "✅ Partial payment of 300,000 recorded for John. Balance: 200,000.\n";
        
        echo "\n=== Rental Module Test Data Seeded Successfully ===\n";
    }
}
