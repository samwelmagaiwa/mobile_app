import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/theme_constants.dart';
import '../services/localization_service.dart';

class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({super.key, this.service});
  final String? service;

  @override
  Widget build(BuildContext context) {
    final loc = LocalizationService.instance;
    final s = service ?? ModalRoute.of(context)?.settings.arguments as String?;
    final name = s == 'rental'
        ? loc.translate('rental_service')
        : s == 'transport'
            ? loc.translate('transport_service')
            : 'Service';
    return Scaffold(
      backgroundColor: ThemeConstants.primaryBlue,
      appBar: ThemeConstants.buildAppBar(name),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Text(
            loc.translate('coming_soon'),
            style: ThemeConstants.headingStyle.copyWith(fontSize: 22.sp),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
