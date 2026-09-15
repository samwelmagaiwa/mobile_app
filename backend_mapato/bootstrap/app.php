<?php

use Illuminate\Auth\AuthenticationException;
use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Illuminate\Http\Request;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        api: __DIR__.'/../routes/api.php',
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
    )
    ->withCommands([
        \App\Console\Commands\MakeSuperAdmin::class,
    ])
    ->withMiddleware(function (Middleware $middleware): void {
        $middleware->api(prepend: [
            \Laravel\Sanctum\Http\Middleware\EnsureFrontendRequestsAreStateful::class,
        ]);
        
        $middleware->alias([
            'role'     => \App\Http\Middleware\RoleMiddleware::class,
            'role_any' => \App\Http\Middleware\RoleAny::class,
            'inv_perm' => \App\Http\Middleware\CheckInventoryPermission::class,
        ]);
        
        $middleware->validateCsrfTokens(except: [
            'api/*',
        ]);

        // API-only backend: there is no 'login' route. Laravel's
        // ApplicationBuilder pre-registers a default redirect callback of
        // `fn () => route('login')`; Authenticate::unauthenticated() calls
        // that callback EAGERLY while building the AuthenticationException
        // whenever the request doesn't look like it expects JSON (a mobile
        // HTTP client that omits Accept: application/json, say) -- so it
        // throws RouteNotFoundException before the AuthenticationException
        // even exists, crashing as a raw 500 instead of reaching any
        // exception render callback. Overriding it to return null stops
        // that eager crash; the render() below turns the resulting
        // AuthenticationException into a proper 401 JSON response.
        $middleware->redirectGuestsTo(fn () => null);
    })
    ->withExceptions(function (Exceptions $exceptions): void {
        // API-only backend: there is no 'login' route to redirect guests to.
        // Laravel's default Handler::unauthenticated() falls back to
        // route('login') whenever the request doesn't look like it expects
        // JSON (e.g. a mobile HTTP client that omits Accept: application/json)
        // -- that route doesn't exist here, so it throws RouteNotFoundException
        // and a plain unauthenticated request crashes as a raw 500 instead of
        // the intended 401. Render it as JSON unconditionally instead.
        $exceptions->render(function (AuthenticationException $e, Request $request) {
            return response()->json(['message' => $e->getMessage()], 401);
        });
    })->create();
