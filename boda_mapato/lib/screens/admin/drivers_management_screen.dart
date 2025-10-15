// ignore_for_file: avoid_dynamic_calls, unused_element
import "dart:async";
import "dart:convert";
import "dart:io";
import "package:file_picker/file_picker.dart";
import "package:flutter/foundation.dart" show kIsWeb;
import "package:flutter/material.dart";
import "package:intl/intl.dart";
import "package:path_provider/path_provider.dart";
import "package:provider/provider.dart";
import "../../constants/theme_constants.dart";
import "../../models/driver.dart";
import "../../services/api_service.dart";
import "../../services/localization_service.dart";
import "../../utils/responsive_helper.dart";
import "debts_management_screen.dart";
import "driver_agreement_screen.dart";
import "driver_history_screen.dart";
import "driver_prediction_screen.dart";

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
      if (!mounted) return;
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

    if (!mounted) return;
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

      if (!mounted) return;
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

      if (mounted) _filterDrivers();
    } on Exception catch (e) {
      if (mounted) _showErrorSnackBar("Hitilafu katika kupakia madereva: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  void _filterDrivers() {
    if (!mounted) return;
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
    ThemeConstants.showErrorSnackBar(context, message);
  }

  @override
  Widget build(final BuildContext context) {
    ResponsiveHelper.init(context);
    return Consumer<LocalizationService>(
      builder: (context, localizationService, child) => ThemeConstants.buildResponsiveScaffold(
        context,
        title: localizationService.translate('drivers_management'),
        body: _isLoading
            ? ThemeConstants.buildResponsiveLoadingWidget(context)
            : _buildMainContent(localizationService),
        floatingActionButton: _buildFloatingActionButton(localizationService),
      ),
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
                case "template":
                  _exportDriversTemplate();
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
              const PopupMenuItem(
                value: "template",
                child: Row(
                  children: <Widget>[
                    Icon(Icons.description, color: Colors.green),
                    SizedBox(width: 8),
                    Text("Pakua Template (CSV)"),
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
                color: ThemeConstants
                    .textSecondary, // Light text on blue background
              ),
            ),
          ],
        ),
      );

  Widget _buildMainContent(LocalizationService localizationService) => Column(
        children: <Widget>[
          _buildSearchAndFilter(localizationService),
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

  Widget _buildSearchAndFilter(LocalizationService localizationService) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: <Widget>[
            // Search bar - Blue themed
            DecoratedBox(
              decoration: BoxDecoration(
                color: ThemeConstants.primaryBlue.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                ),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                style: ThemeConstants.bodyStyle,
                decoration: InputDecoration(
                  hintText: localizationService.translate('search_drivers'),
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
        style: const TextStyle(
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
            const Icon(
              Icons.people_outline,
              size: 80,
              color: ThemeConstants
                  .textSecondary, // Light text for blue background
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? "Hakuna dereva aliyepatikana"
                  : "Hakuna madereva bado",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color:
                    ThemeConstants.textPrimary, // White text on blue background
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty
                  ? "Jaribu kutafuta kwa jina lingine"
                  : "Ongeza dereva wa kwanza",
              style: const TextStyle(
                fontSize: 14,
                color: ThemeConstants
                    .textSecondary, // Light text on blue background
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
              // Defer load to next frame to avoid setState during build
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  unawaited(_loadDrivers());
                }
              });
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
                        : Colors.grey
                            .shade600, // Darker grey for better contrast on blue
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
                                color: ThemeConstants
                                    .textPrimary, // White text on blue background
                              ),
                            ),
                          ),
                          // Agreement status indicator
                          if (!driver.hasCompletedAgreement)
                            Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: ThemeConstants.primaryOrange,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: ThemeConstants.primaryOrange,
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Icon(
                                    Icons.assignment_outlined,
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                  SizedBox(width: 2),
                                  Text(
                                    "MAKUBALIANO",
                                    style: TextStyle(
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          // Driver status indicator
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
                                color: isActive
                                    ? ThemeConstants.successGreen
                                    : Colors.grey.shade400,
                              ),
                            ),
                            child: Text(
                              isActive ? "HAI" : "HAHAI",
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors
                                    .white, // White text for better contrast
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
                          color: ThemeConstants
                              .textSecondary, // Light text on blue background
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
                              color: ThemeConstants
                                  .textSecondary, // Light text on blue background
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
                          Icon(Icons.visibility,
                              color: ThemeConstants.primaryBlue),
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
                    const PopupMenuItem(
                      value: "history",
                      child: Row(
                        children: <Widget>[
                          Icon(Icons.history,
                              color: ThemeConstants.primaryOrange),
                          SizedBox(width: 8),
                          Text("Ona Historia"),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: "predict",
                      child: Row(
                        children: <Widget>[
                          Icon(Icons.trending_up, color: Colors.greenAccent),
                          SizedBox(width: 8),
                          Text("Utabiri"),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: "record_payment",
                      child: Row(
                        children: <Widget>[
                          Icon(Icons.payments, color: ThemeConstants.primaryOrange),
                          SizedBox(width: 8),
                          Text("Rekodi Malipo"),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: "record_debt",
                      child: Row(
                        children: <Widget>[
                          Icon(Icons.receipt_long, color: Colors.amber),
                          SizedBox(width: 8),
                          Text("Rekodi Deni"),
                        ],
                      ),
                    ),
                    // Show "Complete Agreement" option if not completed
                    if (!driver.hasCompletedAgreement)
                      const PopupMenuItem(
                        value: "complete_agreement",
                        child: Row(
                          children: <Widget>[
                            Icon(Icons.assignment_outlined,
                                color: ThemeConstants.primaryOrange),
                            SizedBox(width: 8),
                            Text("Kamilisha Makubaliano"),
                          ],
                        ),
                      ),
                    PopupMenuItem(
                      value: isActive ? "deactivate" : "activate",
                      child: Row(
                        children: <Widget>[
                          Icon(
                            isActive ? Icons.block : Icons.check_circle,
                            color: isActive
                                ? ThemeConstants.errorRed
                                : ThemeConstants.successGreen,
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
              color:
                  ThemeConstants.textSecondary, // Light text on blue background
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );

  Widget _buildFloatingActionButton(LocalizationService localizationService) => FloatingActionButton.extended(
        onPressed: _showAddDriverDialog,
        backgroundColor: ThemeConstants.primaryOrange,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(
          localizationService.translate('add_driver'),
          style: const TextStyle(fontWeight: FontWeight.w600),
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
        // If driver hasn't completed agreement, redirect to agreement screen
        if (!driver.hasCompletedAgreement) {
          _navigateToDriverAgreement(driver);
        } else {
          _fetchAndShowDriverDetails(driver);
        }
      case "edit":
        _showEditDriverDialog(driver);
      case "history":
        _navigateToDriverHistory(driver);
      case "predict":
        _navigateToDriverPrediction(driver);
      case "record_payment":
        Navigator.of(context).pushNamed('/payments');
      case "record_debt":
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => DebtsManagementScreen(initialDriverId: driver.id),
          ),
        );
      case "activate":
      case "deactivate":
        _toggleDriverStatus(driver);
      case "delete":
        _confirmDeleteDriver(driver);
      case "complete_agreement":
        _navigateToDriverAgreement(driver);
    }
  }

  void _showDriverDetails(
    final Driver driver, {
    String? daysText,
    String? paymentsText,
    String? debtText,
  }) {
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
                "Chombo:",
                "${driver.vehicleNumber ?? "N/A"} (${driver.vehicleType ?? "N/A"})",
              ),
              _buildDetailRow(
                "Hali:",
                driver.status == "active" ? "Hai" : "Hahai",
              ),
              _buildDetailRow(
                "Jumla ya Malipo:",
                paymentsText ?? "TSH ${_formatThousands(driver.totalPayments)}",
              ),
              _buildDetailRow(
                "Leo ni siku ya:",
                daysText ?? "-",
              ),
              _buildDetailRow(
                "Deni:",
                debtText ?? "TSH ${_formatThousands(0)}",
              ),
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

  String _formatThousands(num value) => NumberFormat('#,##0', 'sw_TZ').format(value);

  DateTime? _parseDate(final Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) {
      try {
        return DateTime.parse(value);
      } on Exception catch (_) {
        return null;
      }
    }
    return null;
  }

  int _countWorkingDaysInclusive(
    final DateTime start,
    final DateTime end, {
    required final bool weekendsCountable,
    required final bool saturdayIncluded,
    required final bool sundayIncluded,
  }) {
    DateTime s = start;
    DateTime e = end;
    if (e.isBefore(s)) {
      final DateTime tmp = s;
      s = e;
      e = tmp;
    }
    int count = 0;
    DateTime d = DateTime(s.year, s.month, s.day);
    final DateTime last = DateTime(e.year, e.month, e.day);
    while (!d.isAfter(last)) {
      final int wd = d.weekday; // 1=Mon..7=Sun
      bool include = true;
      if (!weekendsCountable) {
        if (wd == DateTime.saturday || wd == DateTime.sunday) include = false;
      } else {
        if (wd == DateTime.saturday && !saturdayIncluded) include = false;
        if (wd == DateTime.sunday && !sundayIncluded) include = false;
      }
      if (include) count++;
      d = d.add(const Duration(days: 1));
    }
    // Ensure at least 1 day when start == end and included
    return count == 0 ? 1 : count;
  }

  Future<void> _fetchAndShowDriverDetails(final Driver driver) async {
    // Show a small loading dialog while fetching
    unawaited(showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        backgroundColor: ThemeConstants.primaryBlue,
        content: SizedBox(
          height: 64,
          child: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ),
      ),
    ));

    try {
      await _apiService.initialize();
      final Map<String, dynamic> resp =
          await _apiService.getDriverById(driver.id);

      // Handle both {data: {...}} and direct map
      final dynamic data = resp.containsKey('data') ? resp['data'] : resp;
      if (data is! Map<String, dynamic>) {
        throw Exception('Invalid driver response');
      }

      final Driver fresh = Driver.fromJson(data);

      // Fetch agreement (for days and totals) and debt summary in parallel
      final futures = await Future.wait<List<dynamic>>([
        () async {
          try {
            final Map<String, dynamic> a =
                await _apiService.getDriverAgreementByDriverId(fresh.id);
            return [a];
          } on Exception catch (_) {
            return [];
          }
        }(),
        () async {
          try {
            final Map<String, dynamic> d =
                await _apiService.getDriverDebtSummary(fresh.id);
            return [d];
          } on Exception catch (_) {
            return [];
          }
        }(),
      ]);

      Map<String, dynamic>? agreementData;
      if (futures.isNotEmpty && futures[0].isNotEmpty) {
        final Map<String, dynamic> a = futures[0][0] as Map<String, dynamic>;
        final dynamic inner = a['data'] ?? a;
        if (inner is Map<String, dynamic>) agreementData = inner;
      }

      Map<String, dynamic>? debtData;
      if (futures.length > 1 && futures[1].isNotEmpty) {
        final Map<String, dynamic> d = futures[1][0] as Map<String, dynamic>;
        final dynamic inner = d['data'] ?? d;
        if (inner is Map<String, dynamic>) debtData = inner;
      }

      // Build computed strings
      String? daysText;
      String? paymentsText;
      String? debtText;

      // Payments text (and remaining if agreement total provided)
      final double totalPaid = fresh.totalPayments;
      double? agreementTotal;
      if (agreementData != null) {
        final dynamic total = agreementData['total_amount'] ??
            agreementData['total_profit'] ??
            agreementData['grand_total'] ??
            agreementData['expected_total'];
        if (total is num) agreementTotal = total.toDouble();
      }
      if (agreementTotal != null && agreementTotal > 0) {
        paymentsText =
            "TSH ${_formatThousands(totalPaid)} kati ya ${_formatThousands(agreementTotal)}";
      } else {
        paymentsText = "TSH ${_formatThousands(totalPaid)}";
      }

      // Debt text
      if (debtData != null) {
        final dynamic unpaid = debtData['total_unpaid'] ??
            debtData['unpaid_total'] ??
            debtData['outstanding_amount'] ??
            debtData['total_debt'];
        if (unpaid is num) {
          debtText = "TSH ${_formatCurrency(unpaid.toDouble())}";
        }
      }

      // Days text using agreement dates and weekend rules
      if (agreementData != null) {
        try {
          final DateTime? start = _parseDate(agreementData['start_date']);
          final DateTime? end = _parseDate(agreementData['end_date']);
          final bool weekendsCountable =
              (agreementData['weekends_countable'] ?? true) == true;
          final bool sat = (agreementData['saturday_included'] ?? true) == true;
          final bool sun = (agreementData['sunday_included'] ?? true) == true;
          if (start != null) {
            final DateTime today = DateTime.now();
            int dayNumber = today.difference(start).inDays + 1; // inclusive
            if (dayNumber < 1) dayNumber = 1;

            int? totalDays;
            if (end != null) {
              totalDays = _countWorkingDaysInclusive(start, end,
                  weekendsCountable: weekendsCountable,
                  saturdayIncluded: sat,
                  sundayIncluded: sun);
              if (dayNumber > totalDays) dayNumber = totalDays;
            }

            daysText = totalDays != null
                ? "$dayNumber kati ya $totalDays"
                : "$dayNumber";
          }
        } on Exception catch (_) {}
      }

      if (mounted) {
        Navigator.pop(context); // close loader
        _showDriverDetails(
          fresh,
          daysText: daysText,
          paymentsText: paymentsText,
          debtText: debtText,
        );
      }
    } on Exception catch (e) {
      if (mounted) {
        Navigator.pop(context); // close loader
        // Fall back to showing existing data, but inform user
        _showDriverDetails(driver);
        _showErrorSnackBar('Imeshindikana kupata taarifa mpya za dereva: $e');
      }
    }
  }

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
    showDialog(
      context: context,
      builder: (final BuildContext context) => _EditDriverDialog(
        driver: driver,
        onDriverUpdated: (final Driver updated) {
          // Update local list and filters
          final int idx = _drivers.indexWhere((final d) => d.id == updated.id);
          if (idx != -1) {
            setState(() {
              _drivers[idx] = updated;
            });
            _filterDrivers();
          } else {
            _loadDrivers(refresh: true);
          }
        },
      ),
    );
  }

  void _navigateToDriverHistory(final Driver driver) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (final BuildContext context) => DriverHistoryScreen(
          driver: driver,
        ),
      ),
    );
  }

  void _navigateToDriverPrediction(final Driver driver) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (final BuildContext context) => DriverPredictionScreen(
          driverId: driver.id,
          driverName: driver.name,
        ),
      ),
    );
  }

  void _navigateToDriverAgreement(final Driver driver) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (final BuildContext context) => DriverAgreementScreen(
          driverId: driver.id,
          driverName: driver.name,
          onAgreementCreated: () {
            // Refresh the drivers list when agreement is completed
            _loadDrivers(refresh: true);
          },
        ),
      ),
    );
  }

  void _toggleDriverStatus(final Driver driver) {
    final bool isActive = driver.status == "active";
    final String newStatus = isActive ? "inactive" : "active";
    // Capture root context to use after async gaps inside dialog callbacks
    final BuildContext rootContext = context;

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
              Navigator.pop(context);

              try {
                // Call API to update driver status
                await _apiService.updateDriver(driver.id, <String, dynamic>{
                  "status": newStatus,
                });

                if (!mounted) return;

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

                final String message = isActive
                    ? "${driver.name} amezimwa"
                    : "${driver.name} amewashwa";
                if (!mounted) return;
                if (isActive) {
                  ThemeConstants.showErrorSnackBar(rootContext, message);
                } else {
                  ThemeConstants.showSuccessSnackBar(rootContext, message);
                }
              } on Exception catch (e) {
                if (!mounted) return;
                _showErrorSnackBar("Hitilafu katika kubadilisha hali: $e");
              }
            },
            child: Text(
              isActive ? "Zima" : "Washa",
              style: TextStyle(
                color: isActive
                    ? ThemeConstants.errorRed
                    : ThemeConstants.successGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteDriver(final Driver driver) {
    // Capture root context for safe snackbar usage after awaits
    final BuildContext rootContext = context;
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
              Navigator.pop(context);

              try {
                // Call API to delete driver
                await _apiService.deleteDriver(driver.id);

                if (!mounted) return;
                // Remove from local state
                setState(() {
                  _drivers.removeWhere((final Driver d) => d.id == driver.id);
                });
                _filterDrivers();

                if (!mounted) return;
                ThemeConstants.showErrorSnackBar(rootContext, "${driver.name} amefutwa");
              } on Exception catch (e) {
                if (!mounted) return;
                _showErrorSnackBar("Hitilafu katika kufuta dereva: $e");
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

  Future<void> _exportDrivers() async {
    if (kIsWeb) {
      ThemeConstants.showErrorSnackBar(context, "Uhamishaji wa faili haupatikani kwenye web. Tumia simu/desktop.");
      return;
    }

    try {
      final String csv = _buildDriversCsv(_drivers);

      final Directory dir = await getApplicationDocumentsDirectory();
      final String timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final String filePath = "${dir.path}/boda_drivers_$timestamp.csv";

      final File file = File(filePath);
      await file.writeAsString(csv);

      if (!mounted) return;
      ThemeConstants.showSuccessSnackBar(context, "Faili limehifadhiwa: $filePath");
    } on Exception catch (e) {
      if (!mounted) return;
      _showErrorSnackBar("Imeshindikana kuhamisha data: $e");
    }
  }

  String _buildDriversCsv(final List<Driver> drivers) {
    String esc(String? v) {
      final String s = (v ?? '').replaceAll('"', '""');
      if (s.contains(',') || s.contains('"') || s.contains('\n')) {
        return '"$s"';
      }
      return s;
    }

    final String header = [
      'id',
      'name',
      'email',
      'phone',
      'vehicle_number',
      'vehicle_type',
      'status',
      'total_payments',
      'rating',
      'trips_completed',
      'joined_date'
    ].join(',');

    final List<String> lines = <String>[
      header,
      ...drivers.map((d) => [
            esc(d.id),
            esc(d.name),
            esc(d.email),
            esc(d.phone),
            esc(d.vehicleNumber),
            esc(d.vehicleType),
            esc(d.status),
            d.totalPayments.toStringAsFixed(0),
            d.rating.toStringAsFixed(1),
            d.tripsCompleted.toString(),
            DateFormat('yyyy-MM-dd').format(d.joinedDate),
          ].join(',')),
    ];

    return lines.join('\n');
  }

  Future<void> _importDrivers() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: <String>['csv'],
        withData: true,
      );
      if (result == null) return;

      String csvContent;
      final PlatformFile file = result.files.first;
      if (kIsWeb || file.bytes != null) {
        csvContent = utf8.decode(file.bytes!);
      } else if (file.path != null) {
        csvContent = await File(file.path!).readAsString();
      } else {
        _showErrorSnackBar("Imeshindikana kusoma faili");
        return;
      }

      // Parse CSV
      final List<Map<String, String>> rows = _parseDriversCsv(csvContent);
      if (rows.isEmpty) {
        if (mounted) _showErrorSnackBar("Hakuna rekodi kwenye faili");
        return;
      }
      // Validate headers
      final Set<String> required = {'name', 'phone_number'};
      final Set<String> headers = rows.first.keys.toSet();
      if (!headers.containsAll(required)) {
        if (mounted) {
          _showErrorSnackBar("Faili halina vichwa sahihi. Vinavyotakiwa: name, phone_number");
        }
        return;
      }

      // Show progress
      int success = 0;
      int failed = 0;

      for (final Map<String, String> r in rows) {
        try {
          final Map<String, dynamic> payload = <String, dynamic>{
            'name': r['name'] ?? r['full_name'] ?? '',
            'email': r['email'] ?? '',
            'phone_number': r['phone'] ?? r['phone_number'] ?? '',
            'license_number': r['license_number'] ?? r['license'] ?? '',
            'vehicle_number': r['vehicle_number'],
            'vehicle_type': r['vehicle_type']?.toLowerCase(),
            'status': r['status']?.toLowerCase() ?? 'active',
          };
          await _apiService.createDriver(payload);
          success++;
        } on Exception {
          failed++;
        }
      }

      final String message = "Uingizaji umekamilika: $success mafanikio, $failed imeshindikana";
      if (!mounted) return;
      if (failed == 0) {
        ThemeConstants.showSuccessSnackBar(context, message);
      } else {
        ThemeConstants.showWarningSnackBar(context, message);
      }

      // Refresh list
      await _loadDrivers(refresh: true);
    } on Exception catch (e) {
      if (mounted) _showErrorSnackBar("Imeshindikana kuingiza data: $e");
    }
  }

  Future<void> _exportDriversTemplate() async {
    if (kIsWeb) {
      ThemeConstants.showErrorSnackBar(context, "Upakuaji wa faili kwenye web haupatikani");
      return;
    }
    try {
      const String header = 'name,email,phone_number,license_number,vehicle_number,vehicle_type,status';
      const String example = 'John Doe,john@example.com,+255712345678,DL123456,T123ABC,pikipiki,active';
      const String csv = '$header\n$example\n';
      final Directory dir = await getApplicationDocumentsDirectory();
      final String filePath = "${dir.path}/drivers_template.csv";
      await File(filePath).writeAsString(csv);
      if (!mounted) return;
      ThemeConstants.showSuccessSnackBar(context, "Template imehifadhiwa: $filePath");
    } on Exception catch (e) {
      _showErrorSnackBar("Imeshindikana kutengeneza template: $e");
    }
  }

  List<Map<String, String>> _parseDriversCsv(String content) {
    final List<String> lines = content.split(RegExp(r"\r?\n"));
    if (lines.isEmpty) return <Map<String, String>>[];
    final List<String> headers = _splitCsvLine(lines.first);
    final List<Map<String, String>> rows = <Map<String, String>>[];

    for (int i = 1; i < lines.length; i++) {
      final String line = lines[i].trim();
      if (line.isEmpty) continue;
      final List<String> cols = _splitCsvLine(line);
      final Map<String, String> row = <String, String>{};
      for (int j = 0; j < headers.length && j < cols.length; j++) {
        row[headers[j].trim().toLowerCase()] = cols[j];
      }
      rows.add(row);
    }
    return rows;
  }

  List<String> _splitCsvLine(String line) {
    final List<String> out = <String>[];
    final StringBuffer cur = StringBuffer();
    bool inQuotes = false;
    for (int i = 0; i < line.length; i++) {
      final String ch = line[i];
      if (ch == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          cur.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (ch == ',' && !inQuotes) {
        out.add(cur.toString());
        cur.clear();
      } else {
        cur.write(ch);
      }
    }
    out.add(cur.toString());
    return out;
  }
}

// Edit Driver Dialog Widget
class _EditDriverDialog extends StatefulWidget {
  const _EditDriverDialog(
      {required this.driver, required this.onDriverUpdated});
  final Driver driver;
  final void Function(Driver updated) onDriverUpdated;

  @override
  State<_EditDriverDialog> createState() => _EditDriverDialogState();
}

class _EditDriverDialogState extends State<_EditDriverDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  // Controllers
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _licenseController;
  late final TextEditingController _vehicleNumberController;

  bool _isSaving = false;
  late String _selectedVehicleType;
  late String _selectedStatus;

  final Map<String, String> _vehicleTypes = <String, String>{
    "bajaji": "Bajaji",
    "pikipiki": "Pikipiki",
    "gari": "Gari",
  };
  final Map<String, String> _statusOptions = <String, String>{
    "active": "Hai",
    "inactive": "Hahai",
  };

  InputDecoration _inputDecoration(String label, {IconData? icon}) {
    final OutlineInputBorder border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.white.withOpacity(0.25)),
    );
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: ThemeConstants.textSecondary),
      prefixIcon:
          icon != null ? Icon(icon, color: ThemeConstants.textSecondary) : null,
      filled: true,
      fillColor: ThemeConstants.primaryBlue.withOpacity(0.35),
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide:
            const BorderSide(color: ThemeConstants.primaryOrange, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  @override
  void initState() {
    super.initState();
    final d = widget.driver;
    _nameController = TextEditingController(text: d.name);
    _emailController = TextEditingController(text: d.email);
    _phoneController = TextEditingController(text: d.phone);
    _licenseController = TextEditingController(text: d.licenseNumber);
    _vehicleNumberController =
        TextEditingController(text: d.vehicleNumber ?? "");
    _selectedVehicleType = (d.vehicleType ?? "bajaji").toLowerCase();
    if (!_vehicleTypes.keys.contains(_selectedVehicleType)) {
      _selectedVehicleType = "bajaji";
    }
    _selectedStatus = d.status;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _licenseController.dispose();
    _vehicleNumberController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      await _apiService.initialize();
      final Map<String, dynamic> payload = <String, dynamic>{
        "name": _nameController.text.trim(),
        "email": _emailController.text.trim(),
        // backend expects phone_number
        "phone_number": _phoneController.text.trim(),
        "license_number": _licenseController.text.trim(),
        "vehicle_number": _vehicleNumberController.text.trim().isNotEmpty
            ? _vehicleNumberController.text.trim()
            : null,
        "vehicle_type": _selectedVehicleType,
        "status": _selectedStatus,
      };

      await _apiService.updateDriver(widget.driver.id, payload);

      final Driver updated = widget.driver.copyWith(
        name: payload["name"] as String?,
        email: payload["email"] as String?,
        phone: payload["phone"] as String?,
        licenseNumber: payload["license_number"] as String?,
        vehicleNumber: payload["vehicle_number"] as String?,
        vehicleType: payload["vehicle_type"] as String?,
        status: payload["status"] as String?,
      );

      if (!mounted) return;
      Navigator.pop(context);
      widget.onDriverUpdated(updated);

      ThemeConstants.showSuccessSnackBar(context, "Taarifa za dereva zimehifadhiwa.");
    } on Exception catch (e) {
      if (!mounted) return;
      ThemeConstants.showErrorSnackBar(context, "Hitilafu katika kuhariri: $e");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: ThemeConstants.primaryBlue,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        "Hariri ${widget.driver.name}",
        style: ThemeConstants.headingStyle,
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(color: ThemeConstants.textPrimary),
                  decoration: _inputDecoration("Jina", icon: Icons.person),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? "Weka jina" : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  style: const TextStyle(color: ThemeConstants.textPrimary),
                  decoration: _inputDecoration("Barua pepe", icon: Icons.email),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneController,
                  style: const TextStyle(color: ThemeConstants.textPrimary),
                  decoration: _inputDecoration("Simu", icon: Icons.phone),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? "Weka namba ya simu"
                      : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _licenseController,
                  style: const TextStyle(color: ThemeConstants.textPrimary),
                  decoration: _inputDecoration("Namba ya Leseni",
                      icon: Icons.credit_card),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _vehicleNumberController,
                  style: const TextStyle(color: ThemeConstants.textPrimary),
                  decoration: _inputDecoration("Namba ya Chombo",
                      icon: Icons.directions_car),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedVehicleType,
                        dropdownColor: ThemeConstants.primaryBlue,
                        style:
                            const TextStyle(color: ThemeConstants.textPrimary),
                        decoration: _inputDecoration("Aina ya Chombo",
                            icon: Icons.category),
                        items: _vehicleTypes.entries
                            .map((e) => DropdownMenuItem<String>(
                                  value: e.key,
                                  child: Text(e.value),
                                ))
                            .toList(),
                        onChanged: (val) => setState(() =>
                            _selectedVehicleType = val ?? _selectedVehicleType),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedStatus,
                        dropdownColor: ThemeConstants.primaryBlue,
                        style:
                            const TextStyle(color: ThemeConstants.textPrimary),
                        decoration:
                            _inputDecoration("Hali", icon: Icons.toggle_on),
                        items: _statusOptions.entries
                            .map((e) => DropdownMenuItem<String>(
                                  value: e.key,
                                  child: Text(e.value),
                                ))
                            .toList(),
                        onChanged: (val) => setState(
                            () => _selectedStatus = val ?? _selectedStatus),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text("Ghairi", style: TextStyle(color: Colors.white)),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: ThemeConstants.primaryOrange,
            foregroundColor: Colors.white,
          ),
          child: _isSaving
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text("Hifadhi"),
        ),
      ],
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
  final TextEditingController _licenseExpiryController =
      TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _emergencyContactController =
      TextEditingController();
  final TextEditingController _nationalIdController = TextEditingController();
  final TextEditingController _dateOfBirthController = TextEditingController();
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

  InputDecoration _getBlueInputDecoration(String labelText,
      {required IconData icon, String? hintText}) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      labelStyle: const TextStyle(color: ThemeConstants.textSecondary),
      hintStyle: const TextStyle(color: ThemeConstants.textSecondary),
      prefixIcon: Icon(icon, color: ThemeConstants.textSecondary),
      filled: true,
      fillColor: ThemeConstants.primaryBlue.withOpacity(0.3),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            const BorderSide(color: ThemeConstants.primaryOrange, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: ThemeConstants.errorRed, width: 2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: ThemeConstants.errorRed, width: 2),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _licenseController.dispose();
    _licenseExpiryController.dispose();
    _addressController.dispose();
    _emergencyContactController.dispose();
    _nationalIdController.dispose();
    _dateOfBirthController.dispose();
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
        // backend expects phone_number
        "phone_number": _phoneController.text.trim(),
        "license_number": _licenseController.text.trim(),
        "license_expiry": _licenseExpiryController.text.trim(),
        "address": _addressController.text.trim(),
        "emergency_contact": _emergencyContactController.text.trim(),
        "national_id": _nationalIdController.text.trim().isNotEmpty
            ? _nationalIdController.text.trim()
            : null,
        "date_of_birth": _dateOfBirthController.text.trim().isNotEmpty
            ? _dateOfBirthController.text.trim()
            : null,
        "vehicle_number": _vehicleNumberController.text.trim().isNotEmpty
            ? _vehicleNumberController.text.trim()
            : null,
        "vehicle_type": _selectedVehicleType,
        "status": _selectedStatus,
      };

      final response = await _apiService.createDriver(driverData);

      if (mounted) {
        Navigator.pop(context);
        widget.onDriverAdded();

        ThemeConstants.showSuccessSnackBar(context, "Dereva ${_nameController.text} ameongezwa kikamilifu!");

        // Debug: Print the response
        debugPrint('Driver creation response: $response');

        // Navigate to Driver Agreement screen
        if (response['status'] == 'success') {
          final dynamic data = response['data'];
          final String driverId = data is Map<String, dynamic>
              ? (data['id']?.toString() ?? '')
              : '';
          final String driverName = _nameController.text.trim();

          debugPrint('Driver ID extracted: $driverId');
          debugPrint('Driver Name: $driverName');

          if (driverId.isNotEmpty) {
            debugPrint('Navigating to Driver Agreement Screen');
            try {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => DriverAgreementScreen(
                    driverId: driverId,
                    driverName: driverName,
                    onAgreementCreated: () {
                      // Refresh the drivers list when agreement is created
                      widget.onDriverAdded();
                    },
                  ),
                ),
              );
              if (!mounted) return;
              debugPrint('Successfully navigated to Driver Agreement Screen');
            } on Exception catch (navError) {
              debugPrint(
                  'Error navigating to Driver Agreement Screen: $navError');
              if (!mounted) return;
              // Show error to user
              ThemeConstants.showErrorSnackBar(context, 'Hitilafu katika kuongoza kwenye makubaliano: $navError');
            }
          } else {
            debugPrint(
                'Driver ID is empty, cannot navigate to agreement screen');
          }
        } else {
          debugPrint('Response status is not success or data is null');
          debugPrint('Status: ${response['status']}');
          debugPrint('Data: ${response['data']}');
        }
      }
    } on Exception catch (e) {
      if (mounted) {
        ThemeConstants.showErrorSnackBar(context, "Hitilafu katika kuongeza dereva: $e");
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
  Widget build(final BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final maxDialogHeight = screenHeight * 0.9; // 90% of screen height

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: ThemeConstants.primaryBlue,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 500,
          maxHeight: maxDialogHeight,
        ),
        decoration: const BoxDecoration(
          color: ThemeConstants.primaryBlue,
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
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
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height * 0.6,
                  ),
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
                            color: ThemeConstants.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Name field
                        TextFormField(
                          controller: _nameController,
                          style: const TextStyle(
                              color: ThemeConstants.textPrimary),
                          decoration: _getBlueInputDecoration(
                            "Jina Kamili *",
                            icon: Icons.person,
                            hintText: "Ingiza jina kamili la dereva",
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
                          style: const TextStyle(
                              color: ThemeConstants.textPrimary),
                          decoration: _getBlueInputDecoration(
                            "Barua Pepe *",
                            icon: Icons.email,
                            hintText: "mfano@email.com",
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
                          style: const TextStyle(
                              color: ThemeConstants.textPrimary),
                          decoration: _getBlueInputDecoration(
                            "Namba ya Simu *",
                            icon: Icons.phone,
                            hintText: "+255XXXXXXXXX",
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
                          style: const TextStyle(
                              color: ThemeConstants.textPrimary),
                          decoration: _getBlueInputDecoration(
                            "Namba ya Leseni *",
                            icon: Icons.credit_card,
                            hintText: "DL123456789",
                          ),
                          validator: (final String? value) {
                            if (value == null || value.trim().isEmpty) {
                              return "Namba ya leseni ni lazima";
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // License expiry field
                        TextFormField(
                          controller: _licenseExpiryController,
                          readOnly: true,
                          style: const TextStyle(
                              color: ThemeConstants.textPrimary),
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate:
                                  DateTime.now().add(const Duration(days: 365)),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now()
                                  .add(const Duration(days: 365 * 10)),
                            );
                            if (date != null) {
                              _licenseExpiryController.text =
                                  '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                            }
                          },
                          decoration: _getBlueInputDecoration(
                            "Tarehe ya Mwisho wa Leseni *",
                            icon: Icons.calendar_today,
                            hintText: "Chagua tarehe",
                          ).copyWith(
                            suffixIcon: const Icon(Icons.arrow_drop_down,
                                color: ThemeConstants.textSecondary),
                          ),
                          validator: (final String? value) {
                            if (value == null || value.trim().isEmpty) {
                              return "Tarehe ya mwisho wa leseni ni lazima";
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // Address field
                        TextFormField(
                          controller: _addressController,
                          maxLines: 3,
                          style: const TextStyle(
                              color: ThemeConstants.textPrimary),
                          decoration: _getBlueInputDecoration(
                            "Anwani *",
                            icon: Icons.location_on,
                            hintText: "Ingiza anwani kamili",
                          ),
                          validator: (final String? value) {
                            if (value == null || value.trim().isEmpty) {
                              return "Anwani ni lazima";
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // Emergency contact field
                        TextFormField(
                          controller: _emergencyContactController,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(
                              color: ThemeConstants.textPrimary),
                          decoration: _getBlueInputDecoration(
                            "Simu ya Dharura *",
                            icon: Icons.emergency,
                            hintText: "+255XXXXXXXXX",
                          ),
                          validator: (final String? value) {
                            if (value == null || value.trim().isEmpty) {
                              return "Simu ya dharura ni lazima";
                            }
                            if (value.trim().length < 10) {
                              return "Namba ya simu si sahihi";
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // National ID field (optional)
                        TextFormField(
                          controller: _nationalIdController,
                          style: const TextStyle(
                              color: ThemeConstants.textPrimary),
                          decoration: _getBlueInputDecoration(
                            "Namba ya Kitambulisho (Hiari)",
                            icon: Icons.badge,
                            hintText: "Ingiza namba ya kitambulisho",
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Date of birth field (optional)
                        TextFormField(
                          controller: _dateOfBirthController,
                          readOnly: true,
                          style: const TextStyle(
                              color: ThemeConstants.textPrimary),
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now()
                                  .subtract(const Duration(days: 365 * 25)),
                              firstDate: DateTime.now()
                                  .subtract(const Duration(days: 365 * 80)),
                              lastDate: DateTime.now()
                                  .subtract(const Duration(days: 365 * 18)),
                            );
                            if (date != null) {
                              _dateOfBirthController.text =
                                  '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                            }
                          },
                          decoration: _getBlueInputDecoration(
                            "Tarehe ya Kuzaliwa (Hiari)",
                            icon: Icons.cake,
                            hintText: "Chagua tarehe ya kuzaliwa",
                          ).copyWith(
                            suffixIcon: const Icon(Icons.arrow_drop_down,
                                color: ThemeConstants.textSecondary),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Vehicle Information Section
                        const Text(
                          "Taarifa za Gari (Hiari)",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: ThemeConstants.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Vehicle number field
                        TextFormField(
                          controller: _vehicleNumberController,
                          style: const TextStyle(
                              color: ThemeConstants.textPrimary),
                          decoration: _getBlueInputDecoration(
                            "Namba ya Chombo",
                            icon: Icons.directions_car,
                            hintText: "T123ABC (hiari)",
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Vehicle type dropdown
                        DropdownButtonFormField<String>(
                          value: _selectedVehicleType,
                          dropdownColor: ThemeConstants.primaryBlue,
                          style: const TextStyle(
                              color: ThemeConstants.textPrimary),
                          decoration: _getBlueInputDecoration(
                            "Aina ya Chombo",
                            icon: Icons.category,
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
                          dropdownColor: ThemeConstants.primaryBlue,
                          style: const TextStyle(
                              color: ThemeConstants.textPrimary),
                          decoration: _getBlueInputDecoration(
                            "Hali ya Dereva",
                            icon: Icons.toggle_on,
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
            ),

            // Action buttons
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: ThemeConstants.primaryBlue.withOpacity(0.3),
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
                          side: const BorderSide(
                              color: ThemeConstants.textSecondary),
                        ),
                      ),
                      child: const Text(
                        "Ghairi",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: ThemeConstants.textPrimary,
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
}
