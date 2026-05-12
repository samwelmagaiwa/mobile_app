import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../constants/theme_constants.dart';
import '../../providers/rental_provider.dart';
import '../../services/localization_service.dart';

class EditPropertyScreen extends StatefulWidget {
  final Map<String, dynamic> property;
  const EditPropertyScreen({super.key, required this.property});

  @override
  State<EditPropertyScreen> createState() => _EditPropertyScreenState();
}

class _EditPropertyScreenState extends State<EditPropertyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _loc = LocalizationService.instance;

  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _addressController;
  late final TextEditingController _wardController;
  late final TextEditingController _streetController;

  late String _propertyType;
  late String? _region;
  late String? _district;
  late String _billingCycle;
  late String _currency;
  late String _status;

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
    _wardController = TextEditingController(text: p['ward'] ?? '');
    _streetController = TextEditingController(text: p['street'] ?? '');
    _propertyType = p['property_type'] ?? 'apartment';
    _region = p['region'];
    _district = p['district'];
    _billingCycle = p['billing_cycle'] ?? 'monthly';
    _currency = p['currency'] ?? 'TZS';
    _status = p['status'] ?? 'active';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _wardController.dispose();
    _streetController.dispose();
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
      'ward': _wardController.text.trim(),
      'street': _streetController.text.trim(),
      'address': _addressController.text.trim(),
      'billing_cycle': _billingCycle,
      'currency': _currency,
      'status': _status,
    };

    final success = await context
        .read<RentalProvider>()
        .updateProperty(widget.property['id'], data);

    setState(() => _isSubmitting = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_loc.translate('property_updated')),
          backgroundColor: ThemeConstants.successGreen,
        ),
      );
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_loc.translate('error_occurred')),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeConstants.primaryBlue,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(_loc.translate('edit_property'),
            style: TextStyle(color: Colors.white, fontSize: 20.sp, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16.w),
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
                SizedBox(height: 16.h),
                _buildSection(
                  _loc.translate('location'),
                  Icons.location_on,
                  [
                    _buildDropdownField(
                      label: _loc.translate('region'),
                      value: _region,
                      items: _regions,
                      formatter: (v) => v,
                      onChanged: (v) => setState(() => _region = v),
                    ),
                    SizedBox(height: 14.h),
                    _buildTextInput(
                      label: _loc.translate('district'),
                      icon: Icons.location_city,
                      initialValue: _district,
                      onChanged: (v) => _district = v,
                    ),
                    SizedBox(height: 14.h),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextInput(
                            controller: _wardController,
                            label: _loc.translate('ward'),
                            icon: Icons.map,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: _buildTextInput(
                            controller: _streetController,
                            label: _loc.translate('street'),
                            icon: Icons.streetview,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 14.h),
                    _buildTextInput(
                      controller: _addressController,
                      label: _loc.translate('address'),
                      icon: Icons.home,
                      required: true,
                      maxLines: 2,
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                _buildSection(
                  _loc.translate('configuration'),
                  Icons.settings,
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
                      items: const ['active', 'inactive', 'under_maintenance', 'archived'],
                      formatter: _formatType,
                      onChanged: (v) => setState(() => _status = v!),
                    ),
                  ],
                ),
                SizedBox(height: 28.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ThemeConstants.primaryOrange,
                      disabledBackgroundColor: ThemeConstants.primaryOrange.withOpacity(0.5),
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                    ),
                    child: _isSubmitting
                        ? SizedBox(
                            height: 20.h,
                            width: 20.h,
                            child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(_loc.translate('update'),
                            style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.w600)),
                  ),
                ),
                SizedBox(height: 20.h),
              ],
            ),
          ),
        ),
      ),
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
                  style: TextStyle(color: Colors.white, fontSize: 15.sp, fontWeight: FontWeight.w600)),
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
            hint: Text(_loc.translate('select'), style: TextStyle(color: Colors.white38)),
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
