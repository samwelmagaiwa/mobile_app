# Mwongozo wa Kujaribu Mfumo wa Ripoti (Report System Testing Guide)

## Muhtasari (Overview)

Mfumo wa ripoti umebadilishwa kutoka data za mfano hadi data halisi. Sasa unaweza kutengeneza ripoti za kweli kutoka kwenye hifadhidata.

## Jinsi ya Kujaribu (How to Test)

### 1. Kupitia Dashboard ya Admin (Through Admin Dashboard)

#### Hatua za Kujaribu:

1. **Fungua Dashboard ya Admin**
   ```
   http://localhost:8000/admin/dashboard
   ```

2. **Bofya Kitufe cha "Generate Report"**
   - Kipo katika sehemu ya "Quick Actions"
   - Kitufe kina alama ya faili

3. **Jaza Fomu ya Ripoti**
   - **Aina ya Ripoti**: Chagua kutoka:
     - Ripoti ya Mapato (Revenue Report)
     - Ripoti ya Matumizi (Expense Report)
     - Ripoti ya Faida na Hasara (Profit/Loss Report)
     - Utendaji wa Vifaa (Device Performance)
   
   - **Tarehe ya Mwanzo**: Tarehe ya kuanza (default: siku 30 zilizopita)
   - **Tarehe ya Mwisho**: Tarehe ya mwisho (default: leo)
   - **Kifaa**: Hiari - chagua kifaa maalum au acha tupu kwa vifaa vyote

4. **Bofya "Tengeneza Ripoti"**
   - Utaona ujumbe: "Kipengele cha generate_report kinatengenezwa. Subiri kidogo!"
   - Hii ni ujumbe wa kusubiri wakati ripoti inapotengenezwa

5. **Angalia Matokeo**
   - Baada ya sekunde chache, ripoti itaonyeshwa katika modal mpya
   - Utaona takwimu na jedwali za data halisi

### 2. Kupitia API Moja kwa Moja (Direct API Testing)

#### Endpoints za Majaribio (Test Endpoints):

```bash
# 1. Tengeneza data za majaribio
GET http://localhost:8000/api/test/reports

# 2. Angalia hali ya data za majaribio
GET http://localhost:8000/api/test/reports/status

# 3. Jaribu ripoti ya mapato
GET http://localhost:8000/api/test/reports/revenue?start_date=2025-01-01&end_date=2025-01-27

# 4. Jaribu ripoti ya matumizi
GET http://localhost:8000/api/test/reports/expenses?start_date=2025-01-01&end_date=2025-01-27

# 5. Jaribu ripoti ya faida na hasara
GET http://localhost:8000/api/test/reports/profit-loss?start_date=2025-01-01&end_date=2025-01-27

# 6. Jaribu ripoti ya utendaji wa vifaa
GET http://localhost:8000/api/test/reports/device-performance?start_date=2025-01-01&end_date=2025-01-27

# 7. Futa data za majaribio
POST http://localhost:8000/api/test/reports/cleanup
```

#### Mifano ya Matumizi (Usage Examples):

```bash
# Kwa kutumia curl
curl "http://localhost:8000/api/test/reports/revenue?start_date=2025-01-01&end_date=2025-01-27"

# Kwa kutumia browser
http://localhost:8000/api/test/reports/revenue?start_date=2025-01-01&end_date=2025-01-27
```

### 3. Kujaribu kwa Postman au Insomnia

#### Collection ya Postman:

```json
{
  "info": {
    "name": "Boda Mapato Reports Testing",
    "description": "Test collection for report generation"
  },
  "item": [
    {
      "name": "Generate Test Data",
      "request": {
        "method": "GET",
        "url": "{{base_url}}/api/test/reports"
      }
    },
    {
      "name": "Revenue Report",
      "request": {
        "method": "GET",
        "url": "{{base_url}}/api/test/reports/revenue",
        "query": [
          {"key": "start_date", "value": "2025-01-01"},
          {"key": "end_date", "value": "2025-01-27"},
          {"key": "group_by", "value": "day"}
        ]
      }
    },
    {
      "name": "Expense Report",
      "request": {
        "method": "GET",
        "url": "{{base_url}}/api/test/reports/expenses",
        "query": [
          {"key": "start_date", "value": "2025-01-01"},
          {"key": "end_date", "value": "2025-01-27"}
        ]
      }
    },
    {
      "name": "Profit Loss Report",
      "request": {
        "method": "GET",
        "url": "{{base_url}}/api/test/reports/profit-loss",
        "query": [
          {"key": "start_date", "value": "2025-01-01"},
          {"key": "end_date", "value": "2025-01-27"}
        ]
      }
    },
    {
      "name": "Device Performance Report",
      "request": {
        "method": "GET",
        "url": "{{base_url}}/api/test/reports/device-performance",
        "query": [
          {"key": "start_date", "value": "2025-01-01"},
          {"key": "end_date", "value": "2025-01-27"}
        ]
      }
    },
    {
      "name": "Cleanup Test Data",
      "request": {
        "method": "POST",
        "url": "{{base_url}}/api/test/reports/cleanup"
      }
    }
  ],
  "variable": [
    {
      "key": "base_url",
      "value": "http://localhost:8000"
    }
  ]
}
```

