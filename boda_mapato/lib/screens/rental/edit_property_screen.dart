import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../constants/theme_constants.dart';
import '../../providers/rental_provider.dart';
import '../../services/localization_service.dart';
import '../../widgets/location_selector.dart';

class EditPropertyScreen extends StatefulWidget {
  const EditPropertyScreen({required this.property, super.key});
  final Map<String, dynamic> property;

  @override
  State<EditPropertyScreen> createState() => _EditPropertyScreenState();
}

class _EditPropertyScreenState extends State<EditPropertyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _loc = LocalizationService.instance;

  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _addressController;
  late final TextEditingController _defaultRentController;
  late final TextEditingController _defaultDepositController;
  late final TextEditingController _ownershipNotesController;
  late final TextEditingController _latController;
  late final TextEditingController _lngController;

  late String _propertyType;
  late String? _region;
  late String? _district;
  late String? _ward;
  late String? _street;
  late String? _place;
  late String _billingCycle;
  late String _currency;
  late String _status;
  bool _utilityBillingEnabled = false;
  File? _newCoverImage;
  String? _currentImageUrl;

  bool _isSubmitting = false;

  static const List<String> _propertyTypes = [
    'apartment', 'rental_compound', 'standalone_house', 'hostel',
    'commercial_building', 'mixed_use', 'office_space', 'shop_units',
  ];

  static const List<String> _regions = [
    'Dar es Salaam', 'Arusha', 'Mwanza', 'Dodoma', 'Mbeya',
    'Morogoro', 'Tanga', 'Kilimanjaro', 'Pwani', 'Kigoma',
    'Kagera', 'Mara', 'Shinyanga', 'Tabora', 'Rukwa',
    'Iringa', 'Lindi', 'Mtwara', 'Ruvuma', 'Singida',
    'Geita', 'Simiyu', 'Njombe', 'Katavi', 'Songwe',
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.property;
    _nameController = TextEditingController(text: p['name'] ?? '');
    _descriptionController = TextEditingController(text: p['description'] ?? '');
    _addressController = TextEditingController(text: p['address'] ?? '');
    _latController = TextEditingController(text: (p['latitude'] ?? '').toString());
    _lngController = TextEditingController(text: (p['longitude'] ?? '').toString());
    _defaultRentController = TextEditingController(text: (p['default_rent_amount'] ?? '0').toString());
    _defaultDepositController = TextEditingController(text: (p['default_deposit_amount'] ?? '0').toString());
    _ownershipNotesController = TextEditingController(text: p['ownership_notes'] ?? '');
    _utilityBillingEnabled = p['utility_billing_enabled'] == 1 || p['utility_billing_enabled'] == true;
    _propertyType = p['property_type'] ?? 'apartment';
    _region = p['region'];
    _district = p['district'];
    _ward = p['ward'];
    _street = p['street'];
    _place = p['place'];
    _billingCycle = p['default_billing_cycle'] ?? p['billing_cycle'] ?? 'monthly';
    _currency = p['default_currency'] ?? p['currency'] ?? 'TZS';
    _status = p['status'] ?? 'active';
    _currentImageUrl = p['cover_image'];
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.gallery, maxWidth: 1200);
    if (picked != null) {
      setState(() => _newCoverImage = File(picked.path));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSubmitting = true);

    final data = <String, dynamic>{
      'name': _nameController.text.trim(),
      'property_type': _propertyType,
      'description': _descriptionController.text.trim(),
      'region': _region ?? '',
      'district': _district ?? '',
      'ward': _ward,
      'street': _street,
      'place': _place,
      'address': _addressController.text.trim(),
      'latitude': _latController.text,
      'longitude': _lngController.text,
      'default_billing_cycle': _billingCycle,
      'default_currency': _currency,
      'status': _status,
      'default_rent_amount': _defaultRentController.text,
      'default_deposit_amount': _defaultDepositController.text,
      'ownership_notes': _ownershipNotesController.text,
      'utility_billing_enabled': _utilityBillingEnabled ? 1 : 0,
    };

    final success = await context
        .read<RentalProvider>()
        .updateProperty(widget.property['id'], data, image: _newCoverImage);

    setState(() => _isSubmitting = false);

    if (success && mounted) {
      ThemeConstants.showSuccessSnackBar(context, _loc.translate('property_updated'));
      Navigator.pop(context);
    } else if (mounted) {
      ThemeConstants.showErrorSnackBar(context, _loc.translate('error_occurred'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ThemeConstants.buildScaffold(
      title: _loc.translate('edit_property'),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 20.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSection(
                  _loc.translate('basic_information'),
                  Icons.info_outline,
                  [
                    _buildTextInput(
                      controller: _nameController,
                      label: _loc.translate('property_name'),
                      icon: Icons.apartment,
                      required: true,
                    ),
                    SizedBox(height: 14.h),
                    _buildDropdownField(
                      label: _loc.translate('property_type'),
                      value: _propertyType,
                      items: _propertyTypes,
                      formatter: _formatType,
                      onChanged: (v) => setState(() => _propertyType = v!),
                    ),
                    SizedBox(height: 14.h),
                    _buildTextInput(
                      controller: _descriptionController,
                      label: _loc.translate('description'),
                      icon: Icons.description,
                      maxLines: 3,
                    ),
                  ],
                ),
                SizedBox(height: 20.h),
                _buildSection(
                  _loc.translate('location'),
                  Icons.location_on_outlined,
                  [
                    LocationSelector(
                      onChanged: (region, district, ward, street, place) {
                        _region = region;
                        _district = district;
                        _ward = ward;
                        _street = street;
                        _place = place;
                      },
                    ),
                    SizedBox(height: 14.h),
                    _buildTextInput(
                      controller: _addressController,
                      label: _loc.translate('address'),
                      icon: Icons.home_outlined,
                      required: true,
                      maxLines: 2,
                    ),
                    SizedBox(height: 14.h),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextInput(
                            controller: _latController,
                            label: "Latitudo",
                            icon: Icons.location_on_outlined,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: _buildTextInput(
                            controller: _lngController,
                            label: "Longitudo",
                            icon: Icons.location_on_outlined,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 20.h),
                _buildSection(
                  _loc.translate('configuration'),
                  Icons.settings_outlined,
                  [
                    Row(
                      children: [
                        Expanded(
                          child: _buildDropdownField(
                            label: _loc.translate('billing_cycle'),
                            value: _billingCycle,
                            items: const ['monthly', 'quarterly', 'yearly'],
                            formatter: (v) => v == 'monthly'
                                ? _loc.translate('monthly')
                                : v == 'quarterly'
                                    ? _loc.translate('quarterly')
                                    : _loc.translate('yearly'),
                            onChanged: (v) => setState(() => _billingCycle = v!),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: _buildDropdownField(
                            label: _loc.translate('currency'),
                            value: _currency,
                            items: const ['TZS', 'USD'],
                            formatter: (v) => v,
                            onChanged: (v) => setState(() => _currency = v!),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 14.h),
                    _buildDropdownField(
                      label: _loc.translate('status'),
                      value: _status,
                      items: const [
                        'active',
                        'inactive',
                        'under_maintenance',
                        'archived'
                      ],
                      formatter: _formatType,
                      onChanged: (v) => setState(() => _status = v!),
                    ),
                    SizedBox(height: 14.h),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextInput(
                            controller: _defaultRentController,
                            label: "Kodi ya Msingi (TSh)",
                            icon: Icons.monetization_on_outlined,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: _buildTextInput(
                            controller: _defaultDepositController,
                            label: "Amana ya Msingi (TSh)",
                            icon: Icons.savings_outlined,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 14.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Bili za Huduma (Maji/Umeme)",
                            style: TextStyle(
                                color: Colors.white70, fontSize: 13.sp)),
                        Switch(
                          value: _utilityBillingEnabled,
                          onChanged: (v) =>
                              setState(() => _utilityBillingEnabled = v),
                          activeThumbColor: ThemeConstants.primaryOrange,
                        ),
                      ],
                    ),
                    SizedBox(height: 14.h),
                    _buildTextInput(
                      controller: _ownershipNotesController,
                      label: "Maelezo ya Umiliki",
                      icon: Icons.note_alt_outlined,
                      maxLines: 3,
                    ),
                  ],
                ),
                SizedBox(height: 20.h),
                _buildSection(
                  _loc.translate('media'),
                  Icons.image_outlined,
                  [
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 180.h,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(18.r),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.12),
                          ),
                        ),
                        child: _newCoverImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(18.r),
                                child: Image.file(_newCoverImage!,
                                    width: double.infinity,
                                    height: 180.h,
                                    fit: BoxFit.cover),
                              )
                            : (_currentImageUrl != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(18.r),
                                    child: Image.network(_currentImageUrl!,
                                        width: double.infinity,
                                        height: 180.h,
                                        fit: BoxFit.cover,
                                        errorBuilder: (c, e, s) => Center(
                                            child: Icon(Icons.broken_image_outlined,
                                                color: Colors.white24,
                                                size: 40.sp))),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.cloud_upload_outlined,
                                          size: 40.sp, color: Colors.white38),
                                      SizedBox(height: 8.h),
                                      Text(_loc.translate('tap_to_upload'),
                                          style: ThemeConstants.captionStyle),
                                    ],
                                  )),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 32.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ThemeConstants.primaryOrange,
                      disabledBackgroundColor: ThemeConstants.primaryOrange.withOpacity(0.5),
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                      elevation: 8,
                      shadowColor: ThemeConstants.primaryOrange.withOpacity(0.4),
                    ),
                    child: _isSubmitting
                        ? SizedBox(
                            height: 20.h,
                            width: 20.h,
                            child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(_loc.translate('update_property'),
                            style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.bold)),
                  ),
                ),
                SizedBox(height: 40.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return ThemeConstants.buildResponsiveGlassCardStatic(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: ThemeConstants.primaryOrange, size: 20.sp),
              SizedBox(width: 10.w),
              Text(title, style: ThemeConstants.headingStyle.copyWith(fontSize: 15.sp)),
            ],
          ),
          SizedBox(height: 20.h),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextInput({
    required String label, TextEditingController? controller,
    IconData? icon,
    bool required = false,
    int maxLines = 1,
    String? initialValue,
    Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      initialValue: controller == null ? initialValue : null,
      maxLines: maxLines,
      style: TextStyle(color: Colors.white, fontSize: 14.sp),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: required ? "$label *" : label,
        labelStyle: TextStyle(color: Colors.white54, fontSize: 12.sp),
        prefixIcon: icon != null ? Icon(icon, color: Colors.white38, size: 18.sp) : null,
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: ThemeConstants.primaryOrange),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
      ),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? _loc.translate('field_required') : null
          : null,
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required String Function(String) formatter,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white54, fontSize: 12.sp)),
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
            hint: Text(_loc.translate('select'), style: const TextStyle(color: Colors.white38)),
            items: items
                .map((item) => DropdownMenuItem(value: item, child: Text(formatter(item))))
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  String _formatType(String type) {
    return type
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isNotEmpty ? "${w[0].toUpperCase()}${w.substring(1)}" : "")
        .join(' ');
  }
}
