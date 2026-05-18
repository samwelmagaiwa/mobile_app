import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../../constants/theme_constants.dart';
import '../../providers/rental_provider.dart';
import '../../services/localization_service.dart';

class LeaseAgreementWizardScreen extends StatefulWidget {
  final Map<String, dynamic>? preSelectedTenant;
  final Map<String, dynamic>? preSelectedProperty;
  final Map<String, dynamic>? preSelectedHouse;

  const LeaseAgreementWizardScreen({
    super.key,
    this.preSelectedTenant,
    this.preSelectedProperty,
    this.preSelectedHouse,
  });

  @override
  State<LeaseAgreementWizardScreen> createState() => _LeaseAgreementWizardScreenState();
}

class _LeaseAgreementWizardScreenState extends State<LeaseAgreementWizardScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 6;
  final _formKey = GlobalKey<FormState>();

  File? _signatureFile;
  final ImagePicker _picker = ImagePicker();

  // --- Step 1: Selection ---
  String? _selectedTenantId;
  String? _selectedPropertyId;
  String? _selectedHouseId;
  Map<String, dynamic>? _selectedHouseData;

  // --- Step 2: Terms & Financials ---
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 365));
  final _rentController = TextEditingController();
  final _depositAmountController = TextEditingController();
  final _depositPaidController = TextEditingController();
  int _advanceMonths = 1; // Default 1 month

  // --- Step 3: Billing Cycle & Fees ---
  String _billingCycle = 'monthly';
  int _dueDay = 5;
  int _gracePeriod = 0;
  String _lateFeeType = 'none';
  final _lateFeeAmountController = TextEditingController();
  bool _autoRenew = false;

  // --- Step 4: Utilities & Extra Charges ---
  final Map<String, bool> _utilities = {
    'utilities_water': false,
    'utilities_electricity': false,
    'service_charge': false,
    'parking_space': false,
  };
  final Map<String, TextEditingController> _utilityAmounts = {
    'utilities_water': TextEditingController(),
    'utilities_electricity': TextEditingController(),
    'service_charge': TextEditingController(),
    'parking_space': TextEditingController(),
  };

  // --- Step 5: Rules & Policies ---
  final _landlordObligationsController = TextEditingController();
  final _tenantObligationsController = TextEditingController();
  final _terminationPolicyController = TextEditingController();

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.preSelectedTenant != null) {
      _selectedTenantId = widget.preSelectedTenant!['id']?.toString();
    }
    if (widget.preSelectedProperty != null) {
      _selectedPropertyId = widget.preSelectedProperty!['id']?.toString();
    }
    if (widget.preSelectedHouse != null) {
      _selectedHouseId = widget.preSelectedHouse!['id']?.toString();
      _selectedHouseData = widget.preSelectedHouse;
      final rent = (_selectedHouseData?['rent_amount'] ?? _selectedHouseData?['rent'] ?? '').toString();
      final deposit = (_selectedHouseData?['deposit_amount'] ?? _selectedHouseData?['deposit'] ?? rent).toString();
      _rentController.text = rent;
      if (deposit.isNotEmpty) {
        _depositAmountController.text = deposit;
        _depositPaidController.text = deposit;
      }
    }

    _rentController.addListener(() {
      if (_rentController.text.isNotEmpty && _currentStep == 1) { // Only auto-fill if we are in Step 2 (VIPINDI)
        // If deposit is empty, suggest rent. If not, leave it.
        if (_depositAmountController.text.isEmpty) {
          _depositAmountController.text = _rentController.text;
        }
        if (_depositPaidController.text.isEmpty) {
          _depositPaidController.text = _rentController.text;
        }
      }
    });

    if (widget.preSelectedHouse != null) {
      context.read<RentalProvider>().fetchHouseDetails(widget.preSelectedHouse!['id'].toString()).then((details) {
        if (details != null && mounted) {
          setState(() {
            _selectedHouseData = details;
            final rent = (details['rent_amount'] ?? details['rent'] ?? _rentController.text).toString();
            final deposit = (details['deposit_amount'] ?? details['deposit'] ?? rent).toString();
            _rentController.text = rent;
            if (deposit.isNotEmpty) {
              _depositAmountController.text = deposit;
              _depositPaidController.text = deposit;
            }
          });
        }
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RentalProvider>().fetchTenants();
      context.read<RentalProvider>().fetchProperties();
      
      // Initialize obligations from localization
      _landlordObligationsController.text = LocalizationService.instance.translate('default_landlord_obligations');
      _tenantObligationsController.text = LocalizationService.instance.translate('default_tenant_obligations');
      _terminationPolicyController.text = LocalizationService.instance.translate('default_termination_policy');
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _rentController.dispose();
    _depositAmountController.dispose();
    _depositPaidController.dispose();
    _lateFeeAmountController.dispose();
    _utilityAmounts.values.forEach((c) => c.dispose());
    _landlordObligationsController.dispose();
    _tenantObligationsController.dispose();
    _terminationPolicyController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _handleSave();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = LocalizationService.instance;
    return ThemeConstants.buildResponsiveScaffold(
      context,
      title: loc.translate('lease_wizard'),
      body: Column(
        children: [
          _buildStepper(),
          Expanded(
            child: Form(
              key: _formKey,
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentStep = i),
                children: [
                  _buildStep1(),
                  _buildStep2(),
                  _buildStep3(),
                  _buildStep4(),
                  _buildStep5(),
                  _buildStep6(),
                ],
              ),
            ),
          ),
          _buildBottomActions(),
        ],
      ),
    );
  }

  Widget _buildStepper() {
    final loc = LocalizationService.instance;
    final steps = [
      loc.translate("step_selection"),
      loc.translate("step_terms"),
      loc.translate("step_payments"),
      loc.translate("step_utilities"),
      loc.translate("step_rules"),
      loc.translate("step_review"),
    ];
    return Container(
      height: 60.h,
      padding: EdgeInsets.symmetric(horizontal: 14.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: steps.length,
        separatorBuilder: (context, index) => Icon(Icons.chevron_right, color: Colors.white24, size: 14.w),
        itemBuilder: (context, index) {
          final isCurrent = index == _currentStep;
          final isDone = index < _currentStep;
          return Center(
            child: Row(
              children: [
                Container(
                  width: 24.w,
                  height: 24.w,
                  decoration: BoxDecoration(
                    color: isCurrent ? ThemeConstants.primaryOrange : (isDone ? ThemeConstants.successGreen : Colors.white10),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: isDone ? Icon(Icons.check, size: 12.w, color: Colors.white) : Text("${index + 1}", style: TextStyle(fontSize: 10.sp, color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  steps[index],
                  style: TextStyle(
                    color: isCurrent ? Colors.white : Colors.white54,
                    fontSize: 11.sp,
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomActions() {
    final loc = LocalizationService.instance;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 20.h),
      decoration: BoxDecoration(
        color: ThemeConstants.bgMid,
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: ThemeConstants.buildResponsiveGlassCard(
                  context,
                  onTap: _prevStep,
                  padding: EdgeInsets.all(12.h),
                  child: Center(child: Text(loc.translate("previous"), style: const TextStyle(color: Colors.white))),
                ),
              ),
            if (_currentStep > 0) SizedBox(width: 12.w),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _nextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ThemeConstants.primaryOrange,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
                child: _isSaving 
                   ? SizedBox(height: 20.h, width: 20.h, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                   : Text(_currentStep == _totalSteps - 1 ? loc.translate("complete") : loc.translate("next_step"), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Step 1: Selection ---
  Widget _buildStep1() {
    final rentalProvider = context.watch<RentalProvider>();
    final tenants = rentalProvider.tenants;
    final properties = rentalProvider.properties;

    List<dynamic> houses = [];
    if (_selectedPropertyId != null) {
      final prop = properties.firstWhere((p) => p['id'].toString() == _selectedPropertyId, orElse: () => null);
      if (prop != null) {
        houses = (prop['houses'] as List? ?? []).where((h) => 
          h['status'] == 'vacant' || h['current_tenant_id'] == null
        ).toList();
      }
    }

    final loc = LocalizationService.instance;
    return _buildStepLayout(
      title: loc.translate("step_selection"),
      children: [
        _buildDropdownField(
          loc.translate("select_tenant"), 
          _selectedTenantId, 
          tenants.map((t) => t['id'].toString()).toList(),
          (v) => setState(() => _selectedTenantId = v),
          labels: tenants.map((t) => t['name'].toString()).toList(),
          icon: Icons.person,
        ),
        SizedBox(height: 16.h),
        _buildDropdownField(
          loc.translate("select_property"), 
          _selectedPropertyId, 
          properties.map((p) => p['id'].toString()).toList(),
          (v) => setState(() { _selectedPropertyId = v; _selectedHouseId = null; }),
          labels: properties.map((p) => p['name'].toString()).toList(),
          icon: Icons.business,
        ),
        SizedBox(height: 16.h),
        _buildDropdownField(
          loc.translate("select_house"), 
          _selectedHouseId, 
          houses.map((h) => h['id'].toString()).toList(),
          (v) => _handleHouseSelection(v, houses),
          labels: houses.map((h) => "No: ${h['house_number']} (${h['type']})").toList(),
          icon: Icons.house,
          enabled: _selectedPropertyId != null,
        ),
        if (_selectedHouseData != null) ...[
          SizedBox(height: 20.h),
          ThemeConstants.buildResponsiveGlassCardStatic(
            context,
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(loc.translate("house_details"), style: TextStyle(color: Colors.white70, fontSize: 12.sp)),
                SizedBox(height: 8.h),
                _buildInfoRow(Icons.payments, "${loc.translate('rent')}:", "${_selectedHouseData!['rent_amount'] ?? _selectedHouseData!['rent']} TZS"),
                _buildInfoRow(Icons.meeting_room, "${loc.translate('type')}:", "${_selectedHouseData!['type']}"),
                _buildInfoRow(Icons.layers, "${loc.translate('floor')}:", "${_selectedHouseData!['floor']}"),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // --- Step 2: Terms & Financials ---
  Widget _buildStep2() {
    final loc = LocalizationService.instance;
    return _buildStepLayout(
      title: loc.translate("step_terms"),
      children: [
        Row(
          children: [
            Expanded(child: _buildDatePickerField(loc.translate("start_date"), _startDate, (d) => setState(() => _startDate = d!))),
            SizedBox(width: 12.w),
            Expanded(child: _buildDatePickerField(loc.translate("end_date"), _endDate, (d) => setState(() => _endDate = d!))),
          ],
        ),
        SizedBox(height: 16.h),
        _buildInputField(loc.translate("rent_monthly"), _rentController, Icons.payments, keyboardType: TextInputType.number),
        SizedBox(height: 16.h),
        _buildInputField(loc.translate("security_deposit"), _depositAmountController,
            Icons.account_balance_wallet,
            keyboardType: TextInputType.number),
        SizedBox(height: 16.h),
        _buildInputField(loc.translate("deposit_paid"), _depositPaidController,
            Icons.check_circle_outline,
            keyboardType: TextInputType.number),
        SizedBox(height: 16.h),
        _buildDropdownField(
          loc.translate("advance_months"),
          _advanceMonths.toString(),
          List.generate(12, (i) => (i + 1).toString()),
          (v) => setState(() => _advanceMonths = int.parse(v!)),
          icon: Icons.timer,
        ),
        if (_rentController.text.isNotEmpty) ...[
          SizedBox(height: 12.h),
          ThemeConstants.buildResponsiveGlassCardStatic(
            context,
            padding: EdgeInsets.all(12.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(loc.translate("total_prepaid"), style: TextStyle(color: Colors.white54, fontSize: 10.sp)),
                    Text("TZS ${((double.tryParse(_rentController.text) ?? 0) * _advanceMonths).toStringAsFixed(2)}", 
                         style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(loc.translate("paid_until"), style: TextStyle(color: Colors.white54, fontSize: 10.sp)),
                    Text(DateFormat('dd/MM/yyyy').format(DateTime(_startDate.year, _startDate.month + _advanceMonths, _startDate.day)), 
                         style: const TextStyle(color: ThemeConstants.successGreen, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // --- Step 3: Billing & Fees ---
  Widget _buildStep3() {
    final loc = LocalizationService.instance;
    return _buildStepLayout(
      title: loc.translate("step_payments"),
      children: [
        _buildDropdownField(
          loc.translate("billing_cycle"),
          _billingCycle,
          ['monthly', 'quarterly', 'semi_annual', 'annual'],
          (v) => setState(() => _billingCycle = v!),
          labels: [
            loc.translate("monthly"),
            loc.translate("quarterly"),
            loc.translate("semi_annual"),
            loc.translate("annual")
          ],
          icon: Icons.refresh,
        ),
        SizedBox(height: 16.h),
        _buildDropdownField(
          loc.translate("due_day"),
          _dueDay.toString(),
          List.generate(28, (i) => (i + 1).toString()),
          (v) => setState(() => _dueDay = int.parse(v!)),
          icon: Icons.calendar_today,
        ),
        SizedBox(height: 16.h),
        _buildDropdownField(
          loc.translate("grace_period"),
          _gracePeriod.toString(),
          List.generate(15, (i) => i.toString()),
          (v) => setState(() => _gracePeriod = int.parse(v!)),
          icon: Icons.timer_outlined,
        ),
        SizedBox(height: 16.h),
        _buildDropdownField(
          loc.translate("late_fee_type"), 
          _lateFeeType, 
          ['none', 'fixed', 'percentage'],
          (v) => setState(() => _lateFeeType = v!),
          labels: [loc.translate("none"), loc.translate("fixed"), loc.translate("percentage")],
          icon: Icons.warning_amber_rounded,
        ),
        if (_lateFeeType != 'none') ...[
          SizedBox(height: 16.h),
          _buildInputField(
            _lateFeeType == 'fixed' ? loc.translate("late_fee_amount") : loc.translate("late_fee_percent"), 
            _lateFeeAmountController, 
            Icons.money_off, 
            keyboardType: TextInputType.number,
          ),
        ],
        SizedBox(height: 16.h),
        _buildCheckboxRow(loc.translate("auto_renew"), _autoRenew, (v) => setState(() => _autoRenew = v!)),
      ],
    );
  }

  // --- Step 4: Utilities ---
  Widget _buildStep4() {
    final loc = LocalizationService.instance;
    return _buildStepLayout(
      title: loc.translate("step_utilities"),
      children: [
        ..._utilities.keys.map((key) => _buildUtilityToggle(key)),
      ],
    );
  }

  Widget _buildUtilityToggle(String key) {
    final loc = LocalizationService.instance;
    bool isSelected = _utilities[key]!;
    return Column(
      children: [
        ThemeConstants.buildResponsiveGlassCard(
          context,
          onTap: () => setState(() => _utilities[key] = !isSelected),
          padding: EdgeInsets.all(12.w),
          child: Row(
            children: [
              Icon(isSelected ? Icons.check_box : Icons.check_box_outline_blank, color: isSelected ? ThemeConstants.primaryOrange : Colors.white24),
              SizedBox(width: 12.w),
              Expanded(child: Text(loc.translate(key), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
              if (isSelected) Text(loc.translate("included"), style: const TextStyle(color: ThemeConstants.successGreen, fontSize: 10)),
            ],
          ),
        ),
        if (isSelected) 
          Padding(
            padding: EdgeInsets.only(top: 8.h, bottom: 16.h, left: 32.w),
            child: _buildInputField(loc.translate("amount_per_month"), _utilityAmounts[key]!, Icons.add_card, keyboardType: TextInputType.number),
          )
        else 
          SizedBox(height: 12.h),
      ],
    );
  }

  // --- Step 5: Rules ---
  Widget _buildStep5() {
    final loc = LocalizationService.instance;
    return _buildStepLayout(
      title: loc.translate("step_rules"),
      children: [
        _buildMultiLineField(loc.translate("tenant_obligations"), _tenantObligationsController),
        SizedBox(height: 16.h),
        _buildMultiLineField(loc.translate("landlord_obligations"), _landlordObligationsController),
        SizedBox(height: 16.h),
        _buildMultiLineField(loc.translate("termination_policy"), _terminationPolicyController),
      ],
    );
  }

  // --- Step 6: Review ---
  Widget _buildStep6() {
    final rentalProvider = context.watch<RentalProvider>();
    final loc = LocalizationService.instance;
    final tenant = rentalProvider.tenants.firstWhere((t) => t['id'].toString() == _selectedTenantId, orElse: () => {'name': loc.translate('tenant_not_selected')});
    final property = rentalProvider.properties.firstWhere((p) => p['id'].toString() == _selectedPropertyId, orElse: () => {'name': loc.translate('property_not_selected')});

    return _buildStepLayout(
      title: loc.translate("review_lease"),
      children: [
        ThemeConstants.buildResponsiveGlassCardStatic(
          context,
          padding: EdgeInsets.all(16.w),
          child: Column(
            children: [
              _buildReviewSummary(loc.translate("tenant"), tenant['name'].toString()),
              _buildReviewSummary(loc.translate("house"), "${property['name']} - ${_selectedHouseData?['house_number'] ?? '-'}"),
              _buildReviewSummary(loc.translate("period"), "${DateFormat('dd/MM/yyyy').format(_startDate)} - ${DateFormat('dd/MM/yyyy').format(_endDate)}"),
              _buildReviewSummary(loc.translate("rent"), "${_rentController.text} TZS / ${loc.translate(_billingCycle)}"),
              _buildReviewSummary(loc.translate("security_deposit"), "${_depositAmountController.text} TZS"),
              const Divider(color: Colors.white10),
              _buildReviewSummary(loc.translate("advance_months"), "$_advanceMonths Months"),
              _buildReviewSummary(loc.translate("total_prepaid"), "${((double.tryParse(_rentController.text) ?? 0) * _advanceMonths).toStringAsFixed(2)} TZS"),
              _buildReviewSummary(loc.translate("paid_until"), DateFormat('dd/MM/yyyy').format(DateTime(_startDate.year, _startDate.month + _advanceMonths, _startDate.day))),
              const Divider(color: Colors.white10),
              SizedBox(height: 8.h),
              Text(loc.translate("wizard_complete_msg"), style: TextStyle(color: Colors.white54, fontSize: 11.sp)),
            ],
          ),
        ),
        SizedBox(height: 20.h),
        Text(loc.translate("signature_upload"), style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14.sp)),
        SizedBox(height: 12.h),
        ThemeConstants.buildResponsiveGlassCard(
          context,
          onTap: _showPickerOptions,
          padding: EdgeInsets.all(20.h),
          child: Center(
            child: _signatureFile != null
                ? Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8.r),
                        child: Image.file(_signatureFile!, height: 120.h, width: double.infinity, fit: BoxFit.cover),
                      ),
                      SizedBox(height: 8.h),
                      Text(loc.translate("change_image") ?? 'Change Image', style: TextStyle(color: ThemeConstants.primaryOrange, fontSize: 12.sp)),
                    ],
                  )
                : Column(
                    children: [
                      Icon(Icons.cloud_upload_outlined, color: ThemeConstants.primaryOrange, size: 32.w),
                      SizedBox(height: 8.h),
                      Text(loc.translate("upload_signed_copy"), style: TextStyle(color: Colors.white70, fontSize: 11.sp)),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickDocument(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source, imageQuality: 80);
      if (pickedFile != null) {
        setState(() {
          _signatureFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) ThemeConstants.showErrorSnackBar(context, 'Error picking document: $e');
    }
  }

  void _showPickerOptions() {
    final loc = LocalizationService.instance;
    showModalBottomSheet(
      context: context,
      backgroundColor: ThemeConstants.bgMid,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20.r))),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.white),
                title: Text(loc.translate('gallery') ?? 'Gallery', style: const TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickDocument(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera, color: Colors.white),
                title: Text(loc.translate('camera') ?? 'Camera', style: const TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickDocument(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // --- Helpers ---

  Widget _buildStepLayout({required String title, required List<Widget> children}) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 20.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.bold)),
          SizedBox(height: 24.h),
          ...children,
          SizedBox(height: 100.h),
        ],
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, IconData icon, {TextInputType? keyboardType}) {
    return ThemeConstants.buildResponsiveGlassCardStatic(
      context,
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white, fontSize: 13),
        decoration: ThemeConstants.invInputDecoration(label).copyWith(
          prefixIcon: Icon(icon, color: Colors.white70, size: 18.w),
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
        ),
      ),
    );
  }

  Widget _buildMultiLineField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        SizedBox(height: 8.h),
        ThemeConstants.buildResponsiveGlassCardStatic(
          context,
          child: TextFormField(
            controller: controller,
            maxLines: 4,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: ThemeConstants.invInputDecoration("").copyWith(
              contentPadding: EdgeInsets.all(12.w),
              hintText: label,
              hintStyle: const TextStyle(color: Colors.white54),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField(String label, String? value, List<String> items, Function(String?) onChanged, {List<String>? labels, IconData? icon, bool enabled = true}) {
    // Ensure unique values to avoid Flutter assertion errors
    final uniqueItems = <String>[];
    final uniqueLabels = <String>[];
    final seen = <String>{};
    
    for (int i = 0; i < items.length; i++) {
      if (!seen.contains(items[i])) {
        seen.add(items[i]);
        uniqueItems.add(items[i]);
        if (labels != null && i < labels.length) {
          uniqueLabels.add(labels[i]);
        }
      }
    }

    return Opacity(
      opacity: enabled ? 1.0 : 0.4,
      child: ThemeConstants.buildResponsiveGlassCardStatic(
        context,
        child: DropdownButtonFormField<String>(
          value: uniqueItems.contains(value) ? value : null,
          items: List.generate(uniqueItems.length, (i) => DropdownMenuItem(
            value: uniqueItems[i],
            child: Text(uniqueLabels.isNotEmpty ? uniqueLabels[i] : uniqueItems[i], 
                 style: const TextStyle(fontSize: 13, color: Colors.white)),
          )),
          selectedItemBuilder: (BuildContext context) {
            return uniqueItems.map<Widget>((String item) {
              final index = uniqueItems.indexOf(item);
              final display = uniqueLabels.isNotEmpty ? uniqueLabels[index] : item;
              return Text(display, style: const TextStyle(color: Colors.white, fontSize: 13));
            }).toList();
          },
          hint: Text(label, style: const TextStyle(color: Colors.white60, fontSize: 13)),
          onChanged: enabled ? onChanged : null,
          isExpanded: true,
          dropdownColor: const Color(0xFF1A3B45),
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: ThemeConstants.invInputDecoration(label).copyWith(
            prefixIcon: icon != null ? Icon(icon, color: Colors.white70, size: 18.w) : null,
            labelText: label,
            labelStyle: const TextStyle(color: Colors.white70),
            hintStyle: const TextStyle(color: Colors.white30),
          ),
        ),
      ),
    );
  }

  Widget _buildDatePickerField(String label, DateTime date, Function(DateTime?) onSelected) {
    return ThemeConstants.buildResponsiveGlassCard(
      context,
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime.now().subtract(const Duration(days: 30)), // Allow slightly backdated
          lastDate: DateTime(2050),
        );
        if (picked != null) onSelected(picked);
      },
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
            SizedBox(height: 4.h),
            Row(
              children: [
                Icon(Icons.calendar_today, color: ThemeConstants.primaryOrange, size: 14.w),
                SizedBox(width: 8.w),
                Text(DateFormat('dd/MM/yyyy').format(date), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        children: [
          Icon(icon, color: ThemeConstants.primaryOrange, size: 14.w),
          SizedBox(width: 8.w),
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          const Spacer(),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildReviewSummary(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        children: [
          Text("$label:", style: const TextStyle(color: Colors.white54, fontSize: 12)),
          const Spacer(),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  Future<void> _handleHouseSelection(String? v, List<dynamic> houses) async {
    if (v == null) return;
    
    setState(() {
      _selectedHouseId = v;
      final house = houses.firstWhere((h) => h['id'].toString() == v);
      _selectedHouseData = house;
      
      final rent = (house['rent_amount'] ?? house['rent'] ?? '').toString();
      final deposit = (house['deposit_amount'] ?? house['deposit'] ?? rent).toString();
      
      _rentController.text = rent;
      if (deposit.isNotEmpty) {
        _depositAmountController.text = deposit;
        _depositPaidController.text = deposit;
      }
    });

    // Fetch full details to get the accurate deposit amount from house creation
    final fullDetails = await context.read<RentalProvider>().fetchHouseDetails(v);
    if (fullDetails != null && mounted) {
      setState(() {
        _selectedHouseData = fullDetails;
        final rent = (fullDetails['rent_amount'] ?? fullDetails['rent'] ?? _rentController.text).toString();
        final deposit = (fullDetails['deposit_amount'] ?? fullDetails['deposit'] ?? rent).toString();
        
        _rentController.text = rent;
        if (deposit.isNotEmpty) {
          _depositAmountController.text = deposit;
          _depositPaidController.text = deposit;
        }
      });
    }
  }

  Widget _buildCheckboxRow(String label, bool value, Function(bool?) onChanged) {
    return Row(
      children: [
        Checkbox(value: value, onChanged: onChanged, activeColor: ThemeConstants.primaryOrange),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Future<void> _handleSave() async {
    final loc = LocalizationService.instance;
    if (_selectedTenantId == null || _selectedHouseId == null || _selectedPropertyId == null) {
      if (mounted) ThemeConstants.showErrorSnackBar(context, loc.translate("please_select_tenant_house"));
      return;
    }

    setState(() => _isSaving = true);
    
    // Prepare utilities
    final List<Map<String, dynamic>> utilityCharges = [];
    _utilities.forEach((key, isSelected) {
      if (isSelected) {
        final amountText = _utilityAmounts[key]!.text;
        utilityCharges.add({
          'name': key,
          'amount': amountText.isNotEmpty ? double.parse(amountText) : 0.0,
          'billing_type': 'fixed',
        });
      }
    });

    // Prepare rules
    final Map<String, String> rules = {
      'landlord_obligations': _landlordObligationsController.text,
      'tenant_obligations': _tenantObligationsController.text,
      'termination_policy': _terminationPolicyController.text,
    };

    final payload = {
      'tenant_id': _selectedTenantId,
      'property_id': _selectedPropertyId,
      'house_id': _selectedHouseId,
      'start_date': DateFormat('yyyy-MM-dd').format(_startDate),
      'end_date': DateFormat('yyyy-MM-dd').format(_endDate),
      'rent_amount': double.parse(_rentController.text),
      'deposit_amount': _depositAmountController.text.isNotEmpty ? double.parse(_depositAmountController.text) : 0.0,
      'deposit_paid': _depositPaidController.text.isNotEmpty ? double.parse(_depositPaidController.text) : 0.0,
      'rent_cycle': _billingCycle,
      'due_day': _dueDay,
      'grace_period_days': _gracePeriod,
      'late_fee_type': _lateFeeType,
      'late_fee_amount': _lateFeeAmountController.text.isNotEmpty ? double.parse(_lateFeeAmountController.text) : 0.0,
      'utility_charges': utilityCharges,
      'rules': rules,
      'auto_renew': _autoRenew,
      'advance_months': _advanceMonths,
      'prepaid_amount': (double.tryParse(_rentController.text) ?? 0) * _advanceMonths,
      'paid_until': DateFormat('yyyy-MM-dd').format(DateTime(_startDate.year, _startDate.month + _advanceMonths, _startDate.day)),
    };

    final success = await context.read<RentalProvider>().createAgreement(payload, document: _signatureFile);
    
    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        ThemeConstants.showSuccessSnackBar(context, loc.translate("lease_created_success"));
        Navigator.pop(context);
      } else {
        ThemeConstants.showErrorSnackBar(context, loc.translate("lease_creation_failed"));
      }
    }
  }
}
