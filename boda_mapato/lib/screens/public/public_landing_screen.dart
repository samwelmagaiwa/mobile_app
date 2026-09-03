import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../config/api_config.dart';
import '../../constants/theme_constants.dart';
import '../../services/api_service.dart';
import '../../services/localization_service.dart';
import '../auth/login_screen.dart';

class PublicLandingScreen extends StatefulWidget {
  const PublicLandingScreen({super.key});
  @override
  State<PublicLandingScreen> createState() => _PublicLandingScreenState();
}

class _PublicLandingScreenState extends State<PublicLandingScreen> with TickerProviderStateMixin {
  final _loc = LocalizationService.instance;
  final _api = ApiService();
  final _searchCtrl = TextEditingController();

  List<dynamic> _houses = [];
  bool _isLoading = true;
  String? _filterType;
  
  // Advanced Filter state
  int? _minBedrooms;
  int? _minBathrooms;
  int? _maxDistance;
  bool? _hasFence;
  bool? _hasTiles;
  bool? _hasKitchen;
  bool? _hasMasterBedroom;
  bool? _hasSittingRoom;

  late AnimationController _heroAnim;
  late Animation<double> _heroFade;

  @override
  void initState() {
    super.initState();
    _heroAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _heroFade = CurvedAnimation(parent: _heroAnim, curve: Curves.easeOut);
    _heroAnim.forward();
    _loadHouses();
  }

