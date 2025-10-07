<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;
use Illuminate\Support\Number;
use App\Helpers\NumberHelper;

class NumberServiceProvider extends ServiceProvider
{
    /**
     * Register services.
     */
    public function register(): void
    {
        // Override Number class methods to work without intl extension
        $this->app->bind('number.helper', function () {
            return new NumberHelper();
        });
    }

    /**
     * Bootstrap services.
     */
    public function boot(): void
    {
        // Override Number facade methods if intl extension is not available
        if (!extension_loaded('intl')) {
            // Create a macro to override fileSize method
            Number::macro('fileSize', function (float $bytes, int $precision = 2) {
                return NumberHelper::fileSize($bytes, $precision);
            });

            Number::macro('format', function (float $number, int $precision = 0, ?string $locale = null) {
                return NumberHelper::format($number, $precision, $locale);
            });

            Number::macro('percentage', function (float $number, int $precision = 0) {
                return NumberHelper::percentage($number, $precision);
            });

            Number::macro('currency', function (float $number, string $currency = 'USD', ?string $locale = null) {
                return NumberHelper::currency($number, $currency, $locale);
            });
        }
    }
}