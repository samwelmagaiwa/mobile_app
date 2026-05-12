import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../constants/theme_constants.dart';
import '../../providers/rental_provider.dart';
import '../../services/localization_service.dart';
import 'edit_property_screen.dart';

class PropertyDetailsScreen extends StatefulWidget {
  final String propertyId;
  const PropertyDetailsScreen({super.key, required this.propertyId});

  @override
  State<PropertyDetailsScreen> createState() => _PropertyDetailsScreenState();
}

class _PropertyDetailsScreenState extends State<PropertyDetailsScreen> {
  final _loc = LocalizationService.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RentalProvider>().fetchPropertyDetails(widget.propertyId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeConstants.primaryBlue,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(_loc.translate('property_details'),
            style: TextStyle(color: Colors.white, fontSize: 20.sp, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Consumer<RentalProvider>(
            builder: (_, p, __) => p.selectedProperty != null
                ? IconButton(
                    icon: const Icon(Icons.edit, color: Colors.white),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditPropertyScreen(property: p.selectedProperty!),
                      ),
                    ).then((_) => context
                        .read<RentalProvider>()
                        .fetchPropertyDetails(widget.propertyId)),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
      body: Consumer<RentalProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.selectedProperty == null) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }
          final property = provider.selectedProperty;
          if (property == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48.sp, color: Colors.white38),
                  SizedBox(height: 12.h),
                  Text(_loc.translate('error_occurred'),
                      style: TextStyle(color: Colors.white54, fontSize: 14.sp)),
                  SizedBox(height: 16.h),
                  ElevatedButton(
                    onPressed: () => provider.fetchPropertyDetails(widget.propertyId),
                    style: ElevatedButton.styleFrom(backgroundColor: ThemeConstants.primaryOrange),
                    child: Text(_loc.translate('retry'), style: const TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
          }
          return _buildContent(property);
        },
      ),
    );
  }

  Widget _buildContent(Map<String, dynamic> property) {
    final totalUnits = property['total_units'] ?? 0;
    final occupied = property['occupied_units'] ?? 0;
    final vacant = property['vacant_units'] ?? 0;
    final occupancyRate = (property['occupancy_rate'] ?? 0).toDouble();
    final revenue = property['revenue_summary'] as Map<String, dynamic>?;
    final totalCollected = revenue?['total_collected'] ?? 0;
    final blocks = property['blocks'] as List? ?? [];
    final houses = property['houses'] as List? ?? [];
    final recentPayments = property['recent_payments'] as List? ?? [];

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () => context.read<RentalProvider>().fetchPropertyDetails(widget.propertyId),
        color: ThemeConstants.primaryOrange,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Property Info Header
              _buildInfoHeader(property),
              SizedBox(height: 16.h),

              // Stats Cards Row
              _buildStatsRow(totalUnits, occupied, vacant, occupancyRate),
              SizedBox(height: 16.h),

              // Revenue Card
              _buildRevenueCard(totalCollected, property['currency'] ?? 'TZS'),
              SizedBox(height: 16.h),

              // Blocks Section
              if (blocks.isNotEmpty) ...[
                _buildSectionHeader(_loc.translate('blocks'), Icons.view_module),
                SizedBox(height: 10.h),
                ...blocks.map((b) => _buildBlockTile(b as Map<String, dynamic>)),
                SizedBox(height: 16.h),
              ],

              // Houses Section
              _buildSectionHeader(_loc.translate('houses'), Icons.home),
              SizedBox(height: 10.h),
              if (houses.isEmpty)
                _buildEmptyCard(_loc.translate('no_houses'))
              else
                ...houses.map((h) => _buildHouseTile(h as Map<String, dynamic>)),
              SizedBox(height: 16.h),

              // Recent Payments
              _buildSectionHeader(_loc.translate('recent_payments'), Icons.payment),
              SizedBox(height: 10.h),
              if (recentPayments.isEmpty)
                _buildEmptyCard(_loc.translate('no_payments'))
              else
                ...recentPayments.map((p) => _buildPaymentTile(p as Map<String, dynamic>)),
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoHeader(Map<String, dynamic> property) {
    final status = property['status'] ?? 'active';
    Color statusColor;
    switch (status) {
      case 'active':
        statusColor = ThemeConstants.successGreen;
        break;
      case 'under_maintenance':
        statusColor = ThemeConstants.warningAmber;
        break;
      default:
        statusColor = Colors.white38;
    }

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(14.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    ThemeConstants.primaryOrange.withOpacity(0.3),
                    ThemeConstants.primaryOrange.withOpacity(0.1),
                  ]),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Icon(Icons.apartment, color: ThemeConstants.primaryOrange, size: 28.sp),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(property['name'] ?? '',
                        style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.bold)),
                    SizedBox(height: 4.h),
                    Text(property['property_type_display'] ?? '',
                        style: TextStyle(color: Colors.white54, fontSize: 12.sp)),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Text(property['status_display'] ?? status,
                    style: TextStyle(color: statusColor, fontSize: 10.sp, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Row(
            children: [
              Icon(Icons.location_on, size: 14.sp, color: Colors.white54),
              SizedBox(width: 4.w),
              Expanded(
                child: Text(
                  property['full_address'] ?? property['address'] ?? '',
                  style: TextStyle(color: Colors.white54, fontSize: 12.sp),
                ),
              ),
            ],
          ),
          if (property['description'] != null && (property['description'] as String).isNotEmpty) ...[
            SizedBox(height: 10.h),
            Text(property['description'],
                style: TextStyle(color: Colors.white38, fontSize: 12.sp)),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsRow(int total, int occupied, int vacant, double rate) {
    return Row(
      children: [
        Expanded(child: _buildStatCard(Icons.home, '$total', _loc.translate('total_houses'), Colors.white)),
        SizedBox(width: 10.w),
        Expanded(child: _buildStatCard(Icons.person, '$occupied', _loc.translate('occupied'), ThemeConstants.primaryOrange)),
        SizedBox(width: 10.w),
        Expanded(child: _buildStatCard(Icons.meeting_room, '$vacant', _loc.translate('vacant'), ThemeConstants.successGreen)),
      ],
    );
  }

  Widget _buildStatCard(IconData icon, String value, String label, Color color) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          children: [
            Icon(icon, color: color, size: 22.sp),
            SizedBox(height: 6.h),
            Text(value,
                style: TextStyle(color: Colors.white, fontSize: 20.sp, fontWeight: FontWeight.bold)),
            SizedBox(height: 2.h),
            Text(label, style: TextStyle(color: Colors.white54, fontSize: 10.sp)),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueCard(dynamic totalCollected, String currency) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          ThemeConstants.primaryOrange.withOpacity(0.2),
          ThemeConstants.primaryOrange.withOpacity(0.05),
        ]),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: ThemeConstants.primaryOrange.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: ThemeConstants.primaryOrange.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.account_balance_wallet, color: ThemeConstants.primaryOrange, size: 22.sp),
          ),
          SizedBox(width: 14.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_loc.translate('total_revenue'),
                  style: TextStyle(color: Colors.white54, fontSize: 12.sp)),
              SizedBox(height: 4.h),
              Text(
                '$currency ${_formatNumber(totalCollected)}',
                style: TextStyle(
                    color: Colors.white, fontSize: 22.sp, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: ThemeConstants.primaryOrange, size: 18.sp),
        SizedBox(width: 8.w),
        Text(title,
            style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildEmptyCard(String message) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Text(message,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white38, fontSize: 13.sp)),
    );
  }

  Widget _buildBlockTile(Map<String, dynamic> block) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Icon(Icons.view_module, color: Colors.white54, size: 18.sp),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(block['name'] ?? '',
                style: TextStyle(color: Colors.white, fontSize: 14.sp)),
          ),
          Text('${block['houses_count'] ?? 0} ${_loc.translate('houses')}',
              style: TextStyle(color: Colors.white38, fontSize: 12.sp)),
        ],
      ),
    );
  }

  Widget _buildHouseTile(Map<String, dynamic> house) {
    final status = house['status'] ?? 'vacant';
    final isOccupied = status == 'occupied';
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Container(
            width: 8.w,
            height: 8.w,
            decoration: BoxDecoration(
              color: isOccupied ? ThemeConstants.primaryOrange : ThemeConstants.successGreen,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(house['house_number'] ?? '',
                    style: TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.w500)),
                if (house['current_tenant'] != null)
                  Text(house['current_tenant']['name'] ?? '',
                      style: TextStyle(color: Colors.white38, fontSize: 11.sp)),
              ],
            ),
          ),
          Text(house['status_display'] ?? status,
              style: TextStyle(
                  color: isOccupied ? ThemeConstants.primaryOrange : ThemeConstants.successGreen,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildPaymentTile(Map<String, dynamic> payment) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Icon(Icons.payment, color: ThemeConstants.successGreen, size: 18.sp),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(payment['tenant'] ?? '',
                    style: TextStyle(color: Colors.white, fontSize: 13.sp)),
                Text('${_loc.translate('house')}: ${payment['house'] ?? ''}',
                    style: TextStyle(color: Colors.white38, fontSize: 11.sp)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('TZS ${_formatNumber(payment['amount'] ?? 0)}',
                  style: TextStyle(color: ThemeConstants.successGreen, fontSize: 13.sp, fontWeight: FontWeight.w600)),
              Text(payment['date'] ?? '',
                  style: TextStyle(color: Colors.white38, fontSize: 10.sp)),
            ],
          ),
        ],
      ),
    );
  }

  String _formatNumber(dynamic number) {
    final n = (number is num) ? number : num.tryParse(number.toString()) ?? 0;
    if (n >= 1000000) {
      return '${(n / 1000000).toStringAsFixed(1)}M';
    } else if (n >= 1000) {
      return '${(n / 1000).toStringAsFixed(0)},${(n % 1000).toString().padLeft(3, '0')}';
    }
    return n.toStringAsFixed(0);
  }
}
