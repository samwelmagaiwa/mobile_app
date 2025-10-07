// Admin Dashboard JavaScript - Boda Mapato
class AdminDashboard {
    constructor() {
        this.sidebar = document.querySelector('.sidebar');
        this.sidebarToggle = document.querySelector('.sidebar-toggle');
        this.sidebarOverlay = document.querySelector('.sidebar-overlay');
        this.mainContent = document.querySelector('.main-content');
        
        this.init();
    }
    
    init() {
        this.setupEventListeners();
        this.setupResponsive();
        this.loadDashboardData();
        this.setupNotifications();
        this.setupSearch();
    }
    
    setupEventListeners() {
        // Sidebar toggle
        if (this.sidebarToggle) {
            this.sidebarToggle.addEventListener('click', () => {
                this.toggleSidebar();
            });
        }
        
        // Sidebar overlay click (mobile)
        if (this.sidebarOverlay) {
            this.sidebarOverlay.addEventListener('click', () => {
                this.closeSidebar();
            });
        }
        
        // Navigation links
        const navLinks = document.querySelectorAll('.nav-link');
        navLinks.forEach(link => {
            link.addEventListener('click', (e) => {
                this.handleNavigation(e, link);
            });
        });
        
        // User menu dropdown
        const userMenu = document.querySelector('.user-menu');
        if (userMenu) {
            userMenu.addEventListener('click', () => {
                this.toggleUserMenu();
            });
        }
        
        // Card action buttons
        const cardBtns = document.querySelectorAll('.card-btn');
        cardBtns.forEach(btn => {
            btn.addEventListener('click', (e) => {
                this.handleCardAction(e, btn);
            });
        });
        
        // Form submissions
        const forms = document.querySelectorAll('form');
        forms.forEach(form => {
            form.addEventListener('submit', (e) => {
                this.handleFormSubmit(e, form);
            });
        });
        
        // Keyboard shortcuts
        document.addEventListener('keydown', (e) => {
            this.handleKeyboardShortcuts(e);
        });
    }
    
    setupResponsive() {
        // Handle window resize
        window.addEventListener('resize', () => {
            this.handleResize();
        });
        
        // Initial responsive setup
        this.handleResize();
    }
    
    handleResize() {
        const isMobile = window.innerWidth < 1024;
        
        if (isMobile) {
            this.sidebar?.classList.add('mobile-hidden');
            this.sidebar?.classList.remove('collapsed');
        } else {
            this.sidebar?.classList.remove('mobile-hidden');
            this.sidebarOverlay?.classList.remove('active');
        }
    }
    
    toggleSidebar() {
        const isMobile = window.innerWidth < 1024;
        
        if (isMobile) {
            // Mobile: Show/hide sidebar with overlay
            this.sidebar?.classList.toggle('mobile-hidden');
            this.sidebarOverlay?.classList.toggle('active');
        } else {
            // Desktop: Collapse/expand sidebar
            this.sidebar?.classList.toggle('collapsed');
        }
    }
    
    closeSidebar() {
        this.sidebar?.classList.add('mobile-hidden');
        this.sidebarOverlay?.classList.remove('active');
    }
    
    handleNavigation(e, link) {
        // Remove active class from all nav links
        document.querySelectorAll('.nav-link').forEach(l => {
            l.classList.remove('active');
        });
        
        // Add active class to clicked link
        link.classList.add('active');
        
        // Get the target page
        const target = link.getAttribute('data-page');
        
        if (target) {
            e.preventDefault();
            this.loadPage(target);
        }
        
        // Close sidebar on mobile after navigation
        if (window.innerWidth < 1024) {
            this.closeSidebar();
        }
    }
    
    loadPage(page) {
        // Show loading state
        this.showLoading();
        
        // Simulate page loading (replace with actual API calls)
        setTimeout(() => {
            this.hideLoading();
            this.updatePageContent(page);
            this.updatePageTitle(page);
        }, 500);
    }
    
    updatePageContent(page) {
        const content = this.getPageContent(page);
        const dashboardContent = document.querySelector('.dashboard-content');
        
        if (dashboardContent) {
            dashboardContent.innerHTML = content;
            dashboardContent.classList.add('fade-in');
            
            // Re-setup event listeners for new content
            this.setupDynamicEventListeners();
        }
    }
    
