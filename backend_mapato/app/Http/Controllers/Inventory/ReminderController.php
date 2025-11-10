<?php

namespace App\Http\Controllers\Inventory;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;
use Illuminate\Routing\Controller;

class ReminderController extends Controller
{
    public function index(Request $request)
    {
        $type = $request->query('type'); // payment_due | low_stock
        $status = $request->query('status'); // open | snoozed | done

        $q = DB::table('inventory_reminders')->orderByDesc('id');
        if ($type) { $q->where('type', $type); }
        if ($status) { $q->where('status', $status); }

        $reminders = $q->paginate(20);
        return response()->json([
            'data' => $reminders->items(),
            'meta' => [
                'current_page' => $reminders->currentPage(),
                'last_page' => $reminders->lastPage(),
                'per_page' => $reminders->perPage(),
                'total' => $reminders->total(),
            ],
        ]);
    }

    public function markDone($id)
    {
        $row = DB::table('inventory_reminders')->where('id', $id)->first();
        if (!$row) return response()->json(['message' => 'Not found'], 404);
        DB::table('inventory_reminders')->where('id', $id)->update([
            'status' => 'done',
            'updated_at' => now(),
        ]);
        return response()->json(['message' => 'Reminder marked done']);
    }

    public function snooze(Request $request, $id)
    {
        $v = Validator::make($request->all(), [
            'minutes' => 'nullable|integer|min:1',
            'until' => 'nullable|date',
        ]);
        if ($v->fails()) return response()->json(['message' => $v->errors()->first()], 422);

        $row = DB::table('inventory_reminders')->where('id', $id)->first();
        if (!$row) return response()->json(['message' => 'Not found'], 404);

        $until = $request->until ? now()->parse($request->until) : now()->addMinutes($request->input('minutes', 60));
        DB::table('inventory_reminders')->where('id', $id)->update([
            'status' => 'snoozed',
            'snooze_until' => $until,
            'updated_at' => now(),
        ]);
        return response()->json(['message' => 'Reminder snoozed']);
    }
}
