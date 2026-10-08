<?php

namespace Tests\Feature;

use FilesystemIterator;
use RecursiveDirectoryIterator;
use RecursiveIteratorIterator;
use Tests\TestCase;

/**
 * Guards against code importing a class that does not exist -- which only fails at the
 * moment that code path runs. This is how the crates report ended up crashing in
 * production: its controller moved namespace and one `use` line was left behind.
 */
class CodeIntegrityTest extends TestCase
{
    /**
     * Known leftovers in code that is never run (no route reaches it). Remove an entry
     * when the dead code is deleted or fixed -- never add one for live code.
     */
    private const KNOWN_DEAD = [
        'app/Http/Controllers/API/Transport/TransactionController.php',
    ];

    public function test_runtime_code_never_imports_a_class_that_does_not_exist(): void
    {
        $bs = chr(92);
        $missing = [];

        foreach (['app', 'routes'] as $dir) {
            $files = new RecursiveIteratorIterator(
                new RecursiveDirectoryIterator(base_path($dir), FilesystemIterator::SKIP_DOTS)
            );

            foreach ($files as $file) {
                if ($file->getExtension() !== 'php') {
                    continue;
                }
                $relative = str_replace($bs, '/', substr($file->getPathname(), strlen(base_path()) + 1));
                if (in_array($relative, self::KNOWN_DEAD, true)) {
                    continue;
                }

                $source = file_get_contents($file->getPathname());
                // [\x5c] is a backslash: `use App\Foo\Bar;`, `use App\Foo\Bar as Baz;`, `\App\Foo\Bar::class`
                preg_match_all('/^use\s+(App(?:[\x5c][A-Za-z0-9_]+)+)(?:\s+as\s+\w+)?;/m', $source, $uses);
                preg_match_all('/[\x5c]?(App(?:[\x5c][A-Za-z0-9_]+)+)::class/', $source, $refs);

                foreach (array_unique(array_merge($uses[1], $refs[1])) as $class) {
                    if (! class_exists($class) && ! interface_exists($class) && ! trait_exists($class) && ! enum_exists($class)) {
                        $missing[] = "{$relative} -> {$class}";
                    }
                }
            }
        }

        $this->assertSame([], $missing, "Imports of classes that do not exist:\n" . implode("\n", $missing));
    }

    public function test_every_routed_controller_method_exists(): void
    {
        $problems = [];

        foreach (app('router')->getRoutes()->getRoutes() as $route) {
            $action = $route->getActionName();
            if ($action === 'Closure' || ! str_contains($action, '@')) {
                continue;
            }
            [$class, $method] = explode('@', $action, 2);
            if (! class_exists($class) || ! method_exists($class, $method)) {
                $problems[] = implode('|', $route->methods()) . ' ' . $route->uri() . " -> {$action}";
            }
        }

        $this->assertSame([], $problems, "Routes pointing at a missing controller/method:\n" . implode("\n", $problems));
    }
}
