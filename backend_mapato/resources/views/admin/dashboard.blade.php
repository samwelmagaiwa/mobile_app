@extends('layouts.admin')

@section('title', 'Dashboard')
@section('page-title', 'Dashboard')

@push('styles')
<link rel="stylesheet" href="{{ asset('assets/css/report-modal.css') }}">
@endpush

@section('content')
<!-- Stats Grid -->
<div class="stats-grid">
    <!-- Total Drivers -->
    <div class="stat-card">
        <div class="stat-header">
            <div class="stat-title">Total Drivers</div>
            <div class="stat-icon blue">
                <svg width="24" height="24" fill="currentColor" viewBox="0 0 24 24">
                    <path d="M12 12c2.21 0 4-1.79 4-4s-1.79-4-4-4-4 1.79-4 4 1.79 4 4 4zm0 2c-2.67 0-8 1.34-8 4v2h16v-2c0-2.66-5.33-4-8-4z"/>
                </svg>
            </div>
        </div>
        <div class="stat-value">{{ $stats['total_drivers'] ?? '24' }}</div>
        <div class="stat-change positive">
            <svg class="stat-change-icon" fill="currentColor" viewBox="0 0 24 24">
                <path d="M7 14l5-5 5 5z"/>
            </svg>
            +12% from last month
        </div>
    </div>
    
    <!-- Active Vehicles -->
    <div class="stat-card">
        <div class="stat-header">
            <div class="stat-title">Active Vehicles</div>
            <div class="stat-icon orange">
                <svg width="24" height="24" fill="currentColor" viewBox="0 0 24 24">
                    <path d="M18.92 6.01C18.72 5.42 18.16 5 17.5 5h-11c-.66 0-1.22.42-1.42 1.01L3 12v8c0 .55.45 1 1 1h1c.55 0 1-.45 1-1v-1h12v1c0 .55.45 1 1 1h1c.55 0 1-.45 1-1v-8l-2.08-5.99zM6.5 16c-.83 0-1.5-.67-1.5-1.5S5.67 13 6.5 13s1.5.67 1.5 1.5S7.33 16 6.5 16zm11 0c-.83 0-1.5-.67-1.5-1.5s.67-1.5 1.5-1.5 1.5.67 1.5 1.5-.67 1.5-1.5 1.5zM5 11l1.5-4.5h11L19 11H5z"/>
                </svg>
            </div>
        </div>
        <div class="stat-value">{{ $stats['active_vehicles'] ?? '18' }}</div>
        <div class="stat-change positive">
            <svg class="stat-change-icon" fill="currentColor" viewBox="0 0 24 24">
                <path d="M7 14l5-5 5 5z"/>
            </svg>
            +8% from last month
        </div>
    </div>
    
    <!-- Monthly Revenue -->
    <div class="stat-card">
        <div class="stat-header">
            <div class="stat-title">Monthly Revenue</div>
            <div class="stat-icon green">
                <svg width="24" height="24" fill="currentColor" viewBox="0 0 24 24">
                    <path d="M11.8 10.9c-2.27-.59-3-1.2-3-2.15 0-1.09 1.01-1.85 2.7-1.85 1.78 0 2.44.85 2.5 2.1h2.21c-.07-1.72-1.12-3.3-3.21-3.81V3h-3v2.16c-1.94.42-3.5 1.68-3.5 3.61 0 2.31 1.91 3.46 4.7 4.13 2.5.6 3 1.48 3 2.41 0 .69-.49 1.79-2.7 1.79-2.06 0-2.87-.92-2.98-2.1h-2.2c.12 2.19 1.76 3.42 3.68 3.83V21h3v-2.15c1.95-.37 3.5-1.5 3.5-3.55 0-2.84-2.43-3.81-4.7-4.4z"/>
                </svg>
            </div>
        </div>
        <div class="stat-value">UGX {{ number_format($stats['monthly_revenue'] ?? 2400000) }}</div>
        <div class="stat-change positive">
            <svg class="stat-change-icon" fill="currentColor" viewBox="0 0 24 24">
                <path d="M7 14l5-5 5 5z"/>
            </svg>
            +15% from last month
        </div>
    </div>
    
    <!-- Pending Payments -->
    <div class="stat-card">
        <div class="stat-header">
            <div class="stat-title">Pending Payments</div>
            <div class="stat-icon purple">
                <svg width="24" height="24" fill="currentColor" viewBox="0 0 24 24">
                    <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/>
                </svg>
            </div>
        </div>
        <div class="stat-value">{{ $stats['pending_payments'] ?? '6' }}</div>
        <div class="stat-change negative">
            <svg class="stat-change-icon" fill="currentColor" viewBox="0 0 24 24">
                <path d="M17 10l-5 5-5-5z"/>
            </svg>
            -3% from last month
        </div>
    </div>
