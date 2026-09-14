<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

use App\Models\DriverAgreement;
use App\Models\Payment;
use App\Models\DriverPredictionCache;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;

class DriverPredictionController extends Controller
{
    public function show(string $driverId): JsonResponse
    {
        $agreement = DriverAgreement::query()
            ->where('driver_id', $driverId)
            ->orderByRaw("CASE WHEN status = 'active' THEN 0 ELSE 1 END")
            ->latest('created_at')
            ->first();
        if (!$agreement) {
            return response()->json(['status' => 'error','message' => 'Agreement not found for this driver'], 404);
        }

        $start = $this->parseDate($agreement->start_date);
        $end   = $this->parseDate($agreement->end_date);
        $weekendsCountable = (bool)($agreement->weekends_countable ?? true);
        $satIncluded       = (bool)($agreement->saturday_included ?? true);
        $sunIncluded       = (bool)($agreement->sunday_included ?? true);

        $totalAmount = (float)($agreement->total_amount ?? $agreement->total_profit ?? $agreement->grand_total ?? $agreement->expected_total ?? 0);

        if (!$start) {
            return response()->json(['status' => 'success','data' => [
                'total_paid' => 0,'total_amount' => $totalAmount,'balance' => $totalAmount,
                'days_passed' => 0,'total_days' => $end ? 0 : null,'on_track' => false,
                'predicted_date' => null,'estimated_delay_days' => 0,
                'weekends_countable' => $weekendsCountable,'saturday_included' => $satIncluded,'sunday_included' => $sunIncluded,
                'payment_history' => [],'start_date' => null,'contract_end' => $end?->toDateString(),
            ]]);
        }

        // If we have a fresh cache from today, use it to avoid recomputation
        $cache = DriverPredictionCache::where('driver_id', $driverId)->first();

        $payments = Payment::query()
            ->where('driver_id', $driverId)
            ->whereNotNull('amount')
            ->selectRaw('DATE(paid_at) as d, SUM(amount) as s')
            ->groupBy('d')
            ->orderBy('d')
            ->get();

        $perDay = [];
        foreach ($payments as $p) {
            if (!$p->d) continue; $dt = $this->parseDate($p->d); if (!$dt) continue;
            $perDay[$dt->toDateString()] = (float)($p->s ?? 0);
        }

        $totalPaid = array_sum($perDay);
        $today = Carbon::today();
        $daysPassed = $this->countIncludedDaysInclusive($start, $today, $weekendsCountable, $satIncluded, $sunIncluded);
        $totalDays  = $end ? $this->countIncludedDaysInclusive($start, $end, $weekendsCountable, $satIncluded, $sunIncluded) : null;

        // If cache is fresh for today, use its predicted values; else compute now
        if ($cache && $cache->calculated_at && $cache->calculated_at->isToday()) {
            $payload = [
                'total_paid' => (float)$totalPaid,
                'total_amount' => (float)$totalAmount,
                'balance' => max($totalAmount - $totalPaid, 0),
                'days_passed' => $daysPassed,
                'total_days' => $totalDays,
                'on_track' => (bool)$cache->on_track,
                'predicted_date' => optional($cache->predicted_date)->toDateString(),
                'estimated_delay_days' => (int)$cache->estimated_delay_days,
                'weekends_countable' => $weekendsCountable,
                'saturday_included' => $satIncluded,
                'sunday_included' => $sunIncluded,
                'payment_history' => array_map(fn($d,$s)=>['date'=>$d,'amount'=>(float)$s], array_keys($perDay), array_values($perDay)),
                'start_date' => $start->toDateString(),
                'contract_end' => $end?->toDateString(),
                'model' => $cache->model,
                'r2' => $cache->r2,
                'confidence_days' => null,
            ];
            return response()->json(['status' => 'success','data' => $payload]);
        }

        $pred = $this->predictAuto($start, $end, $totalAmount, $totalPaid, $perDay, $weekendsCountable, $satIncluded, $sunIncluded);

        return response()->json(['status' => 'success','data' => [
            'total_paid' => (float)$totalPaid,
            'total_amount' => (float)$totalAmount,
            'balance' => max($totalAmount - $totalPaid, 0),
            'days_passed' => $daysPassed,
            'total_days' => $totalDays,
            'on_track' => $pred['on_track'],
            'predicted_date' => $pred['predicted_date'],
            'estimated_delay_days' => $pred['estimated_delay_days'],
            'weekends_countable' => $weekendsCountable,
            'saturday_included' => $satIncluded,
            'sunday_included' => $sunIncluded,
            'payment_history' => array_map(fn($d,$s)=>['date'=>$d,'amount'=>(float)$s], array_keys($perDay), array_values($perDay)),
            'start_date' => $start->toDateString(),
            'contract_end' => $end?->toDateString(),
            'model' => $pred['model'],
            'r2' => $pred['r2'], 'confidence_days' => $pred['confidence_days'] ?? null,
        ]]);
    }

