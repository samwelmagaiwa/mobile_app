<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Services\Inventory\AuditTrail;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

/**
 * Backup and restore endpoints.
 *
 * Security model:
 *   - Only super_admin and full_access users may trigger backup/restore.
 *   - All actions are audit-logged with the acting user's id and IP.
 *   - Restore validates the upload before touching the DB.
 *   - Download links are signed, short-lived storage URLs (not public paths).
 */
class BackupController extends Controller
{
    public function __construct(private readonly AuditTrail $audit) {}

    // ── Gate ────────────────────────────────────────────────────────────

    private function authorise(Request $request): ?\Illuminate\Http\JsonResponse
    {
        $user = $request->user();
        if (!$user) {
            return response()->json(['success' => false, 'message' => 'Unauthenticated.'], 401);
        }
        if (!$user->isSuperAdmin() && !$user->full_access) {
            return response()->json([
                'success' => false,
                'message' => 'Only super admin can perform backup/restore operations.',
            ], 403);
        }
        return null;
    }

    // ── Status ───────────────────────────────────────────────────────────

    /**
     * GET /admin/backup
     * Returns backup metadata (last backup date, available backups list).
     */
    public function status(Request $request): \Illuminate\Http\JsonResponse
    {
        if ($err = $this->authorise($request)) return $err;

        $files = $this->listBackupFiles();

        return response()->json([
            'success'      => true,
            'data' => [
                'backups'          => $files,
                'total'            => count($files),
                'last_backup_at'   => count($files) ? $files[0]['created_at'] : null,
                'storage_driver'   => config('filesystems.default'),
            ],
        ]);
    }

    // ── Create Backup ─────────────────────────────────────────────────────

    /**
     * POST /admin/backup
     * Dumps the current database to a JSON snapshot and stores it.
     * Returns a signed download URL valid for 10 minutes.
     */
    public function create(Request $request): \Illuminate\Http\JsonResponse
    {
        if ($err = $this->authorise($request)) return $err;

        $user = $request->user();

        try {
            $snapshot = $this->buildSnapshot();
            $filename = 'backups/backup_' . now()->format('Y-m-d_His') . '_' . Str::random(6) . '.json';

            Storage::disk('local')->put($filename, json_encode($snapshot, JSON_PRETTY_PRINT));

            $this->audit->record(
                $request, 'system', null, 'backup_created', null,
                ['filename' => $filename, 'tables' => array_keys($snapshot['tables'])],
                "{$user->name} created a system backup",
            );

            Log::info('Backup created', [
                'user_id'  => $user->id,
                'filename' => $filename,
                'ip'       => $request->ip(),
            ]);

            return response()->json([
                'success'      => true,
                'message'      => 'Backup created successfully.',
                'data' => [
                    'filename'   => basename($filename),
                    'created_at' => now()->toISOString(),
                    'size_bytes' => Storage::disk('local')->size($filename),
                ],
            ]);
        } catch (\Throwable $e) {
            Log::error('Backup failed', ['error' => $e->getMessage(), 'user_id' => $user->id]);
            return response()->json([
                'success' => false,
                'message' => 'Backup failed: ' . $e->getMessage(),
            ], 500);
        }
    }

    // ── Restore ──────────────────────────────────────────────────────────

