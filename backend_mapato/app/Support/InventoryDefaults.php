<?php

namespace App\Support;

/**
 * Reference data every depot starts with. The original inventory migration seeds
 * these rows; they live here too so the settings endpoints can fall back to them
 * (and re-create a missing key) instead of failing on an empty table.
 */
final class InventoryDefaults
{
    /** Depot settings: key => default value (stored as strings). */
    public const SETTINGS = [
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
}
