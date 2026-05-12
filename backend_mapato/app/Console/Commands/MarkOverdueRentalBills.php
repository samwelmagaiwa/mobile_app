<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Services\Rental\RentalService;

class MarkOverdueRentalBills extends Command
{
    protected $signature = 'rental:mark-overdue';
    protected $description = 'Mark unpaid bills past due date as overdue';

    public function handle(RentalService $rentalService)
    {
        $this->info('Checking for overdue bills...');
        $count = $rentalService->processOverdueBills();
        $this->info("Marked {$count} bills as overdue.");
    }
}
