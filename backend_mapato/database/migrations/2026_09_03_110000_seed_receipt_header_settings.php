<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    private array $keys = [
        'receipt_tagline'     => '',       // line printed under shop name
        'receipt_tin'         => '',       // Tax Identification Number
        'receipt_email'       => '',       // contact email on receipt
        'receipt_website'     => '',       // website / social handle
        'receipt_footer_note' => 'Bidhaa zilizouzwa haziruhusiwi kurudishwa bila risiti.',
        'receipt_show_barcode'=> '1',      // 1 = show, 0 = hide
        'receipt_show_tin'    => '1',
        'receipt_copies'      => '1',      // how many copies to print
    ];

    public function up(): void
    {
        $existing = DB::table('inventory_settings')->pluck('key')->all();

        foreach ($this->keys as $key => $default) {
            if (in_array($key, $existing, true)) {
                continue;
            }
            DB::table('inventory_settings')->insert([
                'key'        => $key,
                'value'      => $default,
                'updated_at' => now(),
            ]);
        }
    }

    public function down(): void
    {
        DB::table('inventory_settings')
            ->whereIn('key', array_keys($this->keys))
            ->delete();
    }
};
