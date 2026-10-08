<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Put back the reference data every depot starts with -- the two default crate
     * types and the depot settings -- after a data clean-up emptied those tables.
     * Without crate types a sale cannot record crates owed; without settings the
     * settings screen cannot save anything.
     *
     * Only adds what is missing: existing rows (including any a user has edited or
     * renamed) are left exactly as they are, so running this twice changes nothing.
     */
    public function up(): void
    {
        $settings = [
            'depot_name' => 'Beverage Depot',
            'depot_phone' => '',
            'depot_address' => '',
            'invoice_prefix' => 'INV',
            'invoice_next_number' => '1',
            'tax_percent' => '0',
            'max_discount_percent' => '10',
            'low_stock_threshold' => '5',
            'expiry_alert_days' => '30',
            'overdue_alert_days' => '7',
            'large_discount_percent' => '15',
            'receipt_tagline' => '',
            'receipt_tin' => '',
            'receipt_email' => '',
            'receipt_website' => '',
            'receipt_footer_note' => 'Bidhaa zilizouzwa haziruhusiwi kurudishwa bila risiti.',
            'receipt_show_barcode' => '1',
            'receipt_show_tin' => '1',
            'receipt_copies' => '1',
        ];

        foreach ($settings as $key => $value) {
            if (! DB::table('inventory_settings')->where('key', $key)->exists()) {
                DB::table('inventory_settings')->insert([
                    'key' => $key,
                    'value' => $value,
                    'updated_at' => now(),
                ]);
            }
        }

        foreach ([['Crate', 2000], ['Empty bottle', 100]] as [$name, $deposit]) {
            if (! DB::table('inventory_crate_types')->where('name', $name)->exists()) {
                DB::table('inventory_crate_types')->insert([
                    'name' => $name,
                    'deposit_value' => $deposit,
                    'status' => 'active',
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);
            }
        }
    }

    public function down(): void
    {
        // Reference data: nothing to undo.
    }
};
