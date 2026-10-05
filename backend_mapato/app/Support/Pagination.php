<?php

namespace App\Support;

use Illuminate\Http\Request;

final class Pagination
{
    /** Hard ceiling so one request can never ask for the whole table. */
    public const MAX_PER_PAGE = 100;

    /**
     * Page size from ?per_page, clamped to 1..$max (falls back to $default when
     * absent/invalid). Pass a higher $max only for an endpoint whose client
     * genuinely needs a long page.
     */
    public static function perPage(Request $request, int $default = 15, int $max = self::MAX_PER_PAGE): int
    {
        $requested = (int) $request->query('per_page', $default);

        return min(max($requested > 0 ? $requested : $default, 1), $max);
    }
}
