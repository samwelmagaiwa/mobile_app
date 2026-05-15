import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../../constants/theme_constants.dart';
import '../../providers/rental_provider.dart';
import '../../services/localization_service.dart';

class RentalPropertiesScreen extends StatefulWidget {
  const RentalPropertiesScreen({super.key});

  @override
  State<RentalPropertiesScreen> createState() => _RentalPropertiesScreenState();
}

class _RentalPropertiesScreenState extends State<RentalPropertiesScreen> {
  final List<String> _propertyTypes = [
    'apartment',
    'rental_compound',
    'standalone_house',
    'hostel',
    'commercial_building',
    'mixed_use',
    'office_space',
    'shop_units'
  ];

  final List<String> _regions = [
    'Dar es Salaam',
    'Arusha',
    'Mwanza',
    'Dodoma',
    'Mbeya',
    'Morogoro',
    'Tanga',
    'Kilimanjaro',
    'Pwani',
    'Kigoma'
  ];

  final TextEditingController _searchController = TextEditingController();
  String? _selectedStatus;
  String? _selectedType;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProperties();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadProperties() {
    context.read<RentalProvider>().fetchPropertiesWithPagination(
          search: _searchQuery.isNotEmpty ? _searchQuery : null,
          status: _selectedStatus,
        );
  }

  void _onSearchChanged(String query) {
    setState(() => _searchQuery = query);
    context.read<RentalProvider>().resetPagination();
    _loadProperties();
  }

