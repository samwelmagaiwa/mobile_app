<?php

namespace App\Services\Inventory;

use Illuminate\Support\Facades\DB;
use InvalidArgumentException;

/**
 * Generates a readable, unique SKU: {PREFIX}-{RANDOM_4_DIGITS}, e.g. COC-COL-7482.
 * Mirrors the frontend auto-generation logic precisely.
 */
class SkuGenerator
{
    public function generate(string $productName): string
    {
        $name = trim($productName);
        $prefix = 'SKU';

        if ($name !== '') {
            $parts = preg_split('/\s+/', $name);
            if (count($parts) >= 2) {
                $p1 = strtoupper(preg_replace('/[^A-Za-z]/', '', $parts[0]));
                $p2 = strtoupper(preg_replace('/[^A-Za-z]/', '', $parts[1]));

                $p1 = strlen($p1) >= 3 ? substr($p1, 0, 3) : (empty($p1) ? 'SKU' : str_pad($p1, 3, 'X'));
                $p2 = strlen($p2) >= 3 ? substr($p2, 0, 3) : (empty($p2) ? '' : str_pad($p2, 3, 'X'));

                $prefix = empty($p2) ? $p1 : "{$p1}-{$p2}";
            } else {
                $p1 = strtoupper(preg_replace('/[^A-Za-z]/', '', $parts[0]));
                $p1 = strlen($p1) >= 3 ? substr($p1, 0, 3) : (empty($p1) ? 'SKU' : str_pad($p1, 3, 'X'));
                $prefix = $p1;
            }
        }

        // Loop to ensure absolute uniqueness in DB
        do {
            $randomNum = random_int(1000, 9999);
            $sku = "{$prefix}-{$randomNum}";
            $exists = DB::table('inventory_products')->where('sku', $sku)->exists();
        } while ($exists);

        return $sku;
    }
}