    updatePageTitle(page) {
        const pageTitle = document.querySelector('.page-title');
        const titles = {
            'dashboard': 'Dashboard',
            'drivers': 'Driver Management',
            'vehicles': 'Vehicle Management',
            'payments': 'Payment Management',
            'receipts': 'Receipt Management',
            'reports': 'Reports & Analytics',
            'settings': 'Settings'
        };
        
        if (pageTitle && titles[page]) {
            pageTitle.textContent = titles[page];
        }
    }
    
    getPageContent(page) {
        // This would typically fetch content from the server
        // For now, return placeholder content
        const contents = {
            'dashboard': this.getDashboardContent(),
            'drivers': this.getDriversContent(),
            'vehicles': this.getVehiclesContent(),
            'payments': this.getPaymentsContent(),
            'receipts': this.getReceiptsContent(),
            'reports': this.getReportsContent(),
            'settings': this.getSettingsContent()
        };
        
        return contents[page] || contents['dashboard'];
    }
    
    getDashboardContent() {
        return `
            <div class="stats-grid">
                <div class="stat-card">
                    <div class="stat-header">
                        <div class="stat-title">Total Drivers</div>
                        <div class="stat-icon blue">
                            <svg width="24" height="24" fill="currentColor" viewBox="0 0 24 24">
                                <path d="M12 12c2.21 0 4-1.79 4-4s-1.79-4-4-4-4 1.79-4 4 1.79 4 4 4zm0 2c-2.67 0-8 1.34-8 4v2h16v-2c0-2.66-5.33-4-8-4z"/>
                            </svg>
                        </div>
                    </div>
                    <div class="stat-value">24</div>
                    <div class="stat-change positive">
                        <svg class="stat-change-icon" fill="currentColor" viewBox="0 0 24 24">
                            <path d="M7 14l5-5 5 5z"/>
                        </svg>
                        +12% from last month
                    </div>
                </div>
                
                <div class="stat-card">
                    <div class="stat-header">
                        <div class="stat-title">Active Vehicles</div>
                        <div class="stat-icon orange">
                            <svg width="24" height="24" fill="currentColor" viewBox="0 0 24 24">
                                <path d="M18.92 6.01C18.72 5.42 18.16 5 17.5 5h-11c-.66 0-1.22.42-1.42 1.01L3 12v8c0 .55.45 1 1 1h1c.55 0 1-.45 1-1v-1h12v1c0 .55.45 1 1 1h1c.55 0 1-.45 1-1v-8l-2.08-5.99zM6.5 16c-.83 0-1.5-.67-1.5-1.5S5.67 13 6.5 13s1.5.67 1.5 1.5S7.33 16 6.5 16zm11 0c-.83 0-1.5-.67-1.5-1.5s.67-1.5 1.5-1.5 1.5.67 1.5 1.5-.67 1.5-1.5 1.5zM5 11l1.5-4.5h11L19 11H5z"/>
                            </svg>
                        </div>
                    </div>
                    <div class="stat-value">18</div>
                    <div class="stat-change positive">
                        <svg class="stat-change-icon" fill="currentColor" viewBox="0 0 24 24">
                            <path d="M7 14l5-5 5 5z"/>
                        </svg>
                        +8% from last month
                    </div>
                </div>
                
                <div class="stat-card">
                    <div class="stat-header">
                        <div class="stat-title">Monthly Revenue</div>
                        <div class="stat-icon green">
                            <svg width="24" height="24" fill="currentColor" viewBox="0 0 24 24">
                                <path d="M11.8 10.9c-2.27-.59-3-1.2-3-2.15 0-1.09 1.01-1.85 2.7-1.85 1.78 0 2.44.85 2.5 2.1h2.21c-.07-1.72-1.12-3.3-3.21-3.81V3h-3v2.16c-1.94.42-3.5 1.68-3.5 3.61 0 2.31 1.91 3.46 4.7 4.13 2.5.6 3 1.48 3 2.41 0 .69-.49 1.79-2.7 1.79-2.06 0-2.87-.92-2.98-2.1h-2.2c.12 2.19 1.76 3.42 3.68 3.83V21h3v-2.15c1.95-.37 3.5-1.5 3.5-3.55 0-2.84-2.43-3.81-4.7-4.4z"/>
                            </svg>
                        </div>
                    </div>
                    <div class="stat-value">UGX 2.4M</div>
                    <div class="stat-change positive">
                        <svg class="stat-change-icon" fill="currentColor" viewBox="0 0 24 24">
                            <path d="M7 14l5-5 5 5z"/>
                        </svg>
                        +15% from last month
                    </div>
                </div>
                
                <div class="stat-card">
                    <div class="stat-header">
                        <div class="stat-title">Pending Payments</div>
                        <div class="stat-icon purple">
                            <svg width="24" height="24" fill="currentColor" viewBox="0 0 24 24">
                                <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/>
                            </svg>
                        </div>
                    </div>
                    <div class="stat-value">6</div>
                    <div class="stat-change negative">
                        <svg class="stat-change-icon" fill="currentColor" viewBox="0 0 24 24">
                            <path d="M17 10l-5 5-5-5z"/>
                        </svg>
                        -3% from last month
                    </div>
                </div>
            </div>
            
            <div class="content-grid">
                <div class="content-card">
                    <div class="card-header">
                        <h3 class="card-title">Recent Transactions</h3>
                        <div class="card-actions">
                            <button class="card-btn">View All</button>
                            <button class="card-btn primary">Add New</button>
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
                                    </tr>
                                </thead>
                                <tbody>
                                    <tr>
                                        <td>John Mukasa</td>
                                        <td>UBE 123A</td>
                                        <td>UGX 50,000</td>
                                        <td>Oct 6, 2025</td>
                                        <td><span class="status-badge active">Paid</span></td>
                                    </tr>
                                    <tr>
                                        <td>Peter Ssali</td>
                                        <td>UBF 456B</td>
                                        <td>UGX 45,000</td>
                                        <td>Oct 5, 2025</td>
                                        <td><span class="status-badge pending">Pending</span></td>
                                    </tr>
                                    <tr>
                                        <td>Mary Nakato</td>
                                        <td>UBG 789C</td>
                                        <td>UGX 55,000</td>
                                        <td>Oct 4, 2025</td>
                                        <td><span class="status-badge active">Paid</span></td>
                                    </tr>
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
                
                <div class="content-card">
                    <div class="card-header">
                        <h3 class="card-title">Quick Actions</h3>
                    </div>
                    <div class="card-content">
                        <div style="display: flex; flex-direction: column; gap: 1rem;">
                            <button class="btn btn-primary">
                                <svg width="20" height="20" fill="currentColor" viewBox="0 0 24 24">
                                    <path d="M19 13h-6v6h-2v-6H5v-2h6V5h2v6h6v2z"/>
                                </svg>
                                Add New Driver
                            </button>
                            <button class="btn btn-secondary">
                                <svg width="20" height="20" fill="currentColor" viewBox="0 0 24 24">
                                    <path d="M18.92 6.01C18.72 5.42 18.16 5 17.5 5h-11c-.66 0-1.22.42-1.42 1.01L3 12v8c0 .55.45 1 1 1h1c.55 0 1-.45 1-1v-1h12v1c0 .55.45 1 1 1h1c.55 0 1-.45 1-1v-8l-2.08-5.99z"/>
                                </svg>
                                Register Vehicle
                            </button>
                            <button class="btn btn-success">
                                <svg width="20" height="20" fill="currentColor" viewBox="0 0 24 24">
                                    <path d="M11.8 10.9c-2.27-.59-3-1.2-3-2.15 0-1.09 1.01-1.85 2.7-1.85 1.78 0 2.44.85 2.5 2.1h2.21c-.07-1.72-1.12-3.3-3.21-3.81V3h-3v2.16c-1.94.42-3.5 1.68-3.5 3.61 0 2.31 1.91 3.46 4.7 4.13 2.5.6 3 1.48 3 2.41 0 .69-.49 1.79-2.7 1.79-2.06 0-2.87-.92-2.98-2.1h-2.2c.12 2.19 1.76 3.42 3.68 3.83V21h3v-2.15c1.95-.37 3.5-1.5 3.5-3.55 0-2.84-2.43-3.81-4.7-4.4z"/>
                                </svg>
                                Record Payment
                            </button>
                            <button class="btn btn-warning">
                                <svg width="20" height="20" fill="currentColor" viewBox="0 0 24 24">
                                    <path d="M14 2H6c-1.1 0-1.99.9-1.99 2L4 20c0 1.1.89 2 2 2h8c1.1 0 2-.9 2-2V8l-6-6zm2 16H8v-2h8v2zm0-4H8v-2h8v2zm-3-5V3.5L18.5 9H13z"/>
                                </svg>
                                Generate Report
                            </button>
                        </div>
                    </div>
                </div>
            </div>
        `;
    }
    