## Matokeo Yanayotarajiwa (Expected Results)

### 1. Ripoti ya Mapato (Revenue Report)

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
      "total_revenue": 1500000.00,
      "transaction_count": 45,
      "average_per_transaction": 33333.33
    },
    "grouped_data": [...],
    "category_breakdown": [...],
    "payment_method_breakdown": [...],
    "device_breakdown": [...]
  }
}
```

### 2. Ripoti ya Matumizi (Expense Report)

```json
{
  "status": "success",
  "message": "Ripoti ya matumizi imetengenezwa kikamilifu",
  "data": {
    "period": {
      "start_date": "2025-01-01",
      "end_date": "2025-01-27"
    },
    "summary": {
      "total_expenses": 450000.00,
      "transaction_count": 20,
      "average_per_transaction": 22500.00
    },
    "category_breakdown": [...],
    "monthly_trend": [...],
    "recent_transactions": [...]
  }
}
```

### 3. Ripoti ya Faida na Hasara (Profit/Loss Report)

```json
{
  "status": "success",
  "message": "Ripoti ya faida na hasara imetengenezwa kikamilifu",
  "data": {
    "period": {
      "start_date": "2025-01-01",
      "end_date": "2025-01-27"
    },
    "summary": {
      "total_income": 1500000.00,
      "total_expenses": 450000.00,
      "net_profit": 1050000.00,
      "profit_margin": 70.00,
      "is_profitable": true
    },
    "monthly_breakdown": [...],
    "device_comparison": [...]
  }
}
```

## Matatizo na Ufumbuzi (Troubleshooting)

### 1. "Imeshindwa kutengeneza ripoti"

**Sababu zinazowezekana:**
- Server haijafunguliwa
- Database haijaundwa
- Makosa ya mtandao

**Ufumbuzi:**
```bash
# Hakikisha server inafanya kazi
php artisan serve

# Angalia hali ya database
php artisan migrate:status

# Jaribu endpoint rahisi
curl http://localhost:8000/api/health
```

### 2. "Data za majaribio hazipo"

**Ufumbuzi:**
```bash
# Tengeneza data za majaribio
curl http://localhost:8000/api/test/reports

# Au kupitia browser
http://localhost:8000/api/test/reports
```

### 3. "Modal haionyeshi"

**Sababu:**
- CSS haijaongezwa
- JavaScript error

**Ufumbuzi:**
- Angalia browser console kwa makosa
- Hakikisha CSS file ipo: `/assets/css/report-modal.css`
- Refresh page

### 4. "CORS Error"

**Ufumbuzi:**
```bash
# Ongeza CORS headers katika config/cors.php
'paths' => ['api/*', 'sanctum/csrf-cookie'],
'allowed_methods' => ['*'],
'allowed_origins' => ['*'],
```

## Maelezo ya Kiteknolojia (Technical Details)

### 1. Mfumo wa Data (Data Flow)

```
Frontend (Dashboard) 
    ↓
JavaScript Function (generateReportFromForm)
    ↓
API Call (fetch)
    ↓
Laravel Route (/api/test/reports/*)
    ↓
TestReportController
    ↓
ReportService
    ↓
Database (Eloquent Models)
    ↓
JSON Response
    ↓
Frontend Display (Modal)
```

### 2. Faili Muhimu (Key Files)

- **Frontend**: `resources/views/admin/dashboard.blade.php`
- **CSS**: `public/assets/css/report-modal.css`
- **Controller**: `app/Http/Controllers/API/TestReportController.php`
- **Service**: `app/Services/ReportService.php`
- **Routes**: `routes/api.php`

### 3. Database Tables

- **users**: Watumiaji wa mfumo
- **drivers**: Profaili za wadereva
- **devices**: Vifaa (bajaji, pikipiki, etc.)
- **transactions**: Miamala (mapato na matumizi)
- **receipts**: Risiti za malipo

## Hatua za Baadaye (Next Steps)

### 1. Kuongeza Authentication

Badilisha endpoints kutoka `/api/test/reports/*` hadi `/api/admin/reports/*` na ongeza authentication:

```javascript
// Katika dashboard.blade.php
const endpoints = {
    'revenue': '/api/admin/reports/revenue',
    'expenses': '/api/admin/reports/expenses',
    'profit_loss': '/api/admin/reports/profit-loss',
    'device_performance': '/api/admin/reports/device-performance'
};

// Ongeza authentication header
headers: {
    'Authorization': 'Bearer ' + getAuthToken(),
    'Content-Type': 'application/json',
    'Accept': 'application/json'
}
```

### 2. Kuongeza PDF Export

Ongeza package ya PDF:

```bash
composer require barryvdh/laravel-dompdf
```

Badilisha `ReportService.php` kurudisha PDF halisi.

### 3. Kuboresha UI/UX

- Ongeza charts na graphs
- Kuboresha responsive design
- Ongeza animations zaidi

### 4. Kuongeza Real-time Updates

- WebSocket connections
- Auto-refresh data
- Live notifications

## Mchango (Contributing)

Kama unataka kuchangia:

1. Fork repository
2. Tengeneza branch mpya
3. Fanya mabadiliko
4. Jaribu mabadiliko
5. Tuma pull request

## Leseni (License)

Mfumo huu unatumia leseni ya MIT.