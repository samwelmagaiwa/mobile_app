<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Symfony\Component\HttpFoundation\StreamedResponse;

class MediaController extends Controller
{
    /**
     * Serve public disk files (e.g., avatars) with CORS headers for web clients.
     */
    public function publicFile(Request $request, string $path): StreamedResponse
    {
        if (!Storage::disk('public')->exists($path)) {
            abort(404);
        }
        $response = Storage::disk('public')->response($path);
        $response->headers->set('Access-Control-Allow-Origin', '*');
        $response->headers->set('Access-Control-Allow-Methods', 'GET, OPTIONS');
        $response->headers->set('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept, Authorization');
        return $response;
    }
}