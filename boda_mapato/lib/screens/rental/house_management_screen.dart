import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../../constants/theme_constants.dart';
import '../../providers/rental_provider.dart';
import '../../services/localization_service.dart';

class HouseManagementScreen extends StatefulWidget {
  final String propertyId;
  final String propertyName;
  const HouseManagementScreen(
      {super.key, required this.propertyId, required this.propertyName});

  @override
  State<HouseManagementScreen> createState() => _HouseManagementScreenState();
}

class _HouseManagementScreenState extends State<HouseManagementScreen> {
  List<dynamic> _houses = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHouses();
  }

  Future<void> _loadHouses() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final provider = context.read<RentalProvider>();
      final houses = await provider.fetchPropertyHouses(widget.propertyId);
      if (mounted)
        setState(() {
          _houses = houses;
          _isLoading = false;
        });
    } catch (e) {
      if (mounted)
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ThemeConstants.buildResponsiveScaffold(
      context,
      title: "Vyumba - ${widget.propertyName}",
      actions: [
        IconButton(
          icon: const Icon(Icons.add, color: Colors.white),
          onPressed: () => _showAddHouseDialog(),
        ),
      ],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _error != null
              ? _buildErrorState()
              : _houses.isEmpty
                  ? _buildEmptyState()
                  : _buildHouseList(),
    );
  }

  Widget _buildEmptyState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
                padding: EdgeInsets.all(24.w),
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle),
                child: Icon(Icons.door_front_door,
                    size: 64.sp, color: Colors.white38)),
            SizedBox(height: 24.h),
            Text("Hakuna vyumba",
                style: TextStyle(color: Colors.white54, fontSize: 18.sp)),
            SizedBox(height: 8.h),
            Text("Ongeza vyumba vya kukodisha",
                style: TextStyle(color: Colors.white38, fontSize: 14.sp)),
            SizedBox(height: 24.h),
            ElevatedButton.icon(
              onPressed: () => _showAddHouseDialog(),
              style: ElevatedButton.styleFrom(
                  backgroundColor: ThemeConstants.primaryOrange,
                  padding:
                      EdgeInsets.symmetric(horizontal: 24.w, vertical: 14.h)),
              icon: const Icon(Icons.add, color: Colors.white),
              label:
                  Text("Ongeza Nyumba", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

  Widget _buildErrorState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline,
                size: 64.sp, color: ThemeConstants.errorRed),
            SizedBox(height: 16.h),
            Text("Hitilafu",
                style: TextStyle(color: Colors.white, fontSize: 18.sp)),
            SizedBox(height: 8.h),
            Text(_error ?? '',
                style: TextStyle(color: Colors.white54, fontSize: 14.sp)),
            SizedBox(height: 16.h),
            ElevatedButton(
                onPressed: _loadHouses,
                style: ElevatedButton.styleFrom(
                    backgroundColor: ThemeConstants.primaryOrange),
                child: const Text("Retry")),
          ],
        ),
      );

  Widget _buildHouseList() => RefreshIndicator(
        onRefresh: _loadHouses,
        color: ThemeConstants.primaryOrange,
        child: ListView.builder(
          padding: EdgeInsets.all(16.w),
          itemCount: _houses.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) return _buildStatsHeader();
            final house = _houses[index - 1];
            return _buildHouseCard(house);
          },
        ),
      );

  Widget _buildStatsHeader() {
    final occupied = _houses.where((h) => h['status'] == 'occupied').length;
    final vacant = _houses.where((h) => h['status'] == 'vacant').length;
    final maintenance =
        _houses.where((h) => h['status'] == 'maintenance').length;

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16.r)),
      child: Row(
        children: [
          _buildMiniStat("Jumla", _houses.length.toString(), Colors.white),
          Container(width: 1, height: 30.h, color: Colors.white12),
          _buildMiniStat(
              "Imekalia", occupied.toString(), ThemeConstants.successGreen),
          Container(width: 1, height: 30.h, color: Colors.white12),
          _buildMiniStat(
              "Wazi", vacant.toString(), ThemeConstants.warningAmber),
          Container(width: 1, height: 30.h, color: Colors.white12),
          _buildMiniStat(
              "Matengenezo", maintenance.toString(), ThemeConstants.errorRed),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Expanded(
        child: Column(children: [
      Text(value,
          style: TextStyle(
              color: color, fontSize: 18.sp, fontWeight: FontWeight.bold)),
      Text(label, style: TextStyle(color: Colors.white54, fontSize: 10.sp)),
    ]));
  }

  Widget _buildHouseCard(Map<String, dynamic> house) {
    final status = house['status'] ?? 'vacant';
    final tenant = house['current_tenant'] as Map?;

    Color statusColor;
    String statusLabel;
    switch (status) {
      case 'occupied':
        statusColor = ThemeConstants.successGreen;
        statusLabel = 'Imekalia';
        break;
      case 'maintenance':
        statusColor = ThemeConstants.warningAmber;
        statusLabel = 'Matengenezo';
        break;
      case 'reserved':
        statusColor = ThemeConstants.primaryOrange;
        statusLabel = 'Hifadhi';
        break;
      default:
        statusColor = Colors.white54;
        statusLabel = 'Wazi';
    }

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: Colors.white.withOpacity(0.15))),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showHouseDetails(house),
          borderRadius: BorderRadius.circular(16.r),
          child: Padding(
            padding: EdgeInsets.all(14.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [
                            ThemeConstants.invAccent.withOpacity(0.3),
                            ThemeConstants.invAccent.withOpacity(0.1)
                          ]),
                          borderRadius: BorderRadius.circular(12.r)),
                      child: Icon(Icons.door_front_door,
                          color: ThemeConstants.invAccent, size: 22.sp),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(house['house_number'] ?? '',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600)),
                          Text(house['type'] ?? '',
                              style: TextStyle(
                                  color: Colors.white54, fontSize: 12.sp)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text("TSh ${_formatCurrency(house['rent_amount'])}",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold)),
                        Container(
                          margin: EdgeInsets.only(top: 4.h),
                          padding: EdgeInsets.symmetric(
                              horizontal: 8.w, vertical: 3.h),
                          decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10.r)),
                          child: Text(statusLabel,
                              style: TextStyle(
                                  color: statusColor,
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ],
                ),
                if (tenant != null) ...[
                  SizedBox(height: 8.h),
                  Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8.r)),
                    child: Row(
                      children: [
                        Icon(Icons.person, color: Colors.white54, size: 14.sp),
                        SizedBox(width: 6.w),
                        Text(tenant['name'] ?? '',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 12.sp)),
                        Spacer(),
                        Text(tenant['phone'] ?? '',
                            style: TextStyle(
                                color: Colors.white38, fontSize: 11.sp)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
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

  void _showAddHouseDialog({Map<String, dynamic>? existing}) {
    bool attemptedSubmit = false;
    final isEdit = existing != null;
    final numberCtrl = TextEditingController(text: existing?['house_number']);
    final rentCtrl =
        TextEditingController(text: existing != null ? _formatAmount(existing['rent_amount']) : '');
    final depositCtrl = TextEditingController(
        text: existing != null ? _formatAmount(existing['deposit_amount']) : '0');
    final meterCtrl =
        TextEditingController(text: existing?['electricity_meter']);
    final waterCtrl = TextEditingController(text: existing?['water_meter']);
    String type = existing?['type'] ?? 'room';
    String status = existing?['status'] ?? 'vacant';

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
                    Text(isEdit ? "Hariri Nyumba" : "Ongeza Nyumba",
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
                                    ? LocalizationService.instance.translate('field_required')
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
                                      ? LocalizationService.instance.translate('field_required')
                                      : (attemptedSubmit && double.tryParse(rentCtrl.text) == null
                                          ? LocalizationService.instance.translate('invalid_amount')
                                          : null))),
                              SizedBox(width: 12.w),
                              Expanded(child: _numberField(depositCtrl, "${LocalizationService.instance.translate('deposit_amount')} (TSh)",
                                  onChanged: (v) => setS(() {}),
                                  errorText: (double.tryParse(depositCtrl.text) ?? 0) > (double.tryParse(rentCtrl.text) ?? 0)
                                      ? LocalizationService.instance.translate('deposit_exceeds_rent')
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
                              Expanded(child: _numberField(null, "Vyumba vya Kulala", hint: "0")),
                              SizedBox(width: 12.w),
                              Expanded(child: _numberField(null, "Bafu", hint: "0")),
                            ]),
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
                                      'property_id': widget.propertyId,
                                      'house_number': numberCtrl.text,
                                      'rent_amount':
                                          double.parse(rentCtrl.text),
                                      'deposit_amount':
                                          double.tryParse(depositCtrl.text) ??
                                              0,
                                      'type': type,
                                      'status': status,
                                      'electricity_meter': meterCtrl.text,
                                      'water_meter': waterCtrl.text,
                                    };
                                    bool success;
                                    if (isEdit) {
                                      success = await provider.updateHouse(
                                          existing!['id'], data);
                                    } else {
                                      success =
                                          await provider.createHouse(data);
                                    }
                                    if (ctx.mounted) Navigator.pop(ctx);
                                    if (success) _loadHouses();
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        ThemeConstants.primaryOrange,
                                    padding:
                                        EdgeInsets.symmetric(vertical: 16.h),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12.r))),
                                child: Text(isEdit ? "Sasisha" : "Hifadhi",
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
      {String? hint, String? errorText, void Function(String)? onChanged}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: errorText != null ? Colors.redAccent : Colors.white70, fontSize: 12.sp)),
      SizedBox(height: 6.h),
      TextField(
        controller: ctrl,
        onChanged: onChanged,
        keyboardType: TextInputType.number,
        style: TextStyle(color: Colors.white, fontSize: 14.sp),
        decoration: InputDecoration(
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

  void _showHouseDetails(Map<String, dynamic> house) {
    final tenant = house['current_tenant'] as Map?;
    final status = house['status'] ?? 'vacant';
    Color statusColor;
    switch (status) {
      case 'occupied':
        statusColor = ThemeConstants.successGreen;
        break;
      case 'maintenance':
        statusColor = ThemeConstants.warningAmber;
        break;
      default:
        statusColor = Colors.white54;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
            color: ThemeConstants.primaryBlue,
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24.r),
                topRight: Radius.circular(24.r))),
        child: Column(children: [
          Container(
              margin: EdgeInsets.only(top: 12.h),
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2.r))),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20.w),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Container(
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(16.r)),
                        child: Icon(Icons.door_front_door,
                            color: statusColor, size: 32.sp),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(house['house_number'] ?? '',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 22.sp,
                                      fontWeight: FontWeight.bold)),
                              Text(
                                  "TSh ${_formatCurrency(house['rent_amount'])}/mwezi",
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 14.sp)),
                            ]),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 12.w, vertical: 6.h),
                        decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12.r)),
                        child: Text(_formatStatus(status),
                            style: TextStyle(
                                color: statusColor,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600)),
                      ),
                    ]),
                    SizedBox(height: 24.h),
                    _detailRow("Aina", house['type'] ?? '-'),
                    _detailRow(LocalizationService.instance.translate('deposit'),
                        "TSh ${_formatCurrency(house['deposit_amount'] ?? 0)}"),
                    _detailRow("Block", house['block']?['name'] ?? '-'),
                    if (house['electricity_meter'] != null)
                      _detailRow("Stima Meter", house['electricity_meter']),
                    if (house['water_meter'] != null)
                      _detailRow("Maji Meter", house['water_meter']),
                    if (house['bedrooms'] != null)
                      _detailRow(
                          "Vyumba vya Kulala", house['bedrooms'].toString()),
                    if (house['bathrooms'] != null)
                      _detailRow("Bafu", house['bathrooms'].toString()),
                    if (house['floor'] != null)
                      _detailRow("Ghorofa", house['floor'].toString()),
                    if (tenant != null) ...[
                      SizedBox(height: 20.h),
                      Container(
                        padding: EdgeInsets.all(14.w),
                        decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.1))),
                        child: Row(children: [
                          Icon(Icons.person,
                              color: ThemeConstants.successGreen, size: 20.sp),
                          SizedBox(width: 10.w),
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text("Mteja: ${tenant['name'] ?? ''}",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w500)),
                                Text(tenant['phone'] ?? '',
                                    style: TextStyle(
                                        color: Colors.white54,
                                        fontSize: 12.sp)),
                              ])),
                        ]),
                      ),
                    ],
                    SizedBox(height: 20.h),
                    Row(children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _showAddHouseDialog(existing: house);
                          },
                          icon: const Icon(Icons.edit, size: 18),
                          label: const Text("Hariri"),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: ThemeConstants.primaryOrange,
                              padding: EdgeInsets.symmetric(vertical: 12.h)),
                        ),
                      ),
                      if (status == 'vacant') ...[
                        SizedBox(width: 12.w),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              Navigator.pop(ctx);
                              final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (c) => AlertDialog(
                                        backgroundColor:
                                            ThemeConstants.primaryBlue,
                                        title: const Text("Futa Nyumba?",
                                            style:
                                                TextStyle(color: Colors.white)),
                                        content: const Text(
                                            "Huu utafuta nyumba hii",
                                            style: TextStyle(
                                                color: Colors.white70)),
                                        actions: [
                                          TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(c, false),
                                              child: const Text("Cancel")),
                                          TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(c, true),
                                              child: const Text("Futa",
                                                  style: TextStyle(
                                                      color: ThemeConstants
                                                          .errorRed))),
                                        ],
                                      ));
                              if (confirm == true) {
                                final provider = context.read<RentalProvider>();
                                await provider.deleteHouse(house['id']);
                                _loadHouses();
                              }
                            },
                            icon: const Icon(Icons.delete, size: 18),
                            label: const Text("Futa"),
                            style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    ThemeConstants.errorRed.withOpacity(0.3),
                                padding: EdgeInsets.symmetric(vertical: 12.h)),
                          ),
                        ),
                      ],
                    ]),
                  ]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _detailRow(String label, String value) => Padding(
        padding: EdgeInsets.only(bottom: 10.h),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: TextStyle(color: Colors.white54, fontSize: 14.sp)),
          Text(value,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500)),
        ]),
      );

  String _formatCurrency(num v) {
    if (v >= 1000000) return "${(v / 1000000).toStringAsFixed(0)}M";
    if (v >= 1000) return "${(v / 1000).toStringAsFixed(0)}K";
    return v.toInt().toString();
  }

  String _formatStatus(String s) => switch (s) {
        'occupied' => 'Imekalia',
        'maintenance' => 'Matengenezo',
        'reserved' => 'Hifadhi',
        _ => 'Wazi'
      };
}
