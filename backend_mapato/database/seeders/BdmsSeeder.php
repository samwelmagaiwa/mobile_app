<?php

namespace Database\Seeders;

use App\Models\Bdms\Category;
use App\Models\Bdms\ContainerType;
use App\Models\Bdms\PackUnit;
use App\Models\Bdms\Product;
use App\Models\Bdms\ProductUnit;
use App\Models\Bdms\Supplier;
use App\Services\Bdms\SkuGenerator;
use Illuminate\Database\Seeder;

class BdmsSeeder extends Seeder
{
    public function run(): void
    {
        // 1. Pack Units
        $crate = PackUnit::firstOrCreate(['code' => 'CR'], ['name' => 'Crate', 'is_returnable' => true]);
        $carton = PackUnit::firstOrCreate(['code' => 'CT'], ['name' => 'Carton', 'is_returnable' => false]);
        $pack = PackUnit::firstOrCreate(['code' => 'PK'], ['name' => 'Pack', 'is_returnable' => false]);
        $bottle = PackUnit::firstOrCreate(['code' => 'BT'], ['name' => 'Bottle', 'is_returnable' => false]);

        // 2. Categories
        $maji = Category::firstOrCreate(['code' => 'MJ'], [
            'name' => 'Maji',
            'default_pack_unit_id' => $carton->id,
            'is_active' => true,
        ]);

        $soda = Category::firstOrCreate(['code' => 'SD'], [
            'name' => 'Soda',
            'default_pack_unit_id' => $crate->id,
            'is_active' => true,
        ]);

        $juice = Category::firstOrCreate(['code' => 'JC'], [
            'name' => 'Juice',
            'default_pack_unit_id' => $carton->id,
            'is_active' => true,
        ]);

        $bia = Category::firstOrCreate(['code' => 'BA'], [
            'name' => 'Bia',
            'default_pack_unit_id' => $crate->id,
            'is_active' => true,
        ]);

        // 3. Suppliers
        $cbl = Supplier::firstOrCreate(['name' => 'Coca-Cola Kwanza Ltd'], [
            'phone' => '+255700111222',
            'terms_days' => 14,
            'is_active' => true,
        ]);

        $tbl = Supplier::firstOrCreate(['name' => 'Tanzania Breweries Ltd'], [
            'phone' => '+255700333444',
            'terms_days' => 30,
            'is_active' => true,
        ]);

        $kiliWater = Supplier::firstOrCreate(['name' => 'Bonite Bottlers Ltd'], [
            'phone' => '+255700555666',
            'terms_days' => 7,
            'is_active' => true,
        ]);

        // 4. Container Types
        $cocaCrate = ContainerType::firstOrCreate(['name' => 'Coca-Cola 24x300ml crate'], [
            'owner_type' => 'MANUFACTURER',
            'owner_supplier_id' => $cbl->id,
            'deposit_value_cents' => 1500000, // 15,000 TZS in cents
            'is_active' => true,
        ]);

        $kiliBeerCrate = ContainerType::firstOrCreate(['name' => 'Kilimanjaro beer crate'], [
            'owner_type' => 'MANUFACTURER',
            'owner_supplier_id' => $tbl->id,
            'deposit_value_cents' => 1800000, // 18,000 TZS in cents
            'is_active' => true,
        ]);

        // 5. Products & Product Units via SkuGenerator
        $skuGen = new SkuGenerator();

        // Product 1: Coca-Cola 300ml (Soda - Crate)
        $sku1 = $skuGen->generate($soda->code, 'CC', 300);
        $prod1 = Product::firstOrCreate(['sku' => $sku1], [
            'name' => 'Coca-Cola 300ml Glass Bottle',
            'category_id' => $soda->id,
            'brand' => 'Coca-Cola',
            'supplier_id' => $cbl->id,
            'base_unit' => 'bottle',
            'size_ml' => 300,
            'is_returnable' => true,
            'container_type_id' => $cocaCrate->id,
            'is_active' => true,
        ]);

        ProductUnit::firstOrCreate([
            'product_id' => $prod1->id,
            'pack_unit_id' => $bottle->id,
        ], [
            'factor_to_base' => 1,
            'barcode' => '600123456701',
            'is_default_receiving_unit' => false,
            'is_default_selling_unit' => true,
        ]);

        ProductUnit::firstOrCreate([
            'product_id' => $prod1->id,
            'pack_unit_id' => $crate->id,
        ], [
            'factor_to_base' => 24,
            'barcode' => '600123456724',
            'is_default_receiving_unit' => true,
            'is_default_selling_unit' => false,
        ]);

        // Product 2: Kilimanjaro Premium Lager 500ml (Bia - Crate)
        $sku2 = $skuGen->generate($bia->code, 'KL', 500);
        $prod2 = Product::firstOrCreate(['sku' => $sku2], [
            'name' => 'Kilimanjaro Premium Lager 500ml',
            'category_id' => $bia->id,
            'brand' => 'Kilimanjaro',
            'supplier_id' => $tbl->id,
            'base_unit' => 'bottle',
            'size_ml' => 500,
            'is_returnable' => true,
            'container_type_id' => $kiliBeerCrate->id,
            'is_active' => true,
        ]);

        ProductUnit::firstOrCreate([
            'product_id' => $prod2->id,
            'pack_unit_id' => $bottle->id,
        ], [
            'factor_to_base' => 1,
            'barcode' => '600234567801',
            'is_default_receiving_unit' => false,
            'is_default_selling_unit' => true,
        ]);

        ProductUnit::firstOrCreate([
            'product_id' => $prod2->id,
            'pack_unit_id' => $crate->id,
        ], [
            'factor_to_base' => 20,
            'barcode' => '600234567820',
            'is_default_receiving_unit' => true,
            'is_default_selling_unit' => false,
        ]);

        // Product 3: Kilimanjaro Pure Drinking Water 500ml (Maji - Carton)
        $sku3 = $skuGen->generate($maji->code, 'KJ', 500);
        $prod3 = Product::firstOrCreate(['sku' => $sku3], [
            'name' => 'Kilimanjaro Water 500ml',
            'category_id' => $maji->id,
            'brand' => 'Kilimanjaro',
            'supplier_id' => $kiliWater->id,
            'base_unit' => 'bottle',
            'size_ml' => 500,
            'is_returnable' => false,
            'container_type_id' => null,
            'is_active' => true,
        ]);

        ProductUnit::firstOrCreate([
            'product_id' => $prod3->id,
            'pack_unit_id' => $bottle->id,
        ], [
            'factor_to_base' => 1,
            'barcode' => '600345678901',
            'is_default_receiving_unit' => false,
            'is_default_selling_unit' => true,
        ]);

        ProductUnit::firstOrCreate([
            'product_id' => $prod3->id,
            'pack_unit_id' => $carton->id,
        ], [
            'factor_to_base' => 12,
            'barcode' => '600345678912',
            'is_default_receiving_unit' => true,
            'is_default_selling_unit' => false,
        ]);

        // Product 4: Ceres Orange Juice 1L (Juice - Carton)
        $sku4 = $skuGen->generate($juice->code, 'CR', 1000);
        $prod4 = Product::firstOrCreate(['sku' => $sku4], [
            'name' => 'Ceres Orange Juice 1L Pack',
            'category_id' => $juice->id,
            'brand' => 'Ceres',
            'supplier_id' => $kiliWater->id,
            'base_unit' => 'pack',
            'size_ml' => 1000,
            'is_returnable' => false,
            'container_type_id' => null,
            'is_active' => true,
        ]);

        ProductUnit::firstOrCreate([
            'product_id' => $prod4->id,
            'pack_unit_id' => $pack->id,
        ], [
            'factor_to_base' => 1,
            'barcode' => '600456789001',
            'is_default_receiving_unit' => false,
            'is_default_selling_unit' => true,
        ]);

        ProductUnit::firstOrCreate([
            'product_id' => $prod4->id,
            'pack_unit_id' => $carton->id,
        ], [
            'factor_to_base' => 12,
            'barcode' => '600456789012',
            'is_default_receiving_unit' => true,
            'is_default_selling_unit' => false,
        ]);
    }
}