</div>

<!-- Content Grid -->
<div class="content-grid">
    <!-- Recent Transactions -->
    <div class="content-card">
        <div class="card-header">
            <h3 class="card-title">Recent Transactions</h3>
            <div class="card-actions">
                <button class="card-btn" onclick="window.location.href='#'">View All</button>
                <button class="card-btn primary" onclick="showAddTransactionModal()">Add New</button>
            </div>
        </div>
        <div class="card-content">
            <div class="table-container">
                <table class="data-table">
                    <thead>
                        <tr>
                            <th>Driver</th>
                            <th>Vehicle</th>
                            <th>Amount</th>
                            <th>Date</th>
                            <th>Status</th>
                            <th>Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                        @forelse($recent_transactions ?? [] as $transaction)
                        <tr>
                            <td>{{ $transaction['driver_name'] }}</td>
                            <td>{{ $transaction['vehicle_number'] }}</td>
                            <td>UGX {{ number_format($transaction['amount']) }}</td>
                            <td>{{ \Carbon\Carbon::parse($transaction['date'])->format('M j, Y') }}</td>
                            <td>
                                <span class="status-badge {{ $transaction['status'] === 'paid' ? 'active' : 'pending' }}">
                                    {{ ucfirst($transaction['status']) }}
                                </span>
                            </td>
                            <td>
                                <button class="btn btn-secondary btn-sm" onclick="viewTransaction('{{ $transaction['id'] }}')">View</button>
                                @if($transaction['status'] === 'pending')
                                <button class="btn btn-success btn-sm" onclick="markAsPaid('{{ $transaction['id'] }}')">Mark Paid</button>
                                @endif
                            </td>
                        </tr>
                        @empty
                        <tr>
                            <td>John Mukasa</td>
                            <td>UBE 123A</td>
                            <td>UGX 50,000</td>
                            <td>Oct 6, 2025</td>
                            <td><span class="status-badge active">Paid</span></td>
                            <td>
                                <button class="btn btn-secondary btn-sm">View</button>
                            </td>
                        </tr>
                        <tr>
                            <td>Peter Ssali</td>
                            <td>UBF 456B</td>
                            <td>UGX 45,000</td>
                            <td>Oct 5, 2025</td>
                            <td><span class="status-badge pending">Pending</span></td>
                            <td>
                                <button class="btn btn-secondary btn-sm">View</button>
                                <button class="btn btn-success btn-sm">Mark Paid</button>
                            </td>
                        </tr>
                        <tr>
                            <td>Mary Nakato</td>
                            <td>UBG 789C</td>
                            <td>UGX 55,000</td>
                            <td>Oct 4, 2025</td>
                            <td><span class="status-badge active">Paid</span></td>
                            <td>
                                <button class="btn btn-secondary btn-sm">View</button>
                            </td>
                        </tr>
                        <tr>
                            <td>James Kato</td>
                            <td>UBH 012D</td>
                            <td>UGX 48,000</td>
                            <td>Oct 3, 2025</td>
                            <td><span class="status-badge active">Paid</span></td>
                            <td>
                                <button class="btn btn-secondary btn-sm">View</button>
                            </td>
                        </tr>
                        <tr>
                            <td>Sarah Nambi</td>
                            <td>UBI 345E</td>
                            <td>UGX 52,000</td>
                            <td>Oct 2, 2025</td>
                            <td><span class="status-badge pending">Pending</span></td>
                            <td>
                                <button class="btn btn-secondary btn-sm">View</button>
                                <button class="btn btn-success btn-sm">Mark Paid</button>
                            </td>
                        </tr>
                        @endforelse
                    </tbody>
                </table>
            </div>
        </div>
    </div>
    
    <!-- Quick Actions & Recent Activity -->
    <div style="display: flex; flex-direction: column; gap: 2rem;">
        <!-- Quick Actions -->
        <div class="content-card">
            <div class="card-header">
                <h3 class="card-title">Quick Actions</h3>
            </div>
            <div class="card-content">
                <div style="display: flex; flex-direction: column; gap: 1rem;">
                    <button class="btn btn-primary" onclick="showAddDriverModal()">
                        <svg width="20" height="20" fill="currentColor" viewBox="0 0 24 24">
                            <path d="M19 13h-6v6h-2v-6H5v-2h6V5h2v6h6v2z"/>
                        </svg>
                        Add New Driver
                    </button>
                    <button class="btn btn-secondary" onclick="showAddVehicleModal()">
                        <svg width="20" height="20" fill="currentColor" viewBox="0 0 24 24">
                            <path d="M18.92 6.01C18.72 5.42 18.16 5 17.5 5h-11c-.66 0-1.22.42-1.42 1.01L3 12v8c0 .55.45 1 1 1h1c.55 0 1-.45 1-1v-1h12v1c0 .55.45 1 1 1h1c.55 0 1-.45 1-1v-8l-2.08-5.99z"/>
                        </svg>
                        Register Vehicle
                    </button>
                    <button class="btn btn-success" onclick="showRecordPaymentModal()">
                        <svg width="20" height="20" fill="currentColor" viewBox="0 0 24 24">
                            <path d="M11.8 10.9c-2.27-.59-3-1.2-3-2.15 0-1.09 1.01-1.85 2.7-1.85 1.78 0 2.44.85 2.5 2.1h2.21c-.07-1.72-1.12-3.3-3.21-3.81V3h-3v2.16c-1.94.42-3.5 1.68-3.5 3.61 0 2.31 1.91 3.46 4.7 4.13 2.5.6 3 1.48 3 2.41 0 .69-.49 1.79-2.7 1.79-2.06 0-2.87-.92-2.98-2.1h-2.2c.12 2.19 1.76 3.42 3.68 3.83V21h3v-2.15c1.95-.37 3.5-1.5 3.5-3.55 0-2.84-2.43-3.81-4.7-4.4z"/>
                        </svg>
                        Record Payment
                    </button>
                    <button class="btn btn-warning" onclick="generateReport()">
                        <svg width="20" height="20" fill="currentColor" viewBox="0 0 24 24">
                            <path d="M14 2H6c-1.1 0-1.99.9-1.99 2L4 20c0 1.1.89 2 2 2h8c1.1 0 2-.9 2-2V8l-6-6zm2 16H8v-2h8v2zm0-4H8v-2h8v2zm-3-5V3.5L18.5 9H13z"/>
                        </svg>
                        Generate Report
                    </button>
                </div>
            </div>
        </div>
        
        <!-- Recent Activity -->
        <div class="content-card">
            <div class="card-header">
                <h3 class="card-title">Recent Activity</h3>
            </div>
            <div class="card-content">
                <div style="display: flex; flex-direction: column; gap: 1rem;">
                    @forelse($recent_activities ?? [] as $activity)
                    <div style="display: flex; align-items: center; gap: 0.75rem; padding: 0.75rem; background: var(--gray-50); border-radius: var(--radius-md);">
                        <div style="width: 8px; height: 8px; background: var(--primary-blue); border-radius: 50%; flex-shrink: 0;"></div>
                        <div style="flex: 1;">
                            <div style="font-weight: 500; font-size: 0.875rem; color: var(--text-primary);">{{ $activity['title'] }}</div>
                            <div style="font-size: 0.75rem; color: var(--text-secondary);">{{ $activity['time'] }}</div>
                        </div>
                    </div>
                    @empty
                    <div style="display: flex; align-items: center; gap: 0.75rem; padding: 0.75rem; background: var(--gray-50); border-radius: var(--radius-md);">
                        <div style="width: 8px; height: 8px; background: var(--primary-blue); border-radius: 50%; flex-shrink: 0;"></div>
                        <div style="flex: 1;">
                            <div style="font-weight: 500; font-size: 0.875rem; color: var(--text-primary);">New driver John Mukasa registered</div>
                            <div style="font-size: 0.75rem; color: var(--text-secondary);">2 hours ago</div>
                        </div>
                    </div>
                    <div style="display: flex; align-items: center; gap: 0.75rem; padding: 0.75rem; background: var(--gray-50); border-radius: var(--radius-md);">
                        <div style="width: 8px; height: 8px; background: var(--secondary-green); border-radius: 50%; flex-shrink: 0;"></div>
                        <div style="flex: 1;">
                            <div style="font-weight: 500; font-size: 0.875rem; color: var(--text-primary);">Payment received from Peter Ssali</div>
                            <div style="font-size: 0.75rem; color: var(--text-secondary);">4 hours ago</div>
                        </div>
                    </div>
                    <div style="display: flex; align-items: center; gap: 0.75rem; padding: 0.75rem; background: var(--gray-50); border-radius: var(--radius-md);">
                        <div style="width: 8px; height: 8px; background: var(--primary-orange); border-radius: 50%; flex-shrink: 0;"></div>
                        <div style="flex: 1;">
                            <div style="font-weight: 500; font-size: 0.875rem; color: var(--text-primary);">Vehicle UBG 789C assigned to Mary Nakato</div>
                            <div style="font-size: 0.75rem; color: var(--text-secondary);">6 hours ago</div>
                        </div>
                    </div>
                    <div style="display: flex; align-items: center; gap: 0.75rem; padding: 0.75rem; background: var(--gray-50); border-radius: var(--radius-md);">
                        <div style="width: 8px; height: 8px; background: var(--secondary-purple); border-radius: 50%; flex-shrink: 0;"></div>
                        <div style="flex: 1;">
                            <div style="font-weight: 500; font-size: 0.875rem; color: var(--text-primary);">Monthly report generated</div>
                            <div style="font-size: 0.75rem; color: var(--text-secondary);">1 day ago</div>
                        </div>
                    </div>
                    @endforelse
                </div>
            </div>
        </div>
    </div>
