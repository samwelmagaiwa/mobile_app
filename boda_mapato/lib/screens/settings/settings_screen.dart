import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "../../constants/theme_constants.dart";
import "../../providers/auth_provider.dart";
import "../../services/localization_service.dart";
import "language_screen.dart";
import "notifications_screen.dart";
import "security_screen.dart";
import "backup_screen.dart";
import "help_screen.dart";

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final LocalizationService _localizationService = LocalizationService.instance;

  @override
  void initState() {
    super.initState();
    // Listen for language changes to rebuild the screen
    _localizationService.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final AuthProvider authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: ThemeConstants.primaryBlue,
      appBar: ThemeConstants.buildAppBar(
        _localizationService.translate('settings'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // User Profile Card
              ThemeConstants.buildGlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: ThemeConstants.primaryOrange,
                        child: authProvider.user?.name != null
                            ? Text(
                                authProvider.user!.name
                                    .substring(0, 1)
                                    .toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 40,
                              ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        authProvider.user?.name ?? "Admin User",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: ThemeConstants.textPrimary,
                        ),
                      ),
                      Text(
                        authProvider.user?.email ?? "admin@bodamapato.com",
                        style: const TextStyle(
                          fontSize: 14,
                          color: ThemeConstants.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Settings Options
              ThemeConstants.buildGlassCard(
                child: Column(
                  children: [
                    _buildSettingsTile(
                      Icons.notifications,
                      _localizationService.translate('notifications'),
                      _localizationService.translate('notifications_subtitle'),
                      () => _navigateToScreen(const NotificationsScreen()),
                    ),
                    const Divider(color: Colors.white24, height: 1),
                    _buildSettingsTile(
                      Icons.language,
                      _localizationService.translate('language'),
                      _localizationService.translate('language_subtitle'),
                      () => _navigateToScreen(const LanguageScreen()),
                    ),
                    const Divider(color: Colors.white24, height: 1),
                    _buildSettingsTile(
                      Icons.security,
                      _localizationService.translate('security'),
                      _localizationService.translate('security_subtitle'),
                      () => _navigateToScreen(const SecurityScreen()),
                    ),
                    const Divider(color: Colors.white24, height: 1),
                    _buildSettingsTile(
                      Icons.backup,
                      _localizationService.translate('backup'),
                      _localizationService.translate('backup_subtitle'),
                      () => _navigateToScreen(const BackupScreen()),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // App Information
              ThemeConstants.buildGlassCard(
                child: Column(
                  children: [
                    _buildSettingsTile(
                      Icons.info,
                      _localizationService.translate('about_app'),
                      _localizationService.translate('about_app_subtitle'),
                      () => _showAboutDialog(),
                    ),
                    const Divider(color: Colors.white24, height: 1),
                    _buildSettingsTile(
                      Icons.help,
                      _localizationService.translate('help'),
                      _localizationService.translate('help_subtitle'),
                      () => _navigateToScreen(const HelpScreen()),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Logout Button
              ThemeConstants.buildGlassCard(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  leading: const Icon(
                    Icons.logout,
                    color: Colors.redAccent,
                    size: 24,
                  ),
                  title: Text(
                    _localizationService.translate('logout'),
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  onTap: () => _showLogoutDialog(authProvider),
                ),
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTile(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
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
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: ThemeConstants.textSecondary,
          fontSize: 13,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: ThemeConstants.textSecondary,
        size: 20,
      ),
      onTap: onTap,
    );
  }

  void _navigateToScreen(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ThemeConstants.primaryBlue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            const Icon(
              Icons.info_outline,
              color: ThemeConstants.primaryOrange,
            ),
            const SizedBox(width: 8),
            Text(
              _localizationService.translate('app_name'),
              style: const TextStyle(color: ThemeConstants.textPrimary),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${_localizationService.translate('version')}: 1.0.0",
              style: const TextStyle(color: ThemeConstants.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              _localizationService.translate('app_description'),
              style: const TextStyle(color: ThemeConstants.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              _localizationService.translate('copyright'),
              style: const TextStyle(color: ThemeConstants.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              _localizationService.translate('ok'),
              style: const TextStyle(color: ThemeConstants.primaryOrange),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(AuthProvider authProvider) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ThemeConstants.primaryBlue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            const Icon(
              Icons.logout,
              color: Colors.redAccent,
            ),
            const SizedBox(width: 8),
            Text(
              _localizationService.translate('confirm'),
              style: const TextStyle(color: ThemeConstants.textPrimary),
            ),
          ],
        ),
        content: Text(
          _localizationService.translate('logout_confirm'),
          style: const TextStyle(color: ThemeConstants.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              _localizationService.translate('no'),
              style: const TextStyle(color: ThemeConstants.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              _localizationService.translate('yes'),
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if ((confirm ?? false) && context.mounted) {
      await authProvider.logout();
    }
  }
}
