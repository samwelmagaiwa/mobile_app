<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Models\User;
use Illuminate\Support\Facades\Hash;

class MakeSuperAdmin extends Command
{
    /**
     * The name and signature of the console command.
     *
     * Usage: php artisan users:make-super-admin user@example.com --phone=0743519100 --password=12345678
     */
    protected $signature = 'users:make-super-admin {email : Email of the user to promote} {--phone= : Optionally set/override phone number} {--password= : Optionally reset password}';

    /**
     * The console command description.
     */
    protected $description = 'Promote an existing user to super_admin and ensure the account is active and verified';

    /**
     * Execute the console command.
     */
    public function handle(): int
    {
        $email = (string) $this->argument('email');
        $phone = (string) ($this->option('phone') ?? '');
        $password = (string) ($this->option('password') ?? '');

        $user = User::where('email', $email)->first();
        if (!$user) {
            $this->error("User not found: {$email}");
            return self::FAILURE;
        }

        $updates = [
            'role' => 'super_admin',
            'is_active' => true,
            'email_verified' => true,
            'phone_verified' => true,
            'email_verified_at' => now(),
        ];

        if ($phone !== '') {
            $updates['phone_number'] = $phone;
        }
        if ($password !== '') {
            $updates['password'] = Hash::make($password);
        }

        $user->update($updates);

        $this->info("✅ {$email} promoted to super_admin");
        if ($phone !== '') {
            $this->info("• Phone set to: {$phone}");
        }
        if ($password !== '') {
            $this->info("• Password updated");
        }
        return self::SUCCESS;
    }
}
