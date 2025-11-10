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
        // Normalize the path to avoid leading slashes or directory traversal
        $path = ltrim($path, '/');

        // Only serve real files; directory requests should 404 (prevents Flysystem file_size error)
        if ($path === '' || !Storage::disk('public')->fileExists($path)) {
            abort(404);
        }

        // Stream the file with CORS headers so mobile/web can fetch it WITHOUT relying on file_size
        $disk = Storage::disk('public');
        $stream = $disk->readStream($path);
        if ($stream === false) {
            abort(404);
        }
        $mime = 'application/octet-stream';
        try {
            $mime = $disk->mimeType($path) ?? $mime;
        } catch (\Throwable $e) {
            // ignore and keep default
        }

        return response()->stream(function () use ($stream) {
            fpassthru($stream);
            if (is_resource($stream)) {
                fclose($stream);
            }
        }, 200, [
            'Content-Type' => $mime,
            'Cache-Control' => 'public, max-age=86400',
            'Access-Control-Allow-Origin' => '*',
            'Access-Control-Allow-Methods' => 'GET, OPTIONS',
            'Access-Control-Allow-Headers' => 'Origin, X-Requested-With, Content-Type, Accept, Authorization',
        ]);
    }
}