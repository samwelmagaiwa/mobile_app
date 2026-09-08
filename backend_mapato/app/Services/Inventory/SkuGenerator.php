<?php

namespace App\Services\Inventory;

use Illuminate\Support\Facades\DB;

/**
 * Generates a structured, readable SKU: BRAND-PRODUCT-SIZE-UNIT, e.g.
 * MAJ-WTR-500-CTN. Deterministic from the product's own fields rather than
 * a random suffix, so two batches of the exact same product/size/unit
 * naturally collide (caught and disambiguated below) instead of getting
 * unrelated random codes that make near-duplicates hard to spot.
 *
 * The DB also enforces uniqueness via a UNIQUE index on inventory_products.sku
 * (see 2025_11_07_140001_create_inventory_products_table.php) as the final
 * safety net.
 */
class SkuGenerator
{
    private const UNIT_CODES = [
        'carton' => 'CTN', 'ctn' => 'CTN',
        'crate' => 'CRT', 'crt' => 'CRT',
        'box' => 'BOX',
        'bag' => 'BAG',
        'bottle' => 'BTL', 'btl' => 'BTL',
        'litre' => 'LTR', 'liter' => 'LTR', 'ltr' => 'LTR', 'l' => 'LTR',
        'kg' => 'KG', 'kilogram' => 'KG',
        'gram' => 'GRM', 'g' => 'GRM',
        'dozen' => 'DZN', 'dz' => 'DZN',
        'packet' => 'PKT', 'pkt' => 'PKT',
        'piece' => 'PCS', 'pieces' => 'PCS', 'pcs' => 'PCS', 'pc' => 'PCS',
        'sack' => 'SCK',
        'roll' => 'RLL',
    ];

    public function generate(string $productName, ?int $brandId = null, ?string $unit = null): string
    {
        $name = trim($productName);

        $brandName = $brandId
            ? (string) (DB::table('inventory_brands')->where('id', $brandId)->value('name') ?? '')
            : '';

        // Pull out a size token (e.g. "500ml", "1.5L", "2KG") so it doesn't
        // also get consumed as the "product" word.
        $sizeCode = null;
        $nameForWords = $name;
        if (preg_match('/(\d+(?:\.\d+)?)\s*(ml|l|kg|g|pcs|pc|dz)\b/i', $name, $m)) {
            $sizeCode = str_replace('.', '', $m[1]);
            $nameForWords = trim(str_replace($m[0], '', $name));
        }

        $words = preg_split('/\s+/', trim($nameForWords)) ?: [];
        $brandWords = $brandName !== '' ? preg_split('/\s+/', $brandName) : [];

        $brandCode = $this->wordCode($brandWords[0] ?? ($words[0] ?? ''), 'SKU');

        // Product code: the first remaining word that isn't the brand's own
        // word, so BRAND and PRODUCT don't repeat the same code.
        $productWord = '';
        foreach ($words as $w) {
            if ($brandName === '' || strcasecmp($w, $brandWords[0] ?? '') !== 0) {
                $productWord = $w;
                break;
            }
        }
        $productCode = $this->wordCode($productWord, 'GEN');

        $unitCode = $this->unitCode($unit);

        $segments = array_filter([$brandCode, $productCode, $sizeCode, $unitCode], fn ($s) => $s !== null && $s !== '');
        $base = implode('-', $segments);

        // Deterministic base should already be unique in the common case;
        // append a running suffix only if it genuinely collides (e.g. the
        // exact same brand/product/size/unit combo already exists).
        $sku = $base;
        $suffix = 1;
        while (DB::table('inventory_products')->where('sku', $sku)->exists()) {
            $suffix++;
            $sku = "{$base}-{$suffix}";
        }

        return $sku;
    }

    private function wordCode(string $word, string $fallback): string
    {
        $letters = strtoupper(preg_replace('/[^A-Za-z]/', '', $word) ?? '');
        if ($letters === '') {
            return $fallback;
        }
        return strlen($letters) >= 3 ? substr($letters, 0, 3) : str_pad($letters, 3, 'X');
    }

    private function unitCode(?string $unit): string
    {
        $unit = strtolower(trim((string) $unit));
        if ($unit === '') {
            return 'PCS';
        }
        return self::UNIT_CODES[$unit] ?? $this->wordCode($unit, 'PCS');
    }
}