</div>

<!-- Performance Chart Section -->
<div class="content-card" style="margin-top: 2rem;">
    <div class="card-header">
        <h3 class="card-title">Revenue Performance</h3>
        <div class="card-actions">
            <select class="form-select" style="width: auto; margin-right: 1rem;">
                <option value="7">Last 7 days</option>
                <option value="30" selected>Last 30 days</option>
                <option value="90">Last 90 days</option>
                <option value="365">Last year</option>
            </select>
            <button class="card-btn">Export Data</button>
        </div>
    </div>
    <div class="card-content">
        <div style="height: 300px; display: flex; align-items: center; justify-content: center; background: var(--gray-50); border-radius: var(--radius-lg); color: var(--text-secondary);">
            <div style="text-align: center;">
                <svg width="48" height="48" fill="currentColor" viewBox="0 0 24 24" style="margin-bottom: 1rem; opacity: 0.5;">
                    <path d="M19 3H5c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2zM9 17H7v-7h2v7zm4 0h-2V7h2v10zm4 0h-2v-4h2v4z"/>
                </svg>
                <p>Chart visualization would be integrated here<br><small>Consider using Chart.js or similar library</small></p>
            </div>
        </div>
    </div>
</div>
@endsection

@push('scripts')
<script>
// Dashboard-specific JavaScript functions
function showAddDriverModal() {
    // Implementation for add driver modal
    alert('Add Driver modal would open here');
}

