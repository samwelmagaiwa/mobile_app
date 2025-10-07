<!DOCTYPE html>
<html lang="sw">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{{ $title }}</title>
    <style>
        body {
            font-family: 'DejaVu Sans', sans-serif;
            font-size: 12px;
            line-height: 1.4;
            color: #333;
            margin: 0;
            padding: 20px;
        }
        
        .header {
            text-align: center;
            margin-bottom: 30px;
            border-bottom: 2px solid #007bff;
            padding-bottom: 20px;
        }
        
        .header h1 {
            color: #007bff;
            margin: 0;
            font-size: 24px;
        }
        
        .header .subtitle {
            color: #666;
            margin: 5px 0;
        }
        
        .driver-info {
            background: #f8f9fa;
            padding: 15px;
            border-radius: 5px;
            margin-bottom: 20px;
        }
        
        .driver-info h3 {
            margin: 0 0 10px 0;
            color: #007bff;
        }
        
        .info-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 10px;
        }
        
        .info-item {
            margin-bottom: 5px;
        }
        
        .info-label {
            font-weight: bold;
            color: #555;
        }
        
        .summary-cards {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 15px;
            margin-bottom: 30px;
        }
        
        .summary-card {
            background: #fff;
            border: 1px solid #ddd;
            border-radius: 5px;
            padding: 15px;
            text-align: center;
        }
        
        .summary-card h4 {
            margin: 0 0 10px 0;
            color: #007bff;
            font-size: 14px;
        }
        
        .summary-card .amount {
            font-size: 18px;
            font-weight: bold;
            color: #28a745;
        }
        
        .summary-card .amount.negative {
            color: #dc3545;
        }
        
        .section {
            margin-bottom: 30px;
        }
        
        .section h3 {
            color: #007bff;
            border-bottom: 1px solid #ddd;
            padding-bottom: 5px;
            margin-bottom: 15px;
        }
        
        table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 20px;
        }
        
        table th,
        table td {
            border: 1px solid #ddd;
            padding: 8px;
            text-align: left;
        }
        
        table th {
            background-color: #f8f9fa;
            font-weight: bold;
            color: #555;
        }
        
        table tr:nth-child(even) {
            background-color: #f9f9f9;
        }
        
        .text-right {
            text-align: right;
        }
        
        .text-center {
            text-align: center;
        }
        
        .amount {
            font-weight: bold;
        }
        
        .positive {
            color: #28a745;
        }
        
        .negative {
            color: #dc3545;
        }
        
        .footer {
            margin-top: 40px;
            text-align: center;
            font-size: 10px;
            color: #666;
            border-top: 1px solid #ddd;
            padding-top: 10px;
        }
        
        .page-break {
            page-break-before: always;
        }
        
        @media print {
            body {
                margin: 0;
                padding: 15px;
            }
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>{{ $title }}</h1>
        <div class="subtitle">Mfumo wa Usimamizi wa Mapato ya Boda</div>
        <div class="subtitle">Imetengenezwa: {{ $generated_at }}</div>
    </div>

    <div class="driver-info">
        <h3>Taarifa za Dereva</h3>
        <div class="info-grid">
            <div class="info-item">
                <span class="info-label">Jina:</span> {{ $driver->user->name }}
            </div>
            <div class="info-item">
                <span class="info-label">Simu:</span> {{ $driver->user->phone }}
            </div>
            <div class="info-item">
                <span class="info-label">Nambari ya Leseni:</span> {{ $driver->license_number }}
            </div>
            <div class="info-item">
                <span class="info-label">Muda wa Ripoti:</span> 
                @if(isset($data['period']))
                    {{ $data['period']['start_date'] }} hadi {{ $data['period']['end_date'] }}
                @endif
            </div>
        </div>
    </div>

    @if(isset($data['summary']))
    <div class="section">
        <h3>Muhtasari</h3>
        <div class="summary-cards">
            @if(isset($data['summary']['total_income']))
            <div class="summary-card">
                <h4>Jumla ya Mapato</h4>
                <div class="amount positive">TSh {{ number_format($data['summary']['total_income'], 2) }}</div>
            </div>
            @endif
            
            @if(isset($data['summary']['total_expenses']))
            <div class="summary-card">
                <h4>Jumla ya Matumizi</h4>
                <div class="amount negative">TSh {{ number_format($data['summary']['total_expenses'], 2) }}</div>
            </div>
            @endif
            
            @if(isset($data['summary']['net_profit']))
            <div class="summary-card">
                <h4>Faida Halisi</h4>
                <div class="amount {{ $data['summary']['net_profit'] >= 0 ? 'positive' : 'negative' }}">
                    TSh {{ number_format($data['summary']['net_profit'], 2) }}
                </div>
            </div>
            @endif
            
            @if(isset($data['summary']['total_revenue']))
            <div class="summary-card">
                <h4>Jumla ya Mapato</h4>
                <div class="amount positive">TSh {{ number_format($data['summary']['total_revenue'], 2) }}</div>
            </div>
            @endif
            
            @if(isset($data['summary']['transaction_count']))
            <div class="summary-card">
                <h4>Idadi ya Miamala</h4>
                <div class="amount">{{ number_format($data['summary']['transaction_count']) }}</div>
            </div>
            @endif
        </div>
    </div>
    @endif

    @if(isset($data['category_breakdown']) && count($data['category_breakdown']) > 0)
    <div class="section">
        <h3>Mgawanyo wa Aina</h3>
        <table>
            <thead>
                <tr>
                    <th>Aina</th>
                    <th class="text-right">Kiasi</th>
                    @if(isset($data['category_breakdown'][0]['count']))
                    <th class="text-center">Idadi</th>
                    <th class="text-right">Wastani</th>
                    @endif
                </tr>
            </thead>
            <tbody>
                @foreach($data['category_breakdown'] as $category)
                <tr>
                    <td>{{ $category['category_display'] ?? $category['category'] }}</td>
                    <td class="text-right amount">TSh {{ number_format($category['total'], 2) }}</td>
                    @if(isset($category['count']))
                    <td class="text-center">{{ $category['count'] }}</td>
                    <td class="text-right">TSh {{ number_format($category['average'], 2) }}</td>
                    @endif
                </tr>
                @endforeach
            </tbody>
        </table>
    </div>
    @endif

    @if(isset($data['device_breakdown']) && count($data['device_breakdown']) > 0)
    <div class="section">
        <h3>Utendaji wa Vifaa</h3>
        <table>
            <thead>
                <tr>
                    <th>Kifaa</th>
                    <th>Aina</th>
                    <th class="text-right">Mapato</th>
                    @if(isset($data['device_breakdown'][0]['expenses']))
                    <th class="text-right">Matumizi</th>
                    <th class="text-right">Faida</th>
                    @endif
                </tr>
            </thead>
            <tbody>
                @foreach($data['device_breakdown'] as $device)
                <tr>
                    <td>{{ $device['device_name'] }}</td>
                    <td>{{ $device['device_type'] }}</td>
                    <td class="text-right amount positive">TSh {{ number_format($device['total'] ?? $device['income'], 2) }}</td>
                    @if(isset($device['expenses']))
                    <td class="text-right amount negative">TSh {{ number_format($device['expenses'], 2) }}</td>
                    <td class="text-right amount {{ ($device['net_profit'] ?? 0) >= 0 ? 'positive' : 'negative' }}">
                        TSh {{ number_format($device['net_profit'] ?? 0, 2) }}
                    </td>
                    @endif
                </tr>
                @endforeach
            </tbody>
        </table>
    </div>
    @endif

    @if(isset($data['device_performance']) && count($data['device_performance']) > 0)
    <div class="section">
        <h3>Utendaji wa Vifaa</h3>
        <table>
            <thead>
                <tr>
                    <th>Kifaa</th>
                    <th>Aina</th>
                    <th>Nambari</th>
                    <th class="text-right">Mapato</th>
                    <th class="text-right">Matumizi</th>
                    <th class="text-right">Faida</th>
                    <th class="text-center">Miamala</th>
                </tr>
            </thead>
            <tbody>
                @foreach($data['device_performance'] as $device)
                <tr>
                    <td>{{ $device['device_name'] }}</td>
                    <td>{{ $device['device_type'] }}</td>
                    <td>{{ $device['plate_number'] }}</td>
                    <td class="text-right amount positive">TSh {{ number_format($device['income'], 2) }}</td>
                    <td class="text-right amount negative">TSh {{ number_format($device['expenses'], 2) }}</td>
                    <td class="text-right amount {{ $device['net_profit'] >= 0 ? 'positive' : 'negative' }}">
                        TSh {{ number_format($device['net_profit'], 2) }}
                    </td>
                    <td class="text-center">{{ $device['transaction_count'] }}</td>
                </tr>
                @endforeach
            </tbody>
        </table>
    </div>
    @endif

    @if(isset($data['monthly_breakdown']) && count($data['monthly_breakdown']) > 0)
    <div class="section">
        <h3>Mgawanyo wa Kila Mwezi</h3>
        <table>
            <thead>
                <tr>
                    <th>Mwezi</th>
                    <th class="text-right">Mapato</th>
                    <th class="text-right">Matumizi</th>
                    <th class="text-right">Faida</th>
                    <th class="text-right">Asilimia ya Faida</th>
                </tr>
            </thead>
            <tbody>
                @foreach($data['monthly_breakdown'] as $month)
                <tr>
                    <td>{{ $month['period'] }}</td>
                    <td class="text-right amount positive">TSh {{ number_format($month['income'], 2) }}</td>
                    <td class="text-right amount negative">TSh {{ number_format($month['expenses'], 2) }}</td>
                    <td class="text-right amount {{ $month['profit'] >= 0 ? 'positive' : 'negative' }}">
                        TSh {{ number_format($month['profit'], 2) }}
                    </td>
                    <td class="text-right">{{ number_format($month['margin'], 1) }}%</td>
                </tr>
                @endforeach
            </tbody>
        </table>
    </div>
    @endif

    @if(isset($data['weekly_breakdown']) && count($data['weekly_breakdown']) > 0)
    <div class="section">
        <h3>Mgawanyo wa Kila Wiki</h3>
        <table>
            <thead>
                <tr>
                    <th>Mwanzo wa Wiki</th>
                    <th>Mwisho wa Wiki</th>
                    <th class="text-right">Mapato</th>
                    <th class="text-right">Matumizi</th>
                    <th class="text-right">Faida</th>
                </tr>
            </thead>
            <tbody>
                @foreach($data['weekly_breakdown'] as $week)
                <tr>
                    <td>{{ $week['week_start'] }}</td>
                    <td>{{ $week['week_end'] }}</td>
                    <td class="text-right amount positive">TSh {{ number_format($week['income'], 2) }}</td>
                    <td class="text-right amount negative">TSh {{ number_format($week['expenses'], 2) }}</td>
                    <td class="text-right amount {{ $week['net'] >= 0 ? 'positive' : 'negative' }}">
                        TSh {{ number_format($week['net'], 2) }}
                    </td>
                </tr>
                @endforeach
            </tbody>
        </table>
    </div>
    @endif

    @if(isset($data['daily_breakdown']) && count($data['daily_breakdown']) > 0)
    <div class="section">
        <h3>Mgawanyo wa Kila Siku</h3>
        <table>
            <thead>
                <tr>
                    <th>Tarehe</th>
                    <th>Siku</th>
                    <th class="text-right">Mapato</th>
                    <th class="text-right">Matumizi</th>
                    <th class="text-right">Faida</th>
                </tr>
            </thead>
            <tbody>
                @foreach($data['daily_breakdown'] as $day)
                <tr>
                    <td>{{ $day['date'] }}</td>
                    <td>{{ $day['day_name'] ?? '' }}</td>
                    <td class="text-right amount positive">TSh {{ number_format($day['income'], 2) }}</td>
                    <td class="text-right amount negative">TSh {{ number_format($day['expenses'], 2) }}</td>
                    <td class="text-right amount {{ $day['net'] >= 0 ? 'positive' : 'negative' }}">
                        TSh {{ number_format($day['net'], 2) }}
                    </td>
                </tr>
                @endforeach
            </tbody>
        </table>
    </div>
    @endif

    @if(isset($data['recent_transactions']) && count($data['recent_transactions']) > 0)
    <div class="section">
        <h3>Miamala ya Hivi Karibuni</h3>
        <table>
            <thead>
                <tr>
                    <th>Tarehe</th>
                    <th>Aina</th>
                    <th>Kiasi</th>
                    <th>Kifaa</th>
                    <th>Maelezo</th>
                </tr>
            </thead>
            <tbody>
                @foreach($data['recent_transactions'] as $transaction)
                <tr>
                    <td>{{ $transaction['date'] }}</td>
                    <td>{{ $transaction['category'] }}</td>
                    <td class="text-right amount">TSh {{ number_format($transaction['amount'], 2) }}</td>
                    <td>{{ $transaction['device'] }}</td>
                    <td>{{ $transaction['description'] ?? '-' }}</td>
                </tr>
                @endforeach
            </tbody>
        </table>
    </div>
    @endif

    <div class="footer">
        <p>Ripoti hii imetengenezwa na Mfumo wa Usimamizi wa Mapato ya Boda</p>
        <p>Tarehe ya Kutengeneza: {{ $generated_at }}</p>
    </div>
</body>
</html>