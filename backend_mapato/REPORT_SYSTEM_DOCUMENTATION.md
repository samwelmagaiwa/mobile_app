# Mfumo wa Ripoti za Mapato ya Boda (Report System Documentation)

## Muhtasari (Overview)

Mfumo huu umetengenezwa kuongoza na kutengeneza ripoti mbalimbali za mapato, matumizi, na faida kwa wadereva wa boda. Mfumo umebadilishwa kutoka data za mfano (mockup) hadi data halisi kutoka kwenye hifadhidata.

## Vipengele Vipya (New Features)

### 1. ReportService - Huduma ya Ripoti

Faili: `app/Services/ReportService.php`

Huduma hii inashughulikia:
- Kutengeneza ripoti za mapato (Revenue Reports)
- Kutengeneza ripoti za matumizi (Expense Reports) 
- Kutengeneza ripoti za faida na hasara (Profit/Loss Reports)
- Muhtasari wa kila siku/wiki/mwezi (Daily/Weekly/Monthly Summaries)
- Utendaji wa vifaa (Device Performance)
- Kuhamisha ripoti kuwa PDF/HTML

### 2. ReportController - Msimamizi wa Ripoti

Faili: `app/Http/Controllers/API/ReportController.php`

Imeongezwa:
- Uthibitishaji bora wa data (Better validation)
- Ujumbe wa makosa kwa Kiswahili
- Uongozi bora wa makosa (Error handling)
- Urekodi wa makosa (Error logging)

### 3. Mfumo wa Majaribio (Test System)

Faili: `app/Http/Controllers/API/TestReportController.php`

Unaweza:
- Kutengeneza data za majaribio
- Kujaribu ripoti mbalimbali
- Kufuta data za majaribio

## API Endpoints

### Ripoti za Kawaida (Regular Reports)

**Lazima uwe umeingia (Authentication required)**

#### 1. Ripoti ya Mapato (Revenue Report)
```
GET /api/admin/reports/revenue
```

Vigezo (Parameters):
- `start_date` (required): Tarehe ya mwanzo (YYYY-MM-DD)
- `end_date` (required): Tarehe ya mwisho (YYYY-MM-DD)
- `device_id` (optional): ID ya kifaa
- `group_by` (optional): Jinsi ya kugawanya (day/week/month)

#### 2. Ripoti ya Matumizi (Expense Report)
```
GET /api/admin/reports/expenses
```

Vigezo:
- `start_date` (required): Tarehe ya mwanzo
- `end_date` (required): Tarehe ya mwisho
- `device_id` (optional): ID ya kifaa
- `category` (optional): Aina ya gharama

#### 3. Ripoti ya Faida na Hasara (Profit/Loss Report)
```
GET /api/admin/reports/profit-loss
```

Vigezo:
- `start_date` (required): Tarehe ya mwanzo
- `end_date` (required): Tarehe ya mwisho
- `device_id` (optional): ID ya kifaa

#### 4. Muhtasari wa Siku (Daily Summary)
```
GET /api/admin/reports/daily-summary
```

Vigezo:
- `date` (optional): Tarehe (default: leo)

#### 5. Muhtasari wa Wiki (Weekly Summary)
```
GET /api/admin/reports/weekly-summary
```

Vigezo:
- `week_start` (optional): Mwanzo wa wiki

#### 6. Muhtasari wa Mwezi (Monthly Summary)
```
GET /api/admin/reports/monthly-summary
```

Vigezo:
- `month` (optional): Mwezi (1-12)
- `year` (optional): Mwaka

#### 7. Utendaji wa Vifaa (Device Performance)
```
GET /api/admin/reports/device-performance
```

Vigezo:
- `start_date` (required): Tarehe ya mwanzo
- `end_date` (required): Tarehe ya mwisho

#### 8. Dashboard ya Ripoti (Report Dashboard)
```
GET /api/admin/reports/dashboard
```

#### 9. Kuhamisha PDF (Export PDF)
```
POST /api/admin/reports/export-pdf
```

Vigezo:
- `report_type` (required): Aina ya ripoti (revenue/expenses/profit_loss/device_performance)
- `start_date` (required): Tarehe ya mwanzo
- `end_date` (required): Tarehe ya mwisho
- `device_id` (optional): ID ya kifaa

### Majaribio (Testing Endpoints)

**Hakuna uhitaji wa kuingia (No authentication required)**

#### 1. Jaribu Ripoti (Test Reports)
```
GET /api/test/reports
```

Inatengeneza data za mfano na kuonyesha ripoti mbalimbali.

#### 2. Hali ya Data za Majaribio (Test Data Status)
```
GET /api/test/reports/status
```

Inaonyesha kama data za majaribio zipo.

#### 3. Futa Data za Majaribio (Cleanup Test Data)
```
POST /api/test/reports/cleanup
```

Inafuta data zote za majaribio.

## Mfano wa Matumizi (Usage Examples)

### 1. Kupata Ripoti ya Mapato ya Wiki Hii

```bash
curl -X GET "http://localhost:8000/api/admin/reports/revenue" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "start_date": "2025-01-20",
    "end_date": "2025-01-27",
    "group_by": "day"
  }'
```

### 2. Jaribu Mfumo wa Ripoti

