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
    return ThemeConstants.buildScaffold(
      title: _loc.translate('properties'),
      actions: [
        IconButton(
          icon: const Icon(Icons.add_circle_outline, color: Colors.white),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreatePropertyScreen()),
          ).then((_) => _loadProperties(refresh: true)),
        ),
      ],
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
      padding: EdgeInsets.fromLTRB(14.w, 8.h, 14.w, 12.h),
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
          SizedBox(height: 12.h),
          // Status filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected
              ? ThemeConstants.primaryOrange
              : Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: isSelected ? [
            BoxShadow(color: ThemeConstants.primaryOrange.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))
          ] : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontSize: 12.sp,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return Consumer<RentalProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.properties.isEmpty) {
          return ThemeConstants.buildLoadingWidget();
        }
        if (provider.properties.isEmpty) {
          return _buildEmptyState();
        }
        return RefreshIndicator(
          onRefresh: () => _loadProperties(refresh: true),
          color: ThemeConstants.primaryOrange,
          child: ListView.builder(
            controller: _scrollController,
            padding: EdgeInsets.fromLTRB(14.w, 4.h, 14.w, 20.h),
            itemCount: provider.properties.length + (provider.hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == provider.properties.length) {
                return Padding(
                  padding: EdgeInsets.all(16.h),
                  child: const Center(child: CircularProgressIndicator(color: Colors.white54)),
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
            padding: EdgeInsets.all(24.r),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.apartment_outlined, size: 56.sp, color: Colors.white38),
          ),
          SizedBox(height: 20.h),
          Text(_loc.translate('no_properties'),
              style: ThemeConstants.subHeadingStyle),
          SizedBox(height: 8.h),
          Text(_loc.translate('add_property_hint'),
              style: ThemeConstants.captionStyle),
          SizedBox(height: 24.h),
          ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreatePropertyScreen()),
            ).then((_) => _loadProperties(refresh: true)),
            style: ElevatedButton.styleFrom(
              backgroundColor: ThemeConstants.primaryOrange,
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 14.h),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add, color: Colors.white),
                SizedBox(width: 8.w),
                Text(_loc.translate('add_property'),
                    style: TextStyle(color: Colors.white, fontSize: 14.sp)),
              ],
            ),
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
      case 'under_maintenance':
        statusColor = ThemeConstants.warningAmber;
        break;
      default: statusColor = Colors.white54;
    }

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: ThemeConstants.buildResponsiveGlassCard(
        context,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PropertyDetailsScreen(propertyId: property['id']),
          ),
        ).then((_) => _loadProperties(refresh: true)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    color: ThemeConstants.primaryOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(Icons.business_outlined, color: ThemeConstants.primaryOrange, size: 24.sp),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        property['name'] ?? '',
                        style: ThemeConstants.bodyStyle.copyWith(fontWeight: FontWeight.bold, fontSize: 16.sp),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 2.h),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined, size: 12.sp, color: Colors.white54),
                          SizedBox(width: 4.w),
                          Expanded(
                            child: Text(
                              property['full_address'] ?? "${property['district'] ?? ''}, ${property['region'] ?? ''}",
                              style: ThemeConstants.captionStyle.copyWith(fontSize: 11.sp),
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
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Text(
                    statusDisplay.toString().toUpperCase(),
                    style: TextStyle(color: statusColor, fontSize: 9.sp, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(child: _buildStat(Icons.home_outlined, '$totalUnits', _loc.translate('houses'))),
                _statDivider(),
                Expanded(child: _buildStat(Icons.person_outline, '$occupied', _loc.translate('occupied'))),
                _statDivider(),
                Expanded(child: _buildStat(Icons.meeting_room_outlined, '$vacant', _loc.translate('vacant'),
                    color: vacant > 0 ? ThemeConstants.successGreen : null)),
              ],
            ),
            if (property['property_type_display'] != null || property['billing_cycle_display'] != null) ...[
              SizedBox(height: 16.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: [
                  if (property['property_type_display'] != null)
                    _buildChip(property['property_type_display']),
                  if (property['billing_cycle_display'] != null)
                    _buildChip(property['billing_cycle_display']),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statDivider() => Container(width: 1, height: 24.h, color: Colors.white.withOpacity(0.08));

  Widget _buildStat(IconData icon, String value, String label, {Color? color}) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14.sp, color: color ?? Colors.white54),
            SizedBox(width: 6.w),
            Text(value, style: TextStyle(color: color ?? Colors.white, fontSize: 15.sp, fontWeight: FontWeight.bold)),
          ],
        ),
        SizedBox(height: 2.h),
        Text(label, style: ThemeConstants.captionStyle.copyWith(fontSize: 10.sp)),
      ],
    );
  }

  Widget _buildChip(String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Text(label, style: ThemeConstants.captionStyle.copyWith(fontSize: 10.sp, color: Colors.white70)),
    );
  }
}
