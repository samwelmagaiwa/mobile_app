import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../constants/theme_constants.dart';
import '../../providers/rental_provider.dart';
import '../../services/localization_service.dart';
import 'edit_property_screen.dart';
import 'add_house_bottom_sheet.dart';

// ─────────────────────────────────────────────
// Color palette (local)
// ─────────────────────────────────────────────
const _kGradientTop    = Color(0xFF04121A);
const _kGradientMid    = Color(0xFF092D3A);
const _kGradientBottom = Color(0xFF0D485A);
const _kOrange         = Color(0xFFF97316);
const _kGreen          = Color(0xFF10B981);
const _kAmber          = Color(0xFFF59E0B);
const _kRed            = Color(0xFFEF4444);
const _kCyan           = Color(0xFF1BA3C7);

class PropertyDetailsScreen extends StatefulWidget {
  const PropertyDetailsScreen({required this.propertyId, super.key});
  final String propertyId;

  @override
  State<PropertyDetailsScreen> createState() => _PropertyDetailsScreenState();
}

class _PropertyDetailsScreenState extends State<PropertyDetailsScreen>
    with SingleTickerProviderStateMixin {
  final _loc = LocalizationService.instance;

  late final AnimationController _animCtrl;
  late final Animation<double>    _fadeAnim;
  late final Animation<Offset>    _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim  = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
            begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RentalProvider>().fetchPropertyDetails(widget.propertyId).then((_) {
        if (mounted) _animCtrl.forward();
      });
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
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

  String _formatType(String type) {
    return type
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isNotEmpty ? "${w[0].toUpperCase()}${w.substring(1)}" : "")
        .join(' ');
  }

  // ── Build joined sections ──
  List<Widget> _buildJoinedSections(Map<String, dynamic> property) {
    final totalUnits = property['total_units'] ?? 0;
    final occupied = property['occupied_units'] ?? 0;
    final vacant = property['vacant_units'] ?? 0;
    final revenue = property['revenue_summary'] as Map<String, dynamic>?;
    final totalCollected = revenue?['total_collected'] ?? 0;
    final blocks = property['blocks'] as List? ?? [];
    final houses = property['houses'] as List? ?? [];
    final recentPayments = property['recent_payments'] as List? ?? [];

    final sections = <Widget>[];

    // ── Stats Section
    sections.add(_wrapSection(_buildStatsSection(totalUnits, occupied, vacant)));

    // ── Financial Section
    sections.add(_wrapSection(_buildFinancialSection(property, totalCollected, recentPayments)));

    // ── Property Config Section
    sections.add(_wrapSection(_buildConfigSection(property)));

    // ── Blocks Section
    if (blocks.isNotEmpty) {
      sections.add(_wrapSection(_buildBlocksSection(blocks)));
    }

    // ── Houses Section
    sections.add(_wrapSection(_buildHousesSection(houses, property['id'])));

    // ── Payments Section
    sections.add(_wrapSection(_buildPaymentsSection(recentPayments)));

    // Insert dividers between sections
    final joined = <Widget>[];
    for (int i = 0; i < sections.length; i++) {
      joined.add(sections[i]);
      if (i < sections.length - 1) {
        joined.add(const _SectionDivider());
      }
    }
    return joined;
  }

  Widget _wrapSection(Widget child) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 16.h),
      child: child,
    );
  }

  // ── STATS SECTION ──
  Widget _buildStatsSection(int total, int occupied, int vacant) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          icon: Icons.analytics_outlined,
          label: _loc.translate('overview'),
        ),
        Divider(height: 24.h, color: Colors.white10),
        Row(children: [
          Expanded(child: _StatPill(
            icon: Icons.home_outlined,
            label: _loc.translate('total_houses'),
            value: '$total',
            color: _kCyan,
          )),
          SizedBox(width: 8.w),
          Expanded(child: _StatPill(
            icon: Icons.person_outline,
            label: _loc.translate('occupied'),
            value: '$occupied',
            color: _kOrange,
          )),
          SizedBox(width: 8.w),
          Expanded(child: _StatPill(
            icon: Icons.meeting_room_outlined,
            label: _loc.translate('vacant'),
            value: '$vacant',
            color: _kGreen,
          )),
        ]),
      ],
    );
  }

  // ── FINANCIAL SECTION ──
  Widget _buildFinancialSection(
      Map<String, dynamic> property, dynamic totalCollected, List recentPayments) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          icon: Icons.account_balance_wallet_outlined,
          label: _loc.translate('financial_summary'),
        ),
        Divider(height: 24.h, color: Colors.white10),

        // Revenue hero chip
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 16.w),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _kGreen.withOpacity(0.18),
                _kCyan.withOpacity(0.12),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: _kGreen.withOpacity(0.22)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_loc.translate('total_revenue'),
                      style: TextStyle(
                          color: Colors.white54, fontSize: 10.sp,
                          letterSpacing: 0.5)),
                  SizedBox(height: 4.h),
                  Text(
                    '${property['currency'] ?? 'TZS'} ${_formatNumber(totalCollected)}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: _kGreen.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(Icons.trending_up_rounded,
                    color: _kGreen, size: 22.sp),
              ),
            ],
          ),
        ),

        SizedBox(height: 12.h),

        // Recent payment mini-card
        if (recentPayments.isNotEmpty)
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 14.w),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: _kOrange.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(Icons.receipt_long_outlined,
                      color: _kOrange, size: 16.sp),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_loc.translate('recent_payments'),
                          style: TextStyle(
                              color: Colors.white54, fontSize: 10.sp)),
                      SizedBox(height: 2.h),
                      Text(
                        'TZS ${_formatNumber(recentPayments.first['amount'] ?? 0)}',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                Text(recentPayments.first['date'] ?? '',
                    style: TextStyle(
                        color: Colors.white38, fontSize: 10.sp)),
              ],
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 14.w),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    color: Colors.white24, size: 16.sp),
                SizedBox(width: 10.w),
                Text(_loc.translate('no_payments'),
                    style: TextStyle(
                        color: Colors.white38, fontSize: 12.sp)),
              ],
            ),
          ),
      ],
    );
  }

  // ── CONFIG SECTION ──
  Widget _buildConfigSection(Map<String, dynamic> property) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          icon: Icons.tune_rounded,
          label: _loc.translate('configuration'),
        ),
        Divider(height: 24.h, color: Colors.white10),

        // Location row
        if ((property['full_address'] ?? property['address'] ?? '').toString().isNotEmpty)
          Container(
            width: double.infinity,
            margin: EdgeInsets.only(bottom: 12.h),
            padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 14.w),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(6.w),
                  decoration: BoxDecoration(
                    color: _kCyan.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(Icons.location_on_outlined,
                      color: _kCyan, size: 14.sp),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    property['full_address'] ?? property['address'] ?? '',
                    style: TextStyle(
                        color: Colors.white70, fontSize: 12.sp, height: 1.4),
                  ),
                ),
              ],
            ),
          ),

        // Description
        if (property['description'] != null &&
            (property['description'] as String).isNotEmpty)
          Container(
            width: double.infinity,
            margin: EdgeInsets.only(bottom: 12.h),
            padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 14.w),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(6.w),
                  decoration: BoxDecoration(
                    color: _kAmber.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(Icons.notes_outlined,
                      color: _kAmber, size: 14.sp),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    property['description'],
                    style: TextStyle(
                        color: Colors.white60,
                        fontSize: 12.sp,
                        fontStyle: FontStyle.italic,
                        height: 1.4),
                  ),
                ),
              ],
            ),
          ),

        // Config details grid
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: Column(
            children: [
              _DetailGridRow(
                item1Label: _loc.translate('billing_cycle'),
                item1Value: _formatType(property['billing_cycle'] ?? '-'),
                item1Icon: Icons.calendar_month_outlined,
                item2Label: _loc.translate('currency'),
                item2Value: property['default_currency'] ?? property['currency'] ?? 'TZS',
                item2Icon: Icons.monetization_on_outlined,
                showBorder: true,
              ),
              if (property['default_rent_amount'] != null)
                _DetailTableRow(
                  label: _loc.translate('base_rent'),
                  value: 'Tsh ${_formatNumber(property['default_rent_amount'])}',
                  icon: Icons.home_work_outlined,
                  showBorder: property['utility_billing_enabled'] != null ||
                      (property['ownership_notes'] ?? '').toString().isNotEmpty,
                ),
              if (property['utility_billing_enabled'] != null)
                _DetailTableRow(
                  label: _loc.translate('utility_billing'),
                  value: (property['utility_billing_enabled'] == true ||
                          property['utility_billing_enabled'] == 1)
                      ? _loc.translate('enabled')
                      : _loc.translate('disabled'),
                  icon: Icons.electrical_services_outlined,
                  showBorder: (property['ownership_notes'] ?? '').toString().isNotEmpty,
                  valueColor: (property['utility_billing_enabled'] == true ||
                          property['utility_billing_enabled'] == 1)
                      ? _kGreen
                      : Colors.white38,
                ),
              if ((property['ownership_notes'] ?? '').toString().isNotEmpty)
                _DetailTableRow(
                  label: _loc.translate('ownership_details'),
                  value: property['ownership_notes'].toString(),
                  icon: Icons.note_alt_outlined,
                  showBorder: false,
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ── BLOCKS SECTION ──
  Widget _buildBlocksSection(List blocks) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          icon: Icons.view_module_outlined,
          label: _loc.translate('blocks'),
        ),
        Divider(height: 24.h, color: Colors.white10),
        ...blocks.map((b) {
          final block = b as Map<String, dynamic>;
          return Container(
            margin: EdgeInsets.only(bottom: 8.h),
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: _kCyan.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(Icons.view_module_rounded,
                      color: _kCyan, size: 16.sp),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(block['name'] ?? '',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500)),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: _kCyan.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Text(
                    '${block['houses_count'] ?? 0} ${_loc.translate('houses')}',
                    style: TextStyle(
                        color: _kCyan,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ── HOUSES SECTION ──
  Widget _buildHousesSection(List houses, dynamic propertyId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _SectionTitle(
                icon: Icons.home_outlined,
                label: _loc.translate('houses'),
              ),
            ),
            _AddHouseButton(
              onTap: () => _showAddHouseDialog(context, propertyId.toString()),
            ),
          ],
        ),
        Divider(height: 24.h, color: Colors.white10),
        if (houses.isEmpty)
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: Column(
              children: [
                Icon(Icons.home_outlined,
                    color: Colors.white12, size: 40.sp),
                SizedBox(height: 8.h),
                Text(_loc.translate('no_houses'),
                    style: TextStyle(
                        color: Colors.white38, fontSize: 13.sp)),
              ],
            ),
          )
        else
          ...houses.map((h) {
            final house = h as Map<String, dynamic>;
            final status = house['status'] ?? 'vacant';
            final isOccupied = status == 'occupied';
            final statusColor = isOccupied ? _kOrange : _kGreen;

            return Container(
              margin: EdgeInsets.only(bottom: 8.h),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.pushNamed(
                      context, '/rental/house-details',
                      arguments: house),
                  borderRadius: BorderRadius.circular(12.r),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: 14.w, vertical: 12.h),
                    child: Row(
                      children: [
                        // Status indicator
                        Container(
                          width: 36.w,
                          height: 36.w,
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10.r),
                            border: Border.all(
                                color: statusColor.withOpacity(0.25)),
                          ),
                          child: Center(
                            child: Icon(
                              isOccupied
                                  ? Icons.person_rounded
                                  : Icons.door_front_door_outlined,
                              color: statusColor,
                              size: 16.sp,
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(house['house_number'] ?? '',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w600)),
                              if (house['current_tenant'] != null)
                                Padding(
                                  padding: EdgeInsets.only(top: 2.h),
                                  child: Text(
                                      house['current_tenant']['name'] ?? '',
                                      style: TextStyle(
                                          color: Colors.white38,
                                          fontSize: 11.sp)),
                                ),
                            ],
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 10.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Text(
                            house['status_display'] ?? _formatType(status),
                            style: TextStyle(
                                color: statusColor,
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Icon(Icons.chevron_right_rounded,
                            color: Colors.white24, size: 18.sp),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  // ── PAYMENTS SECTION ──
  Widget _buildPaymentsSection(List recentPayments) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          icon: Icons.payment_outlined,
          label: _loc.translate('recent_payments'),
        ),
        Divider(height: 24.h, color: Colors.white10),
        if (recentPayments.isEmpty)
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: Column(
              children: [
                Icon(Icons.receipt_long_outlined,
                    color: Colors.white12, size: 40.sp),
                SizedBox(height: 8.h),
                Text(_loc.translate('no_payments'),
                    style: TextStyle(
                        color: Colors.white38, fontSize: 13.sp)),
              ],
            ),
          )
        else
          ...recentPayments.map((p) {
            final payment = p as Map<String, dynamic>;
            return Container(
              margin: EdgeInsets.only(bottom: 8.h),
              padding: EdgeInsets.symmetric(
                  horizontal: 14.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: _kGreen.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Icon(Icons.check_circle_outline_rounded,
                        color: _kGreen, size: 16.sp),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(payment['tenant'] ?? '',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w500)),
                        SizedBox(height: 2.h),
                        Text(
                          '${_loc.translate('house')}: ${payment['house'] ?? ''}',
                          style: TextStyle(
                              color: Colors.white38, fontSize: 10.sp),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('TZS ${_formatNumber(payment['amount'] ?? 0)}',
                          style: TextStyle(
                              color: _kGreen,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600)),
                      SizedBox(height: 2.h),
                      Text(payment['date'] ?? '',
                          style: TextStyle(
                              color: Colors.white38, fontSize: 9.sp)),
                    ],
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kGradientTop,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // ── Background gradient
          const _AnimatedBackground(),

          // ── Main scrollable content
          Consumer<RentalProvider>(
            builder: (context, provider, _) {
              if (provider.isLoading && provider.selectedProperty == null) {
                return CustomScrollView(
                  slivers: [
                    _buildAppBar(null, provider),
                    SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 32.w,
                              height: 32.w,
                              child: const CircularProgressIndicator(
                                color: _kOrange, strokeWidth: 2.5),
                            ),
                            SizedBox(height: 16.h),
                            Text(_loc.translate('loading'),
                                style: TextStyle(
                                    color: Colors.white38, fontSize: 13.sp)),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }
              final property = provider.selectedProperty;
              if (property == null) {
                return CustomScrollView(
                  slivers: [
                    _buildAppBar(null, provider),
                    SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 48.sp,
                                color: Colors.white38),
                            SizedBox(height: 12.h),
                            Text(_loc.translate('error_occurred'),
                                style: ThemeConstants.captionStyle),
                            SizedBox(height: 16.h),
                            _GradientButton(
                              label: _loc.translate('retry'),
                              icon: Icons.refresh_rounded,
                              onTap: () => provider.fetchPropertyDetails(
                                  widget.propertyId),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }
              return _buildMainContent(property, provider);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(
      Map<String, dynamic> property, RentalProvider provider) {
    final status = property['status'] ?? 'active';

    return RefreshIndicator(
      onRefresh: () => provider.fetchPropertyDetails(widget.propertyId),
      color: _kOrange,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          _buildAppBar(property, provider),

          // ── Cards
          SliverPadding(
            padding: EdgeInsets.fromLTRB(12.w, 0, 12.w, 100.h),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: 20.h),
                        _GlassCard(
                          padding: EdgeInsets.zero,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: _buildJoinedSections(property),
                          ),
                        ),
                        SizedBox(height: 24.h),
                      ],
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar(
      Map<String, dynamic>? property, RentalProvider provider) {
    final status = property?['status'] ?? 'active';
    Color statusColor;
    switch (status) {
      case 'active':
        statusColor = _kGreen;
      case 'under_maintenance':
        statusColor = _kAmber;
      case 'inactive':
        statusColor = Colors.white38;
      default:
        statusColor = Colors.white38;
    }

    return SliverAppBar(
      expandedHeight: 260.h,
      pinned: true,
      backgroundColor: _kGradientTop.withOpacity(0.85),
      elevation: 0,
      leading: IconButton(
        icon: Container(
          padding: EdgeInsets.all(6.w),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 14.sp),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        if (property != null)
          PopupMenuButton<String>(
            icon: Container(
              padding: EdgeInsets.all(6.w),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Icon(Icons.more_vert, color: Colors.white, size: 14.sp),
            ),
            color: _kGradientMid,
            offset: const Offset(0, 40),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r)),
            onSelected: (value) {
              if (value == 'edit') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        EditPropertyScreen(property: property),
                  ),
                ).then((_) => context
                    .read<RentalProvider>()
                    .fetchPropertyDetails(widget.propertyId));
              } else if (value == 'delete') {
                _showDeleteConfirmation(context, property);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    const Icon(Icons.edit_outlined,
                        color: Colors.white70, size: 20),
                    SizedBox(width: 12.w),
                    Text(_loc.translate('edit'),
                        style: const TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(Icons.delete_outline,
                        color: Colors.redAccent, size: 20),
                    SizedBox(width: 12.w),
                    Text(_loc.translate('delete'),
                        style: const TextStyle(color: Colors.redAccent)),
                  ],
                ),
              ),
            ],
          ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: _HeroHeader(
          property: property,
          statusColor: statusColor,
          status: status,
        ),
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
        onSaved: () => context
            .read<RentalProvider>()
            .fetchPropertyDetails(propertyId),
      ),
    );
  }

  void _showDeleteConfirmation(
      BuildContext context, Map<String, dynamic> property) {
    showDialog(
      context: context,
      builder: (ctx) => _ConfirmDialog(
        title: _loc.translate("confirm_delete_property"),
        message:
            "${_loc.translate("confirm_delete")} '${property['name']}'? ${_loc.translate("cannot_be_undone")}",
        confirmLabel: _loc.translate("delete"),
        confirmColor: _kRed,
        onConfirm: () async {
          Navigator.pop(ctx);
          final provider = context.read<RentalProvider>();
          final success =
              await provider.deleteProperty(property['id'].toString());
          if (mounted) {
            if (success) {
              ThemeConstants.showSuccessSnackBar(
                  context, _loc.translate("property_delete_success"));
              Navigator.pop(context);
            } else {
              ThemeConstants.showErrorSnackBar(
                  context, _loc.translate("property_delete_failed"));
            }
          }
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Animated gradient background
// ─────────────────────────────────────────────
class _AnimatedBackground extends StatefulWidget {
  const _AnimatedBackground();
  @override
  State<_AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<_AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 8))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final t = _ctrl.value;
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _kGradientTop,
                Color.lerp(_kGradientMid, const Color(0xFF0A3A4A), t)!,
                _kGradientBottom,
              ],
              stops: const [0, 0.55, 1],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// Hero header (flexible space)
// ─────────────────────────────────────────────
class _HeroHeader extends StatelessWidget {
  const _HeroHeader({
    required this.property,
    required this.statusColor,
    required this.status,
  });
  final Map<String, dynamic>? property;
  final Color statusColor;
  final String status;

  @override
  Widget build(BuildContext context) {
    final String name = property?['name'] ?? '';
    final String type =
        property?['property_type_display'] ?? property?['property_type'] ?? '';
    final String initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Stack(
      children: [
        // Background arc decoration
        Positioned.fill(
          child: CustomPaint(painter: _ArcPainter()),
        ),
        // Subtle radial glow behind icon
        Positioned(
          top: 60.h,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              width: 120.w,
              height: 120.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  _kOrange.withOpacity(0.18),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
        ),
        // Content
        Positioned(
          bottom: 24.h,
          left: 0,
          right: 0,
          child: Column(
            children: [
              // Property icon
              Container(
                width: 82.w,
                height: 82.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      _kOrange.withOpacity(0.9),
                      const Color(0xFFFF6B35),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.3), width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: _kOrange.withOpacity(0.4),
                      blurRadius: 24,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(Icons.business_rounded,
                      color: Colors.white, size: 34.sp),
                ),
              ),
              SizedBox(height: 12.h),
              // Property name
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Text(name,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.4,
                    )),
              ),
              SizedBox(height: 4.h),
              if (type.isNotEmpty)
                Text(type,
                    style: TextStyle(
                        color: _kOrange.withOpacity(0.8),
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500)),
              SizedBox(height: 10.h),
              // Status badge
              Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 14.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(20.r),
                  border:
                      Border.all(color: statusColor.withOpacity(0.55)),
                  boxShadow: [
                    BoxShadow(
                        color: statusColor.withOpacity(0.2),
                        blurRadius: 8)
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6.w,
                      height: 6.w,
                      decoration: BoxDecoration(
                          color: statusColor, shape: BoxShape.circle),
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      (property?['status_display'] ?? status)
                          .toString()
                          .toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Arc painter for visual interest
// ─────────────────────────────────────────────
class _ArcPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          _kOrange.withOpacity(0.08),
          _kCyan.withOpacity(0.10),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Offset.zero & size)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, size.height * 0.6)
      ..quadraticBezierTo(size.width * 0.5, size.height * 0.3,
          size.width, size.height * 0.55)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, paint);

    final circlePaint = Paint()
      ..color = _kOrange.withOpacity(0.06)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.15),
        size.width * 0.18, circlePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────
// Glass card base
// ─────────────────────────────────────────────
class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child, this.padding});
  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.07),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: Colors.white.withOpacity(0.13)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: padding ??
                EdgeInsets.symmetric(horizontal: 12.w, vertical: 16.h),
            child: child,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Section divider widget (premium gradient line)
// ─────────────────────────────────────────────
class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          height: 2.h,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.0),
                Colors.white.withOpacity(0.08),
                _kOrange.withOpacity(0.45),
                Colors.white.withOpacity(0.08),
                Colors.white.withOpacity(0.0),
              ],
              stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Section title row
// ─────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.label, this.trailing});
  final IconData icon;
  final String label;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(7.w),
          decoration: BoxDecoration(
            color: _kOrange.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: _kOrange.withOpacity(0.25)),
          ),
          child: Icon(icon, color: _kOrange, size: 14.sp),
        ),
        SizedBox(width: 10.w),
        Text(label,
            style: TextStyle(
                color: Colors.white,
                fontSize: 14.sp,
                fontWeight: FontWeight.bold)),
        if (trailing != null) ...[const Spacer(), trailing!],
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Stat pill widget
// ─────────────────────────────────────────────
class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 8.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(6.w),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(icon, color: color, size: 18.sp),
          ),
          SizedBox(height: 8.h),
          Text(value,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold)),
          SizedBox(height: 2.h),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(label,
                style: TextStyle(
                    color: Colors.white54,
                    fontSize: 10.sp)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Detail table row (label : value)
// ─────────────────────────────────────────────
class _DetailTableRow extends StatelessWidget {
  const _DetailTableRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.showBorder,
    this.valueColor,
  });
  final String label;
  final String value;
  final IconData icon;
  final bool showBorder;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 11.h),
      decoration: BoxDecoration(
        border: showBorder
            ? Border(bottom: BorderSide(color: Colors.white.withOpacity(0.06)))
            : null,
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white24, size: 14.sp),
          SizedBox(width: 10.w),
          Expanded(
            flex: 2,
            child: Text(label,
                style: TextStyle(color: Colors.white54, fontSize: 11.sp)),
          ),
          Expanded(
            flex: 3,
            child: Text(value,
                style: TextStyle(
                    color: valueColor ?? Colors.white,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500),
                textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Detail grid row (2 items side by side)
// ─────────────────────────────────────────────
class _DetailGridRow extends StatelessWidget {
  const _DetailGridRow({
    required this.item1Label,
    required this.item1Value,
    required this.item1Icon,
    required this.item2Label,
    required this.item2Value,
    required this.item2Icon,
    required this.showBorder,
  });
  final String item1Label;
  final String item1Value;
  final IconData item1Icon;
  final String item2Label;
  final String item2Value;
  final IconData item2Icon;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 11.h),
      decoration: BoxDecoration(
        border: showBorder
            ? Border(bottom: BorderSide(color: Colors.white.withOpacity(0.06)))
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(item1Icon, color: Colors.white24, size: 14.sp),
                SizedBox(width: 6.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item1Label,
                          style: TextStyle(
                              color: Colors.white38, fontSize: 9.sp)),
                      SizedBox(height: 2.h),
                      Text(item1Value,
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 28.h,
            color: Colors.white.withOpacity(0.08),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: 12.w),
              child: Row(
                children: [
                  Icon(item2Icon, color: Colors.white24, size: 14.sp),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item2Label,
                            style: TextStyle(
                                color: Colors.white38, fontSize: 9.sp)),
                        SizedBox(height: 2.h),
                        Text(item2Value,
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Add House button
// ─────────────────────────────────────────────
class _AddHouseButton extends StatelessWidget {
  const _AddHouseButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final loc = LocalizationService.instance;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(10.r),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFF97316), Color(0xFFFF6B35)],
            ),
            borderRadius: BorderRadius.circular(10.r),
            boxShadow: [
              BoxShadow(
                  color: _kOrange.withOpacity(0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 3))
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_circle_outline_rounded,
                  color: Colors.white, size: 12.sp),
              SizedBox(width: 5.w),
              Text(loc.translate('add_house'),
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Gradient button
// ─────────────────────────────────────────────
class _GradientButton extends StatelessWidget {
  const _GradientButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(12.r),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFF97316), Color(0xFFFF6B35)],
            ),
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [
              BoxShadow(
                  color: _kOrange.withOpacity(0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4))
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 16.sp),
              SizedBox(width: 8.w),
              Text(label,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Confirm dialog
// ─────────────────────────────────────────────
class _ConfirmDialog extends StatelessWidget {
  const _ConfirmDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.confirmColor,
    required this.onConfirm,
  });
  final String title;
  final String message;
  final String confirmLabel;
  final Color confirmColor;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final loc = LocalizationService.instance;
    return AlertDialog(
      backgroundColor: _kGradientMid,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r)),
      title: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: confirmColor),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(title,
                style: TextStyle(
                    color: Colors.white, fontSize: 16.sp)),
          ),
        ],
      ),
      content: Text(
        message,
        style: TextStyle(color: Colors.white70, fontSize: 13.sp),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(loc.translate("no"),
              style: TextStyle(
                  color: Colors.white54, fontSize: 13.sp)),
        ),
        ElevatedButton(
          onPressed: onConfirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: confirmColor,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r)),
          ),
          child: Text(confirmLabel,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
