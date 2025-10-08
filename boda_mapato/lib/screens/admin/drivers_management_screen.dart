import "dart:ui";
import "package:flutter/material.dart";

import "../../constants/theme_constants.dart";
import "../../utils/responsive_helper.dart";
import "../../models/driver.dart";
import "../../services/api_service.dart";
import "../../widgets/custom_button.dart";
import "../../widgets/custom_card.dart";

class DriversManagementScreen extends StatefulWidget {
  const DriversManagementScreen({super.key});

  @override
  State<DriversManagementScreen> createState() =>
      _DriversManagementScreenState();
}

class _DriversManagementScreenState extends State<DriversManagementScreen>
    with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  List<Driver> _drivers = <Driver>[];
  List<Driver> _filteredDrivers = <Driver>[];
  String _searchQuery = "";
  String _selectedFilter = "all"; // all, active, inactive
  int _currentPage = 1;
  bool _hasMoreData = true;
  bool _isLoadingMore = false;

  // Using theme constants for colors

  @override
  void initState() {
    super.initState();
    _initializeAndLoadDrivers();
  }

  Future<void> _initializeAndLoadDrivers() async {
    // Initialize API service with stored token
    await _apiService.initialize();
    // Load drivers
    await _loadDrivers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDrivers({final bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _isLoading = true;
        _currentPage = 1;
        _hasMoreData = true;
        _drivers.clear();
        _filteredDrivers.clear();
      });
    } else if (!_hasMoreData || _isLoadingMore) {
      return;
    }

    setState(() {
      if (_currentPage == 1) {
        _isLoading = true;
      } else {
        _isLoadingMore = true;
      }
    });

    try {
      final Map<String, dynamic> response = await _apiService.getDrivers(
        page: _currentPage,
      );

      // Handle the actual response structure: {status, message, data: {data: [...], pagination: {...}}}
      List<dynamic> driversData;
      if (response["data"] is Map<String, dynamic>) {
        // Paginated response: data contains another object with "data" key
        driversData = response["data"]["data"] ?? <dynamic>[];
      } else if (response["data"] is List) {
        // Direct list response
        driversData = response["data"];
      } else {
        driversData = <dynamic>[];
      }
      final List<Driver> newDrivers = driversData
          .map((final json) => Driver.fromJson(json as Map<String, dynamic>))
          .toList();

      setState(() {
        if (_currentPage == 1) {
          _drivers = newDrivers;
        } else {
          _drivers.addAll(newDrivers);
        }

        // Check if there"s more data
        _hasMoreData = newDrivers.length >= 20;
        _currentPage++;
      });

      _filterDrivers();
    } on Exception catch (e) {
      _showErrorSnackBar("Hitilafu katika kupakia madereva: $e");
    } finally {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  void _filterDrivers() {
    setState(() {
      _filteredDrivers = _drivers.where((final Driver driver) {
        final bool matchesSearch = _searchQuery.isEmpty ||
            driver.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            driver.phone.contains(_searchQuery) ||
            (driver.vehicleNumber
                    ?.toLowerCase()
                    .contains(_searchQuery.toLowerCase()) ??
                false);

        final bool matchesFilter =
            _selectedFilter == "all" || driver.status == _selectedFilter;

        return matchesSearch && matchesFilter;
      }).toList();
    });
  }

  void _onSearchChanged(final String query) {
    setState(() {
      _searchQuery = query;
    });
    _filterDrivers();
  }

  void _onFilterChanged(final String filter) {
    setState(() {
      _selectedFilter = filter;
    });
    _filterDrivers();
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
      title: "Simamia Madereva",
      body: _isLoading ? ThemeConstants.buildResponsiveLoadingWidget(context) : _buildMainContent(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() => AppBar(
        title: const Text(
          "Simamia Madereva",
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
        actions: <Widget>[
          IconButton(
            onPressed: () => _loadDrivers(refresh: true),
            icon: const Icon(Icons.refresh),
          ),
          PopupMenuButton<String>(
            onSelected: (final String value) {
              switch (value) {
                case "export":
                  _exportDrivers();
                case "import":
                  _importDrivers();
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
                value: "import",
                child: Row(
                  children: <Widget>[
                    Icon(Icons.upload, color: Colors.orange),
                    SizedBox(width: 8),
                    Text("Ingiza Data"),
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
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            SizedBox(height: 16),
            Text(
              "Inapakia madereva...",
              style: TextStyle(
                fontSize: 16,
                color: ThemeConstants.textSecondary, // Light text on blue background
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
            child: RefreshIndicator(
              onRefresh: () => _loadDrivers(refresh: true),
              color: ThemeConstants.textPrimary,
              backgroundColor: ThemeConstants.primaryBlue,
              child: _filteredDrivers.isEmpty
                  ? _buildEmptyState()
                  : _buildDriversList(),
            ),
          ),
        ],
      );

  Widget _buildSearchAndFilter() => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: <Widget>[
            // Search bar - Blue themed
            Container(
              decoration: BoxDecoration(
                color: ThemeConstants.primaryBlue.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                style: ThemeConstants.bodyStyle,
                decoration: InputDecoration(
                  hintText: "Tafuta dereva, simu, au namba ya gari...",
                  hintStyle: ThemeConstants.captionStyle.copyWith(
                    color: ThemeConstants.textSecondary,
                  ),
                  prefixIcon: const Icon(
                    Icons.search, 
                    color: Colors.white,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged("");
                          },
                          icon: const Icon(
                            Icons.clear, 
                            color: Colors.white,
                          ),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  filled: true,
                  fillColor: Colors.transparent,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Filter chips
            Row(
              children: <Widget>[
                _buildFilterChip("all", "Wote", _drivers.length),
                const SizedBox(width: 8),
                _buildFilterChip(
                  "active",
                  "Hai",
                  _drivers
                      .where((final Driver d) => d.status == "active")
                      .length,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  "inactive",
                  "Hahai",
                  _drivers
                      .where((final Driver d) => d.status == "inactive")
                      .length,
                ),
              ],
            ),
          ],
        ),
      );

  Widget _buildFilterChip(
    final String value,
    final String label,
    final int count,
  ) {
    final bool isSelected = _selectedFilter == value;
    return FilterChip(
      selected: isSelected,
      label: Text(
        "$label ($count)",
        style: TextStyle(
          color: Colors.white, // Always white text for visibility
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: ThemeConstants.primaryBlue.withOpacity(0.3),
      selectedColor: ThemeConstants.primaryOrange,
      checkmarkColor: Colors.white,
      side: BorderSide(
        color: isSelected 
            ? ThemeConstants.primaryOrange 
            : Colors.white.withOpacity(0.5),
        width: 1,
      ),
      onSelected: (final bool selected) {
        if (selected) {
          _onFilterChanged(value);
        }
      },
    );
  }

  Widget _buildStatsCards() {
    final int activeDrivers =
        _drivers.where((final Driver d) => d.status == "active").length;
    final double totalPayments = _drivers.fold<double>(
      0,
      (final double sum, final Driver driver) => sum + driver.totalPayments,
    );
    final double avgRating = _drivers.isNotEmpty
        ? _drivers.fold<double>(
              0,
              (final double sum, final Driver driver) => sum + driver.rating,
            ) /
            _drivers.length
        : 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: <Widget>[
          Expanded(
            child: _buildStatCard(
              title: "Madereva Hai",
              value: "$activeDrivers/${_drivers.length}",
              icon: Icons.people,
              color: ThemeConstants.successGreen,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              title: "Jumla ya Malipo",
              value: "TSH ${_formatCurrency(totalPayments)}",
              icon: Icons.payments,
              color: ThemeConstants.primaryOrange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              title: "Kiwango cha Wastani",
              value: avgRating.toStringAsFixed(1),
              icon: Icons.star,
              color: ThemeConstants.warningAmber,
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
      ThemeConstants.buildGlassCardStatic(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: <Widget>[
              Icon(
                icon,
                color: color,
                size: 24,
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: ThemeConstants.bodyStyle.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: ThemeConstants.captionStyle.copyWith(
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );

  Widget _buildEmptyState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.people_outline,
              size: 80,
              color: ThemeConstants.textSecondary, // Light text for blue background
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? "Hakuna dereva aliyepatikana"
                  : "Hakuna madereva bado",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: ThemeConstants.textPrimary, // White text on blue background
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty
                  ? "Jaribu kutafuta kwa jina lingine"
                  : "Ongeza dereva wa kwanza",
              style: const TextStyle(
                fontSize: 14,
                color: ThemeConstants.textSecondary, // Light text on blue background
              ),
            ),
            const SizedBox(height: 24),
            if (_searchQuery.isEmpty)
              ElevatedButton.icon(
                onPressed: _showAddDriverDialog,
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  "Ongeza Dereva",
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ThemeConstants.primaryOrange,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
          ],
        ),
      );

  Widget _buildDriversList() => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredDrivers.length + (_hasMoreData ? 1 : 0),
        itemBuilder: (final BuildContext context, final int index) {
          if (index == _filteredDrivers.length) {
            // Load more indicator
            if (!_isLoadingMore) {
              _loadDrivers();
            }
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          final Driver driver = _filteredDrivers[index];
          return _buildDriverCard(driver);
        },
      );

  Widget _buildDriverCard(final Driver driver) {
    final String status = driver.status;
    final bool isActive = status == "active";

    return ThemeConstants.buildGlassCardStatic(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                // Avatar
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: isActive
                        ? ThemeConstants.successGreen
                        : Colors.grey.shade600, // Darker grey for better contrast on blue
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                // Driver info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              driver.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: ThemeConstants.textPrimary, // White text on blue background
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? ThemeConstants.successGreen.withOpacity(0.3)
                                  : Colors.grey.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isActive ? ThemeConstants.successGreen : Colors.grey.shade400,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              isActive ? "HAI" : "HAHAI",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white, // White text for better contrast
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        driver.phone,
                        style: const TextStyle(
                          fontSize: 14,
                          color: ThemeConstants.textSecondary, // Light text on blue background
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: <Widget>[
                          Icon(
                            _getVehicleIcon(driver.vehicleType ?? ""),
                            size: 16,
                            color: Colors.white, // White icon for contrast
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "${driver.vehicleNumber ?? "N/A"} (${driver.vehicleType ?? "N/A"})",
                            style: const TextStyle(
                              fontSize: 12,
                              color: ThemeConstants.textSecondary, // Light text on blue background
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Actions
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert,
                    color: ThemeConstants.textPrimary, // White icon
                  ),
                  onSelected: (final String value) =>
                      _handleDriverAction(value, driver),
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
                    PopupMenuItem(
                      value: isActive ? "deactivate" : "activate",
                      child: Row(
                        children: <Widget>[
                          Icon(
                            isActive ? Icons.block : Icons.check_circle,
                            color: isActive ? ThemeConstants.errorRed : ThemeConstants.successGreen,
                          ),
                          const SizedBox(width: 8),
                          Text(isActive ? "Zima" : "Washa"),
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
            const SizedBox(height: 16),
            // Stats row
            Row(
              children: <Widget>[
                Expanded(
                  child: _buildDriverStat(
                    "Malipo",
                    "TSH ${_formatCurrency(driver.totalPayments)}",
                    Icons.payments,
                    ThemeConstants.primaryOrange, // Use theme orange
                  ),
                ),
                Expanded(
                  child: _buildDriverStat(
                    "Safari",
                    "${driver.tripsCompleted}",
                    Icons.route,
                    Colors.white, // White for better contrast
                  ),
                ),
                Expanded(
                  child: _buildDriverStat(
                    "Kiwango",
                    "${driver.rating}",
                    Icons.star,
                    ThemeConstants.warningAmber, // Use theme amber
                  ),
                ),
                Expanded(
                  child: _buildDriverStat(
                    "Malipo ya Mwisho",
                    driver.lastPayment != null
                        ? _formatDateTime(driver.lastPayment!)
                        : "Hakuna",
                    Icons.schedule,
                    ThemeConstants.successGreen,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverStat(
    final String label,
    final String value,
    final IconData icon,
    final Color color,
  ) =>
      Column(
        children: <Widget>[
          Icon(
            icon,
            size: 16,
            color: color,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: ThemeConstants.textSecondary, // Light text on blue background
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );

  Widget _buildFloatingActionButton() => FloatingActionButton.extended(
        onPressed: _showAddDriverDialog,
        backgroundColor: ThemeConstants.primaryOrange,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          "Ongeza Dereva",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      );

  IconData _getVehicleIcon(final String vehicleType) {
    switch (vehicleType.toLowerCase()) {
      case "bajaji":
        return Icons
            .directions_car; // three_wheeler not available, using car icon
      case "pikipiki":
        return Icons.motorcycle;
      case "gari":
        return Icons.directions_car;
      default:
        return Icons.directions_car;
    }
  }

  String _formatCurrency(final double amount) {
    if (amount >= 1000000) {
      return "${(amount / 1000000).toStringAsFixed(1)}M";
    } else if (amount >= 1000) {
      return "${(amount / 1000).toStringAsFixed(0)}K";
    } else {
      return amount.toStringAsFixed(0);
    }
  }

  String _formatDateTime(final DateTime dateTime) {
    final DateTime now = DateTime.now();
    final Duration difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return "${difference.inDays}d";
    } else if (difference.inHours > 0) {
      return "${difference.inHours}h";
    } else if (difference.inMinutes > 0) {
      return "${difference.inMinutes}m";
    } else {
      return "Sasa";
    }
  }

  void _handleDriverAction(final String action, final Driver driver) {
    switch (action) {
      case "view":
        _showDriverDetails(driver);
      case "edit":
        _showEditDriverDialog(driver);
      case "activate":
      case "deactivate":
        _toggleDriverStatus(driver);
      case "delete":
        _confirmDeleteDriver(driver);
    }
  }

  void _showDriverDetails(final Driver driver) {
    showDialog(
      context: context,
      builder: (final BuildContext context) => AlertDialog(
        backgroundColor: ThemeConstants.primaryBlue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Maelezo ya ${driver.name}",
          style: ThemeConstants.headingStyle,
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _buildDetailRow("Jina:", driver.name),
              _buildDetailRow("Barua pepe:", driver.email),
              _buildDetailRow("Simu:", driver.phone),
              _buildDetailRow("Leseni:", driver.licenseNumber),
              _buildDetailRow(
                "Gari:",
                "${driver.vehicleNumber ?? "N/A"} (${driver.vehicleType ?? "N/A"})",
              ),
              _buildDetailRow(
                "Hali:",
                driver.status == "active" ? "Hai" : "Hahai",
              ),
              _buildDetailRow(
                "Jumla ya Malipo:",
                "TSH ${_formatCurrency(driver.totalPayments)}",
              ),
              _buildDetailRow("Safari:", "${driver.tripsCompleted}"),
              _buildDetailRow("Kiwango:", "${driver.rating}"),
              _buildDetailRow("Aliungana:", _formatDate(driver.joinedDate)),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Funga",
              style: TextStyle(color: Colors.white),
            ),
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
              width: 100,
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  color: ThemeConstants.textSecondary,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: ThemeConstants.textPrimary,
                ),
              ),
            ),
          ],
        ),
      );

  String _formatDate(final DateTime date) =>
      "${date.day}/${date.month}/${date.year}";

  void _showAddDriverDialog() {
    showDialog(
      context: context,
      builder: (final BuildContext context) => _AddDriverDialog(
        onDriverAdded: () {
          // Refresh the drivers list after adding a new driver
          _loadDrivers(refresh: true);
        },
      ),
    );
  }

  void _showEditDriverDialog(final Driver driver) {
    // TODO(dev): Implement edit driver dialog with real API call
    showDialog(
      context: context,
      builder: (final BuildContext context) => AlertDialog(
        backgroundColor: ThemeConstants.primaryBlue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Hariri ${driver.name}",
          style: ThemeConstants.headingStyle,
        ),
        content: const Text(
          "Kipengele hiki kinatengenezwa. Subiri kidogo!",
          style: TextStyle(color: ThemeConstants.textSecondary),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Sawa",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleDriverStatus(final Driver driver) {
    final bool isActive = driver.status == "active";
    final String newStatus = isActive ? "inactive" : "active";

    showDialog(
      context: context,
      builder: (final BuildContext context) => AlertDialog(
        backgroundColor: ThemeConstants.primaryBlue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          isActive ? "Zima Dereva" : "Washa Dereva",
          style: ThemeConstants.headingStyle,
        ),
        content: Text(
          isActive
              ? "Je, una uhakika unataka kuzima ${driver.name}?"
              : "Je, una uhakika unataka kuwasha ${driver.name}?",
          style: const TextStyle(color: ThemeConstants.textSecondary),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Hapana",
              style: TextStyle(color: Colors.white),
            ),
          ),
          TextButton(
            onPressed: () async {
              final ScaffoldMessengerState scaffoldMessenger =
                  ScaffoldMessenger.of(context);
              Navigator.pop(context);

              try {
                // Call API to update driver status
                await _apiService.updateDriver(driver.id, <String, dynamic>{
                  "status": newStatus,
                });

                // Update local state
                final Driver updatedDriver = driver.copyWith(status: newStatus);
                final int index =
                    _drivers.indexWhere((final Driver d) => d.id == driver.id);
                if (index != -1) {
                  setState(() {
                    _drivers[index] = updatedDriver;
                  });
                  _filterDrivers();
                }

                if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        isActive
                            ? "${driver.name} amezimwa"
                            : "${driver.name} amewashwa",
                      ),
                      backgroundColor: isActive ? ThemeConstants.errorRed : ThemeConstants.successGreen,
                    ),
                  );
                }
              } on Exception catch (e) {
                if (mounted) {
                  _showErrorSnackBar("Hitilafu katika kubadilisha hali: $e");
                }
              }
            },
            child: Text(
              isActive ? "Zima" : "Washa",
              style: TextStyle(
                color: isActive ? ThemeConstants.errorRed : ThemeConstants.successGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteDriver(final Driver driver) {
    showDialog(
      context: context,
      builder: (final BuildContext context) => AlertDialog(
        backgroundColor: ThemeConstants.primaryBlue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Futa Dereva",
          style: ThemeConstants.headingStyle,
        ),
        content: Text(
          "Je, una uhakika unataka kumfuta ${driver.name}? Kitendo hiki hakiwezi kurudishwa.",
          style: const TextStyle(color: ThemeConstants.textSecondary),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Hapana",
              style: TextStyle(color: Colors.white),
            ),
          ),
          TextButton(
            onPressed: () async {
              final ScaffoldMessengerState scaffoldMessenger =
                  ScaffoldMessenger.of(context);
              Navigator.pop(context);

              try {
                // Call API to delete driver
                await _apiService.deleteDriver(driver.id);

                // Remove from local state
                setState(() {
                  _drivers.removeWhere((final Driver d) => d.id == driver.id);
                });
                _filterDrivers();

                if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text("${driver.name} amefutwa"),
                      backgroundColor: ThemeConstants.errorRed,
                    ),
                  );
                }
              } on Exception catch (e) {
                if (mounted) {
                  _showErrorSnackBar("Hitilafu katika kufuta dereva: $e");
                }
              }
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

  void _exportDrivers() {
    // TODO(dev): Implement export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Kipengele cha kuhamisha kinatengenezwa..."),
      ),
    );
  }

  void _importDrivers() {
    // TODO(dev): Implement import functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Kipengele cha kuingiza kinatengenezwa..."),
      ),
    );
  }
}

// Add Driver Dialog Widget
class _AddDriverDialog extends StatefulWidget {
  const _AddDriverDialog({required this.onDriverAdded});
  final VoidCallback onDriverAdded;

  @override
  State<_AddDriverDialog> createState() => _AddDriverDialogState();
}

class _AddDriverDialogState extends State<_AddDriverDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  // Form controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _licenseController = TextEditingController();
  final TextEditingController _vehicleNumberController =
      TextEditingController();

  // Form state
  bool _isLoading = false;
  String _selectedVehicleType = "bajaji";
  String _selectedStatus = "active";

  // Vehicle types
  final Map<String, String> _vehicleTypes = <String, String>{
    "bajaji": "Bajaji",
    "pikipiki": "Pikipiki",
    "gari": "Gari",
  };

  // Status options
  final Map<String, String> _statusOptions = <String, String>{
    "active": "Hai",
    "inactive": "Hahai",
  };

  // Using theme constants for colors

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _licenseController.dispose();
    _vehicleNumberController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _apiService.initialize();

      final Map<String, String?> driverData = <String, String?>{
        "name": _nameController.text.trim(),
        "email": _emailController.text.trim(),
        "phone": _phoneController.text.trim(),
        "license_number": _licenseController.text.trim(),
        "vehicle_number": _vehicleNumberController.text.trim().isNotEmpty
            ? _vehicleNumberController.text.trim()
            : null,
        "vehicle_type": _selectedVehicleType,
        "status": _selectedStatus,
      };

      await _apiService.createDriver(driverData);

      if (mounted) {
        Navigator.pop(context);
        widget.onDriverAdded();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text("Dereva ${_nameController.text} ameongezwa kikamilifu!"),
            backgroundColor: ThemeConstants.successGreen,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Hitilafu katika kuongeza dereva: $e"),
            backgroundColor: ThemeConstants.errorRed,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(final BuildContext context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: ThemeConstants.primaryBlue,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: <Widget>[
                    const Icon(
                      Icons.person_add,
                      color: Colors.white,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        "Ongeza Dereva Mpya",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // Form content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        // Personal Information Section
                        const Text(
                          "Taarifa za Kibinafsi",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Name field
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: "Jina Kamili *",
                            hintText: "Ingiza jina kamili la dereva",
                            prefixIcon: const Icon(Icons.person),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (final String? value) {
                            if (value == null || value.trim().isEmpty) {
                              return "Jina ni lazima";
                            }
                            if (value.trim().length < 2) {
                              return "Jina lazima liwe na angalau herufi 2";
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // Email field
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: "Barua Pepe *",
                            hintText: "mfano@email.com",
                            prefixIcon: const Icon(Icons.email),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (final String? value) {
                            if (value == null || value.trim().isEmpty) {
                              return "Barua pepe ni lazima";
                            }
                            if (!RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$")
                                .hasMatch(value)) {
                              return "Ingiza barua pepe sahihi";
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // Phone field
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: "Namba ya Simu *",
                            hintText: "+255XXXXXXXXX",
                            prefixIcon: const Icon(Icons.phone),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (final String? value) {
                            if (value == null || value.trim().isEmpty) {
                              return "Namba ya simu ni lazima";
                            }
                            if (value.trim().length < 10) {
                              return "Namba ya simu si sahihi";
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // License field
                        TextFormField(
                          controller: _licenseController,
                          decoration: InputDecoration(
                            labelText: "Namba ya Leseni *",
                            hintText: "DL123456789",
                            prefixIcon: const Icon(Icons.credit_card),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (final String? value) {
                            if (value == null || value.trim().isEmpty) {
                              return "Namba ya leseni ni lazima";
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 24),

                        // Vehicle Information Section
                        const Text(
                          "Taarifa za Gari (Hiari)",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Vehicle number field
                        TextFormField(
                          controller: _vehicleNumberController,
                          decoration: InputDecoration(
                            labelText: "Namba ya Gari",
                            hintText: "T123ABC (hiari)",
                            prefixIcon: const Icon(Icons.directions_car),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Vehicle type dropdown
                        DropdownButtonFormField<String>(
                          value: _selectedVehicleType,
                          decoration: InputDecoration(
                            labelText: "Aina ya Gari",
                            prefixIcon: const Icon(Icons.category),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items: _vehicleTypes.entries
                              .map(
                                (final MapEntry<String, String> entry) =>
                                    DropdownMenuItem<String>(
                                  value: entry.key,
                                  child: Text(
                                    entry.value,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (final String? value) {
                            setState(() {
                              _selectedVehicleType = value!;
                            });
                          },
                        ),

                        const SizedBox(height: 16),

                        // Status dropdown
                        DropdownButtonFormField<String>(
                          value: _selectedStatus,
                          decoration: InputDecoration(
                            labelText: "Hali ya Dereva",
                            prefixIcon: const Icon(Icons.toggle_on),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items: _statusOptions.entries
                              .map(
                                (final MapEntry<String, String> entry) =>
                                    DropdownMenuItem<String>(
                                  value: entry.key,
                                  child: Text(
                                    entry.value,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (final String? value) {
                            setState(() {
                              _selectedStatus = value!;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Action buttons
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: TextButton(
                        onPressed:
                            _isLoading ? null : () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: Colors.grey),
                          ),
                        ),
                        child: const Text(
                          "Ghairi",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ThemeConstants.successGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text(
                                "Ongeza Dereva",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}
