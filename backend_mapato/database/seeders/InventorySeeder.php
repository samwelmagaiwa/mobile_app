<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class InventorySeeder extends Seeder
{
    public function run(): void
    {
        $products = [
            [
                'id' => 1,
                'name' => 'Dog Kibble 2.5KG',
                'sku' => 'DK-25',
                'category' => 'Food & treats',
                'cost_price' => 18000.00,
                'selling_price' => 25000.00,
                'unit' => 'kg',
                'quantity' => 12,
                'min_stock' => 5,
                'status' => 'active',
                'barcode' => '000111222333',
            ],
            [
                'id' => 2,
                'name' => 'Wet Food Can 400g',
                'sku' => 'WF-400',
                'category' => 'Food & treats',
                'cost_price' => 3200.00,
                'selling_price' => 5000.00,
                'unit' => 'pcs',
                'quantity' => 60,
                'min_stock' => 20,
                'status' => 'active',
                'barcode' => '000111222334',
            ],
            [
                'id' => 3,
                'name' => 'Grooming Brush',
                'sku' => 'GR-BR',
                'category' => 'Grooming',
                'cost_price' => 7000.00,
                'selling_price' => 12000.00,
                'unit' => 'pcs',
                'quantity' => 8,
                'min_stock' => 10,
                'status' => 'active',
                'barcode' => '000111222335',
            ],
            [
                'id' => 4,
                'name' => 'Cat Litter 5L',
                'sku' => 'CL-5L',
                'category' => 'Litter & hygiene',
                'cost_price' => 15000.00,
                'selling_price' => 22000.00,
                'unit' => 'bag',
                'quantity' => 25,
                'min_stock' => 5,
                'status' => 'active',
                'barcode' => '000111222336',
            ],
            [
                'id' => 5,
                'name' => 'Coca-Cola 350ml Glass Bottle',
                'sku' => 'SD-CC-350',
                'category' => 'Soft Drinks & Sodas',
                'cost_price' => 800.00,
                'selling_price' => 1000.00,
                'unit' => 'bottle',
                'quantity' => 120,
                'min_stock' => 24,
                'status' => 'active',
                'barcode' => '600123456789',
            ],
        ];

        foreach ($products as $p) {
            DB::table('inventory_products')->updateOrInsert(
                ['id' => $p['id']],
                array_merge($p, [
                    'created_at' => now(),
                    'updated_at' => now(),
                ])
            );

            // Seed default base unit if not present
            $hasBase = DB::table('inventory_product_units')
                ->where('product_id', $p['id'])
                ->where('is_base', true)
                ->exists();

            if (!$hasBase) {
                $unitId = DB::table('inventory_product_units')->insertGetId([
                    'product_id' => $p['id'],
                    'name' => $p['unit'],
                    'factor' => 1,
                    'is_base' => true,
                    'barcode' => $p['barcode'],
                    'status' => 'active',
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);

                DB::table('inventory_product_prices')->insert([
                    'product_unit_id' => $unitId,
                    'tier' => 'retail',
                    'customer_id' => null,
                    'price' => $p['selling_price'],
                    'effective_from' => now()->toDateString(),
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);
            }
        }
    }
}
