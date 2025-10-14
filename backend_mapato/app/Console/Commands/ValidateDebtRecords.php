<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Models\DebtRecord;
use App\Models\Payment;

class ValidateDebtRecords extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'debt:validate {--fix : Automatically fix inconsistencies}';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Validate debt records payment_id integrity';

    /**
     * Execute the console command.
     */
    public function handle()
    {
        $this->info('🔍 Validating debt records integrity...');
        
        // Check for inconsistencies
        $inconsistentCount = DebtRecord::where('is_paid', true)
            ->whereNull('payment_id')
            ->count();
            
        $unlinkedPayments = Payment::where('status', 'completed')
            ->whereNotNull('covers_days')
            ->get()
            ->filter(function($payment) {
                return DebtRecord::where('payment_id', $payment->id)->count() == 0;
            })
            ->count();
            
        // Statistics
        $totalPaid = DebtRecord::where('is_paid', true)->count();
        $totalUnpaid = DebtRecord::where('is_paid', false)->count();
        $paidWithPaymentId = DebtRecord::where('is_paid', true)
            ->whereNotNull('payment_id')
            ->count();
            
        $this->info('📊 Statistics:');
        $this->line("  Total paid debt records: {$totalPaid}");
        $this->line("  Total unpaid debt records: {$totalUnpaid}");
        $this->line("  Paid records with payment_id: {$paidWithPaymentId}");
        
        if ($inconsistentCount > 0) {
            $this->error("❌ Found {$inconsistentCount} debt records marked as paid but missing payment_id");
            
            if ($this->option('fix')) {
                $this->warn('🔧 Auto-fix not implemented. Please run the manual fix script.');
            }
            
            return 1;
        }
        
        if ($unlinkedPayments > 0) {
            $this->warn("⚠️  Found {$unlinkedPayments} payments without linked debt records");
            return 1;
        }
        
        $this->info('✅ All debt records have proper payment_id associations!');
        return 0;
    }
}
