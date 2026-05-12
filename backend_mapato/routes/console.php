<?php

use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Schedule;

Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote');

// Nightly prediction job
Schedule::job(new \App\Jobs\PredictDriverCompletionJob())
    ->dailyAt('01:30');

// Rental billing - run on 1st of each month to generate bills
Schedule::command('rental:generate-bills')
    ->monthlyOn(1, '02:00');

// Rental - check for overdue bills daily at 6 AM
Schedule::command('rental:mark-overdue')
    ->dailyAt('06:00');