  @override
  void dispose() {
    _heroAnim.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadHouses() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final result = await _api.getPublicHouses(
      search: _searchCtrl.text,
      type: _filterType,
      bedrooms: _minBedrooms,
      bathrooms: _minBathrooms,
      maxDistance: _maxDistance,
      hasFence: _hasFence,
      hasTiles: _hasTiles,
      hasKitchen: _hasKitchen,
      hasMasterBedroom: _hasMasterBedroom,
      hasSittingRoom: _hasSittingRoom,
    );
    if (!mounted) return;
    final data = result['data'];
    setState(() {
      if (data is List) {
        _houses = data;
      } else if (data is Map && data['data'] is List) {
        _houses = data['data'] as List;
      } else {
        _houses = [];
      }
      _isLoading = false;
    });
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: BoxDecoration(
            color: ThemeConstants.bgMid,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
          ),
          padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40.w, height: 4.h, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2.r)))),
            SizedBox(height: 20.h),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(_loc.translate('filters'), style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: () {
                  setModalState(() {
                    _minBedrooms = _minBathrooms = _maxDistance = null;
                    _hasFence = _hasTiles = _hasKitchen = _hasMasterBedroom = _hasSittingRoom = null;
                  });
                },
                child: Text(_loc.translate('reset'), style: TextStyle(color: ThemeConstants.primaryOrange, fontSize: 13.sp)),
              ),
            ]),
            Expanded(
              child: SingleChildScrollView(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  SizedBox(height: 16.h),
                  _filterSectionTitle(_loc.translate('rooms')),
                  Row(children: [
                    _countFilter(_loc.translate('bedrooms'), _minBedrooms, (v) => setModalState(() => _minBedrooms = v)),
                    SizedBox(width: 15.w),
                    _countFilter(_loc.translate('bathrooms'), _minBathrooms, (v) => setModalState(() => _minBathrooms = v)),
                  ]),
                  SizedBox(height: 24.h),
                  _filterSectionTitle(_loc.translate('distance_from_road') + ' (m)'),
                  _distanceSlider(_maxDistance, (v) => setModalState(() => _maxDistance = v)),
                  SizedBox(height: 24.h),
                  _filterSectionTitle(_loc.translate('house_features')),
                  Wrap(spacing: 8.w, runSpacing: 8.h, children: [
                    _featureToggle(_loc.translate('has_fence'), _hasFence, (v) => setModalState(() => _hasFence = v)),
                    _featureToggle(_loc.translate('has_tiles'), _hasTiles, (v) => setModalState(() => _hasTiles = v)),
                    _featureToggle(_loc.translate('has_kitchen'), _hasKitchen, (v) => setModalState(() => _hasKitchen = v)),
                    _featureToggle(_loc.translate('has_master_bedroom'), _hasMasterBedroom, (v) => setModalState(() => _hasMasterBedroom = v)),
                    _featureToggle(_loc.translate('has_sitting_room'), _hasSittingRoom, (v) => setModalState(() => _hasSittingRoom = v)),
                  ]),
                  SizedBox(height: 40.h),
                ]),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 10.h),
              child: ElevatedButton(
                onPressed: () { Navigator.pop(context); _loadHouses(); },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ThemeConstants.primaryOrange,
                  minimumSize: Size(double.infinity, 50.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
                ),
                child: Text(_loc.translate('apply_filters'), style: TextStyle(color: Colors.white, fontSize: 15.sp, fontWeight: FontWeight.bold)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _filterSectionTitle(String title) => Padding(
    padding: EdgeInsets.only(bottom: 12.h),
    child: Text(title, style: TextStyle(color: Colors.white70, fontSize: 13.sp, fontWeight: FontWeight.w600)),
  );

  Widget _countFilter(String label, int? value, Function(int?) onType) {
    return Expanded(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(color: Colors.white38, fontSize: 11.sp)),
        SizedBox(height: 6.h),
        Row(children: [1, 2, 3, 4].map((i) {
          final sel = value == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => onType(sel ? null : i),
              child: Container(
                margin: EdgeInsets.only(right: 4.w),
                height: 36.h,
                decoration: BoxDecoration(
                  color: sel ? ThemeConstants.primaryOrange : Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: sel ? ThemeConstants.primaryOrange : Colors.white12),
                ),
                child: Center(child: Text('$i+', style: TextStyle(color: sel ? Colors.white : Colors.white60, fontSize: 12.sp, fontWeight: FontWeight.bold))),
              ),
            ),
          );
        }).toList()),
      ]),
    );
  }

  Widget _distanceSlider(int? value, Function(int?) onChange) {
    return Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('0m', style: TextStyle(color: Colors.white38, fontSize: 11.sp)),
        Text(value == null ? _loc.translate('all') : '${value}m', style: TextStyle(color: ThemeConstants.primaryOrange, fontSize: 12.sp, fontWeight: FontWeight.bold)),
        Text('2000m+', style: TextStyle(color: Colors.white38, fontSize: 11.sp)),
      ]),
      Slider(
        value: (value ?? 2000).toDouble(),
        min: 0, max: 2000, divisions: 20,
        activeColor: ThemeConstants.primaryOrange,
        inactiveColor: Colors.white12,
        onChanged: (v) => onChange(v >= 2000 ? null : v.round()),
      ),
    ]);
  }

  Widget _featureToggle(String label, bool? value, Function(bool?) onToggle) {
    final sel = value == true;
    return GestureDetector(
      onTap: () => onToggle(sel ? null : true),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: sel ? ThemeConstants.primaryOrange : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: sel ? ThemeConstants.primaryOrange : Colors.white12),
        ),
        child: Text(label.replaceAll('?', ''), style: TextStyle(color: sel ? Colors.white : Colors.white60, fontSize: 12.sp)),
      ),
    );
  }

  String _imageUrl(String path) {
    if (path.startsWith('http')) return path;
    return '${ApiConfig.webBaseUrl}/storage/$path';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: ThemeConstants.dashboardBackground,
        child: SafeArea(
          child: Column(
            children: [
              // ── Top Bar ──
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                child: Row(
                  children: [
                    Icon(Icons.apartment, color: ThemeConstants.primaryOrange, size: 28.sp),
                    SizedBox(width: 8.w),
                    Text('All In', style: TextStyle(color: Colors.white, fontSize: 22.sp, fontWeight: FontWeight.bold)),
                    Text(' One', style: TextStyle(color: ThemeConstants.primaryOrange, fontSize: 22.sp, fontWeight: FontWeight.w300)),
                    const Spacer(),
                    _loginButton(),
                  ],
                ),
              ),

              // ── Header Section (Narrower & Simplified) ──
              FadeTransition(
                opacity: _heroFade,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10.w), // Slightly wider
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_loc.translate('find_dream_home'), style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.bold)),
                    SizedBox(height: 12.h),
                    Row(children: [
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          onSubmitted: (_) => _loadHouses(),
                          style: TextStyle(color: Colors.white, fontSize: 14.sp),
                          decoration: InputDecoration(
                            hintText: _loc.translate('search_houses'),
                            hintStyle: TextStyle(color: Colors.white38, fontSize: 13.sp),
                            prefixIcon: Icon(Icons.search, color: ThemeConstants.primaryOrange, size: 20.sp),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.06),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r), borderSide: BorderSide.none),
                            contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                          ),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      GestureDetector(
                        onTap: _showFilters,
                        child: Container(
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: (_minBedrooms != null || _minBathrooms != null || _maxDistance != null || _hasFence != null || _hasTiles != null || _hasKitchen != null)
                                ? ThemeConstants.primaryOrange
                                : Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(14.r),
                            border: Border.all(color: Colors.white.withOpacity(0.05)),
                          ),
                          child: Icon(Icons.tune, color: Colors.white, size: 20.sp),
                        ),
                      ),
                    ]),
                  ]),
                ),
              ),

              // ── Filter Chips ──
              SizedBox(height: 12.h),
              SizedBox(
                height: 36.h,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 10.w),
                  children: [null, 'room', 'apartment', 'studio', 'one_bedroom', 'two_bedroom', 'bedsitter'].map((t) {
                    final selected = _filterType == t;
                    return GestureDetector(
                      onTap: () { setState(() => _filterType = t); _loadHouses(); },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: EdgeInsets.only(right: 8.w),
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected ? ThemeConstants.primaryOrange : Colors.transparent,
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(
                            color: selected ? ThemeConstants.primaryOrange : Colors.white.withOpacity(0.15),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          t == null ? _loc.translate('all') : _loc.translate(t),
                          style: TextStyle(
                            color: selected ? Colors.white : Colors.white70,
                            fontSize: 12.sp,
                            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              SizedBox(height: 12.h),

              // ── House Results ──
              Expanded(
                child: _isLoading
                    ? _buildShimmer()
                    : _houses.isEmpty
                        ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.search_off, color: Colors.white24, size: 60.sp),
                            SizedBox(height: 12.h),
                            Text(_loc.translate('no_houses_available'), style: TextStyle(color: Colors.white54, fontSize: 15.sp)),
                          ]))
                        : RefreshIndicator(
                            onRefresh: _loadHouses,
                            color: ThemeConstants.primaryOrange,
                            child: ListView.builder(
                              padding: EdgeInsets.symmetric(horizontal: 10.w), // Wider view
                              itemCount: _houses.length,
                              itemBuilder: (context, i) => _buildHouseCard(_houses[i]),
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Login Button ──
  Widget _loginButton() {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [ThemeConstants.primaryOrange, Color(0xFFFF8C42)]),
          borderRadius: BorderRadius.circular(18.r),
          boxShadow: [BoxShadow(color: ThemeConstants.primaryOrange.withOpacity(0.2), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.login, color: Colors.white, size: 14.sp),
          SizedBox(width: 4.w),
          Text(_loc.translate('login'), style: TextStyle(color: Colors.white, fontSize: 12.sp, fontWeight: FontWeight.bold)),
        ]),
      ),
    );
  }

  // ── Shimmer loading ──
  Widget _buildShimmer() {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      itemCount: 4,
      itemBuilder: (_, __) => Container(
        height: 280.h,
        margin: EdgeInsets.only(bottom: 16.h),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Center(child: CircularProgressIndicator(color: ThemeConstants.primaryOrange.withOpacity(0.3), strokeWidth: 2)),
      ),
    );
  }

  // ── House Card ──
  Widget _buildHouseCard(Map<String, dynamic> house) {
    final images = (house['images'] ?? []) as List;
    final captions = (house['image_captions'] ?? []) as List;
    final property = house['property'] as Map<String, dynamic>?;
    final propertyName = property?['name'] ?? '';
    final address = property?['address'] ?? property?['street'] ?? '';
    final rent = house['rent_amount'];
    final type = house['type'] ?? '';
    final bedrooms = house['bedrooms']?.toString() ?? '';
    final bathrooms = house['bathrooms']?.toString() ?? '';
    final description = house['description'] ?? '';

    // Boolean features
    final hasFence = house['has_fence'] == true || house['has_fence'] == 1;
    final hasTiles = house['has_tiles'] == true || house['has_tiles'] == 1;
    final hasKitchen = house['has_kitchen'] == true || house['has_kitchen'] == 1;
    final hasSitting = house['has_sitting_room'] == true || house['has_sitting_room'] == 1;
    final hasMaster = house['has_master_bedroom'] == true || house['has_master_bedroom'] == 1;
    final landlordPresent = house['landlord_lives_present'] == true || house['landlord_lives_present'] == 1;

    final kitchenLoc = house['kitchen_location'] ?? '';
    final distRoad = house['distance_from_road'] ?? '';
    final elecType = house['electricity_type'] ?? '';
    final waterType = house['water_type'] ?? '';

    return Container(
      margin: EdgeInsets.only(bottom: 20.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Image Gallery ──
        if (images.isNotEmpty)
          _HouseImageCarousel(
            images: images.map((e) => _imageUrl(e.toString())).toList(),
            captions: captions.map((e) => e.toString()).toList(),
          )
        else
          Container(
            height: 180.h,
            color: Colors.white.withOpacity(0.04),
            child: Center(child: Icon(Icons.image_not_supported, color: Colors.white24, size: 50.sp)),
          ),

        Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // ── Price & Type Badge ──
            Row(children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text('TZS ${_formatPrice(rent)}', style: TextStyle(color: ThemeConstants.primaryOrange, fontSize: 20.sp, fontWeight: FontWeight.bold)),
                    Text(' /${_loc.translate('month').toLowerCase()}', style: TextStyle(color: Colors.white54, fontSize: 12.sp)),
                  ]),
                  if (house['status'] == 'maintenance' && house['maintenance_until'] != null)
                    Padding(
                      padding: EdgeInsets.only(top: 4.h),
                      child: Text(
                        "${_loc.translate('available_from')}: ${house['maintenance_until']}",
                        style: TextStyle(color: Colors.blueAccent, fontSize: 11.sp, fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: ThemeConstants.primaryOrange.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: ThemeConstants.primaryOrange.withOpacity(0.3)),
                    ),
                    child: Text(_loc.translate(type), style: TextStyle(color: ThemeConstants.primaryOrange, fontSize: 11.sp, fontWeight: FontWeight.w600)),
                  ),
                  if (house['status'] == 'maintenance')
                    Padding(
                      padding: EdgeInsets.only(top: 6.h),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(color: Colors.blue.withOpacity(0.2)),
                        ),
                        child: Text(
                          _loc.translate('under_maintenance'),
                          style: TextStyle(color: Colors.blueAccent, fontSize: 9.sp, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
            ]),
            SizedBox(height: 12.h),

            // ── Property & Location ──
            if (propertyName.isNotEmpty)
              Row(children: [
                Icon(Icons.apartment, color: Colors.white54, size: 14.sp),
                SizedBox(width: 4.w),
                Expanded(child: Text(propertyName, style: TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis)),
              ]),
            if (address.isNotEmpty) ...[
              SizedBox(height: 4.h),
              Row(children: [
                Icon(Icons.location_on, color: Colors.white38, size: 13.sp),
                SizedBox(width: 4.w),
                Expanded(child: Text(address, style: TextStyle(color: Colors.white54, fontSize: 12.sp), maxLines: 1, overflow: TextOverflow.ellipsis)),
              ]),
            ],
            
            // ── Landlord Presence & Notes ──
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(
                    landlordPresent ? Icons.home_work : Icons.house_outlined,
                    color: landlordPresent ? ThemeConstants.primaryOrange : Colors.white38,
                    size: 16.sp,
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    landlordPresent ? _loc.translate('landlord_status_on') : _loc.translate('landlord_status_off'),
                    style: TextStyle(
                      color: landlordPresent ? ThemeConstants.primaryOrange.withOpacity(0.8) : Colors.white38,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ]),
                if (description.isNotEmpty) ...[
                  SizedBox(height: 8.h),
                  Text(
                    description,
                    style: TextStyle(color: Colors.white60, fontSize: 11.sp, fontStyle: FontStyle.italic),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ]),
            ),
            SizedBox(height: 12.h),

            // ── Quick Stats (bedrooms, bathrooms) ──
            Row(children: [
              if (bedrooms.isNotEmpty && bedrooms != '0') _statChip(Icons.bed, bedrooms, _loc.translate('bedrooms')),
              if (bathrooms.isNotEmpty && bathrooms != '0') _statChip(Icons.bathtub_outlined, bathrooms, _loc.translate('bathrooms')),
              if (distRoad.isNotEmpty) _statChip(Icons.add_road, distRoad, _loc.translate('from_road')),
            ]),
            SizedBox(height: 12.h),

            // ── Feature Chips ──
            Wrap(spacing: 6.w, runSpacing: 6.h, children: [
              if (hasFence) _featureTag(Icons.fence, _loc.translate('has_fence').replaceAll('?', '')),
              if (hasTiles) _featureTag(Icons.grid_on, _loc.translate('has_tiles').replaceAll('?', '')),
              if (hasMaster) _featureTag(Icons.king_bed, _loc.translate('has_master_bedroom').replaceAll('?', '')),
              if (hasSitting) _featureTag(Icons.weekend, _loc.translate('has_sitting_room').replaceAll('?', '')),
              if (hasKitchen) _featureTag(Icons.kitchen, '${_loc.translate('has_kitchen').replaceAll('?', '')} ${kitchenLoc.isNotEmpty ? '(${_loc.translate(kitchenLoc)})' : ''}'),
              if (elecType.isNotEmpty) _featureTag(Icons.bolt, '${_loc.translate('electricity_type')}: ${_loc.translate(elecType)}'),
              if (waterType.isNotEmpty) _featureTag(Icons.water_drop, '${_loc.translate('water_type')}: ${_loc.translate(waterType)}'),
            ]),
          ]),
        ),
      ]),
    );
  }

  Widget _statChip(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.only(right: 6.w),
        padding: EdgeInsets.symmetric(vertical: 8.h),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Column(children: [
          Icon(icon, color: ThemeConstants.primaryOrange, size: 18.sp),
          SizedBox(height: 2.h),
          Text(value, style: TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.bold)),
          Text(label, style: TextStyle(color: Colors.white38, fontSize: 9.sp)),
        ]),
      ),
    );
  }

  Widget _featureTag(IconData icon, String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: ThemeConstants.successGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: ThemeConstants.successGreen.withOpacity(0.25)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: ThemeConstants.successGreen, size: 12.sp),
        SizedBox(width: 4.w),
        Text(label, style: TextStyle(color: ThemeConstants.successGreen, fontSize: 10.sp)),
      ]),
    );
  }

  String _formatPrice(dynamic v) {
    if (v == null) return '0';
    final n = double.tryParse(v.toString()) ?? 0;
    final s = n.toInt().toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  String _formatDistance(dynamic v) {
    if (v == null || v.toString().isEmpty) return '';
    String val = v.toString().toLowerCase().trim();
    double n = 0;
    if (val.endsWith('km')) {
      n = (double.tryParse(val.replaceAll('km', '').trim()) ?? 0) * 1000;
    } else if (val.endsWith('m')) {
      n = double.tryParse(val.replaceAll('m', '').trim()) ?? 0;
    } else {
      n = double.tryParse(val) ?? 0;
    }
    
    if (n >= 1000) {
      return '${(n / 1000).toStringAsFixed(1)}km';
    }
    return '${n.toInt()}m';
  }
}

