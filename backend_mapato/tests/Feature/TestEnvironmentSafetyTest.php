<?php

namespace Tests\Feature;

use Tests\TestCase;

/**
 * Guards against the exact incident that wiped the shared dev database:
 * a test using RefreshDatabase silently running against the live MySQL
 * connection instead of an isolated one, because .env.testing was missing.
 *
 * If this test ever fails, do not run anything that touches the database
 * until it is fixed — any RefreshDatabase-based test would destroy real data.
 */
class TestEnvironmentSafetyTest extends TestCase
{
    public function test_tests_never_run_against_the_shared_mysql_database(): void
    {
        $connection = config('database.default');

        $this->assertNotSame(
            'mysql',
            $connection,
            'Tests are running against the "mysql" connection. This is how the shared '
            . 'dev database got wiped by a RefreshDatabase test. Check that .env.testing '
            . 'exists and sets DB_CONNECTION=sqlite / DB_DATABASE=:memory:, and that no '
            . 'cached config (bootstrap/cache/config.php) is overriding it.',
        );

        $this->assertSame('sqlite', $connection);
        $this->assertSame('testing', app()->environment());
    }
}
