<?php

namespace App\Services;

use Illuminate\Support\Facades\DB;
use Throwable;

/**
 * What the public status page checks before it claims the API is running. Kept to things
 * that are safe to report publicly (reachable or not); details stay in the logs.
 */
class HealthCheck
{
    /** Can the application reach its database and run a query? */
    public function database(): bool
    {
        try {
            DB::select('select 1');

            return true;
        } catch (Throwable) {
            return false;
        }
    }
}
