# Dashboard API Endpoints

This document describes the new comprehensive dashboard API endpoints for the Boda Mapato application.

## Endpoints

### 1. GET `/api/admin/dashboard-data`

**Description**: Get comprehensive dashboard data including all statistics, charts, and recent transactions.

**Authentication**: Required (Admin role)

**Response Structure**:
```json
{
  "success": true,
  "data": {
    "total_drivers": 12,
    "active_drivers": 10,
    "total_vehicles": 8,
    "active_vehicles": 7,
    "monthly_revenue": 1200000.00,
    "weekly_revenue": 280000.00,
    "daily_revenue": 45000.00,
    "pending_receipts_count": 3,
    "receipts_count": 150,
    "debts_count": 5,
    "total_outstanding_debt": 125000.00,
    "recent_payments": [
      {
        "id": "uuid",
        "reference_number": "PAY-ABC123",
        "driver_name": "John Doe",
        "amount": 15000.00,
        "payment_date": "2024-01-15 14:30:00",
        "payment_channel": "mpesa"
      }
    ],
    "daily_revenue_chart": [
      {
        "date": "2024-01-15",
        "amount": 45000.00,
        "formatted_date": "Jan 15"
      }
    ],
    "monthly_payments_chart": [
      {
        "year": 2024,
        "month": 1,
        "amount": 1200000.00,
        "count": 45,
        "month_name": "Jan 2024"
      }
    ],
    "net_profit": 960000.00,
    "saving_rate": 80.0
  },
  "message": "Dashboard data retrieved successfully"
}
```

### 2. GET `/api/admin/dashboard-stats`

**Description**: Get filtered statistics for custom date ranges.

**Authentication**: Required (Admin role)

**Query Parameters**:
- `start_date` (optional): Start date (YYYY-MM-DD format, defaults to current month start)
- `end_date` (optional): End date (YYYY-MM-DD format, defaults to current date)

**Response Structure**:
```json
{
  "success": true,
  "data": {
    "drivers": {
      "total": 12,
      "active": 10,
      "inactive": 2
    },
    "vehicles": {
      "total": 8,
      "active": 7,
      "inactive": 1
    },
    "payments": {
      "total_amount": 850000.00,
      "count": 32,
      "average": 26562.50
    },
    "debts": {
      "total_amount": 125000.00,
      "count": 5
    },
    "receipts": {
      "generated": 150,
      "pending": 3
    }
  },
  "message": "Statistics retrieved successfully"
}
```

## Features

### Dashboard Data Includes:
1. **Driver & Vehicle Counts**: Total and active counts
2. **Revenue Statistics**: Daily, weekly, and monthly revenue
3. **Receipt Management**: Pending and generated receipt counts
4. **Debt Tracking**: Outstanding debt amounts and counts
5. **Recent Transactions**: Latest 5 completed payments
6. **Chart Data**: 30-day revenue chart and 12-month payment trends
7. **Financial Metrics**: Net profit and saving rate calculations

### Chart Data:
- **Daily Revenue Chart**: Last 30 days with zero-filled missing dates
- **Monthly Payments Chart**: Last 12 months with payment counts and amounts

### Error Handling:
- All endpoints include comprehensive error handling
- Database connection failures are handled gracefully
- Invalid date ranges return appropriate error messages

## Usage Examples

### Get Complete Dashboard Data:
```bash
curl -X GET "http://localhost:8000/api/admin/dashboard-data" \
  -H "Authorization: Bearer {your-token}" \
  -H "Accept: application/json"
```

### Get Custom Date Range Stats:
```bash
curl -X GET "http://localhost:8000/api/admin/dashboard-stats?start_date=2024-01-01&end_date=2024-01-31" \
  -H "Authorization: Bearer {your-token}" \
  -H "Accept: application/json"
```

## Integration Notes

1. **Authentication**: All endpoints require valid authentication token with admin role
2. **Rate Limiting**: Consider implementing rate limiting for dashboard endpoints
3. **Caching**: For better performance, consider caching dashboard data for 5-15 minutes
4. **Database Optimization**: Ensure proper indexing on date columns for optimal query performance

## Models Used

- `Payment`: For revenue and payment statistics
- `Driver`: For driver counts and information
- `Device`: For vehicle/device counts
- `DebtRecord`: For debt tracking
- `PaymentReceipt`: For receipt management

## Performance Considerations

- Uses efficient database queries with proper indexing
- Fills missing dates in charts to ensure consistent UI
- Limits recent transactions to 5 items for performance
- Implements proper aggregation queries for statistics