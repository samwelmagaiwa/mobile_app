import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../constants/theme_constants.dart';
import '../../providers/rental_provider.dart';
import '../../services/localization_service.dart';

class CreatePropertyScreen extends StatefulWidget {
  const CreatePropertyScreen({super.key});

  @override
  State<CreatePropertyScreen> createState() => _CreatePropertyScreenState();
}

class _CreatePropertyScreenState extends State<CreatePropertyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _loc = LocalizationService.instance;

  // Section 1 — Basic Information
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _propertyType = 'apartment';

  // Section 2 — Location
  final _addressController = TextEditingController();
  final _wardController = TextEditingController();
  final _streetController = TextEditingController();
  String? _region;
  String? _district;
  final _latController = TextEditingController();
  final _lngController = TextEditingController();

  // Section 3 — Configuration
  final _defaultRentController = TextEditingController(text: "0");
  final _defaultDepositController = TextEditingController(text: "0");
  final _ownershipNotesController = TextEditingController();
  bool _utilityBillingEnabled = false;
  String _billingCycle = 'monthly';
  String _currency = 'TZS';
  String _status = 'active';

  // Section 4 — Media
  File? _coverImage;

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
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _wardController.dispose();
    _streetController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1200);
    if (picked != null) {
      setState(() => _coverImage = File(picked.path));
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSubmitting = true);

    final data = <String, dynamic>{
      'name': _nameController.text.trim(),
      'property_type': _propertyType,
      'description': _descriptionController.text.trim(),
      'region': _region ?? 'Dar es Salaam',
      'district': _district ?? '',
      'ward': _wardController.text.trim(),
      'street': _streetController.text.trim(),
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

    final success = await context.read<RentalProvider>().addProperty(data, image: _coverImage);

    setState(() => _isSubmitting = false);

    if (success && mounted) {
      ThemeConstants.showSuccessSnackBar(context, _loc.translate('property_created'));
      Navigator.pop(context);
    } else if (mounted) {
      ThemeConstants.showErrorSnackBar(context, _loc.translate('error_occurred'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ThemeConstants.buildScaffold(
      title: _loc.translate('add_property'),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 20.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ThemeConstants.buildResponsiveGlassCardStatic(
                context,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(_loc.translate('basic_information'), Icons.info_outline),
                    SizedBox(height: 16.h),
                    _buildTextInput(
                      controller: _nameController,
                      label: _loc.translate('property_name'),
                      icon: Icons.apartment,
                      required: true,
                    ),
                    SizedBox(height: 16.h),
                    _buildDropdownField(
                      label: _loc.translate('property_type'),
                      value: _propertyType,
                      items: _propertyTypes,
                      formatter: _formatType,
                      onChanged: (v) => setState(() => _propertyType = v!),
                    ),
                    SizedBox(height: 16.h),
                    _buildTextInput(
                      controller: _descriptionController,
                      label: _loc.translate('description'),
                      icon: Icons.description,
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20.h),
              ThemeConstants.buildResponsiveGlassCardStatic(
                context,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(_loc.translate('location'), Icons.location_on),
                    SizedBox(height: 16.h),
                    _buildDropdownField(
                      label: _loc.translate('region'),
                      value: _region,
                      items: _regions,
                      formatter: (v) => v,
                      onChanged: (v) => setState(() => _region = v),
                      required: true,
                    ),
                    SizedBox(height: 16.h),
                    _buildTextInput(
                      label: _loc.translate('district'),
                      icon: Icons.location_city,
                      required: true,
                      onChanged: (v) => _district = v,
                    ),
                    SizedBox(height: 16.h),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextInput(
                            controller: _wardController,
                            label: _loc.translate('ward'),
                            icon: Icons.map,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: _buildTextInput(
                            controller: _streetController,
                            label: _loc.translate('street'),
                            icon: Icons.streetview,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    _buildTextInput(
                      controller: _addressController,
                      label: _loc.translate('address'),
                      icon: Icons.home,
                      required: true,
                      maxLines: 2,
                    ),
                    SizedBox(height: 16.h),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextInput(
                            controller: _latController,
                            label: "Latitudo (Mf. -6.7)",
                            icon: Icons.location_on_outlined,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: _buildTextInput(
                            controller: _lngController,
                            label: "Longitudo (Mf. 39.2)",
                            icon: Icons.location_on_outlined,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20.h),
              ThemeConstants.buildResponsiveGlassCardStatic(
                context,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(_loc.translate('configuration'), Icons.settings),
                    SizedBox(height: 16.h),
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
                        SizedBox(width: 8.w),
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
                    SizedBox(height: 16.h),
                    _buildDropdownField(
                      label: _loc.translate('status'),
                      value: _status,
                      items: const [
                        'active',
                        'inactive',
                        'under_maintenance',
                        'archived'
                      ],
                      formatter: (v) => _formatType(v),
                      onChanged: (v) => setState(() => _status = v!),
                    ),
                    SizedBox(height: 16.h),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextInput(
                            controller: _defaultRentController,
                            label: "Kodi ya Msingi (TSh)",
                            icon: Icons.monetization_on,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: _buildTextInput(
                            controller: _defaultDepositController,
                            label: "Amana ya Msingi (TSh)",
                            icon: Icons.savings,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),
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
                          activeColor: ThemeConstants.primaryOrange,
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    _buildTextInput(
                      controller: _ownershipNotesController,
                      label: "Maelezo ya Umiliki",
                      icon: Icons.note_alt,
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20.h),
              ThemeConstants.buildResponsiveGlassCardStatic(
                context,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(_loc.translate('media'), Icons.image),
                    SizedBox(height: 16.h),
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 180.h,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: _coverImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(16.r),
                                child: Image.file(_coverImage!, fit: BoxFit.cover),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(12.r),
                                    decoration: BoxDecoration(
                                      color: ThemeConstants.primaryOrange.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.cloud_upload_outlined, color: ThemeConstants.primaryOrange, size: 32.sp),
                                  ),
                                  SizedBox(height: 12.h),
                                  Text(_loc.translate('tap_to_upload'),
                                      style: ThemeConstants.captionStyle.copyWith(fontSize: 13.sp)),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32.h),
              SizedBox(
                width: double.infinity,
                height: 58.h,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ThemeConstants.primaryOrange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                    elevation: 4,
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(_loc.translate('save'), 
                          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                ),
              ),
              SizedBox(height: 40.h),
            ],
          ),
        ),
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

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: ThemeConstants.primaryOrange, size: 18.sp),
              SizedBox(width: 8.w),
              Text(title,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          SizedBox(height: 16.h),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextInput({
    TextEditingController? controller,
    required String label,
    IconData? icon,
    bool required = false,
    int maxLines = 1,
    Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(color: Colors.white, fontSize: 14.sp),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: required ? "$label *" : label,
        labelStyle: TextStyle(color: Colors.white54, fontSize: 12.sp),
        prefixIcon: icon != null
            ? Icon(icon, color: Colors.white38, size: 18.sp)
            : null,
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: Colors.white12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: Colors.white12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: ThemeConstants.primaryOrange),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
      ),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty)
              ? '${_loc.translate("field_required")}'
              : null
          : null,
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required String Function(String) formatter,
    required Function(String?) onChanged,
    bool required = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(required ? "$label *" : label,
            style: TextStyle(color: Colors.white54, fontSize: 12.sp)),
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
            hint: Text(_loc.translate('select'),
                style: TextStyle(color: Colors.white38)),
            items: items
                .map((item) => DropdownMenuItem(
                      value: item,
                      child: Text(formatter(item)),
                    ))
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