    getDriversContent() {
        return `
            <div class="content-card">
                <div class="card-header">
                    <h3 class="card-title">Driver Management</h3>
                    <div class="card-actions">
                        <button class="card-btn">Export</button>
                        <button class="card-btn primary">Add Driver</button>
                    </div>
                </div>
                <div class="card-content">
                    <div class="table-container">
                        <table class="data-table">
                            <thead>
                                <tr>
                                    <th>Name</th>
                                    <th>Phone</th>
                                    <th>License</th>
                                    <th>Vehicle</th>
                                    <th>Status</th>
                                    <th>Actions</th>
                                </tr>
                            </thead>
                            <tbody>
                                <tr>
                                    <td>John Mukasa</td>
                                    <td>+256 700 123456</td>
                                    <td>DL123456</td>
                                    <td>UBE 123A</td>
                                    <td><span class="status-badge active">Active</span></td>
                                    <td>
                                        <button class="btn btn-secondary btn-sm">Edit</button>
                                        <button class="btn btn-danger btn-sm">Suspend</button>
                                    </td>
                                </tr>
                                <!-- More driver rows would go here -->
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
        `;
    }
    
    getVehiclesContent() {
        return `
            <div class="content-card">
                <div class="card-header">
                    <h3 class="card-title">Vehicle Management</h3>
                    <div class="card-actions">
                        <button class="card-btn">Export</button>
                        <button class="card-btn primary">Add Vehicle</button>
                    </div>
                </div>
                <div class="card-content">
                    <p>Vehicle management content will be displayed here.</p>
                </div>
            </div>
        `;
    }
    
