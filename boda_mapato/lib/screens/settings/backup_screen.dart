import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/theme_constants.dart';
import '../../services/api_service.dart';
import '../../services/localization_service.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

// ignore_for_file: control_flow_in_finally, avoid_catches_without_on_clauses, unnecessary_brace_in_string_interps
class _BackupScreenState extends State<BackupScreen> {
  final LocalizationService _localizationService = LocalizationService.instance;
  final ApiService _apiService = ApiService();

  bool _autoBackupEnabled = false;
  bool _isBackingUp = false;
  bool _isRestoring = false;
  String? _lastBackupDate;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _autoBackupEnabled = prefs.getBool('auto_backup') ?? false;
      _lastBackupDate = prefs.getString('last_backup_date');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeConstants.primaryBlue,
      appBar: ThemeConstants.buildAppBar(
        _localizationService.translate('backup'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
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
                        child: const Icon(
                          Icons.backup,
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
                              _localizationService.translate('backup'),
                              style: const TextStyle(
                                color: ThemeConstants.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _localizationService.translate('backup_subtitle'),
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

              // Backup Settings
              ThemeConstants.buildGlassCard(
                child: Column(
                  children: [
                    // Auto Backup Toggle
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      leading: const Icon(Icons.schedule,
                          color: ThemeConstants.textSecondary),
                      title: Text(
                        _localizationService.translate('auto_backup'),
                        style: const TextStyle(
                            color: ThemeConstants.textPrimary, fontSize: 16),
                      ),
                      subtitle: Text(
                        _localizationService.isSwahili
                            ? 'Hifadhi data kiotomatiki kila siku'
                            : 'Automatically backup data daily',
                        style: const TextStyle(
                            color: ThemeConstants.textSecondary, fontSize: 13),
                      ),
                      trailing: Switch.adaptive(
                        value: _autoBackupEnabled,
                        onChanged: (value) async {
                          setState(() => _autoBackupEnabled = value);
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setBool('auto_backup', value);
                        },
                        activeColor: ThemeConstants.primaryOrange,
                      ),
                    ),

                    const Divider(color: Colors.white24, height: 1),

                    // Manual Backup
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      leading: _isBackingUp
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: ThemeConstants.primaryOrange,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.backup,
                              color: ThemeConstants.textSecondary),
                      title: Text(
                        _localizationService.translate('backup_now'),
                        style: const TextStyle(
                            color: ThemeConstants.textPrimary, fontSize: 16),
                      ),
                      subtitle: Text(
                        _lastBackupDate != null
                            ? '${_localizationService.translate('last_backup')}: $_lastBackupDate'
                            : _localizationService.isSwahili
                                ? 'Hakuna hifadhi ya hivi karibuni'
                                : 'No recent backup',
                        style: const TextStyle(
                            color: ThemeConstants.textSecondary, fontSize: 13),
                      ),
                      trailing: const Icon(Icons.chevron_right,
                          color: ThemeConstants.textSecondary),
                      onTap: _isBackingUp ? null : _performBackup,
                    ),

                    const Divider(color: Colors.white24, height: 1),

                    // Restore Data
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      leading: _isRestoring
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: ThemeConstants.primaryOrange,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.restore,
                              color: ThemeConstants.textSecondary),
                      title: Text(
                        _localizationService.translate('restore_data'),
                        style: const TextStyle(
                            color: ThemeConstants.textPrimary, fontSize: 16),
                      ),
                      subtitle: Text(
                        _localizationService.isSwahili
                            ? 'Rejesha data kutoka hifadhi iliyopo'
                            : 'Restore data from existing backup',
                        style: const TextStyle(
                            color: ThemeConstants.textSecondary, fontSize: 13),
                      ),
                      trailing: const Icon(Icons.chevron_right,
                          color: ThemeConstants.textSecondary),
                      onTap: _isRestoring ? null : _showRestoreDialog,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Backup Info
              ThemeConstants.buildGlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: ThemeConstants.primaryOrange,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _localizationService.isSwahili
                                ? 'Maelezo ya Hifadhi'
                                : 'Backup Information',
                            style: const TextStyle(
                              color: ThemeConstants.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _localizationService.isSwahili
                            ? '• Data yote ya madereva, malipo, na risiti itahifadhiwa\n'
                                '• Hifadhi zinazohifadhiwa kwenye cloud kwa usalama\n'
                                '• Unaweza kurejesha data wakati wowote\n'
                                '• Hifadhi ya kiotomatiki inafanywa kila siku saa 2:00 usiku'
                            : '• All driver, payment, and receipt data will be backed up\n'
                                '• Backups are stored securely in the cloud\n'
                                '• You can restore data at any time\n'
                                '• Auto backup runs daily at 2:00 AM',
                        style: const TextStyle(
                          color: ThemeConstants.textSecondary,
                          fontSize: 13,
                          height: 1.5,
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

  Future<void> _performBackup() async {
    setState(() => _isBackingUp = true);

    try {
      final response = await _apiService.post('/admin/backup', {
        'type': 'full',
        'include_files': true,
      });

      if (response['success'] == true) {
        // Save backup date
        final prefs = await SharedPreferences.getInstance();
        final now = DateTime.now();
        final dateStr = '${now.day}/${now.month}/${now.year}';
        await prefs.setString('last_backup_date', dateStr);
        if (!mounted) return;
        setState(() => _lastBackupDate = dateStr);

        ThemeConstants.showSuccessSnackBar(
          context,
          _localizationService.translate('backup_successful'),
        );
      } else {
        throw Exception(response['message'] ?? 'Backup failed');
      }
    } catch (e) {
      if (!mounted) return;
      ThemeConstants.showErrorSnackBar(
        context,
        _localizationService.isSwahili
            ? 'Imeshindikana kuhifadhi: ${e}'
            : 'Backup failed: ${e}',
      );
    } finally {
      if (!mounted) return;
      setState(() => _isBackingUp = false);
    }
  }

  void _showRestoreDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ThemeConstants.primaryBlue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning, color: Colors.orange),
            const SizedBox(width: 8),
            Text(
              _localizationService.translate('confirm'),
              style: const TextStyle(color: ThemeConstants.textPrimary),
            ),
          ],
        ),
        content: Text(
          _localizationService.isSwahili
              ? 'Je, una uhakika unataka kurejesha data? Hii itafuta data ya sasa na kuiweka na ile ya zamani.'
              : 'Are you sure you want to restore data? This will replace current data with backup data.',
          style: const TextStyle(color: ThemeConstants.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              _localizationService.translate('cancel'),
              style: const TextStyle(color: ThemeConstants.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _performRestore();
            },
            child: Text(
              _localizationService.translate('restore_data'),
              style: const TextStyle(color: Colors.orange),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _performRestore() async {
    setState(() => _isRestoring = true);

    try {
      final response = await _apiService.post('/admin/restore', {
        'type': 'full',
        'confirm': true,
      });

      if (response['success'] == true) {
        if (!mounted) return;
        ThemeConstants.showSuccessSnackBar(
          context,
          _localizationService.translate('restore_successful'),
        );
      } else {
        throw Exception(response['message'] ?? 'Restore failed');
      }
    } catch (e) {
      if (!mounted) return;
      ThemeConstants.showErrorSnackBar(
        context,
        _localizationService.isSwahili
            ? 'Imeshindikana kurejesha: ${e}'
            : 'Restore failed: ${e}',
      );
    } finally {
      if (!mounted) return;
      setState(() => _isRestoring = false);
    }
  }
}
