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
        // Create Admin user
        $admin = User::create([
            'id' => Str::uuid(),
            'name' => 'Samwel magaiwa',
            'email' => 'admin@gmail.com',
            'password' => Hash::make('12345678'),
            'phone_number' => '+255743519104',
            'role' => 'admin',
            'is_active' => true,
            'email_verified' => true,
            'phone_verified' => true,
        ]);

        echo "✅ Admin user created: admin@gmail.com / 12345678\n";

        // Create sample driver
        $driverUser = User::create([
            'id' => Str::uuid(),
            'name' => 'John mwita',
            'email' => 'john@gmail.com',
            'password' => Hash::make('12345678'),
            'phone_number' => '+255743519105',
            'role' => 'driver',
            'created_by' => $admin->id,
            'is_active' => true,
            'email_verified' => true,
            'phone_verified' => true,
        ]);

        // Create driver profile
        $driver = Driver::create([
            'id' => Str::uuid(),
            'user_id' => $driverUser->id,
            'license_number' => 'DL123456789',
            'license_expiry' => now()->addYears(2),
            'address' => 'Dar es Salaam, Tanzania',
            'emergency_contact' => '+255743519106',
            'is_active' => true,
        ]);

        // Create sample vehicle
        $vehicle = Device::create([
            'id' => Str::uuid(),
            'driver_id' => $driver->id,
            'name' => 'Bajaji ya Kwanza',
            'type' => 'bajaji',
            'plate_number' => 'T123ABC',
            'description' => 'Bajaji ya kijani ya abiria',
            'is_active' => true,
        ]);

        // Update driver user with assigned device
        $driverUser->update(['device_id' => $vehicle->id]);

        echo "✅ Sample driver created: john@gmail.com / 12345678\n";
        echo "✅ Sample vehicle created: Bajaji ya Kwanza (T123ABC)\n";

        // Create another driver without vehicle
        $driverUser2 = User::create([
            'id' => Str::uuid(),
            'name' => 'Jane mwita',
            'email' => 'jane@gmail.com',
            'password' => Hash::make('12345678'),
            'phone_number' => '+255743519107',
            'role' => 'driver',
            'created_by' => $admin->id,
            'is_active' => true,
            'email_verified' => true,
            'phone_verified' => true,
        ]);

        $driver2 = Driver::create([
            'id' => Str::uuid(),
            'user_id' => $driverUser2->id,
            'license_number' => 'DL987654321',
            'license_expiry' => now()->addYears(3),
            'address' => 'Mwanza, Tanzania',
            'emergency_contact' => '+255712345682',
            'is_active' => true,
        ]);

        echo "✅ Second driver created: jane@gmail.com / 12345678\n";
        echo "\n=== Initial Data Seeding Complete ===\n";
        echo "You can now login with:\n";
        echo "Admin: admin@gmail.com / 12345678\n";
        echo "Driver 1: john@gmail.com / 12345678\n";
        echo "Driver 2: jane@gmail.com / 12345678\n";
    }
}