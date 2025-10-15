import "dart:async";
import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "../../constants/theme_constants.dart";
import "../../models/reminder.dart";
import "../../services/api_service.dart";
import "../../services/auth_service.dart";
import "../../services/localization_service.dart";
import "../../utils/responsive_helper.dart";

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  final List<Reminder> _reminders = <Reminder>[];
  List<Reminder> _filteredReminders = <Reminder>[];
  String _searchQuery = "";
  String _selectedFilter = "all"; // all, active, overdue, completed

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Guard: only fetch if authenticated
      final bool isAuthed = await AuthService.isAuthenticated();
      if (!isAuthed) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }
      final Map<String, dynamic> response = await _apiService.getReminders();

      // Handle the API response structure
      List<dynamic> remindersList;
      final Map<String, dynamic>? dataMap =
          response['data'] as Map<String, dynamic>?;
      if (response['data'] is List) {
        remindersList = response['data'] as List<dynamic>;
      } else if (dataMap != null && dataMap['data'] is List) {
        remindersList = dataMap['data'] as List<dynamic>;
      } else {
        remindersList = <dynamic>[];
      }

      if (mounted) {
        setState(() {
          _reminders
            ..clear()
            ..addAll(
              remindersList
                  .map((json) =>
                      Reminder.fromJson(json as Map<String, dynamic>))
                  .toList(),
            );
          _filterReminders();
          _isLoading = false;
        });
      }
    } on Exception catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ThemeConstants.showErrorSnackBar(context, "Hitilafu katika kupakia mikumbusho: $e");
      }
    }
  }

  void _filterReminders() {
    setState(() {
      _filteredReminders = _reminders.where((reminder) {
        final bool matchesSearch = _searchQuery.isEmpty ||
            reminder.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            reminder.message.toLowerCase().contains(_searchQuery.toLowerCase());

        final bool matchesFilter = _selectedFilter == "all" ||
            (_selectedFilter == "active" && reminder.isActive) ||
            (_selectedFilter == "overdue" && reminder.isOverdue) ||
            (_selectedFilter == "completed" &&
                reminder.status == ReminderStatus.completed);

        return matchesSearch && matchesFilter;
      }).toList();
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _filterReminders();
  }

  void _onFilterChanged(String filter) {
    setState(() {
      _selectedFilter = filter;
    });
    _filterReminders();
  }

  void _showAddReminderDialog() {
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) => _AddReminderDialog(
        apiService: _apiService,
      ),
).then((bool? result) {
      if (result ?? false) {
        unawaited(_loadReminders()); // Refresh reminders if one was added
      }
    });
  }

  Future<void> _deleteReminder(String reminderId) async {
    try {
      await _apiService.deleteReminder(reminderId);
      unawaited(_loadReminders());

      if (mounted) {
        ThemeConstants.showSuccessSnackBar(context, "Kikumbusho kimefutwa");
      }
    } on Exception catch (e) {
      if (mounted) {
        ThemeConstants.showErrorSnackBar(context, "Hitilafu katika kufuta kikumbusho: $e");
      }
    }
  }

  Future<void> _markAsCompleted(String reminderId) async {
    try {
      await _apiService.updateReminder(reminderId, {'status': 'completed'});
      unawaited(_loadReminders());

      if (mounted) {
        ThemeConstants.showSuccessSnackBar(context, "Kikumbusho kimekamilika");
      }
    } on Exception catch (e) {
      if (mounted) {
        ThemeConstants.showErrorSnackBar(context, "Hitilafu katika kubadilisha hali ya kikumbusho: $e");
      }
    }
  }

  @override
  Widget build(final BuildContext context) {
    ResponsiveHelper.init(context);

    final activeReminders =
        _filteredReminders.where((r) => r.isActive).toList();
    final overdueReminders =
        _filteredReminders.where((r) => r.isOverdue).toList();
    final upcomingReminders =
        _filteredReminders.where((r) => r.isUpcoming).toList();

    return Consumer<LocalizationService>(
      builder: (context, localizationService, child) => ThemeConstants.buildResponsiveScaffold(
        context,
        title: localizationService.translate('reminders'),
      body: _isLoading
          ? ThemeConstants.buildResponsiveLoadingWidget(context)
          : RefreshIndicator(
              onRefresh: _loadReminders,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
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
                            color: ThemeConstants.primaryBlue,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _SummaryCard(
                            title: "Vilivyochelewa",
                            count: overdueReminders.length,
                            icon: Icons.warning,
                            color: ThemeConstants.errorRed,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Search and Filter Section
                    _buildSearchAndFilter(),

                    const SizedBox(height: 24),

                    // Reminders List
                    if (_filteredReminders.isEmpty)
                      _buildEmptyState()
                    else
                      _buildRemindersList(overdueReminders, upcomingReminders),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddReminderDialog,
        backgroundColor: ThemeConstants.primaryBlue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    ),
    );
  }

  Widget _buildSearchAndFilter() {
    return ThemeConstants.buildGlassCardStatic(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: <Widget>[
            // Search Field
            TextField(
              onChanged: _onSearchChanged,
              style: ThemeConstants.bodyStyle,
              decoration: InputDecoration(
                hintText: "Tafuta kikumbusho...",
                hintStyle: ThemeConstants.bodyStyle.copyWith(
                  color: ThemeConstants.textSecondary,
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  color: ThemeConstants.textSecondary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: ThemeConstants.textSecondary.withOpacity(0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: ThemeConstants.textSecondary.withOpacity(0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: ThemeConstants.primaryBlue,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Filter Chips
            Wrap(
              spacing: 8,
              children: <Widget>[
                _buildFilterChip("all", "Yote"),
                _buildFilterChip("active", "Hai"),
                _buildFilterChip("overdue", "Yamechelewa"),
                _buildFilterChip("completed", "Yamekamilika"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : ThemeConstants.textPrimary,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) => _onFilterChanged(value),
      backgroundColor: Colors.transparent,
      selectedColor: ThemeConstants.primaryBlue,
      checkmarkColor: Colors.white,
      side: BorderSide(
        color: isSelected
            ? ThemeConstants.primaryBlue
            : ThemeConstants.textSecondary.withOpacity(0.3),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ThemeConstants.buildGlassCardStatic(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: <Widget>[
            const Icon(
              Icons.notifications_none,
              size: 48,
              color: ThemeConstants.textSecondary,
            ),
            const SizedBox(height: 16),
            const Text(
              "Hakuna Vikumbusho",
              style: ThemeConstants.headingStyle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "Bofya kitufe cha + kuongeza kikumbusho kipya",
              style: ThemeConstants.bodyStyle.copyWith(
                color: ThemeConstants.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _showAddReminderDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: ThemeConstants.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text("Kikumbusho Kipya"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRemindersList(
      List<Reminder> overdueReminders, List<Reminder> upcomingReminders) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Overdue Reminders Section
        if (overdueReminders.isNotEmpty) ...<Widget>[
          const Row(
            children: <Widget>[
              Icon(
                Icons.warning,
                color: ThemeConstants.errorRed,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                "Vikumbusho Vilivyochelewa",
                style: ThemeConstants.headingStyle,
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...overdueReminders
              .map((reminder) => _buildReminderCard(reminder, isOverdue: true)),
          const SizedBox(height: 24),
        ],

        // Active Reminders Section
        if (upcomingReminders.isNotEmpty) ...<Widget>[
          const Text(
            "Vikumbusho vya Baadaye",
            style: ThemeConstants.headingStyle,
          ),
          const SizedBox(height: 12),
          ...upcomingReminders.map(_buildReminderCard),
        ],
      ],
    );
  }

  Widget _buildReminderCard(Reminder reminder, {bool isOverdue = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ThemeConstants.buildGlassCardStatic(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(
                    isOverdue ? Icons.warning : Icons.notification_important,
                    color: isOverdue
                        ? ThemeConstants.errorRed
                        : ThemeConstants.primaryBlue,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      reminder.title,
                      style: ThemeConstants.headingStyle.copyWith(
                        color: isOverdue
                            ? ThemeConstants.errorRed
                            : ThemeConstants.textPrimary,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(
                      Icons.more_vert,
                      color: ThemeConstants.textSecondary,
                    ),
                    onSelected: (String value) {
                      switch (value) {
                        case 'complete':
                          _markAsCompleted(reminder.id);
                        case 'delete':
                          _showDeleteConfirmation(reminder.id);
                      }
                    },
                    itemBuilder: (BuildContext context) =>
                        <PopupMenuEntry<String>>[
                      if (reminder.isActive)
                        const PopupMenuItem<String>(
                          value: 'complete',
                          child: Row(
                            children: <Widget>[
                              Icon(Icons.check, color: Colors.green),
                              SizedBox(width: 8),
                              Text('Kamilisha'),
                            ],
                          ),
                        ),
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: <Widget>[
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Futa'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                reminder.message,
                style: ThemeConstants.bodyStyle.copyWith(
                  color: ThemeConstants.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  const Icon(
                    Icons.access_time,
                    size: 16,
                    color: ThemeConstants.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "${reminder.reminderTime.day}/${reminder.reminderTime.month}/${reminder.reminderTime.year}",
                    style: ThemeConstants.captionStyle,
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(reminder.status).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      reminder.status.name.toUpperCase(),
                      style: ThemeConstants.captionStyle.copyWith(
                        color: _getStatusColor(reminder.status),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(ReminderStatus status) {
    switch (status) {
      case ReminderStatus.active:
        return ThemeConstants.primaryBlue;
      case ReminderStatus.completed:
        return Colors.green;
      case ReminderStatus.cancelled:
        return ThemeConstants.errorRed;
    }
  }

  void _showDeleteConfirmation(String reminderId) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: ThemeConstants.cardColor,
        title: const Text(
          "Futa Kikumbusho",
          style: ThemeConstants.headingStyle,
        ),
        content: Text(
          "Je, una uhakika unataka kufuta kikumbusho hiki?",
          style: ThemeConstants.bodyStyle.copyWith(
            color: ThemeConstants.textSecondary,
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              "Ghairi",
              style: ThemeConstants.bodyStyle.copyWith(
                color: ThemeConstants.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteReminder(reminderId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ThemeConstants.errorRed,
              foregroundColor: Colors.white,
            ),
            child: const Text("Futa"),
          ),
        ],
      ),
    );
  }
}

class _AddReminderDialog extends StatefulWidget {
  const _AddReminderDialog({required this.apiService});

  final ApiService apiService;

  @override
  State<_AddReminderDialog> createState() => _AddReminderDialogState();
}

class _AddReminderDialogState extends State<_AddReminderDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = TimeOfDay.now();
  String _selectedPriority = 'medium';
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: ThemeConstants.primaryBlue,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: ThemeConstants.primaryBlue,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _saveReminder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Combine date and time
      final reminderDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final reminderData = {
        'title': _titleController.text.trim(),
        'message': _messageController.text.trim(),
        'reminder_date': reminderDateTime.toIso8601String(),
        'priority': _selectedPriority,
      };

      await widget.apiService.addReminder(reminderData);

      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate success
        ThemeConstants.showSuccessSnackBar(context, "Kikumbusho kimeongezwa");
      }
    } on Exception catch (e) {
      if (mounted) {
        ThemeConstants.showErrorSnackBar(context, "Hitilafu katika kuongeza kikumbusho: $e");
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
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: ThemeConstants.primaryBlue,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Header
            Row(
              children: <Widget>[
                const Text(
                  "Kikumbusho Kipya",
                  style: ThemeConstants.headingStyle,
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.close,
                    color: ThemeConstants.textPrimary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Form in scrollable area
            Flexible(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const SizedBox(height: 24),

                      // Title Field
                      TextFormField(
                        controller: _titleController,
                        style: ThemeConstants.bodyStyle,
                        decoration: InputDecoration(
                          labelText: "Kichwa cha Kikumbusho",
                          labelStyle: ThemeConstants.bodyStyle.copyWith(
                            color: Colors.white.withOpacity(0.8),
                          ),
                          hintText: "Mfano: Kukusanya Mapato",
                          hintStyle: ThemeConstants.bodyStyle.copyWith(
                            color: Colors.white.withOpacity(0.6),
                          ),
                          filled: true,
                          fillColor:
                              ThemeConstants.primaryBlue.withOpacity(0.3),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: Colors.white.withOpacity(0.5),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: Colors.white.withOpacity(0.5),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                        ),
                        validator: (String? value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Kichwa ni lazima";
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Message Field
                      TextFormField(
                        controller: _messageController,
                        style: ThemeConstants.bodyStyle,
                        decoration: InputDecoration(
                          labelText: "Ujumbe wa Kikumbusho",
                          labelStyle: ThemeConstants.bodyStyle.copyWith(
                            color: Colors.white.withOpacity(0.8),
                          ),
                          hintText: "Maelezo ya kikumbusho",
                          hintStyle: ThemeConstants.bodyStyle.copyWith(
                            color: Colors.white.withOpacity(0.6),
                          ),
                          filled: true,
                          fillColor:
                              ThemeConstants.primaryBlue.withOpacity(0.3),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: Colors.white.withOpacity(0.5),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: Colors.white.withOpacity(0.5),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                        ),
                        maxLines: 3,
                        validator: (String? value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Ujumbe ni lazima";
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Date and Time Selectors
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: InkWell(
                              onTap: _selectDate,
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: ThemeConstants.primaryBlue
                                      .withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.5),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      "Tarehe",
                                      style:
                                          ThemeConstants.captionStyle.copyWith(
                                        color: ThemeConstants.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: <Widget>[
                                        const Icon(
                                          Icons.calendar_today,
                                          size: 16,
                                          color: ThemeConstants.textPrimary,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}",
                                          style: ThemeConstants.bodyStyle,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: _selectTime,
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: ThemeConstants.primaryBlue
                                      .withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.5),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      "Muda",
                                      style:
                                          ThemeConstants.captionStyle.copyWith(
                                        color: ThemeConstants.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: <Widget>[
                                        const Icon(
                                          Icons.access_time,
                                          size: 16,
                                          color: ThemeConstants.textPrimary,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          "${_selectedTime.hour}:${_selectedTime.minute.toString().padLeft(2, '0')}",
                                          style: ThemeConstants.bodyStyle,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Priority Selector
                      Text(
                        "Kipaumbele",
                        style: ThemeConstants.bodyStyle.copyWith(
                          color: ThemeConstants.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: ThemeConstants.primaryBlue.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.5),
                          ),
                        ),
                        child: DropdownButtonFormField<String>(
                          value: _selectedPriority,
                          style: ThemeConstants.bodyStyle,
                          dropdownColor: ThemeConstants.primaryBlue,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                          ),
                          items: const [
                            DropdownMenuItem(
                                value: 'low', child: Text('Chini')),
                            DropdownMenuItem(
                                value: 'medium', child: Text('Wastani')),
                            DropdownMenuItem(value: 'high', child: Text('Juu')),
                            DropdownMenuItem(
                                value: 'urgent', child: Text('Dharura')),
                          ],
                          onChanged: (String? value) {
                            if (value != null) {
                              setState(() {
                                _selectedPriority = value;
                              });
                            }
                          },
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveReminder,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.2),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: const BorderSide(
                                color: Colors.white,
                              ),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text(
                                  "Hifadhi Kikumbusho",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
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
  Widget build(final BuildContext context) =>
      ThemeConstants.buildGlassCardStatic(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(icon, color: color, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: ThemeConstants.captionStyle.copyWith(
                        color: ThemeConstants.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                count.toString(),
                style: ThemeConstants.headingStyle.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
}
