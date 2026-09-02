<?php

namespace App\Http\Controllers\Inventory;

use Illuminate\Http\Request;
use Illuminate\Routing\Controller;
use Illuminate\Support\Facades\DB;

/**
 * Area 10 — the depot generates and prints its own barcodes for product units,
 * batches and crates, and resolves a scanned code back to what it identifies.
 */
class BarcodeController extends Controller
{
    private const PREFIX = [
        'product_unit' => 'PU',
        'batch' => 'BT',
        'crate' => 'CR',
    ];

    /** Issue (or return the existing) code for one entity. */
    public function generate(Request $request)
    {
        $data = $request->validate([
            'entity_type' => 'required|in:product_unit,batch,crate',
            'entity_id' => 'required|integer|min:1',
        ]);

        if (! $this->entityExists($data['entity_type'], (int) $data['entity_id'])) {
            return response()->json(['message' => 'That item does not exist'], 404);
        }

        $existing = DB::table('inventory_barcode_labels')
            ->where('entity_type', $data['entity_type'])
            ->where('entity_id', $data['entity_id'])
            ->first();

        if ($existing) {
            return response()->json(['data' => $existing]);
        }

        $code = $this->buildCode($data['entity_type'], (int) $data['entity_id']);

        $id = DB::table('inventory_barcode_labels')->insertGetId([
            'entity_type' => $data['entity_type'],
            'entity_id' => $data['entity_id'],
            'code' => $code,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        // A product unit's own barcode column is what the POS scans against.
        if ($data['entity_type'] === 'product_unit') {
            DB::table('inventory_product_units')
                ->where('id', $data['entity_id'])
                ->whereNull('barcode')
                ->update(['barcode' => $code, 'updated_at' => now()]);
        }

        return response()->json([
            'data' => DB::table('inventory_barcode_labels')->find($id),
        ], 201);
    }

    /**
     * EAN-13-shaped: prefix + zero-padded id + a check digit, so the code is
     * stable, unique and printable on any label stock.
     */
    private function buildCode(string $type, int $id): string
    {
        $body = self::PREFIX[$type] . str_pad((string) $id, 8, '0', STR_PAD_LEFT);
        $sum = 0;
        foreach (str_split($body) as $i => $char) {
            $sum += (ord($char) * ($i % 2 === 0 ? 1 : 3));
        }

        return $body . ($sum % 10);
    }

    private function entityExists(string $type, int $id): bool
    {
        $table = match ($type) {
            'product_unit' => 'inventory_product_units',
            'batch' => 'inventory_batches',
            'crate' => 'inventory_crate_types',
        };

        return DB::table($table)->where('id', $id)->exists();
    }

    /**
     * Resolve a scanned code. Works for generated labels, a unit's own
     * barcode, and a product's legacy barcode — so counter scanners, phone
     * cameras and manufacturer codes all land in the same place.
     */
    public function resolve(Request $request)
    {
        $code = trim((string) $request->query('code', ''));
        if ($code === '') {
            return response()->json(['message' => 'No code supplied'], 422);
        }

        $label = DB::table('inventory_barcode_labels')->where('code', $code)->first();
        if ($label) {
            return response()->json(['data' => [
                'entity_type' => $label->entity_type,
                'entity_id' => (int) $label->entity_id,
                'detail' => $this->describe($label->entity_type, (int) $label->entity_id),
            ]]);
        }

        $unit = DB::table('inventory_product_units')->where('barcode', $code)->first();
        if ($unit) {
            return response()->json(['data' => [
                'entity_type' => 'product_unit',
                'entity_id' => (int) $unit->id,
                'detail' => $this->describe('product_unit', (int) $unit->id),
            ]]);
        }

        $product = DB::table('inventory_products')->where('barcode', $code)->first();
        if ($product) {
            return response()->json(['data' => [
                'entity_type' => 'product',
                'entity_id' => (int) $product->id,
                'detail' => $product,
            ]]);
        }

        return response()->json(['message' => 'Unknown barcode'], 404);
    }

    private function describe(string $type, int $id): ?object
    {
        return match ($type) {
            'product_unit' => DB::table('inventory_product_units as u')
                ->join('inventory_products as p', 'p.id', '=', 'u.product_id')
                ->where('u.id', $id)
                ->select('u.*', 'p.name as product_name', 'p.id as product_id',
                    'p.quantity as product_quantity')
                ->first(),
            'batch' => DB::table('inventory_batches as b')
                ->join('inventory_products as p', 'p.id', '=', 'b.product_id')
                ->where('b.id', $id)
                ->select('b.*', 'p.name as product_name')
                ->first(),
            'crate' => DB::table('inventory_crate_types')->find($id),
            default => null,
        };
    }

    /** Label data for a print run; the app renders and prints the sheet. */
    public function labels(Request $request)
    {
        $data = $request->validate([
            'entity_type' => 'required|in:product_unit,batch,crate',
            'entity_ids' => 'required|array|min:1',
            'entity_ids.*' => 'integer|min:1',
        ]);

        $labels = [];
        foreach ($data['entity_ids'] as $entityId) {
            $label = DB::table('inventory_barcode_labels')
                ->where('entity_type', $data['entity_type'])
                ->where('entity_id', $entityId)
                ->first();

            if (! $label) {
                continue;
            }

            DB::table('inventory_barcode_labels')->where('id', $label->id)->update([
                'printed_count' => (int) $label->printed_count + 1,
                'last_printed_at' => now(),
                'updated_at' => now(),
            ]);

            $labels[] = [
                'code' => $label->code,
                'entity_type' => $label->entity_type,
                'entity_id' => (int) $label->entity_id,
                'detail' => $this->describe($label->entity_type, (int) $label->entity_id),
            ];
        }

        return response()->json(['data' => $labels]);
    }
}
