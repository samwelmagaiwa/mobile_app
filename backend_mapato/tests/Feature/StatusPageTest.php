<?php

namespace Tests\Feature;

use App\Services\HealthCheck;
use Tests\TestCase;

/**
 * The page at the site root says whether the API is working, from a real check.
 */
class StatusPageTest extends TestCase
{
    public function test_the_root_page_says_the_api_is_running(): void
    {
        $response = $this->get('/');

        $response->assertOk();
        $response->assertSee('The API is running');
        $response->assertSee('Online');
        $response->assertSee('Connected');
        $response->assertSee('3 in One API');
        $response->assertSee('Transport');
        $response->assertSee('Open the health check');
        $response->assertSee(config('app.api_version'));
        $response->assertSee(url('/api/health'), false);
    }

    public function test_it_is_no_longer_laravels_welcome_page(): void
    {
        $this->get('/')
            ->assertDontSee("Let's get started")
            ->assertDontSee('Deploy now')
            ->assertDontSee('Laracasts');
    }

    public function test_it_shows_the_server_time_in_utc_and_is_never_cached(): void
    {
        $this->travelTo(now()->utc()->setDate(2026, 10, 13)->setTime(10, 46, 40));

        $response = $this->get('/');

        $response->assertSee('2026-10-13 10:46:40');
        $this->assertStringContainsString('no-store', $response->headers->get('Cache-Control'));
    }

    public function test_it_does_not_tell_the_public_anything_sensitive(): void
    {
        $body = $this->get('/')->getContent();

        $this->assertStringNotContainsString(PHP_VERSION, $body);
        $this->assertStringNotContainsString(base_path(), $body);
        $this->assertStringNotContainsStringIgnoringCase('sqlite', $body);
        $this->assertStringNotContainsStringIgnoringCase('mysql', $body);
    }

    public function test_when_the_database_is_down_it_says_so_and_returns_503(): void
    {
        $this->mock(HealthCheck::class, fn ($m) => $m->shouldReceive('database')->andReturn(false));

        $response = $this->get('/');

        $response->assertStatus(503);
        $response->assertSee('The API is having trouble');
        $response->assertSee('Degraded');
        $response->assertSee('Unreachable');
        $response->assertDontSee('The API is running');
    }

    public function test_monitoring_tools_can_ask_for_json(): void
    {
        $this->getJson('/')
            ->assertOk()
            ->assertJsonPath('status', 'online')
            ->assertJsonPath('database', 'connected')
            ->assertJsonPath('version', config('app.api_version'))
            ->assertJsonStructure(['status', 'database', 'version', 'server_time_utc']);

        $this->mock(HealthCheck::class, fn ($m) => $m->shouldReceive('database')->andReturn(false));
        $this->getJson('/')->assertStatus(503)->assertJsonPath('status', 'degraded');
    }

    public function test_the_api_health_check_reports_the_same_version(): void
    {
        $this->getJson('/api/health')
            ->assertOk()
            ->assertJsonPath('version', config('app.api_version'));
    }

    public function test_the_real_health_check_is_true_when_the_database_answers(): void
    {
        $this->assertTrue(app(HealthCheck::class)->database());
    }
}
