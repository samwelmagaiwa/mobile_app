<?php

namespace App\Http\Controllers\Inventory;

use Illuminate\Http\Request;
use Illuminate\Routing\Controller;
use Illuminate\Support\Facades\DB;

/**
 * A logged-in user's own approval-notification inbox. No inv_perm gate --
 * every authenticated user may read and clear their own notifications;
 * what they were notified ABOUT was already permission-checked when it
 * was created (InventoryNotifier only fans out to holders of the relevant
 * permission), and the query below is always scoped to the caller's id.
 */
class NotificationController extends Controller
{
    public function index(Request $request)
    {
        $userId = optional($request->user())->id;
        if ($userId === null) {
            return response()->json(['message' => 'Unauthenticated.'], 401);
        }

        $query = DB::table('inventory_notifications')->where('user_id', $userId);
        if ($request->boolean('unread_only')) {
            $query->whereNull('read_at');
        }

        $rows = $query->orderByDesc('id')->limit(200)->get()->map(function ($row) {
            $row->data = $row->data !== null ? json_decode($row->data, true) : null;

            return $row;
        });

        return response()->json([
            'data' => $rows,
            'meta' => [
                'unread_count' => DB::table('inventory_notifications')
                    ->where('user_id', $userId)->whereNull('read_at')->count(),
            ],
        ]);
    }

    public function markRead(Request $request, int $id)
    {
        $userId = optional($request->user())->id;
        $updated = DB::table('inventory_notifications')
            ->where('id', $id)
            ->where('user_id', $userId) // never lets a user mark someone else's notification
            ->update(['read_at' => now(), 'updated_at' => now()]);

        return $updated
            ? response()->json(['message' => 'Marked read'])
            : response()->json(['message' => 'Not found'], 404);
    }

    public function markAllRead(Request $request)
    {
        $userId = optional($request->user())->id;
        DB::table('inventory_notifications')
            ->where('user_id', $userId)
            ->whereNull('read_at')
            ->update(['read_at' => now(), 'updated_at' => now()]);

        return response()->json(['message' => 'All marked read']);
    }
}