// ── Image Carousel with 3D parallax ──

class _HouseImageCarousel extends StatefulWidget {
  final List<String> images;
  final List<String> captions;
  const _HouseImageCarousel({required this.images, this.captions = const []});
  @override
  State<_HouseImageCarousel> createState() => _HouseImageCarouselState();
}

class _HouseImageCarouselState extends State<_HouseImageCarousel> {
  final PageController _ctrl = PageController(viewportFraction: 1.0);
  int _current = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Auto-play timer: cycle images every 3 seconds
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (widget.images.length > 1 && _ctrl.hasClients) {
        final next = (_current + 1) % widget.images.length;
        _ctrl.animateToPage(
          next,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220.h,
      child: Stack(children: [
        PageView.builder(
          controller: _ctrl,
          onPageChanged: (i) => setState(() => _current = i),
          itemCount: widget.images.length,
          itemBuilder: (_, i) => Stack(fit: StackFit.expand, children: [
            Image.network(
              widget.images[i],
              fit: BoxFit.cover,
              width: double.infinity,
              errorBuilder: (_, __, ___) => Container(
                color: Colors.white.withOpacity(0.04),
                child: Center(child: Icon(Icons.broken_image, color: Colors.white24, size: 40.sp)),
              ),
            ),
            // Caption Overlay
            if (widget.captions.length > i && widget.captions[i].isNotEmpty)
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Container(
                  padding: EdgeInsets.fromLTRB(12.w, 15.h, 12.w, 25.h),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                    ),
                  ),
                  child: Text(
                    widget.captions[i],
                    style: TextStyle(color: Colors.white, fontSize: 13.sp, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
          ]),
        ),
        // Counter badge
        Positioned(
          top: 10.h, right: 12.w,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Text('${_current + 1}/${widget.images.length}', style: TextStyle(color: Colors.white, fontSize: 11.sp, fontWeight: FontWeight.w600)),
          ),
        ),
        // Dot indicators
        if (widget.images.length > 1)
          Positioned(
            bottom: 10.h,
            left: 0, right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.images.length, (i) => Container(
                width: _current == i ? 18.w : 6.w,
                height: 5.h,
                margin: EdgeInsets.symmetric(horizontal: 2.w),
                decoration: BoxDecoration(
                  color: _current == i ? ThemeConstants.primaryOrange : Colors.white30,
                  borderRadius: BorderRadius.circular(3.r),
                ),
              )),
            ),
          ),
      ]),
    );
  }
}
