<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Services\HealthCheck;
use Illuminate\Http\Request;

/**
 * The page at the site's root. It used to be Laravel's default welcome page; it now says
 * whether the API is actually working, using a real check rather than a fixed message.
 * Monitoring tools that send `Accept: application/json` get the same facts as JSON.
 */
class StatusController extends Controller
{
    public function __invoke(Request $request, HealthCheck $health)
    {
        $databaseUp = $health->database();
        $httpStatus = $databaseUp ? 200 : 503;

        $facts = [
            'online' => $databaseUp,
            'database' => $databaseUp,
            'version' => config('app.api_version'),
            'time' => now()->utc()->format('Y-m-d H:i:s'),
        ];

        $response = $request->expectsJson()
            ? response()->json([
                'status' => $databaseUp ? 'online' : 'degraded',
                'database' => $databaseUp ? 'connected' : 'unreachable',
                'version' => $facts['version'],
                'server_time_utc' => $facts['time'],
            ], $httpStatus)
            : response()->view('status', $facts + [
                'brand' => config('app.brand'),
                'healthUrl' => url('/api/health'),
            ], $httpStatus);

        // A status page that is cached shows yesterday's answer.
        return $response->header('Cache-Control', 'no-store, max-age=0');
    }
}