  void _applyFilter({String? status, String? type}) {
    setState(() {
      _selectedStatus = status;
      _selectedType = type;
    });
    context.read<RentalProvider>().resetPagination();
    _loadProperties();
  }

  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _selectedStatus = null;
      _selectedType = null;
      _searchController.clear();
    });
    context.read<RentalProvider>().resetPagination();
    _loadProperties();
  }

  @override
  Widget build(BuildContext context) {
    final rentalProvider = context.watch<RentalProvider>();
    final properties = rentalProvider.properties;

    return ThemeConstants.buildResponsiveScaffold(
      context,
      title: "Mali ya Upangaji",
      actions: [
        IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () => _showAddPropertyDialog(context)),
      ],
      body: Column(
        children: [
          _buildSearchAndFilter(),
          Expanded(
            child: rentalProvider.isLoading && properties.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white))
                : properties.isEmpty
                    ? _buildEmptyState()
                    : _buildPropertyList(properties),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          // Search Bar
          TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "Tafuta mali...",
              hintStyle: TextStyle(color: Colors.white38),
              prefixIcon: Icon(Icons.search, color: Colors.white38),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: Colors.white38),
                      onPressed: _clearFilters)
                  : null,
              filled: true,
              fillColor: Colors.white.withOpacity(0.1),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide.none),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            ),
          ),
          SizedBox(height: 12.h),
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip("All", null,
                    _selectedStatus == null && _selectedType == null),
                SizedBox(width: 8.w),
                _buildFilterChip("Hai", "active", _selectedStatus == "active"),
                SizedBox(width: 8.w),
                _buildFilterChip(
                    "Si Hai", "inactive", _selectedStatus == "inactive"),
                SizedBox(width: 8.w),
                _buildFilterChip("Matengenezo", "under_maintenance",
                    _selectedStatus == "under_maintenance"),
                SizedBox(width: 8.w),
                _buildFilterChip(
                    "Apartment", "apartment", _selectedType == "apartment",
                    isType: true),
                SizedBox(width: 8.w),
                _buildFilterChip("Hostel", "hostel", _selectedType == "hostel",
                    isType: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String? value, bool isSelected,
      {bool isType = false}) {
    return GestureDetector(
      onTap: () {
        if (isType) {
          _applyFilter(type: isSelected ? null : value);
        } else {
          _applyFilter(status: isSelected ? null : value);
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected
              ? ThemeConstants.primaryOrange
              : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
              color:
                  isSelected ? ThemeConstants.primaryOrange : Colors.white12),
        ),
        child: Text(label,
            style: TextStyle(
                color: Colors.white,
                fontSize: 12.sp,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
      ),
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
            child: Icon(Icons.apartment, size: 64.sp, color: Colors.white38),
          ),
          SizedBox(height: 24.h),
          Text(
            "Hakuna mali iliyosajiliwa",
            style: TextStyle(
                color: Colors.white54,
                fontSize: 18.sp,
                fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 8.h),
          Text(
            "Bonyeza kitufe hapo chini kuongeza",
            style: TextStyle(color: Colors.white38, fontSize: 14.sp),
          ),
          SizedBox(height: 24.h),
          ElevatedButton.icon(
            onPressed: () => _showAddPropertyDialog(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: ThemeConstants.primaryOrange,
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 14.h),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r)),
            ),
            icon: const Icon(Icons.add, color: Colors.white),
            label: Text("Ongeza Mali",
                style: TextStyle(color: Colors.white, fontSize: 16.sp)),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyList(List properties) {
    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: properties.length,
      itemBuilder: (context, index) {
        final property = properties[index] as Map<String, dynamic>;
        return _buildPropertyCard(property);
      },
    );
  }

  Widget _buildPropertyCard(Map<String, dynamic> property) {
    final houses = property['houses'] as List? ?? [];
    final occupiedCount = houses.where((h) => h['status'] == 'occupied').length;
    final status = property['status'] ?? 'active';

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

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showPropertyDetails(property),
          borderRadius: BorderRadius.circular(20.r),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(14.w),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            ThemeConstants.primaryOrange.withOpacity(0.3),
                            ThemeConstants.primaryOrange.withOpacity(0.1)
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: Icon(Icons.apartment,
                          color: ThemeConstants.primaryOrange, size: 28.sp),
                    ),
                    SizedBox(width: 14.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            property['name'] ?? '',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4.h),
                          Row(
                            children: [
                              Icon(Icons.location_on,
                                  size: 14.sp, color: Colors.white54),
                              SizedBox(width: 4.w),
                              Expanded(
                                child: Text(
                                  "${property['district'] ?? ''}, ${property['region'] ?? ''}",
                                  style: TextStyle(
                                      color: Colors.white54, fontSize: 12.sp),
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
                      padding:
                          EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        status.toString().replaceAll('_', ' '),
                        style: TextStyle(
                            color: statusColor,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                          Icons.home, "${houses.length}", "Nyumba"),
                    ),
                    Container(width: 1, height: 30.h, color: Colors.white12),
                    Expanded(
                      child: _buildStatItem(
                          Icons.person, "$occupiedCount", "Wenyeji"),
                    ),
                    Container(width: 1, height: 30.h, color: Colors.white12),
                    Expanded(
                      child: _buildStatItem(Icons.meeting_room,
                          "${houses.length - occupiedCount}", "Wazi",
                          color: houses.length - occupiedCount > 0
                              ? ThemeConstants.successGreen
                              : null),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    if (property['property_type'] != null)
                      _buildInfoChip(
                          _formatPropertyType(property['property_type'])),
                    SizedBox(width: 8.w),
                    if (property['default_billing_cycle'] != null)
                      _buildInfoChip(property['default_billing_cycle']),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label,
      {Color? color}) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16.sp, color: color ?? Colors.white54),
            SizedBox(width: 6.w),
            Text(value,
                style: TextStyle(
                    color: color ?? Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold)),
          ],
        ),
        SizedBox(height: 2.h),
        Text(label, style: TextStyle(color: Colors.white38, fontSize: 10.sp)),
      ],
    );
  }

  Widget _buildInfoChip(String label, {Color? color}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: (color ?? Colors.white).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Text(label,
          style: TextStyle(color: color ?? Colors.white70, fontSize: 11.sp)),
    );
  }

  String _formatPropertyType(String type) {
    return type
        .replaceAll('_', ' ')
        .split(' ')
        .map(
            (w) => w.isNotEmpty ? "${w[0].toUpperCase()}${w.substring(1)}" : "")
        .join(' ');
  }

  void _showAddPropertyDialog(BuildContext context) {
    final nameController = TextEditingController();
    final addressController = TextEditingController();
    String? selectedRegion;
    String? selectedDistrict;
    String selectedType = 'apartment';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: ThemeConstants.primaryBlue,
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24.r), topRight: Radius.circular(24.r)),
        ),
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.only(top: 12.h),
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2.r)),
            ),
            Padding(
              padding: EdgeInsets.all(20.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Ongeza Mali",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold)),
                  IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white54)),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: StatefulBuilder(
                  builder: (context, setState) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle("Taarifa za Msingi"),
                      SizedBox(height: 12.h),
                      _buildTextField(
                          nameController, "Jina la Mali *", Icons.apartment),
                      SizedBox(height: 16.h),
                      _buildDropdown(
                          "Aina ya Mali *",
                          selectedType,
                          _propertyTypes,
                          (v) => setState(() => selectedType = v!),
                          _formatPropertyType),
                      SizedBox(height: 16.h),
                      _buildTextField(addressController, "Anuani ya Makazi *",
                          Icons.location_on,
                          maxLines: 2),
                      SizedBox(height: 24.h),
                      _buildSectionTitle("Location"),
                      SizedBox(height: 12.h),
                      Row(
                        children: [
                          Expanded(
                              child: _buildDropdown(
                                  "Mkoa *",
                                  selectedRegion,
                                  _regions,
                                  (v) => setState(() => selectedRegion = v),
                                  (v) => v)),
                          SizedBox(width: 12.w),
                          Expanded(
                              child: _buildTextField(
                                  null, "Wilaya *", Icons.location_city,
                                  hint: "Jina la Wilaya")),
                        ],
                      ),
                      SizedBox(height: 16.h),
                      Row(
                        children: [
                          Expanded(
                              child: _buildTextField(
                                  null, "Kata", Icons.location_on,
                                  hint: "Jina la Kata")),
                          SizedBox(width: 12.w),
                          Expanded(
                              child: _buildTextField(
                                  null, "Mtaa", Icons.streetview,
                                  hint: "Jina la Mtaa")),
                        ],
                      ),
                      SizedBox(height: 24.h),
                      _buildSectionTitle("Usimamizi"),
                      SizedBox(height: 12.h),
                      Row(
                        children: [
                          Expanded(
                              child: _buildNumberField("Idadi ya Blocks", "1")),
                          SizedBox(width: 12.w),
                          Expanded(
                              child: _buildNumberField("Jumla ya Vyumba", "0")),
                        ],
                      ),
                      SizedBox(height: 16.h),
                      Row(
                        children: [
                          Expanded(
                              child: _buildDropdown(
                                  "Kipindi cha Kodi",
                                  "monthly",
                                  ["monthly", "quarterly", "yearly"],
                                  (v) {},
                                  (v) => v == 'monthly'
                                      ? "Mwezi"
                                      : v == 'quarterly'
                                          ? "Robo"
                                          : "Mwaka")),
                          SizedBox(width: 12.w),
                          Expanded(
                              child: _buildDropdown("Sarafu", "TZS",
                                  ["TZS", "USD"], (v) {}, (v) => v)),
                        ],
                      ),
                      SizedBox(height: 24.h),
                      _buildSectionTitle("Kiwango cha Default (Optional)"),
                      SizedBox(height: 12.h),
                      Row(
                        children: [
                          Expanded(
                              child: _buildNumberField("Kodi Default", "0",
                                  prefix: "TSh ")),
                          SizedBox(width: 12.w),
                          Expanded(
                              child: _buildNumberField("${LocalizationService.instance.translate('deposit')} Default", "0",
                                  prefix: "TSh ")),
                        ],
                      ),
                      SizedBox(height: 32.h),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (nameController.text.isNotEmpty &&
                                addressController.text.isNotEmpty) {
                              final provider = context.read<RentalProvider>();
                              await provider.addProperty({
                                'name': nameController.text,
                                'property_type': selectedType,
                                'address': addressController.text,
                                'region': selectedRegion ?? 'Dar es Salaam',
                                'district': 'Default',
                                'billing_cycle': 'monthly',
                                'currency': 'TZS',
                              });
                              if (context.mounted) Navigator.pop(context);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ThemeConstants.primaryOrange,
                            padding: EdgeInsets.symmetric(vertical: 16.h),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r)),
                          ),
                          child: Text("Hifadhi",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                      SizedBox(height: 20.h),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title,
        style: TextStyle(
            color: Colors.white70,
            fontSize: 14.sp,
            fontWeight: FontWeight.w600));
  }

  Widget _buildTextField(
      TextEditingController? controller, String label, IconData icon,
      {int maxLines = 1, String? hint}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(color: Colors.white, fontSize: 14.sp),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white24, fontSize: 14.sp),
        labelStyle: TextStyle(color: Colors.white70, fontSize: 12.sp),
        prefixIcon: Icon(icon, color: Colors.white38, size: 20.sp),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide(color: Colors.white12)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide(color: Colors.white12)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide(color: ThemeConstants.primaryOrange)),
      ),
    );
  }

  Widget _buildDropdown(String label, String? value, List<String> items,
      Function(String) onChanged, String Function(String) formatter) {
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
          child: DropdownButton<String>(
            value: (value != null && items.contains(value)) ? value : null,
            isExpanded: true,
            dropdownColor: ThemeConstants.primaryBlue,
            underline: const SizedBox(),
            style: TextStyle(color: Colors.white, fontSize: 14.sp),
            hint: Text("Chagua", style: TextStyle(color: Colors.white38)),
            items: items
                .map((item) => DropdownMenuItem(
                      value: item,
                      child: Text(formatter(item)),
                    ))
                .toList(),
            onChanged: (v) => onChanged(v ?? items.first),
          ),
        ),
      ],
    );
  }

  Widget _buildNumberField(String label, String hint, {String prefix = ""}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white70, fontSize: 12.sp)),
        SizedBox(height: 6.h),
        TextField(
          keyboardType: TextInputType.number,
          style: TextStyle(color: Colors.white, fontSize: 14.sp),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white24),
            prefixText: prefix,
            prefixStyle: TextStyle(color: Colors.white54),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: Colors.white12)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: Colors.white12)),
          ),
        ),
      ],
    );
  }

  void _showAddHouseDialog(BuildContext context, String propertyId) {
    final houseNumberController = TextEditingController();
    final rentController = TextEditingController();
    final depositController = TextEditingController(text: "0");
    String selectedType = 'room';
    String selectedStatus = 'vacant';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: ThemeConstants.primaryBlue,
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24.r), topRight: Radius.circular(24.r)),
        ),
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.only(top: 12.h),
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2.r)),
            ),
            Padding(
              padding: EdgeInsets.all(20.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Ongeza Nyumba",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold)),
                  IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white54)),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: StatefulBuilder(
                  builder: (context, setState) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTextField(houseNumberController,
                          "Namba ya Nyumba *", Icons.door_front_door),
                      SizedBox(height: 16.h),
                      Row(
                        children: [
                          Expanded(
                              child: _buildDropdown(
                                  "Aina",
                                  selectedType,
                                  [
                                    'room',
                                    'apartment',
                                    'studio',
                                    'commercial',
                                    'bedsitter',
                                    'one_bedroom'
                                  ],
                                  (v) => setState(() => selectedType = v!),
                                  (v) => v)),
                          SizedBox(width: 12.w),
                          Expanded(
                              child: _buildDropdown(
                                  "Hali",
                                  selectedStatus,
                                  ['vacant', 'occupied', 'maintenance'],
                                  (v) => setState(() => selectedStatus = v!),
                                  (v) => v == 'vacant'
                                      ? 'Wazi'
                                      : v == 'occupied'
                                          ? 'Imekalia'
                                          : 'Matengenezo')),
                        ],
                      ),
                      SizedBox(height: 16.h),
                      Row(
                        children: [
                          Expanded(
                              child: _buildNumberField("Kodi ya Mwezi *", "0",
                                  prefix: "TSh ")),
                          SizedBox(width: 12.w),
                          Expanded(
                              child: _buildNumberField(LocalizationService.instance.translate('deposit'), "0",
                                  prefix: "TSh ")),
                        ],
                      ),
                      SizedBox(height: 16.h),
                      Row(
                        children: [
                          Expanded(
                              child: _buildNumberField("Namba ya Stima", "")),
                          SizedBox(width: 12.w),
                          Expanded(
                              child: _buildNumberField("Namba ya Maji", "")),
                        ],
                      ),
                      SizedBox(height: 32.h),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (houseNumberController.text.isNotEmpty &&
                                rentController.text.isNotEmpty) {
                              final provider = context.read<RentalProvider>();
                              await provider.addHouse(propertyId, {
                                'house_number': houseNumberController.text,
                                'rent_amount':
                                    double.tryParse(rentController.text) ?? 0,
                                'deposit_amount':
                                    double.tryParse(depositController.text) ??
                                        0,
                                'type': selectedType,
                                'status': selectedStatus,
                              });
                              if (context.mounted) Navigator.pop(context);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ThemeConstants.primaryOrange,
                            padding: EdgeInsets.symmetric(vertical: 16.h),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r)),
                          ),
                          child: Text("Ongeza",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                      SizedBox(height: 20.h),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPropertyDetails(Map<String, dynamic> property) {
    final houses = property['houses'] as List? ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: ThemeConstants.primaryBlue,
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24.r), topRight: Radius.circular(24.r)),
        ),
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.only(top: 12.h),
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2.r)),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(16.w),
                          decoration: BoxDecoration(
                            color:
                                ThemeConstants.primaryOrange.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                          child: Icon(Icons.apartment,
                              color: ThemeConstants.primaryOrange, size: 32.sp),
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(property['name'] ?? '',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 22.sp,
                                      fontWeight: FontWeight.bold)),
                              Text("${property['address'] ?? ''}",
                                  style: TextStyle(
                                      color: Colors.white54, fontSize: 14.sp)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20.h),
                    _buildDetailRow("Mkoa", property['region'] ?? '-'),
                    _buildDetailRow("Wilaya", property['district'] ?? '-'),
                    _buildDetailRow(
                        "Aina",
                        _formatPropertyType(
                            property['property_type'] ?? 'N/A')),
                    _buildDetailRow(
                        "Kipindi",
                        property['default_billing_cycle']
                                ?.replaceAll('_', ' ') ??
                            '-'),
                    _buildDetailRow("Kodi Default",
                        "TSh ${property['default_rent_amount'] ?? 0}"),
                    _buildDetailRow(
                        "Status",
                        property['status']?.toString().replaceAll('_', ' ') ??
                            'active'),
                    SizedBox(height: 24.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Nyumba (${houses.length})",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w600)),
                        TextButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _showAddHouseDialog(context, property['id']);
                          },
                          icon: Icon(Icons.add,
                              color: ThemeConstants.primaryOrange, size: 18.sp),
                          label: Text("Ongeza",
                              style: TextStyle(
                                  color: ThemeConstants.primaryOrange)),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    if (houses.isEmpty)
                      Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.h),
                          child: Column(
                            children: [
                              Icon(Icons.home_work,
                                  size: 48.sp, color: Colors.white24),
                              SizedBox(height: 12.h),
                              Text("Hakuna vyumba vya kukodisha",
                                  style: TextStyle(
                                      color: Colors.white38, fontSize: 14.sp)),
                            ],
                          ),
                        ),
                      )
                    else
                      ...houses.map((house) => _buildHouseItem(house)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.white54, fontSize: 14.sp)),
          Text(value,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildHouseItem(Map<String, dynamic> house) {
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

    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(Icons.door_front_door, color: statusColor, size: 20.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(house['house_number'] ?? '',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600)),
                Text("TSh ${house['rent_amount']}/m",
                    style: TextStyle(color: Colors.white54, fontSize: 12.sp)),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Text(
              status == 'vacant'
                  ? 'Wazi'
                  : status == 'occupied'
                      ? 'Imekalia'
                      : 'Matengenezo',
              style: TextStyle(
                  color: statusColor,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
