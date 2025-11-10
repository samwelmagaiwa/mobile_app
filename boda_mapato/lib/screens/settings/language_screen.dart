import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../constants/theme_constants.dart';
import '../../services/localization_service.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  final LocalizationService _localizationService = LocalizationService.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeConstants.primaryBlue,
      appBar: ThemeConstants.buildAppBar(
        _localizationService.translate('select_language'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Header
              ThemeConstants.buildGlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: ThemeConstants.primaryOrange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.language,
                          color: ThemeConstants.primaryOrange,
                          size: 20.sp,
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _localizationService.translate('language'),
                              style: const TextStyle(
                                color: ThemeConstants.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _localizationService
                                  .translate('language_subtitle'),
                              style: const TextStyle(
                                color: ThemeConstants.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Language Options
              ThemeConstants.buildGlassCard(
                child: Column(
                  children: [
                    _buildLanguageOption(
                      'sw',
                      _localizationService.translate('swahili'),
                      '🇹🇿',
                      _localizationService.isSwahili,
                    ),
                    const Divider(color: Colors.white24, height: 1),
                    _buildLanguageOption(
                      'en',
                      _localizationService.translate('english'),
                      '🇺🇸',
                      _localizationService.isEnglish,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Current Language Info
              ThemeConstants.buildGlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: ThemeConstants.primaryOrange,
                        size: 18.sp,
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          _localizationService.isSwahili
                              ? 'Programu inatumia lugha ya Kiswahili'
                              : 'App is using English language',
                          style: const TextStyle(
                            color: ThemeConstants.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageOption(
    String languageCode,
    String languageName,
    String flag,
    bool isSelected,
  ) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Text(
        flag,
        style: TextStyle(fontSize: 24.sp),
      ),
      title: Text(
        languageName,
        style: TextStyle(
          color: isSelected
              ? ThemeConstants.primaryOrange
              : ThemeConstants.textPrimary,
          fontSize: 16,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      trailing: isSelected
          ? Icon(
              Icons.check_circle,
              color: ThemeConstants.primaryOrange,
              size: 18.sp,
            )
          : Icon(
              Icons.radio_button_unchecked,
              color: ThemeConstants.textSecondary,
              size: 18.sp,
            ),
      onTap: () => _changeLanguage(languageCode),
    );
  }

  Future<void> _changeLanguage(String languageCode) async {
    if (languageCode == _localizationService.currentLanguage) return;

// Show loading (fire-and-forget)
    unawaited(showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: ThemeConstants.primaryBlue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              color: ThemeConstants.primaryOrange,
              strokeWidth: 2,
            ),
            const SizedBox(width: 16),
            Text(
              _localizationService.translate('loading'),
              style: const TextStyle(color: ThemeConstants.textPrimary),
            ),
          ],
        ),
      ),
    ));

    // Change language
    await _localizationService.changeLanguage(languageCode);

    // Close loading dialog
    if (mounted) {
      Navigator.of(context).pop();

      // Show success message
      ThemeConstants.showSuccessSnackBar(
        context,
        _localizationService.translate('language_changed'),
      );

      // Refresh the screen
      setState(() {});

      // Optional: Navigate back to settings or restart app
      // For full app language change, you might want to restart the app
    }
  }
}