function showAddVehicleModal() {
    // Implementation for add vehicle modal
    alert('Add Vehicle modal would open here');
}

function showRecordPaymentModal() {
    // Implementation for record payment modal
    alert('Record Payment modal would open here');
}

function showAddTransactionModal() {
    // Implementation for add transaction modal
    alert('Add Transaction modal would open here');
}

function generateReport() {
    // Show loading message in Swahili
    showReportModal();
}

function showReportModal() {
    // Create modal for report generation
    const modal = document.createElement('div');
    modal.className = 'modal-overlay';
    modal.innerHTML = `
        <div class="modal-content">
            <div class="modal-header">
                <h3>Tengeneza Ripoti (Generate Report)</h3>
                <button class="modal-close" onclick="closeReportModal()">&times;</button>
            </div>
            <div class="modal-body">
                <form id="reportForm">
                    <div class="form-group">
                        <label for="reportType">Aina ya Ripoti (Report Type):</label>
                        <select id="reportType" name="reportType" class="form-control" required>
                            <option value="">Chagua aina ya ripoti...</option>
                            <option value="revenue">Ripoti ya Mapato (Revenue Report)</option>
                            <option value="expenses">Ripoti ya Matumizi (Expense Report)</option>
                            <option value="profit_loss">Ripoti ya Faida na Hasara (Profit/Loss Report)</option>
                            <option value="device_performance">Utendaji wa Vifaa (Device Performance)</option>
                        </select>
                    </div>
                    <div class="form-group">
                        <label for="startDate">Tarehe ya Mwanzo (Start Date):</label>
                        <input type="date" id="startDate" name="startDate" class="form-control" required>
                    </div>
                    <div class="form-group">
                        <label for="endDate">Tarehe ya Mwisho (End Date):</label>
                        <input type="date" id="endDate" name="endDate" class="form-control" required>
                    </div>
                    <div class="form-group">
                        <label for="deviceId">Kifaa (Device) - Hiari (Optional):</label>
                        <select id="deviceId" name="deviceId" class="form-control">
                            <option value="">Vifaa vyote (All devices)</option>
                            <!-- Device options would be loaded dynamically -->
                        </select>
                    </div>
                </form>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" onclick="closeReportModal()">Ghairi (Cancel)</button>
                <button type="button" class="btn btn-primary" onclick="generateReportFromForm()">Tengeneza Ripoti (Generate Report)</button>
            </div>
        </div>
    `;
    
    // Add modal styles
    modal.style.cssText = `
        position: fixed;
        top: 0;
        left: 0;
        width: 100%;
        height: 100%;
        background: rgba(0, 0, 0, 0.5);
        display: flex;
        align-items: center;
        justify-content: center;
        z-index: 10000;
    `;
    
    document.body.appendChild(modal);
    
    // Set default dates (last 30 days)
    const endDate = new Date();
    const startDate = new Date();
    startDate.setDate(startDate.getDate() - 30);
    
    document.getElementById('startDate').value = startDate.toISOString().split('T')[0];
    document.getElementById('endDate').value = endDate.toISOString().split('T')[0];
    
    // Load devices
    loadDevicesForReport();
}

