<!DOCTYPE html>
<html lang="sw">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Ripoti ya Historia ya Dereva</title>
  <style>
    :root { --primary-blue:#1d4ed8; --dark-blue:#0b3b7a; --orange:#f97316; --text:#0f172a; --muted:#6b7280; --border:#e5e7eb; --bg:#ffffff; --bg-soft:#f8fafc; --green:#16a34a; --red:#dc2626; --amber:#d97706; }
    * { box-sizing: border-box; }
    body { font-family: DejaVu Sans, sans-serif; color: var(--text); background: var(--bg); }

    /* Brand header */
    .brand-header { background: linear-gradient(90deg, var(--dark-blue), var(--primary-blue)); color:#fff; border-radius:10px; padding:14px 16px; margin-bottom:10px; border:1px solid rgba(255,255,255,.15); display:flex; align-items:center; justify-content:space-between; }
    .brand-left { display:flex; align-items:center; gap:10px; }
    .brand-logo { height:32px; width:auto; border-radius:6px; background:#ffffff20; padding:4px; }
    .brand-title { font-size:18px; font-weight:800; margin:0; letter-spacing:.3px; }
    .brand-meta { font-size:12px; opacity:.95; margin-top:3px; }
    .orange-keyline { height:4px; background: var(--orange); border-radius:12px; margin-top:8px; }

    /* Info grid */
    .info-grid { width:100%; border-collapse:collapse; margin-top:10px; }
    .info-grid td { padding:6px 8px; font-size:12px; border:1px solid var(--border); }
    .info-grid tr:nth-child(odd) td { background:#fafafa; }

    /* Summary cards */
    .cards { margin-top:8px; }
    .card { display:inline-block; width:24%; background:var(--bg-soft); border:1px solid var(--border); border-radius:8px; padding:8px; margin-right:6px; }
    .card .label { font-size:10px; color:var(--muted); }
    .card .value { font-size:13px; font-weight:700; }

    /* Tables */
    table { width:100%; border-collapse:collapse; }
    th, td { border:1px solid var(--border); padding:6px 8px; font-size:12px; }
    th { background:#eef2ff; color:#111827; text-align:left; }
    tbody tr:nth-child(even) td { background:#f9fafb; }
    thead { display: table-header-group; }
    tfoot { display: table-row-group; }
    tr { page-break-inside: avoid; }
    td { word-wrap: break-word; }

    .section-title { font-size:14px; font-weight:700; color:#0a1a2b; margin:12px 0 6px; }

    .footer { border-top:2px solid var(--border); margin-top:16px; padding-top:8px; font-size:10px; color:var(--muted); text-align:center; }

    /* Compact mode for dense reports */
    body.compact { font-size: 11px; }
    body.compact .brand-title { font-size: 16px; }
    body.compact th, body.compact td { padding: 4px 6px; font-size: 11px; }
    body.compact .card { padding: 6px; }
  </style>
</head>
<body class="{{ !empty($compact) && $compact ? 'compact' : '' }}">
  <!-- Brand Header -->
  <div class="brand-header">
    <div class="brand-left">
      @if(!empty($logo_data))
        <img class="brand-logo" src="{{ $logo_data }}" alt="logo" />
      @endif
      <div class="brand-text">
        <div class="brand-title">{{ $org_name ?? 'Boda Mapato' }} • {{ $title ?? 'Ripoti ya Historia ya Dereva' }}</div>
        <div class="brand-meta">
          Dereva: {{ $driver->name }}
          @php($lic = $driver->license_number ?? null)
          @php($plt = $driver->vehicle_number ?? null)
          @php($typ = $driver->vehicle_type ?? null)
          @if($lic) • Leseni: {{ $lic }} @endif
          @if($plt) • Gari: {{ $plt }}@if($typ) ({{ $typ }})@endif @endif
          • Imetengenezwa: {{ $generated_at->format('d/m/Y H:i') }}
        </div>
      </div>
    </div>
    
  </div>
  <div class="orange-keyline"></div>

  @if(!empty($filters['start_date']) && !empty($filters['end_date']))
    <div style="margin:6px 0 10px 0; font-size:12px; color:#334155;">
      Kipindi: {{ \Carbon\Carbon::parse($filters['start_date'])->format('d/m/Y') }} - {{ \Carbon\Carbon::parse($filters['end_date'])->format('d/m/Y') }}
    </div>
  @endif

  <!-- Driver Profile Card -->
  @php
    $driverName = $driver->name;
    $initial = strtoupper(mb_substr($driverName ?? 'D', 0, 1));
    $phone = $driver->phone ?? ($driver->user->phone_number ?? 'N/A');
    $email = $driver->user->email ?? null;
    $joined = optional($driver->user->created_at)->format('d/m/Y');
    $statusActive = (bool)($driver->is_active ?? $driver->user->is_active ?? true);
    $ratingValue = $driver->rating ?? null;
    $trips = $driver->total_trips ?? null;
  @endphp

  <div style="background:#f8fafc;border:1px solid var(--border);border-radius:12px;padding:12px;display:flex;align-items:center;gap:14px;margin-bottom:12px;">
    <!-- Avatar -->
    <div style="width:48px;height:48px;border-radius:999px;background:#e2e8f0;color:#0a1a2b;display:flex;align-items:center;justify-content:center;font-weight:800;font-size:18px;">
      {{ $initial }}
    </div>

    <!-- Contact + Chips -->
    <div style="flex:1;">
      <div style="font-size:12px;color:#0a1a2b;">Simu: <strong>{{ $phone }}</strong></div>
      @if($email)
        <div style="font-size:12px;color:#0a1a2b;">Barua pepe: <strong>{{ $email }}</strong></div>
      @endif

      <div style="display:flex;flex-wrap:wrap;gap:8px;margin-top:8px;">
        <div class="chip" style="border-color:#a7b0d8;background:#eef2ff;">
          <div class="label">Leseni</div><div class="value">{{ $driver->license_number ?? 'Hakuna' }}</div>
        </div>
        <div class="chip" style="border-color:#a7b0d8;background:#eef2ff;">
          <div class="label">Gari</div><div class="value">{{ $driver->vehicle_number ?? 'Hakuna' }} @if($driver->vehicle_type) ({{ $driver->vehicle_type }}) @endif</div>
        </div>
        <div class="chip" style="border-color:#a7b0d8;background:#eef2ff;">
          <div class="label">Aliungana</div><div class="value">{{ $joined ?? '-' }}</div>
        </div>
        <div class="chip" style="border-color:#fde68a;background:#fff7ed;">
          <div class="label">Kiwango</div><div class="value">{{ $ratingValue !== null ? number_format($ratingValue,1) : '-' }}</div>
        </div>
        <div class="chip" style="border-color:#bae6fd;background:#ecfeff;">
          <div class="label">Safari</div><div class="value">{{ $trips !== null ? number_format($trips) : '-' }}</div>
        </div>
        <div class="chip" style="border-color:{{ $statusActive ? '#86efac' : '#fecaca' }};background:{{ $statusActive ? '#d1fae5' : '#fee2e2' }};">
          <div class="label">Hali</div>
          <div class="value" style="color:{{ $statusActive ? '#065f46' : '#991b1b' }};font-weight:800;">{{ $statusActive ? 'Hai' : 'Si Hai' }}</div>
        </div>
      </div>
    </div>
  </div>

  <!-- Financial Summary Cards -->
  @php
    $records = collect($summary['debt_records'] ?? []);
    $totalExpected = (float) $records->sum('expected_amount');
    $totalPaid = (float) $records->sum('paid_amount');
    $totalDebt = (float) ($summary['total_debt'] ?? 0);
    $unpaidDays = (int)($summary['unpaid_days'] ?? 0);
    $overdueDays = (int)($summary['overdue_days'] ?? 0);
    $avgOverdue = (int) round(($records->count() ? ($records->sum('days_overdue') / max(1,$records->count())) : 0));
    $rating = $overdueDays > 10 || ($totalDebt > 0 && $unpaidDays > 15) ? 'Late' : ($overdueDays > 0 || $totalDebt > 0 ? 'Inconsistent' : 'Consistent');
  @endphp

  <div style="background:#fff7ed;border:1px solid #fdba74;border-radius:12px;padding:12px;margin:10px 0;">
    <div style="font-weight:800;color:#9a3412;margin-bottom:8px;">Muhtasari wa Kifedha</div>
    <div class="cards" style="margin-top:0;">
      <div class="card"><div class="label">Jumla Iliyorekodiwa</div><div class="value" style="color:var(--primary-blue)">TSh {{ number_format($totalExpected,0) }}</div></div>
      <div class="card"><div class="label">Jumla ya Madeni</div><div class="value" style="color:#ea580c">TSh {{ number_format($totalDebt + 0,0) }}</div></div>
      <div class="card"><div class="label">Deni Linalosalia</div><div class="value" style="color:#dc2626">TSh {{ number_format($totalDebt,0) }}</div></div>
      <div class="card"><div class="label">Jumla Alizolipa</div><div class="value" style="color:var(--green)">TSh {{ number_format($totalPaid,0) }}</div></div>
    </div>
    <div class="cards" style="margin-top:8px;">
      <div class="card"><div class="label">Wastani wa kuchelewa</div><div class="value" style="color:#0a1a2b">{{ $avgOverdue }} siku</div></div>
      <div class="card"><div class="label">Siku zisizolipwa</div><div class="value" style="color:#0a1a2b">{{ $unpaidDays }}</div></div>
      <div class="card"><div class="label">Siku zilizochelewa</div><div class="value" style="color:#0a1a2b">{{ $overdueDays }}</div></div>
      <div class="card"><div class="label">Kiwango cha ulipaji</div>
        <div class="value">
          @if($rating === 'Consistent')<span style="color:var(--green)">Consistent</span>
          @elseif($rating === 'Late')<span style="color:var(--red)">Late</span>
          @else <span style="color:var(--amber)">Inconsistent</span> @endif
        </div>
      </div>
    </div>
  </div>

  @if(count($payments))
    <div class="section-title" style="color:#166534">Historia ya Malipo</div>
    <table>
      <thead><tr><th style="width:22%">Tarehe</th><th style="width:28%">Kiasi (TSh)</th><th style="width:25%">Njia</th><th style="width:25%">Rejea</th></tr></thead>
      <tbody>
        @foreach($payments as $p)
          <tr>
            <td>{{ optional($p->payment_date)->format('d/m/Y') }}</td>
            <td><strong>{{ number_format((float)$p->amount,0) }}</strong></td>
            <td>{{ $p->formatted_payment_channel ?? $p->payment_channel }}</td>
            <td>{{ $p->reference_number ?? '-' }}</td>
          </tr>
        @endforeach
      </tbody>
      <tfoot>
        <tr>
          <th>Jumla</th>
          <th><strong>{{ number_format((float)($payments->sum('amount') ?? 0),0) }}</strong></th>
          <th></th>
          <th></th>
        </tr>
      </tfoot>
    </table>
  @else
    <div class="section-title" style="color:#166534">Historia ya Malipo</div>
    <div style="font-size:12px;color:#475569;margin:4px 0 8px;">Hakuna malipo yaliyopatikana</div>
  @endif

  @if(count($debts))
    <div class="section-title" style="color:#991b1b">Historia ya Madeni</div>
    <table>
      <thead><tr><th style="width:25%">Tarehe</th><th style="width:30%">Inayotarajiwa (TSh)</th><th style="width:20%">Aliyolipa (TSh)</th><th style="width:25%">Hali</th></tr></thead>
      <tbody>
        @foreach($debts as $d)
          <tr>
            <td>{{ optional($d->earning_date)->format('d/m/Y') }}</td>
            <td><strong>{{ number_format((float)$d->expected_amount,0) }}</strong></td>
            <td>{{ number_format((float)($d->paid_amount ?? 0),0) }}</td>
            <td>
              @if($d->is_paid)
                <span style="background:#dcfce7;color:#065f46;border:1px solid #86efac;border-radius:999px;padding:2px 8px;font-weight:700;">Imelipwa</span>
              @elseif($d->is_overdue)
                <span style="background:#fff7ed;color:#9a3412;border:1px solid #fdba74;border-radius:999px;padding:2px 8px;font-weight:700;">Imechelewa</span>
              @else
                <span style="background:#fef9c3;color:#854d0e;border:1px solid #fde68a;border-radius:999px;padding:2px 8px;font-weight:700;">Haijalipwa</span>
              @endif
            </td>
          </tr>
        @endforeach
      </tbody>
      <tfoot>
        <tr>
          <th>Jumla</th>
          <th><strong>{{ number_format((float)($debts->sum('expected_amount') ?? 0),0) }}</strong></th>
          <th>{{ number_format((float)($debts->sum('paid_amount') ?? 0),0) }}</th>
          <th></th>
        </tr>
      </tfoot>
    </table>
  @endif

  <div class="footer">
    {{ $org_name ?? 'Boda Mapato' }} • Toleo la Ripoti: {{ $generated_at->format('d/m/Y H:i') }}
  </div>

  <script type="text/php">
    if (isset($pdf)) {
      $font = $fontMetrics->getFont('DejaVu Sans', 'normal');
      $pdf->page_text(520, 820, 'Uk. {PAGE_NUM}/{PAGE_COUNT}', $font, 9, [0.38,0.41,0.46]);
    }
  </script>
</body>
</html>

