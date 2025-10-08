import "package:flutter/material.dart";
import "package:flutter_screenutil/flutter_screenutil.dart";

import "../../models/vehicle.dart";
import "../../services/api_service.dart";
import "../../widgets/custom_button.dart";
import "../../widgets/custom_card.dart";

class VehiclesManagementScreen extends StatefulWidget {
  const VehiclesManagementScreen({super.key});

  @override
  State<VehiclesManagementScreen> createState() => _VehiclesManagementScreenState();
}

class _VehiclesManagementScreenState extends State<VehiclesManagementScreen>
    with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  
  bool _isLoading = true;
  List<Vehicle> _vehicles = <Vehicle>[];
  List<Vehicle> _filteredVehicles = <Vehicle>[];
  String _searchQuery = "";
  String _selectedFilter = "all"; // all, active, inactive, assigned, unassigned
  int _currentPage = 1;
  bool _hasMoreData = true;
  bool _isLoadingMore = false;
  
  
  // Enhanced color scheme
  static const Color primaryBlue = Color(0xFF1E40AF);
  static const Color successGreen = Color(0xFF10B981);
  static const Color errorRed = Color(0xFFEF4444);
  static const Color grayBackground = Color(0xFFF8FAFC);
  static const Color darkGray = Color(0xFF1F2937);

  @override
  void initState() {
    super.initState();
    _initializeAndLoadVehicles();
  }
  
  Future<void> _initializeAndLoadVehicles() async {
    // Initialize API service with stored token
    await _apiService.initialize();
    // Load vehicles
    await _loadVehicles();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadVehicles({final bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _isLoading = true;
        _currentPage = 1;
        _hasMoreData = true;
        _vehicles.clear();
        _filteredVehicles.clear();
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
      final Map<String, dynamic> response = await _apiService.getVehicles(
        page: _currentPage,
      );
      
      // Handle the actual response structure: {status, message, data: {data: [...], pagination: {...}}}
      List<dynamic> vehiclesData;
      if (response["data"] is Map<String, dynamic>) {
        // Paginated response: data contains another object with "data" key
        vehiclesData = response["data"]["data"] ?? <Map<String, dynamic>>[];
      } else if (response["data"] is List) {
        // Direct list response
        vehiclesData = response["data"];
      } else {
        vehiclesData = <Map<String, dynamic>>[];
      }
      final List<Vehicle> newVehicles = vehiclesData
          .map((final json) => Vehicle.fromJson(json as Map<String, dynamic>))
          .toList();
      
      setState(() {
        if (_currentPage == 1) {
          _vehicles = newVehicles;
        } else {
          _vehicles.addAll(newVehicles);
        }
        
        // Check if there"s more data
        _hasMoreData = newVehicles.length >= 20;
        _currentPage++;
      });
      
      _filterVehicles();
    } catch (e) {
      _showErrorSnackBar("Hitilafu katika kupakia magari: $e");
    } finally {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  void _filterVehicles() {
    setState(() {
      _filteredVehicles = _vehicles.where((final Vehicle vehicle) {
        final bool matchesSearch = _searchQuery.isEmpty ||
            vehicle.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            vehicle.plateNumber.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            vehicle.type.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (vehicle.driverName?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
        
        final bool matchesFilter = _selectedFilter == "all" ||
            (_selectedFilter == "active" && vehicle.isActive) ||
            (_selectedFilter == "inactive" && !vehicle.isActive) ||
            (_selectedFilter == "assigned" && vehicle.driverName != null) ||
            (_selectedFilter == "unassigned" && vehicle.driverName == null);
        
        return matchesSearch && matchesFilter;
      }).toList();
    });
  }

  void _onSearchChanged(final String query) {
    setState(() {
      _searchQuery = query;
    });
    _filterVehicles();
  }

  void _onFilterChanged(final String filter) {
    setState(() {
      _selectedFilter = filter;
    });
    _filterVehicles();
  }

  void _showErrorSnackBar(final String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: SelectableText(message),
        backgroundColor: errorRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(final BuildContext context) => Scaffold(
      backgroundColor: grayBackground,
      appBar: _buildAppBar(),
      body: _isLoading ? _buildLoadingScreen() : _buildMainContent(),
      floatingActionButton: _buildFloatingActionButton(),
    );

  PreferredSizeWidget _buildAppBar() => AppBar(
      title: const Text(
        "Simamia Magari",
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: primaryBlue,
      foregroundColor: Colors.white,
      elevation: 0,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          color: primaryBlue, // Solid blue background
        ),
      ),
      actions: <Widget>[
        IconButton(
          onPressed: () => _loadVehicles(refresh: true),
          icon: const Icon(Icons.refresh),
        ),
        PopupMenuButton<String>(
          onSelected: (final String value) {
            switch (value) {
              case "export":
                _exportVehicles();
              case "import":
                _importVehicles();
            }
          },
          itemBuilder: (final BuildContext context) => <PopupMenuEntry<String>>[
            const PopupMenuItem(
              value: "export",
              child: Row(
                children: <Widget>[
                  Icon(Icons.download, color: primaryBlue),
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

  Widget _buildLoadingScreen() => Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const CircularProgressIndicator(),
          SizedBox(height: 16.h),
          const Text(
            "Inapakia magari...",
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
          child: RefreshIndicator(
            onRefresh: () => _loadVehicles(refresh: true),
            color: primaryBlue,
            child: _filteredVehicles.isEmpty
                ? _buildEmptyState()
                : _buildVehiclesList(),
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
                hintText: "Tafuta gari, namba, aina, au dereva...",
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
          SizedBox(height: 16.h),
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: <Widget>[
                _buildFilterChip("all", "Yote", _vehicles.length),
                const SizedBox(width: 8),
                _buildFilterChip(
                  "active",
                  "Hai",
                  _vehicles.where((final Vehicle v) => v.isActive).length,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  "inactive",
                  "Hahai",
                  _vehicles.where((final Vehicle v) => !v.isActive).length,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  "assigned",
                  "Yamepewa",
                  _vehicles.where((final Vehicle v) => v.driverName != null).length,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  "unassigned",
                  "Hayajapewa",
                  _vehicles.where((final Vehicle v) => v.driverName == null).length,
                ),
              ],
            ),
          ),
        ],
      ),
    );

  Widget _buildFilterChip(final String value, final String label, final int count) {
    final bool isSelected = _selectedFilter == value;
    return FilterChip(
      selected: isSelected,
      label: Text(
        "$label ($count)",
        style: TextStyle(
          color: isSelected ? Colors.white : darkGray,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: Colors.white,
      selectedColor: primaryBlue,
      checkmarkColor: Colors.white,
      onSelected: (final bool selected) {
        if (selected) {
          _onFilterChanged(value);
        }
      },
    );
  }

  Widget _buildStatsCards() {
    final int activeVehicles = _vehicles.where((final Vehicle v) => v.isActive).length;
    final int assignedVehicles = _vehicles.where((final Vehicle v) => v.driverName != null).length;
    final double utilizationRate = _vehicles.isNotEmpty ? (assignedVehicles / _vehicles.length * 100) : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: <Widget>[
          Expanded(
            child: _buildStatCard(
              title: "Magari Hai",
              value: "$activeVehicles/${_vehicles.length}",
              icon: Icons.directions_car,
              color: successGreen,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              title: "Yamepewa Madereva",
              value: "$assignedVehicles/${_vehicles.length}",
              icon: Icons.assignment_ind,
              color: Colors.orange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              title: "Kiwango cha Matumizi",
              value: "${utilizationRate.toStringAsFixed(1)}%",
              icon: Icons.trending_up,
              color: Colors.amber,
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
  }) => CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: <Widget>[
            Icon(
              icon,
              color: color,
              size: 24,
            ),
            SizedBox(height: 8.h),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              title,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.black54,
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
            Icons.directions_car_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty
                ? "Hakuna gari lililopatikana"
                : "Hakuna magari bado",
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? "Jaribu kutafuta kwa jina lingine"
                : "Sajili gari la kwanza",
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black45,
            ),
          ),
          SizedBox(height: 24.h),
          if (_searchQuery.isEmpty)
            CustomButton(
              text: "Sajili Gari",
              icon: Icons.add,
              onPressed: _showAddVehicleDialog,
            ),
        ],
      ),
    );

  Widget _buildVehiclesList() => ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredVehicles.length + (_hasMoreData ? 1 : 0),
      itemBuilder: (final BuildContext context, final int index) {
        if (index == _filteredVehicles.length) {
          // Load more indicator
          if (!_isLoadingMore) {
            _loadVehicles();
          }
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        final Vehicle vehicle = _filteredVehicles[index];
        return _buildVehicleCard(vehicle);
      },
    );

  Widget _buildVehicleCard(final Vehicle vehicle) {
    final bool isActive = vehicle.isActive;
    final bool isAssigned = vehicle.driverName != null;
    
    return CustomCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                // Vehicle icon
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: isActive ? successGreen : Colors.grey,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Icon(
                    _getVehicleIcon(vehicle.type),
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                // Vehicle info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              vehicle.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: darkGray,
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
                                  ? successGreen.withOpacity(0.1)
                                  : Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isActive ? "HAI" : "HAHAI",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isActive ? successGreen : Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        vehicle.plateNumber,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: primaryBlue,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: <Widget>[
                          Icon(
                            Icons.category,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getVehicleTypeDisplay(vehicle.type),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                          if (isAssigned) ...<Widget>[
                            const SizedBox(width: 16),
                            Icon(
                              Icons.person,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                vehicle.driverName!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // Actions
                PopupMenuButton<String>(
                  onSelected: (final String value) => _handleVehicleAction(value, vehicle),
                  itemBuilder: (final BuildContext context) => <PopupMenuEntry<String>>[
                    const PopupMenuItem(
                      value: "view",
                      child: Row(
                        children: <Widget>[
                          Icon(Icons.visibility, color: primaryBlue),
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
                      value: isAssigned ? "unassign" : "assign",
                      child: Row(
                        children: <Widget>[
                          Icon(
                            isAssigned ? Icons.person_remove : Icons.person_add,
                            color: isAssigned ? Colors.amber : successGreen,
                          ),
                          const SizedBox(width: 8),
                          Text(isAssigned ? "Ondoa Dereva" : "Weka Dereva"),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: isActive ? "deactivate" : "activate",
                      child: Row(
                        children: <Widget>[
                          Icon(
                            isActive ? Icons.block : Icons.check_circle,
                            color: isActive ? errorRed : successGreen,
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
                          Icon(Icons.delete, color: errorRed),
                          SizedBox(width: 8),
                          Text("Futa"),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (vehicle.description != null && vehicle.description!.isNotEmpty) ...<Widget>[
              SizedBox(height: 12.h),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  vehicle.description!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() => FloatingActionButton.extended(
      onPressed: _showAddVehicleDialog,
      backgroundColor: Colors.orange,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.add),
      label: const Text(
        "Sajili Gari",
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
    );

  IconData _getVehicleIcon(final String vehicleType) {
    switch (vehicleType.toLowerCase()) {
      case "bajaji":
        return Icons.directions_car; // three_wheeler not available, using car icon
      case "pikipiki":
        return Icons.motorcycle;
      case "gari":
        return Icons.directions_car;
      default:
        return Icons.directions_car;
    }
  }

  String _getVehicleTypeDisplay(final String vehicleType) {
    switch (vehicleType.toLowerCase()) {
      case "bajaji":
        return "Bajaji";
      case "pikipiki":
        return "Pikipiki";
      case "gari":
        return "Gari";
      default:
        return vehicleType;
    }
  }

  void _handleVehicleAction(final String action, final Vehicle vehicle) {
    switch (action) {
      case "view":
        _showVehicleDetails(vehicle);
      case "edit":
        _showEditVehicleDialog(vehicle);
      case "assign":
        _showAssignDriverDialog(vehicle);
      case "unassign":
        _confirmUnassignDriver(vehicle);
      case "activate":
      case "deactivate":
        _toggleVehicleStatus(vehicle);
      case "delete":
        _confirmDeleteVehicle(vehicle);
    }
  }

  void _showVehicleDetails(final Vehicle vehicle) {
    showDialog(
      context: context,
      builder: (final BuildContext context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Maelezo ya ${vehicle.name}"),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _buildDetailRow("Jina:", vehicle.name),
              _buildDetailRow("Namba ya Gari:", vehicle.plateNumber),
              _buildDetailRow("Aina:", _getVehicleTypeDisplay(vehicle.type)),
              _buildDetailRow("Hali:", vehicle.isActive ? "Hai" : "Hahai"),
              _buildDetailRow("Dereva:", vehicle.driverName ?? "Hajapewa dereva"),
              if (vehicle.description != null && vehicle.description!.isNotEmpty)
                _buildDetailRow("Maelezo:", vehicle.description!),
              _buildDetailRow("Ilisajiliwa:", _formatDate(vehicle.createdAt)),
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
            width: 100,
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

  String _formatDate(final DateTime date) => "${date.day}/${date.month}/${date.year}";

  void _showAddVehicleDialog() {
    showDialog(
      context: context,
      builder: (final BuildContext context) => _AddVehicleDialog(
        onVehicleAdded: () {
          // Refresh the vehicles list after adding a new vehicle
          _loadVehicles(refresh: true);
        },
      ),
    );
  }

  void _showEditVehicleDialog(final Vehicle vehicle) {
    // TODO: Implement edit vehicle dialog with real API call
    showDialog(
      context: context,
      builder: (final BuildContext context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Hariri ${vehicle.name}"),
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

  void _showAssignDriverDialog(final Vehicle vehicle) {
    // TODO: Implement assign driver dialog
    showDialog(
      context: context,
      builder: (final BuildContext context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Weka Dereva kwa ${vehicle.name}"),
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

  void _confirmUnassignDriver(final Vehicle vehicle) {
    showDialog(
      context: context,
      builder: (final BuildContext context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Ondoa Dereva"),
        content: Text(
          "Je, una uhakika unataka kuondoa ${vehicle.driverName} kutoka kwa gari ${vehicle.plateNumber}?",
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hapana"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              // TODO: Implement unassign driver API call
              _showErrorSnackBar("Kipengele hiki kinatengenezwa. Subiri kidogo!");
            },
            child: const Text(
              "Ondoa",
              style: TextStyle(color: Colors.amber),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleVehicleStatus(final Vehicle vehicle) {
    final bool isActive = vehicle.isActive;
    
    showDialog(
      context: context,
      builder: (final BuildContext context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isActive ? "Zima Gari" : "Washa Gari"),
        content: Text(
          isActive
              ? "Je, una uhakika unataka kuzima gari ${vehicle.plateNumber}?"
              : "Je, una uhakika unataka kuwasha gari ${vehicle.plateNumber}?",
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hapana"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              // TODO: Implement update vehicle status API call
              _showErrorSnackBar("Kipengele hiki kinatengenezwa. Subiri kidogo!");
            },
            child: Text(
              isActive ? "Zima" : "Washa",
              style: TextStyle(
                color: isActive ? errorRed : successGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteVehicle(final Vehicle vehicle) {
    showDialog(
      context: context,
      builder: (final BuildContext context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Futa Gari"),
        content: Text(
          "Je, una uhakika unataka kufuta gari ${vehicle.plateNumber}? Kitendo hiki hakiwezi kurudishwa.",
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hapana"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              // TODO: Implement delete vehicle API call
              _showErrorSnackBar("Kipengele hiki kinatengenezwa. Subiri kidogo!");
            },
            child: const Text(
              "Futa",
              style: TextStyle(color: errorRed),
            ),
          ),
        ],
      ),
    );
  }

  void _exportVehicles() {
    // TODO: Implement export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Kipengele cha kuhamisha kinatengenezwa..."),
      ),
    );
  }

  void _importVehicles() {
    // TODO: Implement import functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Kipengele cha kuingiza kinatengenezwa..."),
      ),
    );
  }
}

// Add Vehicle Dialog Widget
class _AddVehicleDialog extends StatefulWidget {

  const _AddVehicleDialog({required this.onVehicleAdded});
  final VoidCallback onVehicleAdded;

  @override
  State<_AddVehicleDialog> createState() => _AddVehicleDialogState();
}

class _AddVehicleDialogState extends State<_AddVehicleDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  
  // Form controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _plateNumberController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  
  // Form state
  bool _isLoading = false;
  String _selectedVehicleType = "bajaji";
  
  // Vehicle types
  final Map<String, String> _vehicleTypes = <String, String>{
    "bajaji": "Bajaji",
    "pikipiki": "Pikipiki",
    "gari": "Gari",
  };
  
  // Colors
  static const Color primaryBlue = Color(0xFF1E40AF);
  static const Color successGreen = Color(0xFF10B981);
  static const Color errorRed = Color(0xFFEF4444);

  @override
  void dispose() {
    _nameController.dispose();
    _plateNumberController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _apiService.initialize();
      
      final Map<String, String?> vehicleData = <String, String?>{
        "name": _nameController.text.trim(),
        "type": _selectedVehicleType,
        "plate_number": _plateNumberController.text.trim().toUpperCase(),
        "description": _descriptionController.text.trim().isNotEmpty 
            ? _descriptionController.text.trim() 
            : null,
      };

      await _apiService.createVehicle(vehicleData);

      if (mounted) {
        Navigator.pop(context);
        widget.onVehicleAdded();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gari ${_plateNumberController.text} limesajiliwa kikamilifu!"),
            backgroundColor: successGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Hitilafu katika kusajili gari: $e"),
            backgroundColor: errorRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: primaryBlue,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: <Widget>[
                  const Icon(
                    Icons.directions_car,
                    color: Colors.white,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      "Sajili Gari Jipya",
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
                      // Vehicle name field
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: "Jina la Gari *",
                          hintText: "Mfano: Bajaji ya Kwanza",
                          prefixIcon: const Icon(Icons.label),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (final String? value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Jina la gari ni lazima";
                          }
                          if (value.trim().length < 2) {
                            return "Jina lazima liwe na angalau herufi 2";
                          }
                          return null;
                        },
                      ),
                      
                      SizedBox(height: 16.h),
                      
                      // Vehicle type dropdown
                      DropdownButtonFormField<String>(
                        value: _selectedVehicleType,
                        decoration: InputDecoration(
                          labelText: "Aina ya Gari *",
                          prefixIcon: const Icon(Icons.category),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: _vehicleTypes.entries.map((final MapEntry<String, String> entry) => DropdownMenuItem<String>(
                            value: entry.key,
                            child: Text(
                              entry.value,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),).toList(),
                        onChanged: (final String? value) {
                          setState(() {
                            _selectedVehicleType = value!;
                          });
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Plate number field
                      TextFormField(
                        controller: _plateNumberController,
                        decoration: InputDecoration(
                          labelText: "Namba ya Gari *",
                          hintText: "T123ABC",
                          prefixIcon: const Icon(Icons.confirmation_number),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        textCapitalization: TextCapitalization.characters,
                        validator: (final String? value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Namba ya gari ni lazima";
                          }
                          if (value.trim().length < 3) {
                            return "Namba ya gari si sahihi";
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Description field
                      TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: "Maelezo (Hiari)",
                          hintText: "Maelezo ya ziada kuhusu gari",
                          prefixIcon: const Icon(Icons.description),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        maxLines: 3,
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
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
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
                        backgroundColor: successGreen,
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
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              "Sajili Gari",
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
