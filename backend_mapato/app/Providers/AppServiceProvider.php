<?php

namespace App\Providers;

use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\Facades\URL;
use Illuminate\Support\ServiceProvider;
use Laravel\Sanctum\Sanctum;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        // The container sits behind aaPanel's nginx, which terminates TLS
        // and proxies to us over plain HTTP -- with no trusted-proxy config,
        // Laravel can't see the request was HTTPS, so asset()/url() (used by
        // the Swagger UI view for its CSS/JS/favicon links) generated
        // http:// URLs and got blocked as mixed content on the https:// page.
        // This is a single known HTTPS-only production domain, so forcing
        // the scheme is simpler and more reliable than trusting proxy
        // headers we don't control.
        if ($this->app->environment('production')) {
            URL::forceScheme('https');
        }

        // 10 attempts/minute per email+IP. Keeps shared-IP offices usable while
        // making password guessing against a known email impractical.
        RateLimiter::for('login', fn (Request $request) => Limit::perMinute(10)
            ->by(strtolower((string) $request->input('email')) . '|' . $request->ip()));

        // A deactivated account's existing tokens must stop working at once, on
        // every route, instead of waiting for the app's next background refresh.
        Sanctum::authenticateAccessTokensUsing(
            fn ($accessToken, bool $isValid) => $isValid && (bool) ($accessToken->tokenable?->is_active)
        );
    }
}
