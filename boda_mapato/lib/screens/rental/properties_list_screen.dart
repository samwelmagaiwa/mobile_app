import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../constants/theme_constants.dart';
import '../../providers/rental_provider.dart';
import '../../services/localization_service.dart';
import 'create_property_screen.dart';
import 'property_details_screen.dart';

class PropertiesListScreen extends StatefulWidget {
  const PropertiesListScreen({super.key});

  @override
  State<PropertiesListScreen> createState() => _PropertiesListScreenState();
}

class _PropertiesListScreenState extends State<PropertiesListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _selectedStatus;
  final _loc = LocalizationService.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProperties(refresh: true);
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final provider = context.read<RentalProvider>();
      if (!provider.isLoading && provider.hasMore) {
        provider.fetchPropertiesWithPagination(
          page: provider.currentPage + 1,
          search: _searchController.text,
          status: _selectedStatus,
        );
      }
    }
  }

  Future<void> _loadProperties({bool refresh = false}) async {
    final provider = context.read<RentalProvider>();
    if (refresh) provider.resetPagination();
    await provider.fetchPropertiesWithPagination(
      search: _searchController.text,
      status: _selectedStatus,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeConstants.primaryBlue,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(_loc.translate('properties'),
            style: TextStyle(color: Colors.white, fontSize: 20.sp, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Colors.white),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreatePropertyScreen()),
            ).then((_) => _loadProperties(refresh: true)),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchAndFilter(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            style: TextStyle(color: Colors.white, fontSize: 14.sp),
            onSubmitted: (_) => _loadProperties(refresh: true),
            decoration: InputDecoration(
              hintText: _loc.translate('search'),
              hintStyle: TextStyle(color: Colors.white38, fontSize: 14.sp),
              prefixIcon: Icon(Icons.search, color: Colors.white38, size: 20.sp),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: Colors.white38, size: 18.sp),
                      onPressed: () {
                        _searchController.clear();
                        _loadProperties(refresh: true);
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white.withOpacity(0.08),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.symmetric(vertical: 12.h),
            ),
          ),
          SizedBox(height: 10.h),
          // Status filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(null, _loc.translate('all')),
                SizedBox(width: 8.w),
                _buildFilterChip('active', _loc.translate('active')),
                SizedBox(width: 8.w),
                _buildFilterChip('inactive', _loc.translate('inactive')),
                SizedBox(width: 8.w),
                _buildFilterChip('under_maintenance', _loc.translate('maintenance')),
                SizedBox(width: 8.w),
                _buildFilterChip('archived', _loc.translate('archived')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String? status, String label) {
    final isSelected = _selectedStatus == status;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedStatus = status);
        _loadProperties(refresh: true);
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected
              ? ThemeConstants.primaryOrange
              : Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected
                ? ThemeConstants.primaryOrange
                : Colors.white.withOpacity(0.15),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontSize: 12.sp,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return Consumer<RentalProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.properties.isEmpty) {
          return const Center(
              child: CircularProgressIndicator(color: Colors.white));
        }
        if (provider.properties.isEmpty) {
          return _buildEmptyState();
        }
        return RefreshIndicator(
          onRefresh: () => _loadProperties(refresh: true),
          color: ThemeConstants.primaryOrange,
          child: ListView.builder(
            controller: _scrollController,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            itemCount: provider.properties.length + (provider.hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == provider.properties.length) {
                return Padding(
                  padding: EdgeInsets.all(16.h),
                  child: const Center(
                      child:
                          CircularProgressIndicator(color: Colors.white54)),
                );
              }
              final p = provider.properties[index] as Map<String, dynamic>;
              return _buildPropertyCard(p);
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.apartment, size: 56.sp, color: Colors.white38),
          ),
          SizedBox(height: 20.h),
          Text(_loc.translate('no_properties'),
              style: TextStyle(color: Colors.white54, fontSize: 16.sp, fontWeight: FontWeight.w500)),
          SizedBox(height: 8.h),
          Text(_loc.translate('add_property_hint'),
              style: TextStyle(color: Colors.white38, fontSize: 13.sp)),
          SizedBox(height: 24.h),
          ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreatePropertyScreen()),
            ).then((_) => _loadProperties(refresh: true)),
            style: ElevatedButton.styleFrom(
              backgroundColor: ThemeConstants.primaryOrange,
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 14.h),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
            ),
            icon: const Icon(Icons.add, color: Colors.white),
            label: Text(_loc.translate('add_property'),
                style: TextStyle(color: Colors.white, fontSize: 14.sp)),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyCard(Map<String, dynamic> property) {
    final totalUnits = property['total_units'] ?? 0;
    final occupied = property['occupied_units'] ?? 0;
    final vacant = property['vacant_units'] ?? 0;
    final status = property['status'] ?? 'active';
    final statusDisplay = property['status_display'] ?? status;

    Color statusColor;
    switch (status) {
      case 'active':
        statusColor = ThemeConstants.successGreen;
        break;
      case 'inactive':
        statusColor = Colors.white38;
        break;
      case 'under_maintenance':
        statusColor = ThemeConstants.warningAmber;
        break;
      case 'archived':
        statusColor = Colors.white24;
        break;
      default:
        statusColor = Colors.white54;
    }

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PropertyDetailsScreen(propertyId: property['id']),
        ),
      ).then((_) => _loadProperties(refresh: true)),
      child: Container(
        margin: EdgeInsets.only(bottom: 14.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          ThemeConstants.primaryOrange.withOpacity(0.3),
                          ThemeConstants.primaryOrange.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                    child: Icon(Icons.apartment,
                        color: ThemeConstants.primaryOrange, size: 24.sp),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          property['name'] ?? '',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 3.h),
                        Row(
                          children: [
                            Icon(Icons.location_on,
                                size: 12.sp, color: Colors.white54),
                            SizedBox(width: 4.w),
                            Expanded(
                              child: Text(
                                property['full_address'] ??
                                    "${property['district'] ?? ''}, ${property['region'] ?? ''}",
                                style: TextStyle(
                                    color: Colors.white54, fontSize: 11.sp),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 10.w, vertical: 5.h),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Text(
                      statusDisplay.toString(),
                      style: TextStyle(
                          color: statusColor,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 14.h),
              // Stats row
              Row(
                children: [
                  Expanded(
                      child: _buildStat(
                          Icons.home, '$totalUnits', _loc.translate('houses'))),
                  Container(width: 1, height: 28.h, color: Colors.white12),
                  Expanded(
                      child: _buildStat(Icons.person, '$occupied',
                          _loc.translate('occupied'))),
                  Container(width: 1, height: 28.h, color: Colors.white12),
                  Expanded(
                      child: _buildStat(Icons.meeting_room, '$vacant',
                          _loc.translate('vacant'),
                          color: vacant > 0
                              ? ThemeConstants.successGreen
                              : null)),
                ],
              ),
              SizedBox(height: 10.h),
              // Chips row
              Row(
                children: [
                  if (property['property_type_display'] != null)
                    _buildChip(property['property_type_display']),
                  SizedBox(width: 8.w),
                  if (property['billing_cycle_display'] != null)
                    _buildChip(property['billing_cycle_display']),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(IconData icon, String value, String label,
      {Color? color}) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14.sp, color: color ?? Colors.white54),
              SizedBox(width: 4.w),
              Text(value,
                  style: TextStyle(
                      color: color ?? Colors.white,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          SizedBox(height: 2.h),
          Text(label,
              style: TextStyle(color: Colors.white38, fontSize: 10.sp)),
        ],
      ),
    );
  }

  Widget _buildChip(String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Text(label,
          style: TextStyle(color: Colors.white70, fontSize: 10.sp)),
    );
  }
}
