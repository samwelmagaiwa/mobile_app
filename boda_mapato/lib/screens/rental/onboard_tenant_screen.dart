import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../constants/theme_constants.dart';
import '../../providers/rental_provider.dart';
import '../../widgets/service_switcher_dialog.dart';

class OnboardTenantScreen extends StatefulWidget {
  const OnboardTenantScreen({super.key});

  @override
  State<OnboardTenantScreen> createState() => _OnboardTenantScreenState();
}

class _OnboardTenantScreenState extends State<OnboardTenantScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 7;
  final _formKey = GlobalKey<FormState>();

  // Step 1: Personal Information
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  DateTime? _dob;
  final _nidaController = TextEditingController();
  String _gender = "Male";

  // Step 2: Emergency Contact
  final _emergencyNameController = TextEditingController();
  final _relationshipController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  final _emergencyEmailController = TextEditingController();

  // Step 3: Identification
  final _idNumberController = TextEditingController();
  final _idStateController = TextEditingController();
  DateTime? _idExpiration;

  // Step 4: Employment
  final _employerController = TextEditingController();
  final _jobTitleController = TextEditingController();
  final _employmentLengthController = TextEditingController();
  final _workPhoneController = TextEditingController();
  bool _isEmployed = true;

  // Step 5: Rental History
  final _prevAddressController = TextEditingController();
  final _stayDurationController = TextEditingController();
  final _reasonForLeavingController = TextEditingController();
  final _prevLandlordNameController = TextEditingController();
  final _prevLandlordPhoneController = TextEditingController();

  // Step 6: Occupants & Pets
  int _adultsCount = 1;
  int _childrenCount = 0;
  bool _willOthersLive = false;
  String _petType = "None";
  final _petBreedController = TextEditingController();
  final _petAgeController = TextEditingController();
  final _petWeightController = TextEditingController();

  // Step 7: Assignment & Terms
  String? _selectedPropertyId;
  String? _selectedHouseId;
  DateTime _startDate = DateTime.now();
  final _amountController = TextEditingController();
  String? _tenantPhotoPath;
  bool _acceptedTerms = false;
  bool _acceptedPrivacy = false;

  bool _isSaving = false;

  @override
  void dispose() {
    _pageController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _nidaController.dispose();
    _emergencyNameController.dispose();
    _relationshipController.dispose();
    _emergencyPhoneController.dispose();
    _emergencyEmailController.dispose();
    _idNumberController.dispose();
    _idStateController.dispose();
    _employerController.dispose();
    _jobTitleController.dispose();
    _employmentLengthController.dispose();
    _workPhoneController.dispose();
    _prevAddressController.dispose();
    _stayDurationController.dispose();
    _reasonForLeavingController.dispose();
    _prevLandlordNameController.dispose();
    _prevLandlordPhoneController.dispose();
    _petBreedController.dispose();
    _petAgeController.dispose();
    _petWeightController.dispose();
    _amountController.dispose();
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

  Future<void> _pickTenantPhoto() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      if (result != null && result.files.single.path != null) {
        setState(() => _tenantPhotoPath = result.files.single.path);
      }
    } catch (e) {
      if (mounted) ThemeConstants.showErrorSnackBar(context, "Could not pick image");
    }
  }

  @override
  Widget build(BuildContext context) {
    return ThemeConstants.buildResponsiveScaffold(
      context,
      title: "Register Tenant",
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
                  _buildStep7(),
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
    final steps = ["Personal", "Contact", "Identity", "Job", "History", "Peeps", "Terms"];
    return Container(
      height: 60.h,
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: steps.length,
        separatorBuilder: (context, index) => Icon(Icons.chevron_right, color: Colors.white24, size: 16.w),
        itemBuilder: (context, index) {
          bool isCompleted = index < _currentStep;
          bool isCurrent = index == _currentStep;
          return Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 24.w,
                  height: 24.w,
                  decoration: BoxDecoration(
                    color: isCurrent ? ThemeConstants.primaryOrange : (isCompleted ? ThemeConstants.successGreen : Colors.white10),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: isCompleted 
                      ? Icon(Icons.check, color: Colors.white, size: 14.w)
                      : Text("${index + 1}", style: TextStyle(color: Colors.white, fontSize: 10.sp, fontWeight: FontWeight.bold)),
                  ),
                ),
                SizedBox(width: 4.w),
                Text(
                  steps[index],
                  style: TextStyle(
                    color: isCurrent ? Colors.white : Colors.white54,
                    fontSize: 10.sp,
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
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: ThemeConstants.footerBarColor,
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                flex: 1,
                child: OutlinedButton(
                  onPressed: _prevStep,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white38),
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                  ),
                  child: const Text("Previous", style: TextStyle(color: Colors.white, fontSize: 13)),
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
                  elevation: 2,
                ),
                child: _isSaving 
                  ? SizedBox(height: 20.h, width: 20.h, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(_currentStep == _totalSteps - 1 ? "Submit" : "Next Step", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15.sp)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Step Content Builders ---

  Widget _buildStep1() {
    return _buildStepLayout(
      title: "Step 1: Personal Information",
      children: [
        Row(
          children: [
            Expanded(child: _buildInputField("First Name", _firstNameController, Icons.person)),
            SizedBox(width: 8.w),
            Expanded(child: _buildInputField("Last Name", _lastNameController, Icons.person)),
          ],
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            Expanded(child: _buildDropdownField("Gender", _gender, ["Male", "Female", "Other"], (v) => setState(() => _gender = v!))),
            SizedBox(width: 8.w),
            Expanded(child: _buildDatePickerField("Birth Date", _dob, (d) => setState(() => _dob = d))),
          ],
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            Expanded(child: _buildInputField("NIDA / ID", _nidaController, Icons.badge)),
            SizedBox(width: 8.w),
            Expanded(child: _buildInputField("Phone No", _phoneController, Icons.phone, keyboardType: TextInputType.phone)),
          ],
        ),
        SizedBox(height: 12.h),
        _buildInputField("Email Address", _emailController, Icons.email, keyboardType: TextInputType.emailAddress),
      ],
    );
  }

  Widget _buildStep2() {
    return _buildStepLayout(
      title: "Step 2: Emergency Contact",
      children: [
        Row(
          children: [
            Expanded(child: _buildInputField("Contact Name", _emergencyNameController, Icons.person_outline)),
            SizedBox(width: 8.w),
            Expanded(child: _buildInputField("Relationship", _relationshipController, Icons.family_restroom)),
          ],
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            Expanded(child: _buildInputField("Phone No", _emergencyPhoneController, Icons.phone_android, keyboardType: TextInputType.phone)),
            SizedBox(width: 8.w),
            Expanded(child: _buildInputField("Email", _emergencyEmailController, Icons.alternate_email, keyboardType: TextInputType.emailAddress)),
          ],
        ),
      ],
    );
  }

  Widget _buildStep3() {
    return _buildStepLayout(
      title: "Step 3: Identification",
      children: [
        Row(
          children: [
            Expanded(child: _buildInputField("DL / ID No", _idNumberController, Icons.fingerprint)),
            SizedBox(width: 8.w),
            Expanded(child: _buildInputField("State Issued", _idStateController, Icons.map)),
          ],
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            Expanded(child: _buildDatePickerField("Exp Date", _idExpiration, (d) => setState(() => _idExpiration = d))),
            SizedBox(width: 8.w),
            Expanded(child: _buildUploadField("Upload ID")),
          ],
        ),
      ],
    );
  }

  Widget _buildStep4() {
    return _buildStepLayout(
      title: "Step 4: Current Employment",
      children: [
        Row(
          children: [
            Expanded(child: _buildInputField("Employer", _employerController, Icons.business)),
            SizedBox(width: 8.w),
            Expanded(child: _buildInputField("Job Title", _jobTitleController, Icons.work_outline)),
          ],
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            Expanded(child: _buildInputField("Duration", _employmentLengthController, Icons.timer)),
            SizedBox(width: 8.w),
            Expanded(child: _buildInputField("Work No", _workPhoneController, Icons.phone, keyboardType: TextInputType.phone)),
          ],
        ),
        SizedBox(height: 12.h),
        _buildCheckboxRow("Currently Employed", _isEmployed, (v) => setState(() => _isEmployed = v!)),
      ],
    );
  }

  Widget _buildStep5() {
    return _buildStepLayout(
      title: "Step 5: Rental History",
      children: [
        Row(
          children: [
            Expanded(child: _buildInputField("Prev Address", _prevAddressController, Icons.home_work)),
            SizedBox(width: 8.w),
            Expanded(child: _buildInputField("Stay Years", _stayDurationController, Icons.history)),
          ],
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            Expanded(child: _buildInputField("Reason Out", _reasonForLeavingController, Icons.exit_to_app)),
            SizedBox(width: 8.w),
            Expanded(child: _buildInputField("Landlord", _prevLandlordNameController, Icons.person_pin)),
          ],
        ),
        SizedBox(height: 12.h),
        _buildInputField("Landlord Phone", _prevLandlordPhoneController, Icons.phone, keyboardType: TextInputType.phone),
      ],
    );
  }

  Widget _buildStep6() {
    return _buildStepLayout(
      title: "Step 6: Occupant Details",
      children: [
        Row(
          children: [
            Expanded(child: _buildNumberField("Adults", _adultsCount, (v) => setState(() => _adultsCount = v))),
            SizedBox(width: 8.w),
            Expanded(child: _buildNumberField("Children", _childrenCount, (v) => setState(() => _childrenCount = v))),
          ],
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            Expanded(child: _buildDropdownField("Others Stay?", _willOthersLive ? "Yes" : "No", ["Yes", "No"], (v) => setState(() => _willOthersLive = v == "Yes"))),
            SizedBox(width: 8.w),
            Expanded(child: _buildDropdownField("Pet Type", _petType, ["None", "Dog", "Cat", "Other"], (v) => setState(() => _petType = v!))),
          ],
        ),
        if (_petType != "None") ...[
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(child: _buildInputField("Breed", _petBreedController, Icons.pets)),
              SizedBox(width: 8.w),
              Expanded(child: _buildInputField("Pet Age", _petAgeController, Icons.cake, keyboardType: TextInputType.number)),
            ],
          ),
          SizedBox(height: 12.h),
          _buildInputField("Weight", _petWeightController, Icons.scale, keyboardType: TextInputType.number),
        ],
      ],
    );
  }

  Widget _buildStep7() {
    final rentalProvider = context.watch<RentalProvider>();
    final properties = rentalProvider.properties;

    List<dynamic> houses = [];
    if (_selectedPropertyId != null) {
      final prop = properties.firstWhere((p) => p['id'].toString() == _selectedPropertyId, orElse: () => null);
      if (prop != null) {
        houses = (prop['houses'] as List? ?? []).where((h) => h['is_occupied'] == 0 || h['is_occupied'] == false).toList();
      }
    }

    return _buildStepLayout(
      title: "Step 7: Assignment & Terms",
      children: [
        Row(
          children: [
            Expanded(
              child: _buildDropdownField(
                "Property", 
                _selectedPropertyId, 
                properties.map((p) => p['id'].toString()).toList(),
                (v) => setState(() { _selectedPropertyId = v; _selectedHouseId = null; }),
                labels: properties.map((p) => p['name'].toString()).toList(),
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: _buildDropdownField(
                "House", 
                _selectedHouseId, 
                houses.map((h) => h['id'].toString()).toList(),
                (v) => setState(() => _selectedHouseId = v),
                labels: houses.map((h) => "${h['house_number']}").toList(),
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            Expanded(child: _buildDatePickerField("Start Date", _startDate, (d) => setState(() => _startDate = d!))),
            SizedBox(width: 8.w),
            Expanded(child: _buildInputField("Rent (Tsh)", _amountController, Icons.payments, keyboardType: TextInputType.number)),
          ],
        ),
        SizedBox(height: 16.h),
        _buildPhotoUploadField("Tenant Photo", _tenantPhotoPath, _pickTenantPhoto),
        SizedBox(height: 20.h),
        _buildCheckboxRow("I accept Terms & Conditions", _acceptedTerms, (v) => setState(() => _acceptedTerms = v!)),
        _buildCheckboxRow("I agree to the Privacy Policy", _acceptedPrivacy, (v) => setState(() => _acceptedPrivacy = v!)),
      ],
    );
  }

  // --- Helper Widgets ---

  Widget _buildStepLayout({required String title, required List<Widget> children}) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Text(title, style: TextStyle(color: ThemeConstants.primaryOrange, fontSize: 16.sp, fontWeight: FontWeight.bold)),
          ),
          SizedBox(height: 16.h),
          ...children,
          SizedBox(height: 20.h),
        ],
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, IconData icon, {TextInputType? keyboardType}) {
    return ThemeConstants.buildResponsiveGlassCardStatic(
      context,
      padding: EdgeInsets.zero,
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white, fontSize: 12),
        decoration: ThemeConstants.invInputDecoration(label).copyWith(
          prefixIcon: Icon(icon, color: Colors.white70, size: 14.w),
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white60, fontSize: 12),
          contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
        ),
      ),
    );
  }

  Widget _buildDropdownField(String label, String? value, List<String> items, Function(String?) onChanged, {List<String>? labels}) {
    return ThemeConstants.buildResponsiveGlassCardStatic(
      context,
      padding: EdgeInsets.zero,
      child: DropdownButtonFormField<String>(
        value: value,
        isExpanded: true,
        items: List.generate(items.length, (i) => DropdownMenuItem(
          value: items[i],
          child: Text(labels != null ? labels[i] : items[i], style: const TextStyle(fontSize: 12)),
        )),
        onChanged: onChanged,
        dropdownColor: ThemeConstants.bgMid,
        style: const TextStyle(color: Colors.white),
        decoration: ThemeConstants.invInputDecoration(label).copyWith(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white60, fontSize: 12),
          contentPadding: EdgeInsets.only(left: 12.w, right: 8.w, top: 4.h, bottom: 4.h),
        ),
      ),
    );
  }

  Widget _buildDatePickerField(String label, DateTime? date, Function(DateTime?) onSelected) {
    return ThemeConstants.buildResponsiveGlassCard(
      context,
      padding: EdgeInsets.zero,
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(1920),
          lastDate: DateTime(2100),
        );
        if (picked != null) onSelected(picked);
      },
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: Colors.white70, size: 14.w),
            SizedBox(width: 8.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
                Text(
                  date != null ? "${date.day}/${date.month}/${date.year}" : "Select",
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberField(String label, int value, Function(int) onChanged) {
    return ThemeConstants.buildResponsiveGlassCardStatic(
      context,
      padding: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
        child: Row(
          children: [
            Expanded(child: Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10), overflow: TextOverflow.ellipsis)),
            IconButton(
              constraints: const BoxConstraints(),
              padding: EdgeInsets.all(4.w),
              iconSize: 16.w,
              icon: const Icon(Icons.remove, color: Colors.white70),
              onPressed: () => value > 0 ? onChanged(value - 1) : null,
            ),
            Text("$value", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
            IconButton(
              constraints: const BoxConstraints(),
              padding: EdgeInsets.all(4.w),
              iconSize: 16.w,
              icon: const Icon(Icons.add, color: Colors.white70),
              onPressed: () => onChanged(value + 1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadField(String label) {
    return ThemeConstants.buildResponsiveGlassCard(
      context,
      padding: EdgeInsets.zero,
      onTap: () {},
      child: Container(
        height: 48.h,
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.upload_file, color: ThemeConstants.primaryOrange, size: 18.w),
            SizedBox(width: 4.w),
            Text("Attach", style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoUploadField(String label, String? path, VoidCallback onTap) {
    return ThemeConstants.buildResponsiveGlassCard(
      context,
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(12.w),
        width: double.infinity,
        height: 80.h,
        child: Row(
          children: [
            Container(
              width: 56.h,
              height: 56.h,
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(12.r),
                image: path != null ? DecorationImage(image: FileImage(File(path)), fit: BoxFit.cover) : null,
              ),
              child: path == null ? Icon(Icons.add_a_photo, color: Colors.white38, size: 20.w) : null,
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  Text(
                    path != null ? "Photo attached successfully" : "Tap to capture or upload tenant photo",
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ],
              ),
            ),
            if (path != null) Icon(Icons.check_circle, color: ThemeConstants.successGreen, size: 20.w),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckboxRow(String label, bool value, Function(bool?) onChanged) {
    return Row(
      children: [
        SizedBox(
          width: 24.w,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: ThemeConstants.primaryOrange,
            side: const BorderSide(color: Colors.white54),
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11))),
      ],
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedHouseId == null) {
      if (mounted) ThemeConstants.showErrorSnackBar(context, "Please select a house in Step 7");
      return;
    }
    if (!_acceptedTerms || !_acceptedPrivacy) {
      if (mounted) ThemeConstants.showErrorSnackBar(context, "Please accept Terms and Privacy Policy");
      return;
    }

    setState(() => _isSaving = true);
    
    final data = {
      "first_name": _firstNameController.text,
      "last_name": _lastNameController.text,
      "email": _emailController.text,
      "phone": _phoneController.text,
      "dob": _dob?.toIso8601String().split('T')[0],
      "nida": _nidaController.text,
      "gender": _gender,
      "emergency_contact": {
        "name": _emergencyNameController.text,
        "relationship": _relationshipController.text,
        "phone": _emergencyPhoneController.text,
        "email": _emergencyEmailController.text,
      },
      "id_details": {
        "number": _idNumberController.text,
        "state": _idStateController.text,
        "expiration": _idExpiration?.toIso8601String().split('T')[0],
      },
      "employment": {
        "employer": _employerController.text,
        "title": _jobTitleController.text,
        "length": _employmentLengthController.text,
        "work_phone": _workPhoneController.text,
        "status": _isEmployed ? "Employed" : "Unemployed",
      },
      "history": {
        "prev_address": _prevAddressController.text,
        "duration": _stayDurationController.text,
        "reason": _reasonForLeavingController.text,
        "landlord_name": _prevLandlordNameController.text,
        "landlord_phone": _prevLandlordPhoneController.text,
      },
      "occupants": {
        "adults": _adultsCount,
        "children": _childrenCount,
        "others_will_live": _willOthersLive,
      },
      "pets": {
          "type": _petType,
          "breed": _petBreedController.text,
          "age": _petAgeController.text,
          "weight": _petWeightController.text,
      },
      "rental_house_id": _selectedHouseId,
      "rent_amount": _amountController.text,
      "start_date": _startDate.toIso8601String().split('T')[0],
      "tenant_photo": _tenantPhotoPath,
    };

    final success = await context.read<RentalProvider>().onboardTenant(data);

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        ThemeConstants.showSuccessSnackBar(context, "Tenant onboarded successfully!");
        Navigator.pop(context);
      } else {
        ThemeConstants.showErrorSnackBar(context, "Failed to onboard tenant. Try again.");
      }
    }
  }
}