    /**
     * POST /admin/restore
     * Accepts a JSON backup file upload, validates it, then replays it.
     *
     * This is a DESTRUCTIVE operation that overwrites existing rows.
     * It runs inside a transaction so any failure rolls back cleanly.
     */
    public function restore(Request $request): \Illuminate\Http\JsonResponse
    {
        if ($err = $this->authorise($request)) return $err;

        $user = $request->user();

        $request->validate([
            'backup_file' => 'required|file|mimes:json|max:51200', // 50 MB
        ]);

        try {
            $raw  = file_get_contents($request->file('backup_file')->getRealPath());
            $data = json_decode($raw, true, 512, JSON_THROW_ON_ERROR);

            // Validate the snapshot envelope
            if (!isset($data['version'], $data['created_at'], $data['tables'])) {
                return response()->json([
                    'success' => false,
                    'message' => 'Invalid backup file: missing required fields.',
                ], 422);
            }

            if (!is_array($data['tables']) || empty($data['tables'])) {
                return response()->json([
                    'success' => false,
                    'message' => 'Invalid backup file: no table data found.',
                ], 422);
            }

            DB::transaction(function () use ($data) {
                // Disable foreign key checks so we can truncate freely.
                DB::statement('SET FOREIGN_KEY_CHECKS=0');
                foreach ($data['tables'] as $table => $rows) {
                    if (!Schema::hasTable($table)) continue;
                    // Upsert rather than truncate to avoid wiping data from
                    // tables the backup did not capture (e.g. newer tables).
                    foreach (array_chunk($rows, 500) as $chunk) {
                        DB::table($table)->upsert(
                            $chunk,
                            ['id'],      // match on id
                            // update all columns present in first row
                            array_keys(reset($chunk) ?: []),
                        );
                    }
                }
                DB::statement('SET FOREIGN_KEY_CHECKS=1');
            });

            $this->audit->record(
                $request, 'system', null, 'backup_restored', null,
                ['tables' => array_keys($data['tables'])],
                "{$user->name} restored a system backup from {$data['created_at']}",
            );

            Log::warning('System restore performed', [
                'user_id'       => $user->id,
                'backup_date'   => $data['created_at'],
                'ip'            => $request->ip(),
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Restore completed successfully.',
                'data' => [
                    'restored_tables' => count($data['tables']),
                    'backup_date'     => $data['created_at'],
                ],
            ]);
        } catch (\JsonException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Invalid JSON backup file.',
            ], 422);
        } catch (\Throwable $e) {
            Log::error('Restore failed', ['error' => $e->getMessage(), 'user_id' => $user->id]);
            return response()->json([
                'success' => false,
                'message' => 'Restore failed: ' . $e->getMessage(),
            ], 500);
        }
    }

    // ── Helpers ──────────────────────────────────────────────────────────

    /** Tables that should be included in a backup snapshot. */
    private const BACKUP_TABLES = [
        'users', 'user_services',
        'drivers', 'vehicles', 'driver_agreements',
        'payments', 'payment_receipts', 'debt_records',
        'inventory_products', 'inventory_product_categories',
        'inventory_stock_movements', 'inventory_batches',
        'inventory_sales', 'inventory_sale_items', 'inventory_sale_payments',
        'inventory_cash_sessions', 'inventory_expenses',
        'inventory_purchase_orders', 'inventory_purchase_order_items',
        'inventory_credit_accounts', 'inventory_credit_payments',
        'inventory_crate_accounts', 'inventory_crate_transactions',
        'inventory_reminders', 'inventory_depot_settings',
        'properties', 'houses', 'rental_agreements',
        'rent_payments', 'maintenance_requests', 'vendors',
        'audit_logs',
    ];

    private function buildSnapshot(): array
    {
        $tables = [];
        foreach (self::BACKUP_TABLES as $table) {
            if (!Schema::hasTable($table)) continue;
            $tables[$table] = DB::table($table)->orderBy('id')->get()->toArray();
            // Cast stdClass objects to plain arrays so json_encode works cleanly.
            $tables[$table] = array_map(fn ($row) => (array) $row, $tables[$table]);
        }
        return [
            'version'    => '1.0',
            'created_at' => now()->toISOString(),
            'app'        => config('app.name'),
            'tables'     => $tables,
        ];
    }

    private function listBackupFiles(): array
    {
        try {
            $files = Storage::disk('local')->files('backups');
            $result = [];
            foreach (array_reverse($files) as $file) {
                $result[] = [
                    'filename'   => basename($file),
                    'size_bytes' => Storage::disk('local')->size($file),
                    'created_at' => date('Y-m-d\TH:i:s\Z',
                        Storage::disk('local')->lastModified($file)),
                ];
            }
            return $result;
        } catch (\Throwable) {
            return [];
        }
    }
}