    getPaymentsContent() {
        return `
            <div class="content-card">
                <div class="card-header">
                    <h3 class="card-title">Payment Management</h3>
                    <div class="card-actions">
                        <button class="card-btn">Export</button>
                        <button class="card-btn primary">Record Payment</button>
                    </div>
                </div>
                <div class="card-content">
                    <p>Payment management content will be displayed here.</p>
                </div>
            </div>
        `;
    }
    
    getReceiptsContent() {
        return `
            <div class="content-card">
                <div class="card-header">
                    <h3 class="card-title">Receipt Management</h3>
                    <div class="card-actions">
                        <button class="card-btn">Export</button>
                        <button class="card-btn primary">Generate Receipt</button>
                    </div>
                </div>
                <div class="card-content">
                    <p>Receipt management content will be displayed here.</p>
                </div>
            </div>
        `;
    }
    
    getReportsContent() {
        return `
            <div class="content-card">
                <div class="card-header">
                    <h3 class="card-title">Reports & Analytics</h3>
                    <div class="card-actions">
                        <button class="card-btn">Export PDF</button>
                        <button class="card-btn primary">Generate Report</button>
                    </div>
                </div>
                <div class="card-content">
                    <p>Reports and analytics content will be displayed here.</p>
                </div>
            </div>
        `;
    }
    
    getSettingsContent() {
        return `
            <div class="content-card">
                <div class="card-header">
                    <h3 class="card-title">System Settings</h3>
                    <div class="card-actions">
                        <button class="card-btn primary">Save Changes</button>
                    </div>
                </div>
                <div class="card-content">
                    <p>System settings content will be displayed here.</p>
                </div>
            </div>
        `;
    }
    
