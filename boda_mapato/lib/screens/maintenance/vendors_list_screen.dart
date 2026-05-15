import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:boda_mapato/constants/theme_constants.dart';
import 'package:boda_mapato/providers/maintenance_provider.dart';

class VendorsListScreen extends StatefulWidget {
  const VendorsListScreen({super.key});

  @override
  _VendorsListScreenState createState() => _VendorsListScreenState();
}

class _VendorsListScreenState extends State<VendorsListScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _specialtyController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MaintenanceProvider>().fetchVendors();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _specialtyController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _callVendor(String? phone) async {
    if (phone == null || phone.isEmpty) {
      ThemeConstants.showErrorSnackBar(context, "Namba ya simu haipatikani");
      return;
    }
    final String urlString = "tel:$phone";
    if (await canLaunchUrlString(urlString)) {
      await launchUrlString(urlString, mode: LaunchMode.externalApplication);
    } else {
      ThemeConstants.showErrorSnackBar(context, "Imeshindikana kupiga simu");
    }
  }

  void _showAddVendorSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 14.w, right: 14.w, top: 20.h
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                margin: EdgeInsets.only(bottom: 24.h),
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10.r)),
              ),
            ),
            Text("Ongeza Fundi Mpya", style: ThemeConstants.headingStyle.copyWith(fontSize: 18.sp)),
            SizedBox(height: 24.h),
            _buildTextField(_nameController, "Jina kamili", Icons.person),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(child: _buildTextField(_phoneController, "Namba ya simu", Icons.phone, keyboardType: TextInputType.phone)),
                SizedBox(width: 8.w),
                Expanded(child: _buildTextField(_specialtyController, "Utaalamu", Icons.category)),
              ],
            ),
            SizedBox(height: 16.h),
            _buildTextField(_emailController, "Barua pepe (Email)", Icons.email, keyboardType: TextInputType.emailAddress),
            SizedBox(height: 16.h),
            _buildTextField(_addressController, "Anwani (Mtaa/Eneo)", Icons.location_on),
            SizedBox(height: 32.h),
            SizedBox(
              width: double.infinity,
              height: 58.h,
              child: ElevatedButton(
                onPressed: () async {
                  if (_nameController.text.isEmpty || _phoneController.text.isEmpty) {
                    ThemeConstants.showErrorSnackBar(context, "Tafadhali jaza jina na namba ya simu");
                    return;
                  }
                  final success = await context.read<MaintenanceProvider>().addVendor(
                    name: _nameController.text,
                    phone: _phoneController.text,
                    specialty: _specialtyController.text,
                    email: _emailController.text,
                    address: _addressController.text,
                  );
                  if (success && mounted) {
                    Navigator.pop(context);
                    _nameController.clear();
                    _phoneController.clear();
                    _specialtyController.clear();
                    _emailController.clear();
                    _addressController.clear();
                    ThemeConstants.showSuccessSnackBar(context, "Fundi ameongezwa kikamilifu");
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ThemeConstants.footerBarColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                ),
                child: Text("HIFADHI TAARIFA", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16.sp)),
              ),
            ),
            SizedBox(height: 30.h),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(final BuildContext context) {
    return ThemeConstants.buildScaffold(
      title: "Watoa Huduma & Mafundi",
      body: Consumer<MaintenanceProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.vendors.isEmpty) {
            return ThemeConstants.buildLoadingWidget();
          }

          if (provider.vendors.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_search_outlined, size: 64.sp, color: Colors.grey.withOpacity(0.4)),
                  SizedBox(height: 16.h),
                  Text("Hakuna mafundi waliorekodiwa", style: ThemeConstants.subHeadingStyle),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 100.h),
            itemCount: provider.vendors.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final vendor = provider.vendors[index];
              return Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: ThemeConstants.buildResponsiveGlassCard(
                  context,
                  onTap: () => _callVendor(vendor['phone']),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12.r),
                        decoration: BoxDecoration(
                          color: ThemeConstants.footerBarColor.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.handyman_outlined, color: ThemeConstants.footerBarColor, size: 24.sp),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(vendor['name'] ?? 'N/A', 
                                style: ThemeConstants.bodyStyle.copyWith(fontWeight: FontWeight.bold, fontSize: 16.sp)),
                            SizedBox(height: 4.h),
                            Text(vendor['specialty'] ?? 'Fundi', 
                                style: TextStyle(color: ThemeConstants.footerBarColor, fontSize: 12.sp, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Container(
                          padding: EdgeInsets.all(8.r),
                          decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8.r)),
                          child: Icon(Icons.phone_forwarded, color: Colors.green, size: 20.sp),
                        ),
                        onPressed: () => _callVendor(vendor['phone']),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: 20.h),
        child: FloatingActionButton(
          onPressed: _showAddVendorSheet,
          backgroundColor: ThemeConstants.footerBarColor,
          elevation: 6,
          child: Icon(Icons.person_add_alt_1, color: Colors.white, size: 24.sp),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: ThemeConstants.bodyStyle,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: ThemeConstants.captionStyle,
        prefixIcon: Icon(icon, color: Colors.grey, size: 18.sp),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(color: ThemeConstants.footerBarColor, width: 1.2),
        ),
      ),
    );
  }
}