function closeReportModal() {
    const modal = document.querySelector('.modal-overlay');
    if (modal) {
        modal.remove();
    }
}

function loadDevicesForReport() {
    // This would typically load from an API
    // For now, we'll add some sample options
    const deviceSelect = document.getElementById('deviceId');
    if (deviceSelect) {
        // Add sample devices - in real implementation, this would come from API
        const sampleDevices = [
            { id: '1', name: 'Bajaji 001 - UBE 123A' },
            { id: '2', name: 'Bajaji 002 - UBF 456B' },
            { id: '3', name: 'Pikipiki 001 - UBG 789C' }
        ];
        
        sampleDevices.forEach(device => {
            const option = document.createElement('option');
            option.value = device.id;
            option.textContent = device.name;
            deviceSelect.appendChild(option);
        });
    }
}

function generateReportFromForm() {
    const form = document.getElementById('reportForm');
    const formData = new FormData(form);
    
    const reportData = {
        reportType: formData.get('reportType'),
        startDate: formData.get('startDate'),
        endDate: formData.get('endDate'),
        deviceId: formData.get('deviceId') || null
    };
    
    // Validate form
    if (!reportData.reportType || !reportData.startDate || !reportData.endDate) {
        alert('Tafadhali jaza sehemu zote muhimu (Please fill all required fields)');
        return;
    }
    
    // Show loading state
    const generateBtn = document.querySelector('.modal-footer .btn-primary');
    const originalText = generateBtn.textContent;
    generateBtn.innerHTML = '<span class="loading-spinner"></span> Kipengele cha generate_report kinatengenezwa. Subiri kidogo!';
    generateBtn.disabled = true;
    
    // Call the actual API
    callReportAPI(reportData)
        .then(response => {
            generateBtn.textContent = originalText;
            generateBtn.disabled = false;
            
            if (response.status === 'success') {
                closeReportModal();
                displayReportResults(response.data, reportData.reportType);
                showNotification('Ripoti imetengenezwa kikamilifu! (Report generated successfully!)', 'success');
            } else {
                showNotification('Imeshindwa kutengeneza ripoti: ' + response.message, 'error');
            }
        })
        .catch(error => {
            generateBtn.textContent = originalText;
            generateBtn.disabled = false;
            console.error('Report generation error:', error);
            showNotification('Imeshindwa kutengeneza ripoti. Jaribu tena. (Failed to generate report. Please try again.)', 'error');
        });
}