    setupDynamicEventListeners() {
        // Re-setup event listeners for dynamically loaded content
        const newCardBtns = document.querySelectorAll('.card-btn:not([data-listener])');
        newCardBtns.forEach(btn => {
            btn.setAttribute('data-listener', 'true');
            btn.addEventListener('click', (e) => {
                this.handleCardAction(e, btn);
            });
        });
    }
    
    handleCardAction(e, btn) {
        e.preventDefault();
        const action = btn.textContent.trim();
        
        // Show loading state
        const originalText = btn.textContent;
        btn.innerHTML = '<span class="loading"></span> Loading...';
        btn.disabled = true;
        
        // Simulate action
        setTimeout(() => {
            btn.textContent = originalText;
            btn.disabled = false;
            this.showNotification(`${action} completed successfully!`, 'success');
        }, 1000);
    }
    
    handleFormSubmit(e, form) {
        e.preventDefault();
        
        // Show loading state
        const submitBtn = form.querySelector('button[type="submit"]');
        if (submitBtn) {
            const originalText = submitBtn.textContent;
            submitBtn.innerHTML = '<span class="loading"></span> Processing...';
            submitBtn.disabled = true;
            
            // Simulate form submission
            setTimeout(() => {
                submitBtn.textContent = originalText;
                submitBtn.disabled = false;
                this.showNotification('Form submitted successfully!', 'success');
                form.reset();
            }, 1500);
        }
    }
    
    handleKeyboardShortcuts(e) {
        // Ctrl/Cmd + K for search
        if ((e.ctrlKey || e.metaKey) && e.key === 'k') {
            e.preventDefault();
            const searchInput = document.querySelector('.search-input');
            if (searchInput) {
                searchInput.focus();
            }
        }
        
        // Escape to close sidebar on mobile
        if (e.key === 'Escape') {
            this.closeSidebar();
        }
    }
    
    toggleUserMenu() {
        // Implement user menu dropdown
        console.log('User menu toggled');
    }
    
    setupNotifications() {
        // Create notification container if it doesn't exist
        if (!document.querySelector('.notification-container')) {
            const container = document.createElement('div');
            container.className = 'notification-container';
            container.style.cssText = `
                position: fixed;
                top: 20px;
                right: 20px;
                z-index: 9999;
                display: flex;
                flex-direction: column;
                gap: 10px;
            `;
            document.body.appendChild(container);
        }
    }
    
    showNotification(message, type = 'info') {
        const container = document.querySelector('.notification-container');
        if (!container) return;
        
        const notification = document.createElement('div');
        notification.className = `notification notification-${type}`;
        notification.style.cssText = `
            padding: 12px 16px;
            border-radius: 8px;
            color: white;
            font-weight: 500;
            min-width: 300px;
            box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
            transform: translateX(100%);
            transition: transform 0.3s ease;
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
        
        // Auto remove after 3 seconds
        setTimeout(() => {
            notification.style.transform = 'translateX(100%)';
            setTimeout(() => {
                if (notification.parentNode) {
                    notification.parentNode.removeChild(notification);
                }
            }, 300);
        }, 3000);
    }
    
    setupSearch() {
        const searchInput = document.querySelector('.search-input');
        if (searchInput) {
            searchInput.addEventListener('input', (e) => {
                this.handleSearch(e.target.value);
            });
        }
    }
    
    handleSearch(query) {
        // Implement search functionality
        console.log('Searching for:', query);
    }
    
    showLoading() {
        // Show global loading state
        const dashboardContent = document.querySelector('.dashboard-content');
        if (dashboardContent) {
            dashboardContent.style.opacity = '0.5';
            dashboardContent.style.pointerEvents = 'none';
        }
    }
    
    hideLoading() {
        // Hide global loading state
        const dashboardContent = document.querySelector('.dashboard-content');
        if (dashboardContent) {
            dashboardContent.style.opacity = '1';
            dashboardContent.style.pointerEvents = 'auto';
        }
    }
    
    loadDashboardData() {
        // Load initial dashboard data
        // This would typically make API calls to fetch real data
        console.log('Loading dashboard data...');
    }
}

// Initialize dashboard when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    new AdminDashboard();
});

// Export for use in other modules
if (typeof module !== 'undefined' && module.exports) {
    module.exports = AdminDashboard;
}