    private function predictAuto(Carbon $start, ?Carbon $end, float $totalAmount, float $totalPaid, array $perDay, bool $weekendsCountable, bool $satIncluded, bool $sunIncluded): array
    {
        if ($totalAmount <= 0) return $this->predictAverage($start, $end, $totalAmount, $totalPaid, $weekendsCountable, $satIncluded, $sunIncluded);
        $reg = $this->fitRegression($start, $perDay, $totalAmount, $weekendsCountable, $satIncluded, $sunIncluded);
        if (($reg['valid'] ?? false) && ($reg['a'] ?? 0) > 0 && ($reg['r2'] ?? 0) >= 0.60) {
            return $this->predictionFromIncludedNeeded($reg['need_included_days'], $end, $weekendsCountable, $satIncluded, $sunIncluded, 'regression', $reg['r2']);
        }
        $ewma = $this->computeEwmaDailyRate($perDay, 60, 0.3);
        if ($ewma > 0) {
            $need = (int)ceil(max($totalAmount - $totalPaid, 0) / $ewma);
            return $this->predictionFromIncludedNeeded($need, $end, $weekendsCountable, $satIncluded, $sunIncluded, 'ewma', null);
        }
        return $this->predictAverage($start, $end, $totalAmount, $totalPaid, $weekendsCountable, $satIncluded, $sunIncluded);
    }

    private function predictionFromIncludedNeeded(int $needIncludedDays, ?Carbon $end, bool $weekendsCountable, bool $satIncluded, bool $sunIncluded, string $model, ?float $r2): array
    {
        $needIncludedDays = max(0, min($needIncludedDays, 36500));
        $pd = Carbon::today();
        $added = 0;
        while ($added < $needIncludedDays) { $pd->addDay(); if ($this->isIncluded($pd, $weekendsCountable, $satIncluded, $sunIncluded)) $added++; }
        $onTrack = true; $delay = 0; if ($end) { $onTrack = !$pd->gt($end); $delay = $onTrack ? 0 : $pd->diffInDays($end); }
return ['model'=>$model,'r2'=>$r2,'predicted_date'=>$pd->toDateString(),'on_track'=>$onTrack,'estimated_delay_days'=>$delay,'confidence_days'=>($r2 && $model==='regression') ? max(1, (int)round(($r2>=0.8)?2:3)) : null];
    }

    private function predictAverage(Carbon $start, ?Carbon $end, float $totalAmount, float $totalPaid, bool $weekendsCountable, bool $satIncluded, bool $sunIncluded): array
    {
        $today = Carbon::today();
        $includedDays = $this->countIncludedDaysInclusive($start, $today, $weekendsCountable, $satIncluded, $sunIncluded);
        $rate = $includedDays > 0 ? $totalPaid / $includedDays : 0.0;
        if ($rate <= 0 || $totalAmount <= $totalPaid) {
            return ['model'=>'average','r2'=>null,'predicted_date'=>$today->toDateString(),'on_track'=>$end ? !$today->gt($end) : true,'estimated_delay_days'=>0];
        }
        $remaining = max($totalAmount - $totalPaid, 0);
        $need = (int)ceil($remaining / $rate);
        return $this->predictionFromIncludedNeeded($need, $end, $weekendsCountable, $satIncluded, $sunIncluded, 'average', null);
    }