```bash
# Tengeneza data za majaribio na uone ripoti
curl -X GET "http://localhost:8000/api/test/reports"

# Angalia hali ya data za majaribio
curl -X GET "http://localhost:8000/api/test/reports/status"

# Futa data za majaribio
curl -X POST "http://localhost:8000/api/test/reports/cleanup"
```

## Muundo wa Data (Data Structure)

### Ripoti ya Mapato (Revenue Report Response)

```json
{
  "status": "success",
  "message": "Ripoti ya mapato imetengenezwa kikamilifu",
  "data": {
    "period": {
      "start_date": "2025-01-01",
      "end_date": "2025-01-27",
      "group_by": "day"
    },
    "summary": {
      "total_revenue": 150000.00,
      "transaction_count": 45,
      "average_per_transaction": 3333.33
    },
    "grouped_data": [
      {
        "period": "2025-01-01",
        "period_display": "01 Jan 2025",
        "total": 5000.00,
        "count": 2
      }
    ],
    "category_breakdown": [
      {
        "category": "daily_payment",
        "category_display": "Malipo ya Kila Siku",
        "total": 80000.00
      }
    ],
    "payment_method_breakdown": [
      {
        "method": "mobile_money",
        "method_display": "Pesa za Simu",
        "total": 120000.00
      }
    ],
    "device_breakdown": [
      {
        "device_id": "uuid",
        "device_name": "Bajaji 001",
        "device_type": "Bajaji",
        "total": 75000.00
      }
    ]
  }
}
```

## Mabadiliko Makuu (Key Changes)

### 1. Kuondoa Data za Mfano (Removed Mockup Data)

**Kabla (Before):**
```php
// Data za mfano zilizokuwa hardcoded
return [
    'total_revenue' => 50000,
    'transactions' => [
        ['amount' => 10000, 'date' => '2025-01-01'],
        // ...
    ]
];
```

**Baada (After):**
```php
// Data halisi kutoka database
$totalRevenue = $driver->incomeTransactions()
    ->whereBetween('transaction_date', [$startDate, $endDate])
    ->sum('amount');
```

### 2. Uongozi Bora wa Makosa (Better Error Handling)

**Kabla:**
```php
catch (\Exception $e) {
    return ResponseHelper::error('Failed to generate report', 500);
}
```

**Baada:**
```php
catch (\Exception $e) {
    \Log::error('Revenue report generation failed', [
        'user_id' => $request->user()->id,
        'error' => $e->getMessage(),
        'trace' => $e->getTraceAsString()
    ]);
    return ResponseHelper::error('Imeshindwa kutengeneza ripoti ya mapato: ' . $e->getMessage(), 500);
}
```

### 3. Ujumbe wa Kiswahili (Swahili Messages)

Ujumbe wote wa mtumiaji umebadilishwa kuwa Kiswahili:
- "Revenue report generated successfully" → "Ripoti ya mapato imetengenezwa kikamilifu"
- "Driver profile not found" → "Profaili ya dereva haijapatikana"

## Maelekezo ya Usakinishaji (Installation Instructions)

### 1. Hakikisha Mfumo Upo (Ensure System is Ready)

```bash
# Ingia kwenye directory ya backend
cd backend_mapato

# Hakikisha database imeundwa
php artisan migrate

# Tengeneza storage links
php artisan storage:link
```

### 2. Jaribu Mfumo (Test the System)

```bash
# Anza server
php artisan serve

# Jaribu endpoint ya majaribio
curl http://localhost:8000/api/test/reports
```

### 3. Ongeza PDF Support (Optional)

Kama unataka kuongeza uwezo wa kutengeneza PDF halisi:

```bash
composer require barryvdh/laravel-dompdf
php artisan vendor:publish --provider="Barryvdh\DomPDF\ServiceProvider"
```

Kisha badilisha `ReportService.php` kurudisha PDF badala ya HTML.

## Matatizo na Ufumbuzi (Troubleshooting)

### 1. "Driver profile not found"

**Tatizo:** Mtumiaji hana profaili ya dereva
**Ufumbuzi:** Hakikisha mtumiaji ana profaili ya dereva iliyoundwa

### 2. "No transactions found"

**Tatizo:** Hakuna miamala kwenye kipindi kilichochaguliwa
**Ufumbuzi:** Tumia endpoint ya majaribio kutengeneza data za mfano

### 3. "Storage directory not found"

**Tatizo:** Directory ya storage haijaundwa
**Ufumbuzi:** 
```bash
php artisan storage:link
mkdir -p storage/app/public/reports
```

## Maendeleo ya Baadaye (Future Enhancements)

1. **PDF Generation**: Ongeza uwezo wa kutengeneza PDF halisi
2. **Email Reports**: Tuma ripoti kwa barua pepe
3. **Scheduled Reports**: Ripoti za otomatiki
4. **Advanced Analytics**: Uchambuzi wa kina zaidi
5. **Mobile Optimization**: Kuboresha kwa simu za mkononi

## Mchango (Contributing)

Kama unataka kuchangia:

1. Fork repository
2. Tengeneza branch mpya
3. Fanya mabadiliko yako
4. Jaribu mabadiliko
5. Tuma pull request

## Leseni (License)

Mfumo huu unatumia leseni ya MIT. Angalia faili ya LICENSE kwa maelezo zaidi.