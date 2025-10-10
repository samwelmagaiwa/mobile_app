<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Driver;
use App\Models\Payment;
use App\Models\DebtRecord;
use Dompdf\Dompdf;
use Dompdf\Options;

class DriverReportController extends Controller
{
    /**
     * Stream a Driver History PDF (payments + debts + summary)
     */
    public function driverHistoryPdf(string $driverId, Request $request)
    {
        try {
            // Accept either drivers.id or users.id; resolve to the canonical driver UUID
            $driver = Driver::where('id', $driverId)
                ->orWhere('user_id', $driverId)
                ->firstOrFail();

            // Normalize to driver.id to avoid mismatches when a user UUID is passed
            $resolvedDriverId = $driver->id;

            // Eager-load relationships used by accessors/templates for consistency and performance
            $driver->loadMissing(['user.assignedDevice']);

            // Query params: sort, date range, compact rendering
            $sort = strtolower((string) $request->query('sort', 'desc')) === 'asc' ? 'asc' : 'desc';
            $startDate = $request->query('start_date');
            $endDate = $request->query('end_date');
            $compact = filter_var($request->query('compact', false), FILTER_VALIDATE_BOOLEAN);
            $customTitle = $request->query('title');
            // Build a descriptive default title including license and plate if available
            $license = $driver->license_number ?? null;
            $plate = $driver->vehicle_number ?? null;
            $type = $driver->vehicle_type ?? null;
            $detailPieces = [];
            if (!empty($license)) { $detailPieces[] = $license; }
            if (!empty($plate)) { $detailPieces[] = $plate . (!empty($type) ? " ({$type})" : ''); }
            $details = implode(' • ', $detailPieces);

            $titleBase = 'Ripoti ya Historia ya Dereva — ' . ($driver->name ?? '');
            if (!empty($details)) { $titleBase .= ' — ' . $details; }

            if (empty($customTitle)) {
                if (!empty($startDate) && !empty($endDate)) {
                    $startFmt = \Carbon\Carbon::parse($startDate)->format('d/m/Y');
                    $endFmt = \Carbon\Carbon::parse($endDate)->format('d/m/Y');
                    $title = $titleBase . " ({$startFmt} - {$endFmt})";
                } else {
                    $title = $titleBase;
                }
            } else {
                $title = (string) $customTitle;
            }

            // Data: Payments
            $paymentsQuery = Payment::byDriver($resolvedDriverId);
            if (!empty($startDate) && !empty($endDate)) {
                $paymentsQuery->dateRange($startDate, $endDate);
            }
            $payments = $paymentsQuery
                ->orderBy('payment_date', $sort)
                ->get();

            // Data: Debts
            $debtsQuery = DebtRecord::byDriver($resolvedDriverId);
            if (!empty($startDate) && !empty($endDate)) {
                $debtsQuery->dateRange($startDate, $endDate);
            }
            $debts = $debtsQuery
                ->orderBy('earning_date', $sort)
                ->get();

            // Summary (full or in-range)
            $summary = (!empty($startDate) && !empty($endDate))
                ? DebtRecord::getSummaryForDriverInRange($resolvedDriverId, $startDate, $endDate)
                : DebtRecord::getSummaryForDriver($resolvedDriverId);

            // Organization and admin info
            $orgName  = config('app.name', 'Boda Mapato');
            $orgUrl   = config('app.url');
            $orgEmail = config('mail.from.address');
            $orgPhone = config('app.phone'); // optional custom config
            $adminName = optional($request->user())->name ?? 'Admin';

            // Logo (public/assets/sam_logo.png)
            $logoPath = public_path('assets/sam_logo.png');
            $logoData = null;
            if (is_file($logoPath)) {
                $mime = 'image/png';
                $logoData = 'data:' . $mime . ';base64,' . base64_encode(file_get_contents($logoPath));
            }

            $data = [
                'driver' => $driver,
                'payments' => $payments,
                'debts' => $debts,
                'summary' => $summary,
                'generated_at' => now(),
                'org_name' => $orgName,
                'org_url' => $orgUrl,
                'org_email' => $orgEmail,
                'org_phone' => $orgPhone,
                'admin_name' => $adminName,
                'logo_data' => $logoData,
                'filters' => [
                    'start_date' => $startDate,
                    'end_date' => $endDate,
                    'sort' => $sort,
                    'compact' => $compact,
                ],
                'compact' => $compact,
                'title' => $title,
            ];

            // Render Blade to HTML
            $html = view('reports.driver_history', $data)->render();

            // Configure Dompdf
            $options = new Options();
            $options->set('isRemoteEnabled', true);
            $options->set('defaultFont', 'DejaVu Sans'); // Unicode support

            $dompdf = new Dompdf($options);
            $dompdf->loadHtml($html, 'UTF-8');
            $dompdf->setPaper('A4', 'portrait');
            $dompdf->render();

            // Build a clean filename from the title (ASCII-safe, underscores, no special chars)
            $safeTitle = preg_replace('/[^A-Za-z0-9\-_. ]+/', '', $title);
            $safeTitle = trim(preg_replace('/\s+/', '_', $safeTitle), '_');
            if (empty($safeTitle)) {
                $safeTitle = 'Ripoti_ya_Historia_ya_Dereva';
            }
            $filename = $safeTitle . '_' . now()->format('Ymd_His') . '.pdf';

            return response($dompdf->output(), 200)
                ->header('Content-Type', 'application/pdf')
                ->header('Content-Disposition', 'inline; filename="'.$filename.'"');
        } catch (\Throwable $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to generate driver history PDF',
                'error' => $e->getMessage(),
            ], 500);
        }
    }
}
