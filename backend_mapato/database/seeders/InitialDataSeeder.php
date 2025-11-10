<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;
use App\Models\User;
use App\Models\Driver;
use App\Models\Device;

class InitialDataSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // Create or update Admin user
        $admin = User::updateOrCreate(
            ['email' => 'admin@gmail.com'],
            [
                'name' => 'Samwel magaiwa',
                'password' => Hash::make('12345678'),
                'phone_number' => '+255743519104',
                'role' => 'admin',
                'is_active' => true,
                'email_verified' => true,
                'phone_verified' => true,
                'email_verified_at' => now(),
            ]
        );

        echo "✅ Admin user ensured: admin@gmail.com / 12345678\n";

        // Create or update sample driver 1
        $driverUser = User::updateOrCreate(
            ['email' => 'john@gmail.com'],
            [
                'name' => 'John mwita',
                'password' => Hash::make('12345678'),
                'phone_number' => '+255743519105',
                'role' => 'driver',
                'created_by' => $admin->id,
                'is_active' => true,
                'email_verified' => true,
                'phone_verified' => true,
                'email_verified_at' => now(),
            ]
        );

        // Create or update driver profile 1
        $driver = Driver::updateOrCreate(
            ['user_id' => $driverUser->id],
            [
                'license_number' => 'DL123456789',
                'license_expiry' => now()->addYears(2),
                'address' => 'Dar es Salaam, Tanzania',
                'emergency_contact' => '+255743519106',
                'is_active' => true,
            ]
        );

        // Create or update sample vehicle 1 by unique plate number
        $vehicle = Device::updateOrCreate(
            ['plate_number' => 'T123ABC'],
            [
                'driver_id' => $driver->id,
                'name' => 'Bajaji ya Kwanza',
                'type' => 'bajaji',
                'description' => 'Bajaji ya kijani ya abiria',
                'is_active' => true,
            ]
        );

        // Ensure driver 1 user has assigned device
        if ($driverUser->device_id !== $vehicle->id) {
            $driverUser->update(['device_id' => $vehicle->id]);
        }

        echo "✅ Sample driver ensured: john@gmail.com / 12345678\n";
        echo "✅ Sample vehicle ensured: Bajaji ya Kwanza (T123ABC)\n";

        // Create or update sample driver 2 (no vehicle)
        $driverUser2 = User::updateOrCreate(
            ['email' => 'jane@gmail.com'],
            [
                'name' => 'Jane mwita',
                'password' => Hash::make('12345678'),
                'phone_number' => '+255743519107',
                'role' => 'driver',
                'created_by' => $admin->id,
                'is_active' => true,
                'email_verified' => true,
                'phone_verified' => true,
                'email_verified_at' => now(),
            ]
        );

        $driver2 = Driver::updateOrCreate(
            ['user_id' => $driverUser2->id],
            [
                'license_number' => 'DL987654321',
                'license_expiry' => now()->addYears(3),
                'address' => 'Mwanza, Tanzania',
                'emergency_contact' => '+255712345682',
                'is_active' => true,
            ]
        );

        echo "✅ Second driver ensured: jane@gmail.com / 12345678\n";
        echo "\n=== Initial Data Seeding Complete ===\n";
        echo "You can now login with:\n";
        echo "Admin: admin@gmail.com / 12345678\n";
        echo "Driver 1: john@gmail.com / 12345678\n";
        echo "Driver 2: jane@gmail.com / 12345678\n";
    }
}
