# Analytics API Documentation

## Mobile-Focused Analytics Endpoints

The analytics API provides comprehensive data for the mobile app dashboard, replacing mock data with real database-driven insights.

## Base URL
```
http://192.168.1.5:8000/api/admin/analytics
```

## Endpoints

### 1. Analytics Overview
**GET** `/overview`

Provides comprehensive analytics overview for the mobile dashboard.

**Parameters:**
- `period` (optional): Number of days for analysis (default: 30)

**Response:**
```json
{
  "status": "success",
  "message": "Analytics overview retrieved successfully",
  "data": {
    "overview": {
      "total_revenue": 14351575,
      "total_expenses": 968432,
      "net_profit": 13383143,
      "profit_margin": 93.25,
      "revenue_growth": 0.0,
      "transaction_count": 645,
      "average_transaction_value": 22250.7,
      "active_drivers": 10,
      "active_vehicles": 10,
      "period_days": 30
    },
    "trends": {
      "daily": [
        {
          "date": "2025-09-08",
          "day_name": "Sunday",
          "revenue": 524000,
          "expenses": 75000,
          "profit": 449000,
          "transactions": 8
        }
        // ... more daily data
      ]
    },
    "generated_at": "2025-10-08T19:10:53.000000Z",
    "period_start": "2025-09-08",
    "period_end": "2025-10-08"
  }
}
```

### 2. Top Performers
**GET** `/top-performers`

Returns top performing drivers, vehicles, and revenue breakdown by category.

**Parameters:**
- `period` (optional): Number of days for analysis (default: 30)

**Response:**
```json
{
  "status": "success",
  "message": "Top performers data retrieved successfully",
  "data": {
    "top_drivers": [
      {
        "id": "uuid",
        "name": "James Kato",
        "phone": "+256704567890",
        "revenue": 1829000,
        "trips": 33,
        "average_per_trip": 55454.55,
        "license_number": "DL004567"
      }
      // ... more drivers
    ],
    "top_vehicles": [
      {
        "id": "uuid",
        "name": "Honda CG 125 001",
        "plate_number": "UBH 012D",
        "driver_name": "James Kato",
        "revenue": 1829000,
        "trips": 33,
        "average_per_trip": 55454.55,
        "device_type": "pikipiki"
      }
      // ... more vehicles
    ],
    "revenue_by_category": [
      {
        "category": "daily_payment",
        "category_name": "Malipo ya Kila Siku",
        "total": 5500000,
        "count": 120,
        "percentage": 38.3
      }
      // ... more categories
    ],
    "period_start": "2025-09-08",
    "period_end": "2025-10-08",
    "generated_at": "2025-10-08T19:11:11.000000Z"
  }
}
```

### 3. Live Analytics
**GET** `/live`

Provides real-time analytics for live dashboard updates.

**Response:**
```json
{
  "status": "success",
  "message": "Live analytics retrieved successfully",
  "data": {
    "live_stats": {
      "today_revenue": 574054,
      "today_transactions": 10,
      "week_revenue": 1516730,
      "month_revenue": 3857637,
      "active_drivers_today": 6,
      "active_vehicles_today": 6,
      "average_per_transaction_today": 57405.4
    },
    "recent_transactions": [
      {
        "id": "uuid",
        "amount": 45000,
        "type": "income",
        "category": "daily_payment",
        "category_name": "Malipo ya Kila Siku",
        "driver_name": "John Mukasa",
        "device_name": "Bajaj Boxer 001",
        "date": "2025-10-08T18:30:00.000000Z",
        "formatted_date": "Oct 8, 2025 18:30",
        "payment_method": "mobile_money",
        "reference_number": "TXN20251008001"
      }
      // ... more recent transactions
    ],
    "hourly_revenue": [
      {
        "hour": 0,
        "hour_formatted": "00:00",
        "revenue": 0
      },
      {
        "hour": 6,
        "hour_formatted": "06:00",
        "revenue": 85000
      }
      // ... hourly data for full day
    ],
    "last_updated": "2025-10-08T19:11:27.000000Z"
  }
}
```

### 4. Revenue Trends
**GET** `/trends`

Provides detailed revenue trends with daily breakdown and category analysis.

**Parameters:**
- `start_date` (optional): Start date (YYYY-MM-DD)
- `end_date` (optional): End date (YYYY-MM-DD)

**Response:** Same structure as existing revenue report endpoint.

## Legacy Report Endpoints (Still Available)

### Dashboard Report
**GET** `/api/admin/reports/dashboard`

### Revenue Report
**GET** `/api/admin/reports/revenue`

### Expense Report
**GET** `/api/admin/reports/expenses`

### Profit/Loss Report
**GET** `/api/admin/reports/profit-loss`

### Device Performance Report
**GET** `/api/admin/reports/device-performance`

## Data Features

### Real Data Sources
- **Transactions**: Real transaction data from the database
- **Drivers**: Actual driver profiles with performance metrics
- **Vehicles**: Real device/vehicle data with usage statistics
- **Growth Metrics**: Period-over-period comparison calculations
- **Live Updates**: Current day and real-time statistics

### Mobile Optimization
- **Lightweight Responses**: Optimized data structures for mobile consumption
- **Flexible Periods**: Configurable time periods for analysis
- **Hierarchical Data**: Organized data structure for easy mobile UI integration
- **Performance Metrics**: Pre-calculated averages and percentages

### Sample Data Available
- 10 drivers with realistic profiles
- 10 vehicles (bajaji and pikipiki types)
- 732+ transactions over 60-day period
- Mixed income and expense transactions
- Realistic transaction amounts (20K-80K UGX for income, 5K-30K UGX for expenses)

## Error Handling

All endpoints return consistent error responses:

```json
{
  "status": "error",
  "message": "Error description",
  "data": null
}
```

## Authentication

Currently configured without authentication for testing. In production, these endpoints should be protected with:
- `auth:sanctum` middleware
- `role:admin` middleware

## Performance Notes

- Queries are optimized with appropriate indexes
- Daily trends limited to 30-day periods for performance
- Eager loading used for related data
- Future: Redis caching recommended for production use

## Usage in Flutter

These endpoints are designed to work seamlessly with Flutter HTTP clients:

```dart
// Example usage
final response = await http.get(
  Uri.parse('http://192.168.1.5:8000/api/admin/analytics/overview'),
  headers: {'Content-Type': 'application/json'},
);

final data = jsonDecode(response.body);
if (data['status'] == 'success') {
  final analytics = data['data']['overview'];
  // Use analytics data in UI
}
```