    private function fitRegression(Carbon $start, array $perDay, float $totalAmount, bool $weekendsCountable, bool $satIncluded, bool $sunIncluded): array
    {
        if (count($perDay) < 2) return ['valid'=>false];
        ksort($perDay);
        $running = 0.0; $xs=[]; $ys=[];
        foreach ($perDay as $date=>$amt) {
            $d = $this->parseDate($date); if(!$d) continue; $running += (float)$amt;
            $xs[] = (float)$this->countIncludedDaysInclusive($start, $d, $weekendsCountable, $satIncluded, $sunIncluded);
            $ys[] = (float)$running;
        }
        $n = count($xs); if ($n < 2) return ['valid'=>false];
        $sumx = array_sum($xs); $sumy = array_sum($ys); $sumxy = 0.0; $sumx2 = 0.0;
        for ($i=0;$i<$n;$i++){ $sumxy += $xs[$i]*$ys[$i]; $sumx2 += $xs[$i]*$xs[$i]; }
        $den = ($n*$sumx2) - ($sumx*$sumx); if (abs($den) < 1e-6) return ['valid'=>false];
        $a = (($n*$sumxy) - ($sumx*$sumy)) / $den; $b = ($sumy/$n) - $a*($sumx/$n);
$yMean = $sumy/$n; $ssTot=0.0; $ssRes=0.0; for ($i=0;$i<$n;$i++){ $yHat = $a*$xs[$i]+$b; $ssRes += ($ys[$i]-$yHat)*($ys[$i]-$yHat); $ssTot += ($ys[$i]-$yMean)*($ys[$i]-$yMean);} $r2 = abs($ssTot)<1e-6?0.0:(1.0-($ssRes/$ssTot)); $sigmaY = $n > 2 ? sqrt(max($ssRes / max($n - 2, 1), 0)) : 0.0;
        if ($a <= 0) return ['valid'=>false,'a'=>$a,'b'=>$b,'r2'=>$r2];
        $xNow = $this->countIncludedDaysInclusive($start, Carbon::today(), $weekendsCountable, $satIncluded, $sunIncluded);
        $xStar = ($totalAmount - $b) / ($a ?: 1e-6); if (!is_finite($xStar)) return ['valid'=>false,'a'=>$a,'b'=>$b,'r2'=>$r2];
$xStarCeil = (int)max($xNow, ceil($xStar)); $needIncludedDays = max(0, $xStarCeil - $xNow); $confDays = $a > 0 ? (int)ceil(max($sigmaY / $a, 0)) : 0; return ['valid'=>true,'a'=>$a,'b'=>$b,'r2'=>$r2,'need_included_days'=>$needIncludedDays,'confidence_days'=>$confDays];
    }

    private function parseDate($v): ?Carbon { if(!$v) return null; if($v instanceof Carbon) return $v->copy()->startOfDay(); try { return Carbon::parse($v)->startOfDay(); } catch (\Throwable) { return null; } }
    private function isIncluded(Carbon $d, bool $weekendsCountable, bool $sat, bool $sun): bool { $wd=(int)$d->dayOfWeekIso; if(!$weekendsCountable) return !($wd===6||$wd===7); if($wd===6&&!$sat) return false; if($wd===7&&!$sun) return false; return true; }
    private function countIncludedDaysInclusive(Carbon $start, Carbon $end, bool $weekendsCountable, bool $sat, bool $sun): int { $s=$start->copy()->startOfDay(); $e=$end->copy()->startOfDay(); if($e->lt($s)) [$s,$e]=[$e,$s]; $count=0; for($d=$s->copy();$d->lte($e);$d->addDay()){ if($this->isIncluded($d,$weekendsCountable,$sat,$sun)) $count++; } return max($count,1); }
}
