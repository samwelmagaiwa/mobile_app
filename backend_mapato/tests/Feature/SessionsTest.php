<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * One account may be signed in on several devices at once: signing in on a new
 * device must not end the others, and only the OLDEST session goes once the
 * account is at its cap.
 */
class SessionsTest extends TestCase
{
    use RefreshDatabase;

    private const PASSWORD = 'Secret123!';

    private User $user;

    protected function setUp(): void
    {
        parent::setUp();

        $this->user = User::factory()->create([
            'email' => 'shared@example.test',
            'password' => self::PASSWORD,
            'phone_number' => '0712345678',
            'role' => 'sales_officer',
            'is_active' => true,
        ]);
        $this->user->services()->create(['service_type' => 'inventory']);
    }

    /** Sign in as a new device; returns the bearer token the app would store. */
    private function signIn(): string
    {
        $this->app['auth']->forgetGuards();

        return $this->postJson('/api/auth/login', [
            'email' => 'shared@example.test',
            'password' => self::PASSWORD,
            'phone_number' => '0712345678',
        ])->assertOk()->json('data.token');
    }

    private function statusFor(string $token, string $method = 'GET', string $uri = '/api/auth/user'): int
    {
        $this->app['auth']->forgetGuards();

        return $this->withHeader('Authorization', "Bearer {$token}")->json($method, $uri)->status();
    }

    public function test_signing_in_on_a_second_device_keeps_the_first_signed_in(): void
    {
        $phone = $this->signIn();
        $emulator = $this->signIn();

        $this->assertSame(200, $this->statusFor($phone));
        $this->assertSame(200, $this->statusFor($emulator));
    }

    public function test_signing_out_on_one_device_leaves_the_others_signed_in(): void
    {
        $phone = $this->signIn();
        $tablet = $this->signIn();

        $this->assertSame(200, $this->statusFor($phone, 'POST', '/api/auth/logout'));

        $this->assertSame(401, $this->statusFor($phone));
        $this->assertSame(200, $this->statusFor($tablet));
    }

    public function test_only_the_oldest_session_is_signed_out_when_the_cap_is_exceeded(): void
    {
        $cap = (int) config('sanctum.max_sessions');
        $this->assertGreaterThanOrEqual(2, $cap);

        $tokens = [];
        for ($i = 0; $i < $cap + 1; $i++) {
            $tokens[] = $this->signIn();
        }

        $this->assertSame(401, $this->statusFor($tokens[0]), 'the oldest session should have been signed out');
        foreach (array_slice($tokens, 1) as $token) {
            $this->assertSame(200, $this->statusFor($token));
        }
        $this->assertSame($cap, $this->user->tokens()->count());
    }

    public function test_retired_and_expired_tokens_neither_count_nor_push_a_real_session_out(): void
    {
        $cap = (int) config('sanctum.max_sessions');

        // $cap - 1 genuine sessions: exactly one slot is still free.
        $real = [];
        for ($i = 0; $i < $cap - 1; $i++) {
            $real[] = $this->user->createToken('device')->plainTextToken;
        }

        // Rows /auth/refresh retired (short grace window still open)...
        for ($i = 0; $i < 3; $i++) {
            $this->user->createToken('retired')->accessToken->forceFill(['expires_at' => now()->addMinutes(5)])->save();
        }
        // ...one that already lapsed, and one older than the token lifetime.
        $this->user->createToken('lapsed')->accessToken->forceFill(['expires_at' => now()->subMinute()])->save();
        $ancient = $this->user->createToken('ancient')->accessToken;
        $ancient->forceFill(['created_at' => now()->subDays(40)])->save();

        $newest = $this->signIn();

        foreach ($real as $token) {
            $this->assertSame(200, $this->statusFor($token), 'a real session was pushed out by non-session rows');
        }
        $this->assertSame(200, $this->statusFor($newest));
        $this->assertDatabaseMissing('personal_access_tokens', ['id' => $ancient->id]);
        $this->assertDatabaseMissing('personal_access_tokens', ['name' => 'lapsed']);
        $this->assertSame(3, $this->user->tokens()->where('name', 'retired')->count(), 'grace-window rows are left alone');
    }

    public function test_changing_the_password_still_signs_out_every_device(): void
    {
        $phone = $this->signIn();
        $tablet = $this->signIn();

        $this->app['auth']->forgetGuards();
        $this->withHeader('Authorization', "Bearer {$phone}")->postJson('/api/auth/change-password', [
            'current_password' => self::PASSWORD,
            'new_password' => 'BrandNewPass99',
            'new_password_confirmation' => 'BrandNewPass99',
        ])->assertOk();

        $this->assertSame(401, $this->statusFor($phone));
        $this->assertSame(401, $this->statusFor($tablet));
    }
}
