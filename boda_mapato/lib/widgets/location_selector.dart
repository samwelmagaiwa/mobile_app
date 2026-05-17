import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../services/api_service.dart';
import '../services/localization_service.dart';
import '../constants/theme_constants.dart';

class LocationSelector extends StatefulWidget {
  final Function(String? region, String? district, String? ward, String? street, String? place) onChanged;

  const LocationSelector({Key? key, required this.onChanged}) : super(key: key);

  @override
  State<LocationSelector> createState() => _LocationSelectorState();
}

class _LocationSelectorState extends State<LocationSelector> {
  final ApiService _api = ApiService();
  final _loc = LocalizationService.instance;

  List<dynamic> _regions = [];
  List<dynamic> _districts = [];
  List<dynamic> _wards = [];
  List<dynamic> _streets = [];
  List<dynamic> _places = [];

  String? _selectedCountryId = "TZ";
  String? _selectedRegionId;
  String? _selectedDistrictId;
  String? _selectedWardId;
  String? _selectedStreetId;
  String? _selectedPlaceId;

  bool _isLoadingRegions = false;
  bool _isLoadingDistricts = false;
  bool _isLoadingWards = false;
  bool _isLoadingStreets = false;
  bool _isLoadingPlaces = false;

  @override
  void initState() {
    super.initState();
    _fetchRegions();
  }

  void _triggerChanged() {
    String? regionName = _getName(_regions, _selectedRegionId);
    String? districtName = _getName(_districts, _selectedDistrictId);
    String? wardName = _getName(_wards, _selectedWardId);
    String? streetName = _getName(_streets, _selectedStreetId);
    String? placeName = _getName(_places, _selectedPlaceId);
    
    widget.onChanged(regionName, districtName, wardName, streetName, placeName);
  }

  String? _getName(List<dynamic> list, String? id) {
    if (id == null) return null;
    try {
      return list.firstWhere((element) => element['id'].toString() == id)['name']?.toString();
    } catch (_) {
      return null;
    }
  }

  Future<void> _fetchRegions() async {
    setState(() => _isLoadingRegions = true);
    try {
      final res = await _api.getLocationsRegions();
      if (mounted) setState(() => _regions = res['data'] ?? []);
    } catch (e) {
      debugPrint("Error fetching regions: $e");
    } finally {
      if (mounted) setState(() => _isLoadingRegions = false);
    }
  }

  Future<void> _fetchDistricts(String regionId) async {
    setState(() {
      _isLoadingDistricts = true;
      _districts = [];
      _wards = [];
      _streets = [];
      _places = [];
      _selectedDistrictId = null;
      _selectedWardId = null;
      _selectedStreetId = null;
      _selectedPlaceId = null;
    });
    try {
      final res = await _api.getLocationsDistricts(regionId);
      if (mounted) setState(() => _districts = res['data'] ?? []);
    } catch (e) {
      debugPrint("Error fetching districts: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoadingDistricts = false);
        _triggerChanged();
      }
    }
  }

  Future<void> _fetchWards(String districtId) async {
    setState(() {
      _isLoadingWards = true;
      _wards = [];
      _streets = [];
      _places = [];
      _selectedWardId = null;
      _selectedStreetId = null;
      _selectedPlaceId = null;
    });
    try {
      final res = await _api.getLocationsWards(districtId);
      if (mounted) setState(() => _wards = res['data'] ?? []);
    } catch (e) {
      debugPrint("Error fetching wards: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoadingWards = false);
        _triggerChanged();
      }
    }
  }

  Future<void> _fetchStreets(String wardId) async {
    setState(() {
      _isLoadingStreets = true;
      _streets = [];
      _places = [];
      _selectedStreetId = null;
      _selectedPlaceId = null;
    });
    try {
      final res = await _api.getLocationsStreets(wardId);
      if (mounted) setState(() => _streets = res['data'] ?? []);
    } catch (e) {
      debugPrint("Error fetching streets: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoadingStreets = false);
        _triggerChanged();
      }
    }
  }

  Future<void> _fetchPlaces(String streetId) async {
    setState(() {
      _isLoadingPlaces = true;
      _places = [];
      _selectedPlaceId = null;
    });
    try {
      final res = await _api.getLocationsPlaces(streetId);
      if (mounted) setState(() => _places = res['data'] ?? []);
    } catch (e) {
      debugPrint("Error fetching places: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoadingPlaces = false);
        _triggerChanged();
      }
    }
  }

  Widget _buildObjectDropdown(String label, String? valueId, List<dynamic> items, Function(String) onChanged, bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white70, fontSize: 12.sp)),
        SizedBox(height: 6.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.white12),
          ),
          child: isLoading 
            ? Padding(
                padding: EdgeInsets.symmetric(vertical: 14.h), 
                child: SizedBox(height: 16.h, width: 16.w, child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white70))
              )
            : DropdownButton<String>(
            value: valueId != null && items.any((i) => i['id'].toString() == valueId) ? valueId : null,
            isExpanded: true,
            dropdownColor: ThemeConstants.primaryBlue,
            underline: const SizedBox(),
            style: TextStyle(color: Colors.white, fontSize: 14.sp),
            hint: Text(_loc.translate('select'), style: const TextStyle(color: Colors.white38)),
            items: items.map((item) => DropdownMenuItem(
                  value: item['id'].toString(),
                  child: Text(item['name']?.toString() ?? ''),
                )).toList(),
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildObjectDropdown(
                "${_loc.translate('country')} *",
                _selectedCountryId,
                [{'id': 'TZ', 'name': 'Tanzania'}],
                (val) {
                  setState(() => _selectedCountryId = val);
                },
                false,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _buildObjectDropdown("${_loc.translate('region')} *", _selectedRegionId, _regions, (val) {
                setState(() {
                  _selectedRegionId = val;
                  _selectedDistrictId = null;
                  _selectedWardId = null;
                  _selectedStreetId = null;
                  _selectedPlaceId = null;
                  _districts = [];
                  _wards = [];
                  _streets = [];
                  _places = [];
                });
                _triggerChanged();
                _fetchDistricts(val);
              }, _isLoadingRegions),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        Row(
          children: [
            Expanded(
              child: _buildObjectDropdown("${_loc.translate('district')} *", _selectedDistrictId, _districts, (val) {
                setState(() {
                  _selectedDistrictId = val;
                  _selectedWardId = null;
                  _selectedStreetId = null;
                  _selectedPlaceId = null;
                  _wards = [];
                  _streets = [];
                  _places = [];
                });
                _triggerChanged();
                _fetchWards(val);
              }, _isLoadingDistricts),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _buildObjectDropdown(_loc.translate('ward'), _selectedWardId, _wards, (val) {
                setState(() {
                  _selectedWardId = val;
                  _selectedStreetId = null;
                  _selectedPlaceId = null;
                  _streets = [];
                  _places = [];
                });
                _triggerChanged();
                _fetchStreets(val);
              }, _isLoadingWards),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        if (_wards.isNotEmpty) Row(
          children: [
            Expanded(
              child: _buildObjectDropdown(_loc.translate('street'), _selectedStreetId, _streets, (val) {
                setState(() {
                  _selectedStreetId = val;
                  _selectedPlaceId = null;
                  _places = [];
                });
                _triggerChanged();
                _fetchPlaces(val);
              }, _isLoadingStreets),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _buildObjectDropdown(_loc.translate('place'), _selectedPlaceId, _places, (val) {
                setState(() => _selectedPlaceId = val);
                _triggerChanged();
              }, _isLoadingPlaces),
            ),
          ],
        ),
      ],
    );
  }
}
