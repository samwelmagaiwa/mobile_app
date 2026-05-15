import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../constants/theme_constants.dart';
import '../../providers/rental_provider.dart';
import '../../services/localization_service.dart';
import 'property_details_screen.dart';
import 'onboard_tenant_screen.dart';

class HouseDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> house;
  const HouseDetailsScreen({super.key, required this.house});

  @override
  State<HouseDetailsScreen> createState() => _HouseDetailsScreenState();
}

class _HouseDetailsScreenState extends State<HouseDetailsScreen> {
  Map<String, dynamic>? _houseData;
  bool _isVacating = false;

  @override
  void initState() {
    super.initState();
    _houseData = Map<String, dynamic>.from(widget.house);
    _loadFullDetails();
  }

  Future<void> _loadFullDetails() async {
    final fullData = await context
        .read<RentalProvider>()
        .fetchHouseDetails(widget.house['id'].toString());
    if (fullData != null && mounted) {
      setState(() {
        _houseData = Map<String, dynamic>.from(fullData);
      });
    }
  }

  @override
  void didUpdateWidget(covariant HouseDetailsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.house != oldWidget.house) {
      setState(() {
        _houseData = Map<String, dynamic>.from(widget.house);
      });
    }
  }

  Future<void> _handleVacate() async {
    final loc = LocalizationService.instance;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ThemeConstants.bgMid,
        title: Text(loc.translate("confirm_vacate"),
            style: const TextStyle(color: Colors.white)),
        content: Text(loc.translate("vacate_message"),
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(loc.translate("cancel"))),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(loc.translate("confirm"),
                style: const TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isVacating = true);
      final tenantId = widget.house['current_tenant_id']?.toString();
      if (tenantId != null) {
        final success = await context
            .read<RentalProvider>()
            .terminateTenantAgreement(tenantId);
        if (mounted) {
          setState(() => _isVacating = false);
          if (success) {
            ThemeConstants.showSuccessSnackBar(
                context, loc.translate("vacate_success"));
            Navigator.pop(context);
          } else {
            ThemeConstants.showErrorSnackBar(
                context, loc.translate("vacate_failed"));
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _houseData ??= Map<String, dynamic>.from(widget.house);
    final h = _houseData!;
    final loc = LocalizationService.instance;
    final isOccupied = h['status'] == 'occupied';

    return ThemeConstants.buildResponsiveScaffold(
      context,
      title: "${loc.translate('house')} ${h['house_number']}",
      actions: [
        IconButton(
          icon: const Icon(Icons.edit, color: Colors.white),
          onPressed: _showEditHouseDialog,
        ),
      ],
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            _buildStatusHeader(h),
            SizedBox(height: 16.h),
            _buildQuickStats(h),
            SizedBox(height: 16.h),
            if (isOccupied) _buildTenantSection(h),
            SizedBox(height: 16.h),
            _buildDetailsSection(h),
            SizedBox(height: 24.h),
            if (isOccupied)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isVacating ? null : _handleVacate,
                  icon: const Icon(Icons.exit_to_app, color: Colors.white),
                  label: Text(loc.translate("vacate_house")),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent.withOpacity(0.8),
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r)),
                  ),
                ),
              )
            else if (h['status'] == 'vacant')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OnboardTenantScreen(
                        preSelectedProperty: h['property'],
                        preSelectedHouse: _houseData,
                      ),
                    ),
                  ).then((_) {
                    context.read<RentalProvider>().fetchPropertyDetails(
                        h['property_id']?.toString() ?? '');
                  }),
                  icon: const Icon(Icons.person_add, color: Colors.white),
                  label: Text(loc.translate("onboard_tenant")),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ThemeConstants.primaryOrange,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader(Map<String, dynamic> h) {
    final loc = LocalizationService.instance;
    final status = h['status'] as String;
    Color color = ThemeConstants.successGreen;
    if (status == 'occupied') color = Colors.orange;
    if (status == 'maintenance') color = Colors.redAccent;

    return ThemeConstants.buildResponsiveGlassCardStatic(
      context,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PropertyDetailsScreen(
                    propertyId: h['property_id']?.toString() ?? ''),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(h['property_name'] ?? h['property']?['name'] ?? 'Property',
                    style: TextStyle(
                        color: ThemeConstants.primaryOrange,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600)),
                Text(h['type']?.toString().toUpperCase() ?? 'UNIT',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: color.withOpacity(0.5)),
            ),
            child: Text(loc.translate(status).toUpperCase(),
                style: TextStyle(
                    color: color,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  String _formatAmount(dynamic amount) {
    if (amount == null) return "0";
    if (amount is num) return amount.toInt().toString();
    if (amount is String) {
      final double? parsed = double.tryParse(amount);
      if (parsed != null) return parsed.toInt().toString();
    }
    return amount.toString();
  }

  Widget _buildQuickStats(Map<String, dynamic> h) {
    return Row(
      children: [
        Expanded(
            child: _buildStatItem(
                LocalizationService.instance.translate("rent"),
                "Tsh ${_formatAmount(h['rent_amount'])}",
                Icons.payments)),
        SizedBox(width: 12.w),
        Expanded(
            child: _buildStatItem(
                LocalizationService.instance.translate("deposit"),
                "Tsh ${_formatAmount(h['deposit_amount'])}",
                Icons.account_balance_wallet)),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return ThemeConstants.buildResponsiveGlassCardStatic(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: ThemeConstants.primaryOrange, size: 16.sp),
          SizedBox(height: 8.h),
          Text(label, style: TextStyle(color: Colors.white54, fontSize: 11.sp)),
          Text(value,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTenantSection(Map<String, dynamic> h) {
    final tenant = h['current_tenant'];
    final loc = LocalizationService.instance;
    return ThemeConstants.buildResponsiveGlassCard(
      context,
      onTap: () {
        if (tenant != null) {
          Navigator.pushNamed(context, '/rental/tenant-details',
              arguments: tenant);
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person,
                  color: ThemeConstants.primaryOrange, size: 16.sp),
              SizedBox(width: 8.w),
              Text(loc.translate("current_tenant"),
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold)),
              const Spacer(),
              const Icon(Icons.chevron_right, color: Colors.white38),
            ],
          ),
          Divider(color: Colors.white10, height: 24.h),
          Row(
            children: [
              CircleAvatar(
                radius: 20.r,
                backgroundColor: Colors.white10,
                child: Text(tenant?['name']?[0] ?? '?',
                    style: const TextStyle(color: Colors.white)),
              ),
              SizedBox(width: 12.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tenant?['name'] ?? 'N/A',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600)),
                  Text(tenant?['phone_number'] ?? 'N/A',
                      style: TextStyle(color: Colors.white54, fontSize: 11.sp)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsSection(Map<String, dynamic> h) {
    final loc = LocalizationService.instance;
    return ThemeConstants.buildResponsiveGlassCardStatic(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(loc.translate("unit_details"),
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold)),
          Divider(color: Colors.white10, height: 24.h),
          _buildInfoRow(loc.translate("electricity_meter"),
              h['electricity_meter'] ?? '-'),
          _buildInfoRow(loc.translate("water_meter"), h['water_meter'] ?? '-'),
          _buildInfoRow(
              loc.translate("bedrooms"), (h['bedrooms'] ?? 0).toString()),
          _buildInfoRow(
              loc.translate("bathrooms"), (h['bathrooms'] ?? 0).toString()),
          if (h['description'] != null) ...[
            SizedBox(height: 8.h),
            Text(loc.translate("notes"),
                style: TextStyle(color: Colors.white54, fontSize: 11.sp)),
            Text(h['description'],
                style: TextStyle(color: Colors.white70, fontSize: 12.sp)),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.white54, fontSize: 12.sp)),
          Text(value,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _showEditHouseDialog() {
    bool attemptedSubmit = false;
    final loc = LocalizationService.instance;
    final existing = _houseData!;
    final numberCtrl = TextEditingController(text: existing['house_number']);
    final rentCtrl = TextEditingController(text: _formatAmount(existing['rent_amount']));
    final depositCtrl = TextEditingController(text: _formatAmount(existing['deposit_amount']));
    final meterCtrl = TextEditingController(text: existing['electricity_meter']);
    final waterCtrl = TextEditingController(text: existing['water_meter']);
    final floorCtrl = TextEditingController(text: (existing['floor'] ?? '').toString());
    final sqmtrsCtrl = TextEditingController(text: (existing['square_meters'] ?? '').toString());
    final bedroomsCtrl = TextEditingController(text: (existing['bedrooms'] ?? '').toString());
    final bathroomsCtrl = TextEditingController(text: (existing['bathrooms'] ?? '').toString());
    final descCtrl = TextEditingController(text: existing['description'] ?? '');

    String type = existing['type'] ?? 'room';
    String status = existing['status'] ?? 'vacant';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
            color: ThemeConstants.primaryBlue,
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24.r),
                topRight: Radius.circular(24.r))),
        child: Column(
          children: [
            Container(
                margin: EdgeInsets.only(top: 12.h),
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2.r))),
            Padding(
              padding: EdgeInsets.all(20.w),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Hariri Nyumba",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold)),
                    IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close, color: Colors.white54)),
                  ]),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: StatefulBuilder(
                    builder: (ctx, setS) => Column(
                          children: [
                            _field(numberCtrl, "Namba ya Nyumba *", Icons.door_front_door,
                                onChanged: (v) => setS(() {}),
                                errorText: attemptedSubmit && numberCtrl.text.isEmpty
                                    ? loc.translate('field_required')
                                    : null),
                            SizedBox(height: 16.h),
                            Row(children: [
                              Expanded(child: _dropdown("Aina", type, ['room', 'apartment', 'studio', 'commercial', 'bedsitter', 'one_bedroom', 'two_bedroom'], (v) => setS(() => type = v))),
                              SizedBox(width: 12.w),
                              Expanded(child: _dropdown("Hali", status, ['vacant', 'occupied', 'maintenance', 'reserved'], (v) => setS(() => status = v))),
                            ]),
                            SizedBox(height: 16.h),
                            Row(children: [
                              Expanded(child: _numberField(rentCtrl, "Kodi (TSh) *",
                                  onChanged: (v) => setS(() {}),
                                  errorText: attemptedSubmit && rentCtrl.text.isEmpty
                                      ? loc.translate('field_required')
                                      : (attemptedSubmit && double.tryParse(rentCtrl.text) == null
                                          ? loc.translate('invalid_amount')
                                          : null))),
                              SizedBox(width: 12.w),
                              Expanded(child: _numberField(depositCtrl, "${loc.translate('deposit_amount')} (TSh)",
                                  onChanged: (v) => setS(() {}),
                                  errorText: (double.tryParse(depositCtrl.text) ?? 0) > (double.tryParse(rentCtrl.text) ?? 0)
                                      ? loc.translate('deposit_exceeds_rent')
                                      : null)),
                            ]),
                            SizedBox(height: 16.h),
                            Row(children: [
                              Expanded(child: _field(meterCtrl, "Namba ya Stima", Icons.bolt)),
                              SizedBox(width: 12.w),
                              Expanded(child: _field(waterCtrl, "Namba ya Maji", Icons.water_drop)),
                            ]),
                            SizedBox(height: 16.h),
                            Row(children: [
                              Expanded(child: _numberField(floorCtrl, "Ghorofa", prefixIcon: Icons.layers)),
                              SizedBox(width: 12.w),
                              Expanded(child: _numberField(sqmtrsCtrl, "Eneo (sqm)", prefixIcon: Icons.square_foot)),
                            ]),
                            SizedBox(height: 16.h),
                            Row(children: [
                              Expanded(child: _numberField(bedroomsCtrl, "Vyumba", prefixIcon: Icons.bed)),
                              SizedBox(width: 12.w),
                              Expanded(child: _numberField(bathroomsCtrl, "Vyoo/Mali", prefixIcon: Icons.bathtub)),
                            ]),
                            SizedBox(height: 16.h),
                            _field(descCtrl, "Maelezo", Icons.description, max: 3),
                            SizedBox(height: 32.h),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () async {
                                  setS(() => attemptedSubmit = true);
                                  if (numberCtrl.text.isNotEmpty &&
                                      rentCtrl.text.isNotEmpty) {
                                    final double rentAmt = double.tryParse(rentCtrl.text) ?? 0;
                                    final double depositAmt = double.tryParse(depositCtrl.text) ?? 0;
                                    if (depositAmt > rentAmt) return;
                                    
                                    final provider =
                                        context.read<RentalProvider>();
                                    final data = {
                                      'property_id': existing['property_id'],
                                      'house_number': numberCtrl.text,
                                      'rent_amount': double.parse(rentCtrl.text),
                                      'deposit_amount':
                                          double.tryParse(depositCtrl.text) ?? 0,
                                      'type': type,
                                      'status': status,
                                      'electricity_meter': meterCtrl.text,
                                      'water_meter': waterCtrl.text,
                                      'bedrooms': int.tryParse(bedroomsCtrl.text),
                                      'bathrooms': int.tryParse(bathroomsCtrl.text),
                                      'floor': int.tryParse(floorCtrl.text),
                                      'square_meters': int.tryParse(sqmtrsCtrl.text),
                                      'description': descCtrl.text,
                                    };
                                    final success = await provider.updateHouse(
                                        existing['id'], data);
                                    if (ctx.mounted) Navigator.pop(ctx);
                                    if (success && mounted) {
                                      setState(() {
                                        _houseData = {..._houseData!, ...data};
                                      });
                                    }
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: ThemeConstants.primaryOrange,
                                    padding: EdgeInsets.symmetric(vertical: 16.h),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12.r))),
                                child: Text("Sasisha",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w600)),
                              ),
                            ),
                            SizedBox(height: 20.h),
                          ],
                        )),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController? ctrl, String label, IconData icon,
      {int? max, String? errorText, void Function(String)? onChanged}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: errorText != null ? Colors.redAccent : Colors.white70, fontSize: 12.sp)),
      SizedBox(height: 6.h),
      TextField(
        controller: ctrl,
        onChanged: onChanged,
        maxLines: max,
        style: TextStyle(color: Colors.white, fontSize: 14.sp),
        decoration: InputDecoration(
          labelText: label,
          errorText: errorText,
          labelStyle: TextStyle(color: Colors.white70, fontSize: 12.sp),
          prefixIcon: Icon(icon, color: Colors.white38, size: 20.sp),
          filled: true,
          fillColor: Colors.white.withOpacity(0.05),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: errorText != null ? Colors.redAccent : Colors.white12)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: errorText != null ? Colors.redAccent : Colors.white12)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: ThemeConstants.primaryOrange)),
        ),
      ),
    ]);
  }

  Widget _dropdown(String label, String value, List<String> items,
      Function(String) onChange) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: Colors.white70, fontSize: 12.sp)),
      SizedBox(height: 6.h),
      Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.white12)),
        child: DropdownButton<String>(
          value: items.contains(value) ? value : (items.isNotEmpty ? items.first : null),
          isExpanded: true,
          dropdownColor: ThemeConstants.primaryBlue,
          underline: const SizedBox(),
          style: TextStyle(color: Colors.white, fontSize: 14.sp),
          items: items
              .map((i) => DropdownMenuItem(
                  value: i, child: Text(i.replaceAll('_', ' '))))
              .toList(),
          onChanged: (v) => onChange(v ?? items.first),
        ),
      ),
    ]);
  }

  Widget _numberField(TextEditingController? ctrl, String label,
      {IconData? prefixIcon, String? hint, String? errorText, void Function(String)? onChanged}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: errorText != null ? Colors.redAccent : Colors.white70, fontSize: 12.sp)),
      SizedBox(height: 6.h),
      TextField(
        controller: ctrl,
        onChanged: onChanged,
        keyboardType: TextInputType.number,
        style: TextStyle(color: Colors.white, fontSize: 14.sp),
        decoration: InputDecoration(
          prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: Colors.white38, size: 18.sp) : null,
          hintText: hint,
          errorText: errorText,
          hintStyle: TextStyle(color: Colors.white24),
          filled: true,
          fillColor: Colors.white.withOpacity(0.05),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: errorText != null ? Colors.redAccent : Colors.white12)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: errorText != null ? Colors.redAccent : Colors.white12)),
        ),
      ),
    ]);
  }
}
