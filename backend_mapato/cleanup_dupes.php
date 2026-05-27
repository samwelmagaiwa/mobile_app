<?php

require __DIR__.'/vendor/autoload.php';
$app = require_once __DIR__.'/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

$ownerId = 'fce95091-4e86-4f7c-a829-a9fc7bbd26c3';

// Get all MABIBO PROJECT properties ordered by created_at desc
$mabiboProps = App\Models\Rental\Property::where('owner_id', $ownerId)
    ->where('name', 'MABIBO PROJECT')
    ->orderBy('created_at', 'desc')
    ->get();

echo "Found " . $mabiboProps->count() . " MABIBO PROJECT entries\n";

// Keep the newest one, delete the rest
$kept = false;
foreach ($mabiboProps as $prop) {
    if (!$kept) {
        echo "KEEPING: {$prop->id} | {$prop->name} | {$prop->created_at}\n";
        $kept = true;
    } else {
        echo "DELETING: {$prop->id} | {$prop->name} | {$prop->created_at}\n";
        $prop->forceDelete();
    }
}

// Show remaining properties
$remaining = App\Models\Rental\Property::where('owner_id', $ownerId)->get();
echo "\nRemaining properties ({$remaining->count()}):\n";
foreach ($remaining as $p) {
    echo "  - {$p->id} | {$p->name} | {$p->created_at}\n";
}
