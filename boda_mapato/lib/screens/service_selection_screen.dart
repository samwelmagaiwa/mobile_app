import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/theme_constants.dart';
import '../services/localization_service.dart';

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
          await Navigator.pushReplacementNamed(context, '/inventory');
        }
        return;
      case 'rental':
        if (context.mounted) {
          await Navigator.pushReplacementNamed(context, '/coming-soon',
              arguments: service);
        }
        return;
      case 'transport':
        if (context.mounted) {
          await Navigator.pushReplacementNamed(context, '/modern-dashboard');
        }
        return;
      default:
        if (context.mounted) {
          await Navigator.pushReplacementNamed(context, '/coming-soon',
              arguments: service);
        }
        return;
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
  const _ServiceTile(
      {required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16.r),
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80.w,
              height: 80.w,
              decoration: BoxDecoration(
                color: Colors.blue.shade700,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 40.sp),
            ),
            SizedBox(height: 8.h),
            Flexible(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: AutoSizeText(
                  label,
                  maxLines: 2,
                  minFontSize: 10,
                  maxFontSize: 14,
                  overflow: TextOverflow.ellipsis,
                  style: ThemeConstants.bodyStyle
                      .copyWith(fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
