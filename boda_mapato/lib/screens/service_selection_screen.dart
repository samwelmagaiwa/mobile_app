import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../services/localization_service.dart';
import '../constants/theme_constants.dart';

class ServiceSelectionScreen extends StatelessWidget {
  const ServiceSelectionScreen({super.key});

  static const String _serviceKey = 'selected_service';

  Future<void> _selectService(BuildContext context, String service) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_serviceKey, service);

    // Navigate to service home
    switch (service) {
      case 'inventory':
        if (context.mounted) {
          Navigator.pushReplacementNamed(context, '/inventory');
        }
        break;
      case 'rental':
      case 'transport':
      default:
        if (context.mounted) {
          Navigator.pushReplacementNamed(context, '/coming-soon', arguments: service);
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = LocalizationService.instance;
    return Scaffold(
      backgroundColor: ThemeConstants.primaryBlue,
      appBar: ThemeConstants.buildAppBar(loc.translate('select_service')),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AutoSizeText(
                loc.translate('select_service_subtitle'),
                maxLines: 2,
                minFontSize: 12,
                style: ThemeConstants.subHeadingStyle,
              ),
              SizedBox(height: 16.h),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12.w,
                  mainAxisSpacing: 12.h,
                  childAspectRatio: 1.05,
                  children: [
                    _ServiceTile(
                      icon: Icons.storefront,
                      label: loc.translate('inventory_service'),
                      onTap: () => _selectService(context, 'inventory'),
                    ),
                    _ServiceTile(
                      icon: Icons.home_work_outlined,
                      label: loc.translate('rental_service'),
                      onTap: () => _selectService(context, 'rental'),
                    ),
                    _ServiceTile(
                      icon: Icons.local_shipping_outlined,
                      label: loc.translate('transport_service'),
                      onTap: () => _selectService(context, 'transport'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16.r),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: Colors.white24),
        ),
        padding: EdgeInsets.all(16.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56.w,
              height: 56.w,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 28.sp),
            ),
            SizedBox(height: 12.h),
            AutoSizeText(
              label,
              maxLines: 1,
              minFontSize: 12,
              style: ThemeConstants.bodyStyle.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