async function callReportAPI(reportData) {
    // Use test endpoints for now (change to admin endpoints when authentication is ready)
    const endpoints = {
        'revenue': '/api/test/reports/revenue',
        'expenses': '/api/test/reports/expenses',
        'profit_loss': '/api/test/reports/profit-loss',
        'device_performance': '/api/test/reports/device-performance'
    };
    
    const endpoint = endpoints[reportData.reportType];
    if (!endpoint) {
        throw new Error('Invalid report type');
    }
    
    // Prepare request parameters
    const params = new URLSearchParams({
        start_date: reportData.startDate,
        end_date: reportData.endDate
    });
    
    if (reportData.deviceId) {
        params.append('device_id', reportData.deviceId);
    }
    
    if (reportData.reportType === 'revenue') {
        params.append('group_by', 'day');
    }
    
    const response = await fetch(`${endpoint}?${params}`, {
        method: 'GET',
        headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            // Add authentication header if needed
            // 'Authorization': 'Bearer ' + getAuthToken()
        }
    });
    
    if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
    }
    
    return await response.json();
}

function displayReportResults(data, reportType) {
    // Create a new modal to display results
    const modal = document.createElement('div');
    modal.className = 'modal-overlay';
    
    let content = '';
    
    switch (reportType) {
        case 'revenue':
            content = generateRevenueReportHTML(data);
            break;
        case 'expenses':
            content = generateExpenseReportHTML(data);
            break;
        case 'profit_loss':
            content = generateProfitLossReportHTML(data);
            break;
        case 'device_performance':
            content = generateDevicePerformanceReportHTML(data);
            break;
        default:
            content = '<p>Aina ya ripoti haijulikani (Unknown report type)</p>';
    }
    
    modal.innerHTML = `
        <div class="modal-content" style="max-width: 90%; max-height: 90%; overflow-y: auto;">
            <div class="modal-header">
                <h3>Matokeo ya Ripoti (Report Results)</h3>
                <button class="modal-close" onclick="closeResultsModal()">&times;</button>
            </div>
            <div class="modal-body">
                ${content}
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" onclick="closeResultsModal()">Funga (Close)</button>
                <button type="button" class="btn btn-primary" onclick="exportReport()">Hamisha PDF (Export PDF)</button>
            </div>
        </div>
    `;
    
    modal.style.cssText = `
        position: fixed;
        top: 0;
        left: 0;
        width: 100%;
        height: 100%;
        background: rgba(0, 0, 0, 0.5);
        display: flex;
        align-items: center;
        justify-content: center;
        z-index: 10000;
    `;
    
    document.body.appendChild(modal);
}

