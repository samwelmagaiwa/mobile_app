import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  loc.translate('coming_soon'),
                  style: ThemeConstants.headingStyle.copyWith(fontSize: 22.sp),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20.h),
                ElevatedButton.icon(
                  icon: const Icon(Icons.arrow_back),
                  label: Text(loc.translate('select_service')),
                  onPressed: () async {
                    // Clear saved service and go back to selection
                    try {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.remove('selected_service');
                    } on Exception catch (_) {
                      // ignore
                    }
                    if (context.mounted) {
                      await Navigator.pushReplacementNamed(
                          context, '/select-service');
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
