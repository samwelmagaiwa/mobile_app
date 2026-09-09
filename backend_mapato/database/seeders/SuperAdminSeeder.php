<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;
use App\Models\User;
use App\Models\UserService;

class SuperAdminSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $email    = env('SUPER_ADMIN_EMAIL', 'superadmin@example.com');
        $phone    = env('SUPER_ADMIN_PHONE', '');
        $password = env('SUPER_ADMIN_PASSWORD', Str::random(16));

        $user = User::where('email', $email)->first();

        if (!$user) {
            $user = User::create([
                'id'               => Str::uuid(),
                'name'             => 'Super Admin',
                'email'            => $email,
                'password'         => Hash::make($password),
                'phone_number'     => $phone ?: null,
                'role'             => 'super_admin',
                'is_active'        => true,
                'email_verified'   => true,
                'phone_verified'   => true,
                'email_verified_at'=> now(),
            ]);
            echo "✅ Super Admin created: {$email}\n";
        } else {
            $user->update([
                'name'             => 'Super Admin',
                'password'         => Hash::make($password),
                'phone_number'     => $phone ?: $user->phone_number,
                'role'             => 'super_admin',
                'is_active'        => true,
                'email_verified'   => true,
                'phone_verified'   => true,
                'email_verified_at'=> now(),
            ]);
            echo "ℹ️ Super Admin updated: {$email}\n";
        }

        // Super admin is bound to ALL services by default so the services
        // relation is never empty and API responses are consistent.
        foreach (['inventory', 'rental', 'transport'] as $service) {
            UserService::firstOrCreate([
                'user_id'      => $user->id,
                'service_type' => $service,
            ]);
        }
        echo "✅ Super Admin services: inventory, rental, transport\n";
    }
}