function generateRevenueReportHTML(data) {
    return `
        <div class="report-summary">
            <h4>Muhtasari wa Mapato (Revenue Summary)</h4>
            <div class="summary-cards">
                <div class="summary-card">
                    <div class="summary-label">Jumla ya Mapato (Total Revenue)</div>
                    <div class="summary-value">TSh ${data.summary?.total_revenue?.toLocaleString() || '0'}</div>
                </div>
                <div class="summary-card">
                    <div class="summary-label">Idadi ya Miamala (Transactions)</div>
                    <div class="summary-value">${data.summary?.transaction_count || '0'}</div>
                </div>
                <div class="summary-card">
                    <div class="summary-label">Wastani kwa Muamala (Average per Transaction)</div>
                    <div class="summary-value">TSh ${data.summary?.average_per_transaction?.toLocaleString() || '0'}</div>
                </div>
            </div>
        </div>
        
        ${data.category_breakdown?.length ? `
            <div class="report-section">
                <h4>Mgawanyo wa Aina (Category Breakdown)</h4>
                <table class="report-table">
                    <thead>
                        <tr>
                            <th>Aina (Category)</th>
                            <th>Kiasi (Amount)</th>
                        </tr>
                    </thead>
                    <tbody>
                        ${data.category_breakdown.map(cat => `
                            <tr>
                                <td>${cat.category_display || cat.category}</td>
                                <td>TSh ${cat.total?.toLocaleString() || '0'}</td>
                            </tr>
                        `).join('')}
                    </tbody>
                </table>
            </div>
        ` : ''}
    `;
}

function generateExpenseReportHTML(data) {
    return `
        <div class="report-summary">
            <h4>Muhtasari wa Matumizi (Expense Summary)</h4>
            <div class="summary-cards">
                <div class="summary-card">
                    <div class="summary-label">Jumla ya Matumizi (Total Expenses)</div>
                    <div class="summary-value">TSh ${data.summary?.total_expenses?.toLocaleString() || '0'}</div>
                </div>
                <div class="summary-card">
                    <div class="summary-label">Idadi ya Miamala (Transactions)</div>
                    <div class="summary-value">${data.summary?.transaction_count || '0'}</div>
                </div>
            </div>
        </div>
        
        ${data.category_breakdown?.length ? `
            <div class="report-section">
                <h4>Mgawanyo wa Aina (Category Breakdown)</h4>
                <table class="report-table">
                    <thead>
                        <tr>
                            <th>Aina (Category)</th>
                            <th>Kiasi (Amount)</th>
                            <th>Idadi (Count)</th>
                            <th>Wastani (Average)</th>
                        </tr>
                    </thead>
                    <tbody>
                        ${data.category_breakdown.map(cat => `
                            <tr>
                                <td>${cat.category_display || cat.category}</td>
                                <td>TSh ${cat.total?.toLocaleString() || '0'}</td>
                                <td>${cat.count || '0'}</td>
                                <td>TSh ${cat.average?.toLocaleString() || '0'}</td>
                            </tr>
                        `).join('')}
                    </tbody>
                </table>
            </div>
        ` : ''}
    `;
}

function generateProfitLossReportHTML(data) {
    return `
        <div class="report-summary">
            <h4>Muhtasari wa Faida na Hasara (Profit/Loss Summary)</h4>
            <div class="summary-cards">
                <div class="summary-card">
                    <div class="summary-label">Jumla ya Mapato (Total Income)</div>
                    <div class="summary-value">TSh ${data.summary?.total_income?.toLocaleString() || '0'}</div>
                </div>
                <div class="summary-card">
                    <div class="summary-label">Jumla ya Matumizi (Total Expenses)</div>
                    <div class="summary-value">TSh ${data.summary?.total_expenses?.toLocaleString() || '0'}</div>
                </div>
                <div class="summary-card">
                    <div class="summary-label">Faida Halisi (Net Profit)</div>
                    <div class="summary-value ${data.summary?.net_profit >= 0 ? 'positive' : 'negative'}">
                        TSh ${data.summary?.net_profit?.toLocaleString() || '0'}
                    </div>
                </div>
                <div class="summary-card">
                    <div class="summary-label">Asilimia ya Faida (Profit Margin)</div>
                    <div class="summary-value">${data.summary?.profit_margin || '0'}%</div>
                </div>
            </div>
        </div>
    `;
}

