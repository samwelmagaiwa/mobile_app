<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;

/**
 * Deletes records that were created during development/testing so the
 * live database starts clean for real operations.
 *
 * Usage (on the server):
 *   docker compose exec app php artisan inventory:purge-test-data
 *
 * Add --force to skip the confirmation prompt.
 */
class PurgeTestData extends Command
{
    protected $signature   = 'inventory:purge-test-data {--force : Skip confirmation}';
    protected $description = 'Remove test/demo data from inventory tables, keeping the schema and real records intact';

    public function handle(): int
    {
        if (! $this->option('force') && ! $this->confirm(
            'This will DELETE all inventory crate movements, test sales, and test customers. Continue?', false
        )) {
            $this->info('Aborted.');
            return self::SUCCESS;
        }

        DB::transaction(function () {
            // --- Crate ledger (movements + legs) ---------------------------------
            $movements = DB::table('inventory_crate_movements')
                ->where('note', 'like', '%test%')
                ->orWhere('note', 'like', '%demo%')
                ->orWhere('note', 'like', '%sample%')
                ->pluck('id');

            if ($movements->isNotEmpty()) {
                DB::table('inventory_crate_movement_legs')
                    ->whereIn('movement_id', $movements)->delete();
                DB::table('inventory_crate_movements')
                    ->whereIn('id', $movements)->delete();
                $this->line("  Removed {$movements->count()} test crate movement(s).");
            }

            // --- Test customers (created with obviously fake names) ---------------
            $testCustomers = DB::table('inventory_customers')
                ->where('name', 'like', '%test%')
                ->orWhere('name', 'like', '%demo%')
                ->orWhere('name', 'like', '%sample%')
                ->pluck('id');

            if ($testCustomers->isNotEmpty()) {
                // Detach any sale or crate references first
                DB::table('inventory_crate_movement_legs')
                    ->whereIn('party_id', $testCustomers)->delete();
                DB::table('inventory_crate_movements')
                    ->whereIn('customer_id', $testCustomers)->delete();
                DB::table('inventory_customers')
                    ->whereIn('id', $testCustomers)->delete();
                $this->line("  Removed {$testCustomers->count()} test customer(s).");
            }

            // --- Test sales (sale number starts with TEST- or note contains test) -
            $testSales = DB::table('inventory_sales')
                ->where('number', 'like', 'TEST-%')
                ->pluck('id');

            if ($testSales->isNotEmpty()) {
                DB::table('inventory_sale_items')
                    ->whereIn('sale_id', $testSales)->delete();
                DB::table('inventory_sale_payments')
                    ->whereIn('sale_id', $testSales)->delete();
                DB::table('inventory_sale_returns')
                    ->whereIn('sale_id', $testSales)->delete();
                DB::table('inventory_reminders')
                    ->where('type', 'payment_due')
                    ->whereIn('related_id', $testSales)->delete();
                DB::table('inventory_sales')
                    ->whereIn('id', $testSales)->delete();
                $this->line("  Removed {$testSales->count()} test sale(s).");
            }
        });

        $this->info('Test data purge complete.');
        return self::SUCCESS;
    }
}
