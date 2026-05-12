<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Services\Rental\RentalService;

class ProcessRentalBilling extends Command
{
    protected $signature = 'rental:generate-bills';
    protected $description = 'Generate monthly rent bills for active agreements';

    public function handle(RentalService $rentalService)
    {
        $this->info('Starting rental bill generation...');
        $count = $rentalService->generateMonthlyBills();
        $this->info("Successfully generated {$count} new bills.");
    }
}
