import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/theme_constants.dart';
import '../../services/localization_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final LocalizationService _localizationService = LocalizationService.instance;

  bool _pushNotifications = true;
  bool _emailNotifications = true;
  bool _paymentAlerts = true;
  bool _debtReminders = true;
  bool _systemUpdates = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pushNotifications = prefs.getBool('push_notifications') ?? true;
      _emailNotifications = prefs.getBool('email_notifications') ?? true;
      _paymentAlerts = prefs.getBool('payment_alerts') ?? true;
      _debtReminders = prefs.getBool('debt_reminders') ?? true;
      _systemUpdates = prefs.getBool('system_updates') ?? false;
      _isLoading = false;
    });
  }

  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeConstants.primaryBlue,
      appBar: ThemeConstants.buildAppBar(
        _localizationService.translate('notifications'),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: ThemeConstants.primaryOrange,
              ),
            )
          : SafeArea(
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
                                color: ThemeConstants.primaryOrange
                                    .withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.notifications,
                                color: ThemeConstants.primaryOrange,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _localizationService
                                        .translate('notifications'),
                                    style: const TextStyle(
                                      color: ThemeConstants.textPrimary,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _localizationService
                                        .translate('notifications_subtitle'),
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

                    // Notification Settings
                    ThemeConstants.buildGlassCard(
                      child: Column(
                        children: [
                          _buildNotificationSwitch(
                            Icons.notifications_active,
                            _localizationService
                                .translate('push_notifications'),
                            'push_notifications',
                            _pushNotifications,
                            (value) =>
                                setState(() => _pushNotifications = value),
                          ),
                          const Divider(color: Colors.white24, height: 1),
                          _buildNotificationSwitch(
                            Icons.email,
                            _localizationService
                                .translate('email_notifications'),
                            'email_notifications',
                            _emailNotifications,
                            (value) =>
                                setState(() => _emailNotifications = value),
                          ),
                          const Divider(color: Colors.white24, height: 1),
                          _buildNotificationSwitch(
                            Icons.payment,
                            _localizationService.translate('payment_alerts'),
                            'payment_alerts',
                            _paymentAlerts,
                            (value) => setState(() => _paymentAlerts = value),
                          ),
                          const Divider(color: Colors.white24, height: 1),
                          _buildNotificationSwitch(
                            Icons.schedule,
                            _localizationService.translate('debt_reminders'),
                            'debt_reminders',
                            _debtReminders,
                            (value) => setState(() => _debtReminders = value),
                          ),
                          const Divider(color: Colors.white24, height: 1),
                          _buildNotificationSwitch(
                            Icons.system_update,
                            _localizationService.translate('system_updates'),
                            'system_updates',
                            _systemUpdates,
                            (value) => setState(() => _systemUpdates = value),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Info Card
                    ThemeConstants.buildGlassCard(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: ThemeConstants.primaryOrange,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _localizationService.isSwahili
                                    ? 'Mipangilio hii itasaidia kudhibiti aina za arifa unazopokea.'
                                    : 'These settings help control what types of notifications you receive.',
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

  Widget _buildNotificationSwitch(
    IconData icon,
    String title,
    String key,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Icon(
        icon,
        color: ThemeConstants.textSecondary,
        size: 24,
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: ThemeConstants.textPrimary,
          fontSize: 16,
        ),
      ),
      trailing: Switch.adaptive(
        value: value,
        onChanged: (newValue) {
          onChanged(newValue);
          _saveSetting(key, newValue);
        },
        activeColor: ThemeConstants.primaryOrange,
        activeTrackColor: ThemeConstants.primaryOrange.withOpacity(0.3),
        inactiveThumbColor: ThemeConstants.textSecondary,
        inactiveTrackColor: Colors.white24,
      ),
    );
  }
}