function generateDevicePerformanceReportHTML(data) {
    return `
        <div class="report-summary">
            <h4>Muhtasari wa Utendaji wa Vifaa (Device Performance Summary)</h4>
            <div class="summary-cards">
                <div class="summary-card">
                    <div class="summary-label">Idadi ya Vifaa (Total Devices)</div>
                    <div class="summary-value">${data.summary?.total_devices || '0'}</div>
                </div>
                <div class="summary-card">
                    <div class="summary-label">Jumla ya Mapato (Total Income)</div>
                    <div class="summary-value">TSh ${data.summary?.total_income?.toLocaleString() || '0'}</div>
                </div>
                <div class="summary-card">
                    <div class="summary-label">Faida Halisi (Net Profit)</div>
                    <div class="summary-value">TSh ${data.summary?.total_net_profit?.toLocaleString() || '0'}</div>
                </div>
            </div>
        </div>
        
        ${data.device_performance?.length ? `
            <div class="report-section">
                <h4>Utendaji wa Kila Kifaa (Individual Device Performance)</h4>
                <table class="report-table">
                    <thead>
                        <tr>
                            <th>Kifaa (Device)</th>
                            <th>Aina (Type)</th>
                            <th>Mapato (Income)</th>
                            <th>Matumizi (Expenses)</th>
                            <th>Faida (Profit)</th>
                            <th>Miamala (Transactions)</th>
                        </tr>
                    </thead>
                    <tbody>
                        ${data.device_performance.map(device => `
                            <tr>
                                <td>${device.device_name}</td>
                                <td>${device.device_type}</td>
                                <td>TSh ${device.income?.toLocaleString() || '0'}</td>
                                <td>TSh ${device.expenses?.toLocaleString() || '0'}</td>
                                <td class="${device.net_profit >= 0 ? 'positive' : 'negative'}">
                                    TSh ${device.net_profit?.toLocaleString() || '0'}
                                </td>
                                <td>${device.transaction_count || '0'}</td>
                            </tr>
                        `).join('')}
                    </tbody>
                </table>
            </div>
        ` : ''}
    `;
}

function closeResultsModal() {
    const modals = document.querySelectorAll('.modal-overlay');
    modals.forEach(modal => modal.remove());
}

function exportReport() {
    // This would call the export API
    showNotification('Uhamishaji wa PDF utaongezwa hivi karibuni (PDF export will be added soon)', 'info');
}

function showNotification(message, type = 'info') {
    // Create notification if it doesn't exist
    let container = document.querySelector('.notification-container');
    if (!container) {
        container = document.createElement('div');
        container.className = 'notification-container';
        container.style.cssText = `
            position: fixed;
            top: 20px;
            right: 20px;
            z-index: 10001;
            display: flex;
            flex-direction: column;
            gap: 10px;
        `;
        document.body.appendChild(container);
    }
    
    const notification = document.createElement('div');
    notification.className = `notification notification-${type}`;
    notification.style.cssText = `
        padding: 12px 16px;
        border-radius: 8px;
        color: white;
        font-weight: 500;
        min-width: 300px;
        max-width: 400px;
        box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
        transform: translateX(100%);
        transition: transform 0.3s ease;
        word-wrap: break-word;
    `;
    
    // Set background color based on type
    const colors = {
        success: '#10b981',
        error: '#ef4444',
        warning: '#f97316',
        info: '#3b82f6'
    };
    notification.style.backgroundColor = colors[type] || colors.info;
    
    notification.textContent = message;
    container.appendChild(notification);
    
    // Animate in
    setTimeout(() => {
        notification.style.transform = 'translateX(0)';
    }, 10);
    
    // Auto remove after 5 seconds
    setTimeout(() => {
        notification.style.transform = 'translateX(100%)';
        setTimeout(() => {
            if (notification.parentNode) {
                notification.parentNode.removeChild(notification);
            }
        }, 300);
    }, 5000);
}

function viewTransaction(id) {
    // Implementation for viewing transaction details
    alert('View transaction ' + id);
}

function markAsPaid(id) {
    // Implementation for marking transaction as paid
    if (confirm('Mark this transaction as paid?')) {
        alert('Transaction ' + id + ' marked as paid');
        // Here you would make an API call to update the transaction status
    }
}

// Auto-refresh dashboard data every 5 minutes
setInterval(function() {
    // Refresh dashboard statistics
    console.log('Refreshing dashboard data...');
    // Implementation would make AJAX calls to update stats
}, 300000); // 5 minutes
</script>
@endpush