<?php

namespace App\Providers;

use Illuminate\Support\Facades\URL;
use Illuminate\Support\ServiceProvider;

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
    }
}
