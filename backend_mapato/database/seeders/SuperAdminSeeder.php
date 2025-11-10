<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;
use App\Models\User;

class SuperAdminSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $user = User::where('email', 'superadmin@gmail.com')->first();

        $superAdminPhone = '0743519100';

        if (!$user) {
            User::create([
                'id' => Str::uuid(),
                'name' => 'Super Admin',
                'email' => 'superadmin@gmail.com',
                'password' => Hash::make('12345678'),
                'phone_number' => $superAdminPhone,
                'role' => 'super_admin',
                'is_active' => true,
                'email_verified' => true,
                'phone_verified' => true,
                'email_verified_at' => now(),
            ]);
            echo "✅ Super Admin created: superadmin@gmail.com / 12345678\n";
        } else {
            $user->update([
                'name' => 'Super Admin',
                'password' => Hash::make('12345678'),
                'phone_number' => $superAdminPhone,
                'role' => 'super_admin',
                'is_active' => true,
                'email_verified' => true,
                'phone_verified' => true,
                'email_verified_at' => now(),
            ]);
            echo "ℹ️ Super Admin updated: superadmin@gmail.com\n";
        }
    }
}
