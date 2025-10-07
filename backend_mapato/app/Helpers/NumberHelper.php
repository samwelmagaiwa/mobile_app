<?php

namespace App\Helpers;

class NumberHelper
{
    /**
     * Format file size without requiring intl extension
     *
     * @param float $bytes
     * @param int $precision
     * @return string
     */
    public static function fileSize(float $bytes, int $precision = 2): string
    {
        $units = ['B', 'KB', 'MB', 'GB', 'TB', 'PB'];
        
        for ($i = 0; $bytes > 1024 && $i < count($units) - 1; $i++) {
            $bytes /= 1024;
        }
        
        return round($bytes, $precision) . ' ' . $units[$i];
    }

    /**
     * Format number without requiring intl extension
     *
     * @param float $number
     * @param int $precision
     * @param string|null $locale
     * @return string
     */
    public static function format(float $number, int $precision = 0, ?string $locale = null): string
    {
        return number_format($number, $precision);
    }

    /**
     * Format percentage
     *
     * @param float $number
     * @param int $precision
     * @return string
     */
    public static function percentage(float $number, int $precision = 0): string
    {
        return number_format($number, $precision) . '%';
    }

    /**
     * Format currency (basic implementation)
     *
     * @param float $number
     * @param string $currency
     * @param string|null $locale
     * @return string
     */
    public static function currency(float $number, string $currency = 'USD', ?string $locale = null): string
    {
        $formatted = number_format($number, 2);
        
        switch (strtoupper($currency)) {
            case 'USD':
                return '$' . $formatted;
            case 'EUR':
                return '€' . $formatted;
            case 'TZS':
                return 'TSh ' . $formatted;
            default:
                return $currency . ' ' . $formatted;
        }
    }
}