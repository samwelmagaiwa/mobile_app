import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../constants/theme_constants.dart';
import '../../providers/rental_provider.dart';
import '../../services/localization_service.dart';
import 'edit_property_screen.dart';
import 'add_house_bottom_sheet.dart';

class PropertyDetailsScreen extends StatefulWidget {
  const PropertyDetailsScreen({required this.propertyId, super.key});
  final String propertyId;

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
    return ThemeConstants.buildScaffold(
      title: _loc.translate('property_details'),
      actions: [
        Consumer<RentalProvider>(
          builder: (_, p, __) => p.selectedProperty != null
              ? PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  color: ThemeConstants.bgMid,
                  offset: const Offset(0, 40),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                  onSelected: (value) {
                    if (value == 'edit') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditPropertyScreen(property: p.selectedProperty!),
                        ),
                      ).then((_) => context.read<RentalProvider>().fetchPropertyDetails(widget.propertyId));
                    } else if (value == 'delete') {
                      _showDeleteConfirmation(context, p.selectedProperty!);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          const Icon(Icons.edit_outlined, color: Colors.white70, size: 20),
                          SizedBox(width: 12.w),
                          Text(_loc.translate('edit'), style: const TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                          SizedBox(width: 12.w),
                          Text(_loc.translate('delete'), style: const TextStyle(color: Colors.redAccent)),
                        ],
                      ),
                    ),
                  ],
                )
              : const SizedBox.shrink(),
        ),
      ],
      body: Consumer<RentalProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.selectedProperty == null) {
            return ThemeConstants.buildLoadingWidget();
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
                      style: ThemeConstants.captionStyle),
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
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 20.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stats Cards Row
              _buildStatsRow(totalUnits, occupied, vacant, occupancyRate),
              SizedBox(height: 20.h),

              // Property Info Header
              _buildInfoHeader(property),
              SizedBox(height: 20.h),

              // Financial Summary Row
              Row(
                children: [
                   Expanded(child: _buildFinancialCard(
                     _loc.translate('total_revenue'),
                     '${property['currency'] ?? 'TZS'} ${_formatNumber(totalCollected)}',
                     Icons.account_balance_wallet_outlined,
                     ThemeConstants.successGreen,
                   )),
                   SizedBox(width: 12.w),
                   Expanded(child: _buildFinancialCard(
                     _loc.translate('recent_payments'),
                     recentPayments.isNotEmpty 
                        ? 'TZS ${_formatNumber(recentPayments.first['amount'] ?? 0)}'
                        : _loc.translate('no_payments'),
                     Icons.history,
                     ThemeConstants.primaryOrange,
                     subtitle: recentPayments.isNotEmpty ? recentPayments.first['date'] : null,
                   )),
                ],
              ),
              SizedBox(height: 24.h),

              // Blocks Section
              if (blocks.isNotEmpty) ...[
                _buildSectionHeader(_loc.translate('blocks'), Icons.view_module_outlined),
                SizedBox(height: 12.h),
                ...blocks.map((b) => _buildBlockTile(b as Map<String, dynamic>)),
                SizedBox(height: 24.h),
              ],

              // Houses Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionHeader(
                      _loc.translate('houses'), Icons.home_outlined),
                  TextButton.icon(
                    onPressed: () => _showAddHouseDialog(context, property['id']),
                    icon: const Icon(Icons.add, size: 16, color: ThemeConstants.primaryOrange),
                    label: Text(_loc.translate('add_house'),
                        style: TextStyle(color: ThemeConstants.primaryOrange, fontSize: 13.sp)),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              if (houses.isEmpty)
                _buildEmptyCard(_loc.translate('no_houses'))
              else
                ...houses.map((h) => _buildHouseTile(h as Map<String, dynamic>)),
              SizedBox(height: 24.h),

              // Recent Payments
              _buildSectionHeader(_loc.translate('recent_payments'), Icons.payment_outlined),
              SizedBox(height: 12.h),
              if (recentPayments.isEmpty)
                _buildEmptyCard(_loc.translate('no_payments'))
              else
                ...recentPayments.map((p) => _buildPaymentTile(p as Map<String, dynamic>)),
              SizedBox(height: 40.h),
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
      case 'under_maintenance':
        statusColor = ThemeConstants.warningAmber;
      default:
        statusColor = Colors.white38;
    }

    return ThemeConstants.buildResponsiveGlassCardStatic(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(14.r),
                decoration: BoxDecoration(
                  color: ThemeConstants.primaryOrange.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Icon(Icons.business_outlined, color: ThemeConstants.primaryOrange, size: 28.sp),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(property['name'] ?? '',
                        style: ThemeConstants.headingStyle.copyWith(fontSize: 18.sp)),
                    SizedBox(height: 4.h),
                    Text(property['property_type_display'] ?? '',
                        style: ThemeConstants.captionStyle.copyWith(color: ThemeConstants.primaryOrange.withOpacity(0.8), fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Text(
                  (property['status_display'] ?? status).toString().toUpperCase(),
                  style: TextStyle(color: statusColor, fontSize: 10.sp, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Icon(Icons.location_on_outlined, size: 14.sp, color: Colors.white54),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  property['full_address'] ?? property['address'] ?? '',
                  style: ThemeConstants.bodyStyle.copyWith(fontSize: 12.sp, color: Colors.white70),
                ),
              ),
            ],
          ),
          if (property['description'] != null && (property['description'] as String).isNotEmpty) ...[
            SizedBox(height: 12.h),
            Text(property['description'],
                style: ThemeConstants.captionStyle.copyWith(fontSize: 12.sp, fontStyle: FontStyle.italic)),
          ],
          if (property['default_rent_amount'] != null ||
              property['ownership_notes'] != null ||
              property['latitude'] != null) ...[
            SizedBox(height: 12.h),
            const Divider(color: Colors.white10),
            SizedBox(height: 4.h),
            if (property['default_rent_amount'] != null)
              _configRow(Icons.home_work_outlined, _loc.translate("base_rent"),
                  "Tsh ${_formatNumber(property['default_rent_amount'])}"),
            if (property['default_deposit_amount'] != null)
              _configRow(Icons.savings_outlined, _loc.translate("base_deposit"),
                  "Tsh ${_formatNumber(property['default_deposit_amount'])}"),
            if (property['utility_billing_enabled'] != null)
              _configRow(
                  Icons.electrical_services_outlined,
                  _loc.translate("utility_billing"),
                  (property['utility_billing_enabled'] == true ||
                          property['utility_billing_enabled'] == 1)
                      ? _loc.translate("enabled")
                      : _loc.translate("disabled")),
            if (property['latitude'] != null)
              _configRow(Icons.gps_fixed, _loc.translate("gps_location"),
                  "${property['latitude']}, ${property['longitude']}"),
            if (property['ownership_notes'] != null &&
                (property['ownership_notes'] ?? '').toString().isNotEmpty)
              _configRow(Icons.notes_outlined, _loc.translate("ownership_details"),
                  property['ownership_notes'].toString()),
          ],
        ],
      ),
    );
  }

  Widget _configRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 5.h),
      child: Row(
        children: [
          Icon(icon, color: Colors.white38, size: 12.sp),
          SizedBox(width: 6.w),
          Text("$label: ", style: TextStyle(color: Colors.white54, fontSize: 11.sp)),
          Expanded(
            child: Text(value,
                style: TextStyle(color: Colors.white70, fontSize: 11.sp),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  String _formatNumber(value) {
    if (value == null) return '0';
    final num n = num.tryParse(value.toString()) ?? 0;
    if (n == n.truncate()) {
      return n.truncate().toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
    }
    return n.toStringAsFixed(2).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  }

  Widget _buildStatsRow(int total, int occupied, int vacant, double rate) {
    return Row(
      children: [
        Expanded(child: _buildStatCard(Icons.home_outlined, '$total', _loc.translate('total_houses'), Colors.white)),
        SizedBox(width: 8.w),
        Expanded(child: _buildStatCard(Icons.person_outline, '$occupied', _loc.translate('occupied'), ThemeConstants.primaryOrange)),
        SizedBox(width: 8.w),
        Expanded(child: _buildStatCard(Icons.meeting_room_outlined, '$vacant', _loc.translate('vacant'), ThemeConstants.successGreen)),
      ],
    );
  }

  Widget _buildStatCard(IconData icon, String value, String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 8.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24.sp),
          SizedBox(height: 8.h),
          Text(value,
              style: TextStyle(color: Colors.white, fontSize: 20.sp, fontWeight: FontWeight.bold)),
          SizedBox(height: 4.h),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(label, style: ThemeConstants.captionStyle.copyWith(fontSize: 10.sp)),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialCard(String title, String value, IconData icon, Color color, {String? subtitle}) {
    return ThemeConstants.buildResponsiveGlassCardStatic(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16.sp),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(title,
                    style: ThemeConstants.captionStyle.copyWith(fontSize: 10.sp),
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value,
                style: TextStyle(color: Colors.white, fontSize: 13.sp, fontWeight: FontWeight.bold)),
          ),
          if (subtitle != null) ...[
            SizedBox(height: 4.h),
            Text(subtitle,
                style: TextStyle(color: Colors.white38, fontSize: 9.sp)),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: ThemeConstants.primaryOrange, size: 20.sp),
        SizedBox(width: 8.w),
        Text(title, style: ThemeConstants.headingStyle.copyWith(fontSize: 15.sp)),
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
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.pushNamed(context, '/rental/house-details', arguments: house),
          borderRadius: BorderRadius.circular(12.r),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
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
          ),
        ),
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

  void _showAddHouseDialog(BuildContext context, String propertyId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddHouseBottomSheet(
        propertyId: propertyId,
        onSaved: () => context.read<RentalProvider>().fetchPropertyDetails(propertyId),
      ),
    );
  }
  void _showDeleteConfirmation(BuildContext context, Map<String, dynamic> property) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ThemeConstants.bgMid,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            SizedBox(width: 10.w),
            Text(_loc.translate("confirm_delete_property"), style: TextStyle(color: Colors.white, fontSize: 18.sp)),
          ],
        ),
        content: Text(
          "${_loc.translate("confirm_delete")} '${property['name']}'? ${_loc.translate("cannot_be_undone")}",
          style: TextStyle(color: Colors.white70, fontSize: 13.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(_loc.translate("no"), style: TextStyle(color: Colors.white54, fontSize: 13.sp)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx); // Close dialog
              final provider = context.read<RentalProvider>();
              final success = await provider.deleteProperty(property['id'].toString());
              if (mounted) {
                if (success) {
                  ThemeConstants.showSuccessSnackBar(context, _loc.translate("property_delete_success"));
                  Navigator.pop(context); // Go back to properties list
                } else {
                  ThemeConstants.showErrorSnackBar(context, _loc.translate("property_delete_failed"));
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
            ),
            child: Text("Futa", style: TextStyle(color: Colors.white, fontSize: 13.sp, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
