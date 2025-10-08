<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\User;
use App\Models\Driver;
use App\Models\Device;
use App\Models\Transaction;
use Carbon\Carbon;
use Illuminate\Support\Facades\Hash;

class AnalyticsSampleDataSeeder extends Seeder
{
    /**
     * Seed sample data for analytics testing
     */
    public function run(): void
    {
        // Clear existing sample data to avoid conflicts
        $this->command->info('Clearing existing sample data...');
        Transaction::whereIn('reference_number', function($query) {
            $query->select('reference_number')
                  ->from('transactions')
                  ->where('reference_number', 'like', 'TXN%')
                  ->orWhere('reference_number', 'like', 'EXP%')
                  ->orWhere('reference_number', 'like', 'PND%');
        })->delete();
        
        Device::whereIn('plate_number', ['UBE 123A', 'UBF 456B', 'UBG 789C', 'UBH 012D', 'UBI 345E', 'UBJ 678F', 'UBK 901G', 'UBL 234H', 'UBM 567I', 'UBN 890J'])->delete();
        
        Driver::whereIn('license_number', ['DL001234', 'DL002345', 'DL003456', 'DL004567', 'DL005678', 'DL006789', 'DL007890', 'DL008901', 'DL009012', 'DL010123'])->delete();
        
        User::where('email', 'like', '%@bodamapato.com')->where('role', 'driver')->delete();
        
        // Create sample users and drivers
        $users = [];
        $drivers = [];
        
        $sampleDriversData = [
            ['name' => 'John Mukasa', 'phone' => '+256701234567', 'license' => 'DL001234'],
            ['name' => 'Peter Ssali', 'phone' => '+256702345678', 'license' => 'DL002345'],
            ['name' => 'Mary Nakato', 'phone' => '+256703456789', 'license' => 'DL003456'],
            ['name' => 'James Kato', 'phone' => '+256704567890', 'license' => 'DL004567'],
            ['name' => 'Sarah Nambi', 'phone' => '+256705678901', 'license' => 'DL005678'],
            ['name' => 'Robert Muwanga', 'phone' => '+256706789012', 'license' => 'DL006789'],
            ['name' => 'Grace Namutebi', 'phone' => '+256707890123', 'license' => 'DL007890'],
            ['name' => 'David Ssemwanga', 'phone' => '+256708901234', 'license' => 'DL008901'],
            ['name' => 'Joyce Nalubega', 'phone' => '+256709012345', 'license' => 'DL009012'],
            ['name' => 'Paul Kiggundu', 'phone' => '+256700123456', 'license' => 'DL010123']
        ];
        
        foreach ($sampleDriversData as $driverData) {
            // Create user
            $user = User::create([
                'name' => $driverData['name'],
                'email' => strtolower(str_replace(' ', '.', $driverData['name'])) . '@bodamapato.com',
                'phone_number' => $driverData['phone'],
                'password' => Hash::make('password123'),
                'role' => 'driver',
                'email_verified_at' => now()
            ]);
            
            // Create driver
            $driver = Driver::create([
                'user_id' => $user->id,
                'license_number' => $driverData['license'],
                'license_expiry' => Carbon::now()->addYears(2),
                'date_of_birth' => Carbon::now()->subYears(rand(25, 45)),
                'address' => 'Kampala, Uganda',
                'emergency_contact' => '+256700000000',
                'is_active' => true
            ]);
            
            $users[] = $user;
            $drivers[] = $driver;
        }
        
        // Create sample devices/vehicles
        $devices = [];
        $sampleDevicesData = [
            ['name' => 'Bajaj Boxer 001', 'plate' => 'UBE 123A', 'type' => 'bajaji'],
            ['name' => 'Bajaj Boxer 002', 'plate' => 'UBF 456B', 'type' => 'bajaji'],
            ['name' => 'Bajaj Boxer 003', 'plate' => 'UBG 789C', 'type' => 'bajaji'],
            ['name' => 'Honda CG 125 001', 'plate' => 'UBH 012D', 'type' => 'pikipiki'],
            ['name' => 'TVS Apache 001', 'plate' => 'UBI 345E', 'type' => 'pikipiki'],
            ['name' => 'Yamaha YBR 001', 'plate' => 'UBJ 678F', 'type' => 'pikipiki'],
            ['name' => 'Honda CB 001', 'plate' => 'UBK 901G', 'type' => 'pikipiki'],
            ['name' => 'Suzuki GS 001', 'plate' => 'UBL 234H', 'type' => 'pikipiki'],
            ['name' => 'Kawasaki KLX 001', 'plate' => 'UBM 567I', 'type' => 'pikipiki'],
            ['name' => 'Hero HF 001', 'plate' => 'UBN 890J', 'type' => 'bajaji']
        ];
        
        foreach ($sampleDevicesData as $index => $deviceData) {
            $device = Device::create([
                'name' => $deviceData['name'],
                'type' => $deviceData['type'],
                'plate_number' => $deviceData['plate'],
                'driver_id' => $drivers[$index]->id ?? $drivers[0]->id,
                'description' => 'Vehicle for boda boda service',
                'is_active' => true,
                'purchase_date' => Carbon::now()->subYears(rand(1, 5)),
                'purchase_price' => rand(3000000, 8000000) // 3M to 8M UGX
            ]);
            
            $devices[] = $device;
        }
        
        // Create sample transactions for the last 60 days
        $startDate = Carbon::now()->subDays(60);
        $endDate = Carbon::now();
        
        $paymentCategories = array_keys(Transaction::PAYMENT_CATEGORIES);
        $expenseCategories = array_keys(Transaction::EXPENSE_CATEGORIES);
        $paymentMethods = array_keys(Transaction::PAYMENT_METHODS);
        
        // Generate transactions
        for ($date = $startDate->copy(); $date <= $endDate; $date->addDay()) {
            // Generate 5-15 income transactions per day
            $dailyTransactions = rand(5, 15);
            
            for ($i = 0; $i < $dailyTransactions; $i++) {
                $driver = $drivers[rand(0, count($drivers) - 1)];
                $device = $devices[rand(0, count($devices) - 1)];
                
                // Create income transaction
                Transaction::create([
                    'driver_id' => $driver->id,
                    'device_id' => $device->id,
                    'amount' => rand(20000, 80000), // 20K to 80K UGX
                    'type' => 'income',
                    'category' => $paymentCategories[rand(0, count($paymentCategories) - 1)],
                    'description' => 'Daily payment from driver',
                    'customer_name' => $driver->user->name,
                    'customer_phone' => $driver->user->phone_number,
                    'status' => 'completed',
                    'transaction_date' => $date->copy()->addHours(rand(6, 20))->addMinutes(rand(0, 59)),
                    'payment_method' => $paymentMethods[rand(0, count($paymentMethods) - 1)],
                    'reference_number' => 'TXN' . $date->format('Ymd') . $i . rand(1000, 9999)
                ]);
            }
            
            // Generate 1-4 expense transactions per day (less frequent)
            if (rand(1, 10) <= 7) { // 70% chance of expenses on any given day
                $dailyExpenses = rand(1, 4);
                
                for ($i = 0; $i < $dailyExpenses; $i++) {
                    $device = $devices[rand(0, count($devices) - 1)];
                    
                    Transaction::create([
                        'driver_id' => $device->driver_id,
                        'device_id' => $device->id,
                        'amount' => rand(5000, 30000), // 5K to 30K UGX
                        'type' => 'expense',
                        'category' => $expenseCategories[rand(0, count($expenseCategories) - 1)],
                        'description' => 'Vehicle maintenance expense',
                        'status' => 'completed',
                        'transaction_date' => $date->copy()->addHours(rand(8, 18))->addMinutes(rand(0, 59)),
                        'payment_method' => $paymentMethods[rand(0, count($paymentMethods) - 1)],
                        'reference_number' => 'EXP' . $date->format('Ymd') . $i . rand(1000, 9999)
                    ]);
                }
            }
        }
        
        // Create some pending transactions for realism
        for ($i = 0; $i < 5; $i++) {
            $driver = $drivers[rand(0, count($drivers) - 1)];
            $device = $devices[rand(0, count($devices) - 1)];
            
            Transaction::create([
                'driver_id' => $driver->id,
                'device_id' => $device->id,
                'amount' => rand(25000, 60000),
                'type' => 'income',
                'category' => $paymentCategories[rand(0, count($paymentCategories) - 1)],
                'description' => 'Pending payment from driver',
                'customer_name' => $driver->user->name,
                'customer_phone' => $driver->user->phone_number,
                'status' => 'pending',
                'transaction_date' => Carbon::now()->subHours(rand(1, 24)),
                'payment_method' => $paymentMethods[rand(0, count($paymentMethods) - 1)],
                'reference_number' => 'PND' . now()->format('Ymd') . $i . rand(1000, 9999)
            ]);
        }
        
        $this->command->info('Analytics sample data seeded successfully!');
        $this->command->info('Created:');
        $this->command->info('- ' . count($users) . ' users');
        $this->command->info('- ' . count($drivers) . ' drivers'); 
        $this->command->info('- ' . count($devices) . ' devices');
        $this->command->info('- ' . Transaction::count() . ' transactions');
    }
}