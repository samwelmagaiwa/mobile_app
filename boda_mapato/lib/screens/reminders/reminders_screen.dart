import "package:flutter/material.dart";

import "../../constants/colors.dart";
import "../../constants/strings.dart";
import "../../constants/styles.dart";
import "../../models/reminder.dart";
import "../../widgets/custom_button.dart";
import "../../widgets/custom_card.dart";
import "../../widgets/reminder_tile.dart";

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  final List<Reminder> _reminders = <Reminder>[]; // This would come from a provider
  
  void _showAddReminderDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (final BuildContext context) => const _AddReminderSheet(),
    );
  }

  @override
  Widget build(final BuildContext context) {
    final List<Reminder> activeReminders = _reminders.where((final Reminder r) => r.isActive).toList();
    final List<Reminder> upcomingReminders = activeReminders.where((final Reminder r) => r.isUpcoming).toList();
    final List<Reminder> overdueReminders = activeReminders.where((final Reminder r) => r.isOverdue).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          AppStrings.reminders,
          style: AppStyles.heading2,
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppStyles.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Summary Cards
            Row(
              children: <Widget>[
                Expanded(
                  child: _SummaryCard(
                    title: "Vikumbusho vya Sasa",
                    count: activeReminders.length,
                    icon: Icons.notifications_active,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppStyles.spacingM),
                Expanded(
                  child: _SummaryCard(
                    title: "Vilivyochelewa",
                    count: overdueReminders.length,
                    icon: Icons.warning,
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppStyles.spacingL),
            
            // Overdue Reminders
            if (overdueReminders.isNotEmpty) ...<Widget>[
              const Row(
                children: <Widget>[
                  Icon(
                    Icons.warning,
                    color: AppColors.error,
                    size: 20,
                  ),
                  SizedBox(width: AppStyles.spacingS),
                  Text(
                    "Vikumbusho vilivyochelewa",
                    style: AppStyles.heading3,
                  ),
                ],
              ),
              const SizedBox(height: AppStyles.spacingM),
              ...overdueReminders.map((final Reminder reminder) => Padding(
                padding: const EdgeInsets.only(bottom: AppStyles.spacingM),
                child: CustomCard(
                  child: ReminderTile(
                    reminder: reminder,
                    isOverdue: true,
                  ),
                ),
              ),),
              const SizedBox(height: AppStyles.spacingL),
            ],
            
            // Upcoming Reminders
            const Text(
              "Vikumbusho vya Baadaye",
              style: AppStyles.heading3,
            ),
            const SizedBox(height: AppStyles.spacingM),
            
            if (upcomingReminders.isEmpty)
              CustomCard(
                child: Padding(
                  padding: const EdgeInsets.all(AppStyles.spacingL),
                  child: Column(
                    children: <Widget>[
                      const Icon(
                        Icons.notifications_none,
                        size: 48,
                        color: AppColors.textHint,
                      ),
                      const SizedBox(height: AppStyles.spacingM),
                      Text(
                        "Hakuna vikumbusho vya baadaye",
                        style: AppStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppStyles.spacingM),
                      CustomButton(
                        text: AppStrings.newReminder,
                        onPressed: _showAddReminderDialog,
                      ),
                    ],
                  ),
                ),
              )
            else
              ...upcomingReminders.map((final Reminder reminder) => Padding(
                padding: const EdgeInsets.only(bottom: AppStyles.spacingM),
                child: CustomCard(
                  child: ReminderTile(reminder: reminder),
                ),
              ),),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddReminderDialog,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {

  const _SummaryCard({
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
  });
  final String title;
  final int count;
  final IconData icon;
  final Color color;

  @override
  Widget build(final BuildContext context) => CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(AppStyles.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(icon, color: color, size: 20),
                const SizedBox(width: AppStyles.spacingS),
                Expanded(
                  child: Text(
                    title,
                    style: AppStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppStyles.spacingS),
            Text(
              count.toString(),
              style: AppStyles.heading2.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
}

class _AddReminderSheet extends StatefulWidget {
  const _AddReminderSheet();

  @override
  State<_AddReminderSheet> createState() => _AddReminderSheetState();
}

class _AddReminderSheetState extends State<_AddReminderSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  DateTime _selectedDateTime = DateTime.now().add(const Duration(hours: 1));
  ReminderType _selectedType = ReminderType.oneTime;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime() async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null && mounted) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      );

      if (time != null && mounted) {
        setState(() {
          _selectedDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _saveReminder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Simulate saving reminder
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.reminderSet),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Hitilafu: $e"),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(final BuildContext context) => Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppStyles.spacingM),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppStyles.radiusL(context)),
          ),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                AppStrings.newReminder,
                style: AppStyles.heading2,
              ),
              const SizedBox(height: AppStyles.spacingL),
              
              // Title
              TextFormField(
                controller: _titleController,
                decoration: AppStyles.inputDecoration(context).copyWith(
                  labelText: AppStrings.reminderTitle,
                  hintText: "Mfano: Kukusanya Mapato",
                ),
                validator: (final String? value) {
                  if (value == null || value.trim().isEmpty) {
                    return AppStrings.fieldRequired;
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: AppStyles.spacingM),
              
              // Message
              TextFormField(
                controller: _messageController,
                decoration: AppStyles.inputDecoration(context).copyWith(
                  labelText: AppStrings.reminderMessage,
                  hintText: "Maelezo ya kikumbusho",
                ),
                maxLines: 3,
                validator: (final String? value) {
                  if (value == null || value.trim().isEmpty) {
                    return AppStrings.fieldRequired;
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: AppStyles.spacingM),
              
              // Date and Time
              InkWell(
                onTap: _selectDateTime,
                child: Container(
                  padding: const EdgeInsets.all(AppStyles.spacingM),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.textHint),
                    borderRadius: BorderRadius.circular(AppStyles.radiusM(context)),
                  ),
                  child: Row(
                    children: <Widget>[
                      const Icon(
                        Icons.schedule,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: AppStyles.spacingM),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              AppStrings.reminderTime,
                              style: AppStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              "${_selectedDateTime.day}/${_selectedDateTime.month}/${_selectedDateTime.year} ${_selectedDateTime.hour}:${_selectedDateTime.minute.toString().padLeft(2, "0")}",
                              style: AppStyles.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: AppStyles.spacingM),
              
              // Reminder Type
              const Text(
                "Aina ya Kikumbusho",
                style: AppStyles.bodyMedium,
              ),
              const SizedBox(height: AppStyles.spacingS),
              DropdownButtonFormField<ReminderType>(
                value: _selectedType,
                decoration: AppStyles.inputDecoration(context),
                items: ReminderType.values
                    .map((final ReminderType type) => DropdownMenuItem<ReminderType>(
                          value: type,
                          child: Text(
                            type.name,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),)
                    .toList(),
                onChanged: (final ReminderType? value) {
                  if (value != null) {
                    setState(() {
                      _selectedType = value;
                    });
                  }
                },
              ),
              
              const SizedBox(height: AppStyles.spacingL),
              
              // Save Button
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  text: _isLoading ? AppStrings.loading : AppStrings.save,
                  onPressed: _isLoading ? null : _saveReminder,
                  isLoading: _isLoading,
                ),
              ),
            ],
          ),
        ),
      ),
    );
}
