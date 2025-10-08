import "dart:ui";
import "package:flutter/material.dart";
import "package:intl/intl.dart";
import "../../constants/theme_constants.dart";
import "../../utils/responsive_helper.dart";
import "../../services/api_service.dart";
import "../../widgets/custom_card.dart";

class PaymentsManagementScreen extends StatefulWidget {
  const PaymentsManagementScreen({super.key});

  @override
  State<PaymentsManagementScreen> createState() =>
      _PaymentsManagementScreenState();
}

class _PaymentsManagementScreenState extends State<PaymentsManagementScreen>
    with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

  bool _isLoading = true;
  List<Map<String, dynamic>> _payments = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _filteredPayments = <Map<String, dynamic>>[];
  String _searchQuery = "";
  String _selectedStatus = "all"; // all, paid, pending, overdue
  DateTimeRange? _selectedDateRange;

  // Using theme constants for colors

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeAndLoadPayments();
  }

  Future<void> _initializeAndLoadPayments() async {
    // Initialize API service with stored token
    await _apiService.initialize();
    // Load payments
    await _loadPayments();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPayments({final bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _isLoading = true;
        _payments.clear();
        _filteredPayments.clear();
      });
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final Map<String, dynamic> response = await _apiService.getPayments();
      
      // Handle the actual response structure: {status, message, data: {data: [...], pagination: {...}}}
      List<dynamic> paymentsData;
      if (response["data"] is Map<String, dynamic>) {
        // Paginated response: data contains another object with "data" key
        paymentsData = response["data"]["data"] ?? <Map<String, dynamic>>[];
      } else if (response["data"] is List) {
        // Direct list response
        paymentsData = response["data"];
      } else {
        paymentsData = <Map<String, dynamic>>[];
      }
      
      _payments = paymentsData.map((dynamic json) {
        final Map<String, dynamic> payment = json as Map<String, dynamic>;
        
        // Parse date strings to DateTime objects if they're strings
        if (payment["due_date"] is String) {
          payment["due_date"] = DateTime.tryParse(payment["due_date"]) ?? DateTime.now();
        }
        if (payment["paid_date"] is String && payment["paid_date"] != null) {
          payment["paid_date"] = DateTime.tryParse(payment["paid_date"]);
        }
        
        return payment;
      }).toList();

      _filterPayments();
    } on Exception catch (e) {
      _showErrorSnackBar("Hitilafu katika kupakia malipo: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterPayments() {
    setState(() {
      _filteredPayments = _payments.where((final Map<String, dynamic> payment) {
        final bool matchesSearch = _searchQuery.isEmpty ||
            payment["driver_name"]
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            payment["vehicle_number"]
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            (payment["receipt_number"] ?? "")
                .toLowerCase()
                .contains(_searchQuery.toLowerCase());

        final bool matchesStatus =
            _selectedStatus == "all" || payment["status"] == _selectedStatus;

        final bool matchesDateRange = _selectedDateRange == null ||
            (_isDateInRange(payment["due_date"], _selectedDateRange!) ||
                (payment["paid_date"] != null &&
                    _isDateInRange(payment["paid_date"], _selectedDateRange!)));

        return matchesSearch && matchesStatus && matchesDateRange;
      }).toList();

      // Sort by due date (overdue first, then by date)
      _filteredPayments
          .sort((final Map<String, dynamic> a, final Map<String, dynamic> b) {
        if (a["status"] == "overdue" && b["status"] != "overdue") {
          return -1;
        }
        if (b["status"] == "overdue" && a["status"] != "overdue") {
          return 1;
        }
        return (b["due_date"] as DateTime).compareTo(a["due_date"] as DateTime);
      });
    });
  }

  bool _isDateInRange(final DateTime date, final DateTimeRange range) =>
      date.isAfter(range.start.subtract(const Duration(days: 1))) &&
      date.isBefore(range.end.add(const Duration(days: 1)));

  void _onSearchChanged(final String query) {
    setState(() {
      _searchQuery = query;
    });
    _filterPayments();
  }

  void _onStatusChanged(final String status) {
    setState(() {
      _selectedStatus = status;
    });
    _filterPayments();
  }

  void _showErrorSnackBar(final String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: SelectableText(message),
        backgroundColor: ThemeConstants.errorRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(final BuildContext context) {
    ResponsiveHelper.init(context);
    return ThemeConstants.buildResponsiveScaffold(
      context,
      title: "Simamia Malipo",
      body: _isLoading ? ThemeConstants.buildResponsiveLoadingWidget(context) : _buildMainContent(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() => AppBar(
        title: const Text(
          "Simamia Malipo",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: ThemeConstants.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            color: ThemeConstants.primaryBlue, // Solid blue background
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const <Widget>[
            Tab(text: "Yote"),
            Tab(text: "Yanayosubiri"),
            Tab(text: "Yaliyolipwa"),
          ],
        ),
        actions: <Widget>[
          IconButton(
            onPressed: _loadPayments,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: _showDateRangePicker,
            icon: const Icon(Icons.date_range),
          ),
          PopupMenuButton<String>(
            onSelected: (final String value) {
              switch (value) {
                case "export":
                  _exportPayments();
                case "bulk_action":
                  _showBulkActionDialog();
              }
            },
            itemBuilder: (final BuildContext context) =>
                <PopupMenuEntry<String>>[
              const PopupMenuItem(
                value: "export",
                child: Row(
                  children: <Widget>[
                    Icon(Icons.download, color: ThemeConstants.primaryBlue),
                    SizedBox(width: 8),
                    Text("Hamisha Data"),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: "bulk_action",
                child: Row(
                  children: <Widget>[
                    Icon(Icons.checklist, color: Colors.orange),
                    SizedBox(width: 8),
                    Text("Vitendo vya Wingi"),
                  ],
                ),
              ),
            ],
          ),
        ],
      );

  Widget _buildLoadingScreen() => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              "Inapakia malipo...",
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      );

  Widget _buildMainContent() => Column(
        children: <Widget>[
          _buildSearchAndFilter(),
          _buildStatsCards(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: <Widget>[
                _buildPaymentsList(_payments),
                _buildPaymentsList(
                  _payments
                      .where(
                        (final Map<String, dynamic> p) =>
                            p["status"] == "pending" ||
                            p["status"] == "overdue",
                      )
                      .toList(),
                ),
                _buildPaymentsList(
                  _payments
                      .where(
                        (final Map<String, dynamic> p) => p["status"] == "paid",
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      );

  Widget _buildSearchAndFilter() => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: <Widget>[
            // Search bar
            DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: "Tafuta dereva, gari, au namba ya risiti...",
                  prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged("");
                          },
                          icon: const Icon(Icons.clear),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Filter chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: <Widget>[
                  _buildFilterChip("all", "Yote", _payments.length),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    "paid",
                    "Yaliyolipwa",
                    _payments
                        .where(
                          (final Map<String, dynamic> p) =>
                              p["status"] == "paid",
                        )
                        .length,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    "pending",
                    "Yanayosubiri",
                    _payments
                        .where(
                          (final Map<String, dynamic> p) =>
                              p["status"] == "pending",
                        )
                        .length,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    "overdue",
                    "Yaliyochelewa",
                    _payments
                        .where(
                          (final Map<String, dynamic> p) =>
                              p["status"] == "overdue",
                        )
                        .length,
                  ),
                  const SizedBox(width: 8),
                  if (_selectedDateRange != null)
                    Chip(
                      label: Text(
                        "${DateFormat("dd/MM").format(_selectedDateRange!.start)} - ${DateFormat("dd/MM").format(_selectedDateRange!.end)}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      backgroundColor: ThemeConstants.primaryBlue,
                      deleteIcon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 18,
                      ),
                      onDeleted: () {
                        setState(() {
                          _selectedDateRange = null;
                        });
                        _filterPayments();
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildFilterChip(
    final String value,
    final String label,
    final int count,
  ) {
    final bool isSelected = _selectedStatus == value;
    return FilterChip(
      selected: isSelected,
      label: Text(
        "$label ($count)",
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.grey[600],
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: Colors.white,
      selectedColor: ThemeConstants.primaryBlue,
      checkmarkColor: Colors.white,
      onSelected: (final bool selected) {
        if (selected) {
          _onStatusChanged(value);
        }
      },
    );
  }

  Widget _buildStatsCards() {
    final double totalAmount = _payments.fold<double>(
      0,
      (final double sum, final Map<String, dynamic> payment) =>
          sum + _toDouble(payment["amount"]),
    );
    final double paidAmount = _payments
        .where((final Map<String, dynamic> p) => p["status"] == "paid")
        .fold<double>(
          0,
          (final double sum, final Map<String, dynamic> payment) =>
              sum + _toDouble(payment["amount"]),
        );
    final double pendingAmount = _payments
        .where(
          (final Map<String, dynamic> p) =>
              p["status"] == "pending" || p["status"] == "overdue",
        )
        .fold<double>(
          0,
          (final double sum, final Map<String, dynamic> payment) =>
              sum + _toDouble(payment["amount"]),
        );
    final int overdueCount = _payments
        .where((final Map<String, dynamic> p) => p["status"] == "overdue")
        .length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: <Widget>[
          Expanded(
            child: _buildStatCard(
              title: "Jumla",
              value: "TSH ${_formatCurrency(totalAmount)}",
              icon: Icons.account_balance_wallet,
              color: ThemeConstants.primaryBlue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              title: "Yaliyolipwa",
              value: "TSH ${_formatCurrency(paidAmount)}",
              icon: Icons.check_circle,
              color: ThemeConstants.successGreen,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              title: "Yanayosubiri",
              value: "TSH ${_formatCurrency(pendingAmount)}",
              icon: Icons.pending,
              color: Colors.amber,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              title: "Yaliyochelewa",
              value: "$overdueCount",
              icon: Icons.warning,
              color: ThemeConstants.errorRed,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required final String title,
    required final String value,
    required final IconData icon,
    required final Color color,
  }) =>
      CustomCard(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: <Widget>[
              Icon(
                icon,
                color: color,
                size: 20,
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 9,
                  color: Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );

  Widget _buildPaymentsList(final List<Map<String, dynamic>> payments) {
    if (payments.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadPayments,
      color: ThemeConstants.primaryBlue,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: payments.length,
        itemBuilder: (final BuildContext context, final int index) {
          final Map<String, dynamic> payment = payments[index];
          return _buildPaymentCard(payment);
        },
      ),
    );
  }

  Widget _buildEmptyState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.payment_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              "Hakuna malipo yaliyopatikana",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Jaribu kubadilisha vichujio vyako",
              style: TextStyle(
                fontSize: 14,
                color: Colors.black45,
              ),
            ),
          ],
        ),
      );

  Widget _buildPaymentCard(final Map<String, dynamic> payment) {
    final String status = payment["status"] as String;
    final double amount = _toDouble(payment["amount"]);
    final DateTime dueDate = payment["due_date"] as DateTime;
    final DateTime? paidDate = payment["paid_date"] as DateTime?;

    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (status) {
      case "paid":
        statusColor = ThemeConstants.successGreen;
        statusIcon = Icons.check_circle;
        statusText = "YALIYOLIPWA";
      case "pending":
        statusColor = Colors.amber;
        statusIcon = Icons.pending;
        statusText = "YANAYOSUBIRI";
      case "overdue":
        statusColor = ThemeConstants.errorRed;
        statusIcon = Icons.warning;
        statusText = "YALIYOCHELEWA";
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
        statusText = "HAIJULIKANI";
    }

    return CustomCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                // Status indicator
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Icon(
                    statusIcon,
                    color: statusColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                // Payment info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              payment["driver_name"],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF616161), // Colors.grey[700]
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              statusText,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        payment["vehicle_number"],
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: <Widget>[
                          Icon(
                            Icons.schedule,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "Tarehe ya kulipa: ${DateFormat("dd/MM/yyyy").format(dueDate)}",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      if (paidDate != null) ...<Widget>[
                        const SizedBox(height: 2),
                        Row(
                          children: <Widget>[
                            const Icon(
                              Icons.check,
                              size: 14,
                              color: ThemeConstants.successGreen,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "Ililipwa: ${DateFormat("dd/MM/yyyy HH:mm").format(paidDate)}",
                              style: const TextStyle(
                                fontSize: 12,
                                color: ThemeConstants.successGreen,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                // Amount and actions
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Text(
                      "TSH ${_formatCurrency(amount)}",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    PopupMenuButton<String>(
                      onSelected: (final String value) =>
                          _handlePaymentAction(value, payment),
                      itemBuilder: (final BuildContext context) =>
                          <PopupMenuEntry<String>>[
                        const PopupMenuItem(
                          value: "view",
                          child: Row(
                            children: <Widget>[
                              Icon(Icons.visibility, color: ThemeConstants.primaryBlue),
                              SizedBox(width: 8),
                              Text("Ona"),
                            ],
                          ),
                        ),
                        if (status == "pending" || status == "overdue")
                          const PopupMenuItem(
                            value: "mark_paid",
                            child: Row(
                              children: <Widget>[
                                Icon(Icons.check_circle, color: ThemeConstants.successGreen),
                                SizedBox(width: 8),
                                Text("Weka Kuwa Yaliyolipwa"),
                              ],
                            ),
                          ),
                        if (status == "paid")
                          const PopupMenuItem(
                            value: "receipt",
                            child: Row(
                              children: <Widget>[
                                Icon(Icons.receipt, color: Colors.orange),
                                SizedBox(width: 8),
                                Text("Ona Risiti"),
                              ],
                            ),
                          ),
                        const PopupMenuItem(
                          value: "edit",
                          child: Row(
                            children: <Widget>[
                              Icon(Icons.edit, color: Colors.orange),
                              SizedBox(width: 8),
                              Text("Hariri"),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: "delete",
                          child: Row(
                            children: <Widget>[
                              Icon(Icons.delete, color: ThemeConstants.errorRed),
                              SizedBox(width: 8),
                              Text("Futa"),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            if (payment["notes"] != null &&
                payment["notes"].isNotEmpty) ...<Widget>[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  payment["notes"],
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            // Payment details row
            Row(
              children: <Widget>[
                _buildPaymentDetail(
                  "Aina",
                  _getPaymentTypeText(payment["payment_type"]),
                  Icons.category,
                ),
                if (payment["payment_method"] != null)
                  _buildPaymentDetail(
                    "Njia",
                    _getPaymentMethodText(payment["payment_method"]),
                    Icons.payment,
                  ),
                if (payment["receipt_number"] != null)
                  _buildPaymentDetail(
                    "Risiti",
                    payment["receipt_number"],
                    Icons.receipt,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentDetail(
    final String label,
    final String value,
    final IconData icon,
  ) =>
      Expanded(
        child: Row(
          children: <Widget>[
            Icon(
              icon,
              size: 14,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.black45,
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildFloatingActionButton() => FloatingActionButton.extended(
        onPressed: _showRecordPaymentDialog,
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          "Rekodi Malipo",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      );

  String _formatCurrency(final double amount) {
    if (amount >= 1000000) {
      return "${(amount / 1000000).toStringAsFixed(1)}M";
    } else if (amount >= 1000) {
      return "${(amount / 1000).toStringAsFixed(0)}K";
    } else {
      return amount.toStringAsFixed(0);
    }
  }

  String _getPaymentTypeText(final String type) {
    switch (type) {
      case "daily":
        return "Kila siku";
      case "weekly":
        return "Kila wiki";
      case "monthly":
        return "Kila mwezi";
      default:
        return type;
    }
  }

  String _getPaymentMethodText(final String method) {
    switch (method) {
      case "cash":
        return "Fedha taslimu";
      case "mobile_money":
        return "Pesa za simu";
      case "bank_transfer":
        return "Uhamisho wa benki";
      default:
        return method;
    }
  }

  void _handlePaymentAction(
    final String action,
    final Map<String, dynamic> payment,
  ) {
    switch (action) {
      case "view":
        _showPaymentDetails(payment);
      case "mark_paid":
        _markPaymentAsPaid(payment);
      case "receipt":
        _showReceipt(payment);
      case "edit":
        _showEditPaymentDialog(payment);
      case "delete":
        _confirmDeletePayment(payment);
    }
  }

  void _showPaymentDetails(final Map<String, dynamic> payment) {
    showDialog(
      context: context,
      builder: (final BuildContext context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Maelezo ya Malipo - ${payment["driver_name"]}"),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _buildDetailRow("Dereva:", payment["driver_name"]),
              _buildDetailRow("Gari:", payment["vehicle_number"]),
              _buildDetailRow(
                "Kiasi:",
                "TSH ${_formatCurrency(payment["amount"])}",
              ),
              _buildDetailRow(
                "Aina ya Malipo:",
                _getPaymentTypeText(payment["payment_type"]),
              ),
              _buildDetailRow("Hali:", payment["status"]),
              _buildDetailRow(
                "Tarehe ya Kulipa:",
                DateFormat("dd/MM/yyyy").format(payment["due_date"]),
              ),
              if (payment["paid_date"] != null)
                _buildDetailRow(
                  "Ililipwa:",
                  DateFormat("dd/MM/yyyy HH:mm").format(payment["paid_date"]),
                ),
              if (payment["payment_method"] != null)
                _buildDetailRow(
                  "Njia ya Malipo:",
                  _getPaymentMethodText(payment["payment_method"]),
                ),
              if (payment["receipt_number"] != null)
                _buildDetailRow("Namba ya Risiti:", payment["receipt_number"]),
              if (payment["notes"] != null && payment["notes"].isNotEmpty)
                _buildDetailRow("Maelezo:", payment["notes"]),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Funga"),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(final String label, final String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              width: 120,
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.black54,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );

  void _markPaymentAsPaid(final Map<String, dynamic> payment) {
    showDialog(
      context: context,
      builder: (final BuildContext context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Weka Kuwa Yaliyolipwa"),
        content: Text(
          "Je, una uhakika malipo ya ${payment["driver_name"]} ya TSH ${_formatCurrency(payment["amount"])} yamelipwa?",
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hapana"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO(dev): Implement mark as paid API call
              setState(() {
                payment["status"] = "paid";
                payment["paid_date"] = DateTime.now();
                payment["receipt_number"] =
                    "R${DateTime.now().millisecondsSinceEpoch}";
              });
              _filterPayments();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "Malipo ya ${payment["driver_name"]} yamewekwa kuwa yaliyolipwa",
                  ),
                  backgroundColor: ThemeConstants.successGreen,
                ),
              );
            },
            child: const Text(
              "Ndio",
              style: TextStyle(color: ThemeConstants.successGreen),
            ),
          ),
        ],
      ),
    );
  }

  void _showReceipt(final Map<String, dynamic> payment) {
    // TODO(dev): Implement receipt viewing
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Kipengele cha kuona risiti kinatengenezwa..."),
      ),
    );
  }

  void _showEditPaymentDialog(final Map<String, dynamic> payment) {
    // TODO(dev): Implement edit payment dialog
    showDialog(
      context: context,
      builder: (final BuildContext context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Hariri Malipo - ${payment["driver_name"]}"),
        content: const Text("Kipengele hiki kinatengenezwa. Subiri kidogo!"),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Sawa"),
          ),
        ],
      ),
    );
  }

  void _confirmDeletePayment(final Map<String, dynamic> payment) {
    showDialog(
      context: context,
      builder: (final BuildContext context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Futa Malipo"),
        content: Text(
          "Je, una uhakika unataka kufuta malipo ya ${payment["driver_name"]} ya TSH ${_formatCurrency(payment["amount"])}? Kitendo hiki hakiwezi kurudishwa.",
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hapana"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO(dev): Implement delete API call
              setState(() {
                _payments.removeWhere(
                  (final Map<String, dynamic> p) => p["id"] == payment["id"],
                );
              });
              _filterPayments();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content:
                      Text("Malipo ya ${payment["driver_name"]} yamefutwa"),
                  backgroundColor: ThemeConstants.errorRed,
                ),
              );
            },
            child: const Text(
              "Futa",
              style: TextStyle(color: ThemeConstants.errorRed),
            ),
          ),
        ],
      ),
    );
  }

  void _showRecordPaymentDialog() {
    // TODO: Implement record payment dialog
    showDialog(
      context: context,
      builder: (final BuildContext context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Rekodi Malipo"),
        content: const Text("Kipengele hiki kinatengenezwa. Subiri kidogo!"),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Sawa"),
          ),
        ],
      ),
    );
  }

  Future<void> _showDateRangePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _selectedDateRange,
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
      _filterPayments();
    }
  }

  void _exportPayments() {
    // TODO: Implement export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Kipengele cha kuhamisha kinatengenezwa..."),
      ),
    );
  }

  void _showBulkActionDialog() {
    // TODO: Implement bulk actions
    showDialog(
      context: context,
      builder: (final BuildContext context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Vitendo vya Wingi"),
        content: const Text("Kipengele hiki kinatengenezwa. Subiri kidogo!"),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Sawa"),
          ),
        ],
      ),
    );
  }

  // Helper method to safely convert dynamic values to double
  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }
}
