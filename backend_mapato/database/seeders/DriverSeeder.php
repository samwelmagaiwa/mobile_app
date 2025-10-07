<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\User;
use App\Models\Driver;
use App\Models\Device;
use Illuminate\Support\Facades\Hash;

class DriverSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // Create sample drivers
        $drivers = [
            [
                'name' => 'John Mwita',
                'email' => 'john@gmail.com',
                'phone' => '+255743519105',
                'license_number' => 'DL123456789',
                'vehicle_number' => 'T123ABC',
                'vehicle_type' => 'bajaji',
            ],
            [
                'name' => 'Jane Mwita',
                'email' => 'jane@gmail.com',
                'phone' => '+255743519107',
                'license_number' => 'DL987654321',
                'vehicle_number' => null,
                'vehicle_type' => null,
            ],
            [
                'name' => 'Peter Mwangi',
                'email' => 'peter@gmail.com',
                'phone' => '+255743519108',
                'license_number' => 'DL456789123',
                'vehicle_number' => 'T456DEF',
                'vehicle_type' => 'pikipiki',
            ],
            [
                'name' => 'Mary Nakato',
                'email' => 'mary@gmail.com',
                'phone' => '+255743519109',
                'license_number' => 'DL789123456',
                'vehicle_number' => 'T789GHI',
                'vehicle_type' => 'gari',
            ],
        ];

        foreach ($drivers as $driverData) {
            // Create user
            $user = User::create([
                'name' => $driverData['name'],
                'email' => $driverData['email'],
                'phone_number' => $driverData['phone'],
                'password' => Hash::make('password123'),
                'role' => 'driver',
                'is_active' => true,
                'email_verified' => false,
                'phone_verified' => false,
            ]);

            // Create driver profile
            $driver = Driver::create([
                'user_id' => $user->id,
                'license_number' => $driverData['license_number'],
                'license_expiry' => now()->addYears(5),
                'is_active' => true,
                'rating' => 4.5,
                'total_trips' => 0,
                'total_earnings' => 0,
            ]);

            // Create vehicle if provided
            if ($driverData['vehicle_number'] && $driverData['vehicle_type']) {
                $device = Device::create([
                    'driver_id' => $driver->id,
                    'name' => $driverData['vehicle_type'] . ' - ' . $driverData['vehicle_number'],
                    'type' => $driverData['vehicle_type'],
                    'plate_number' => $driverData['vehicle_number'],
                    'description' => 'Vehicle assigned to ' . $driverData['name'],
                    'is_active' => true,
                ]);

                // Update user's assigned device
                $user->update(['device_id' => $device->id]);
            }
        }

        $this->command->info('Sample drivers created successfully!');
    }
}