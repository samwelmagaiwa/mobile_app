import 'package:intl/intl.dart';

class AppDateUtils {
  // Date formatters
  static final DateFormat _dateFormatter = DateFormat('dd/MM/yyyy');
  static final DateFormat _timeFormatter = DateFormat('HH:mm');
  static final DateFormat _dateTimeFormatter = DateFormat('dd/MM/yyyy HH:mm');
  static final DateFormat _monthYearFormatter = DateFormat('MMMM yyyy');
  static final DateFormat _dayMonthFormatter = DateFormat('dd MMM');
  static final DateFormat _fullDateFormatter = DateFormat('EEEE, dd MMMM yyyy');

  // Format date only
  static String formatDate(final DateTime date) => _dateFormatter.format(date);

  // Format time only
  static String formatTime(final DateTime date) => _timeFormatter.format(date);

  // Format date and time
  static String formatDateTime(final DateTime date) => _dateTimeFormatter.format(date);

  // Format month and year
  static String formatMonthYear(final DateTime date) => _monthYearFormatter.format(date);

  // Format day and month
  static String formatDayMonth(final DateTime date) => _dayMonthFormatter.format(date);

  // Format full date
  static String formatFullDate(final DateTime date) => _fullDateFormatter.format(date);

  // Get relative time (e.g., "2 hours ago", "Yesterday")
  static String getRelativeTime(final DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return years == 1 ? 'Mwaka mmoja uliopita' : 'Miaka $years iliyopita';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return months == 1 ? 'Mwezi mmoja uliopita' : 'Miezi $months iliyopita';
    } else if (difference.inDays > 7) {
      final weeks = (difference.inDays / 7).floor();
      return weeks == 1 ? 'Wiki moja iliyopita' : 'Wiki $weeks zilizopita';
    } else if (difference.inDays > 0) {
      return difference.inDays == 1 ? 'Jana' : 'Siku ${difference.inDays} zilizopita';
    } else if (difference.inHours > 0) {
      return difference.inHours == 1 ? 'Saa moja iliyopita' : 'Saa ${difference.inHours} zilizopita';
    } else if (difference.inMinutes > 0) {
      return difference.inMinutes == 1 ? 'Dakika moja iliyopita' : 'Dakika ${difference.inMinutes} zilizopita';
    } else {
      return 'Sasa hivi';
    }
  }

  // Check if date is today
  static bool isToday(final DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && 
           date.month == now.month && 
           date.day == now.day;
  }

  // Check if date is yesterday
  static bool isYesterday(final DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year && 
           date.month == yesterday.month && 
           date.day == yesterday.day;
  }

  // Check if date is this week
  static bool isThisWeek(final DateTime date) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    
    return date.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
           date.isBefore(endOfWeek.add(const Duration(days: 1)));
  }

  // Check if date is this month
  static bool isThisMonth(final DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month;
  }

  // Check if date is this year
  static bool isThisYear(final DateTime date) {
    final now = DateTime.now();
    return date.year == now.year;
  }

  // Get start of day
  static DateTime startOfDay(final DateTime date) => DateTime(date.year, date.month, date.day);

  // Get end of day
  static DateTime endOfDay(final DateTime date) => DateTime(date.year, date.month, date.day, 23, 59, 59, 999);

  // Get start of week (Monday)
  static DateTime startOfWeek(final DateTime date) {
    final daysFromMonday = date.weekday - 1;
    return startOfDay(date.subtract(Duration(days: daysFromMonday)));
  }

  // Get end of week (Sunday)
  static DateTime endOfWeek(final DateTime date) {
    final daysToSunday = 7 - date.weekday;
    return endOfDay(date.add(Duration(days: daysToSunday)));
  }

  // Get start of month
  static DateTime startOfMonth(final DateTime date) => DateTime(date.year, date.month);

  // Get end of month
  static DateTime endOfMonth(final DateTime date) {
    final nextMonth = date.month == 12 
        ? DateTime(date.year + 1)
        : DateTime(date.year, date.month + 1);
    return nextMonth.subtract(const Duration(days: 1));
  }

  // Get start of year
  static DateTime startOfYear(final DateTime date) => DateTime(date.year);

  // Get end of year
  static DateTime endOfYear(final DateTime date) => DateTime(date.year, 12, 31, 23, 59, 59, 999);

  // Get days in month
  static int getDaysInMonth(final int year, final int month) => DateTime(year, month + 1, 0).day;

  // Get week number of year
  static int getWeekOfYear(final DateTime date) {
    final startOfYear = DateTime(date.year);
    final days = date.difference(startOfYear).inDays;
    return ((days - date.weekday + 10) / 7).floor();
  }

  // Parse date string
  static DateTime? parseDate(final String dateString) {
    try {
      return _dateFormatter.parse(dateString);
    } catch (e) {
      return null;
    }
  }

  // Parse time string
  static DateTime? parseTime(final String timeString) {
    try {
      final now = DateTime.now();
      final time = _timeFormatter.parse(timeString);
      return DateTime(now.year, now.month, now.day, time.hour, time.minute);
    } catch (e) {
      return null;
    }
  }

  // Parse date time string
  static DateTime? parseDateTime(final String dateTimeString) {
    try {
      return _dateTimeFormatter.parse(dateTimeString);
    } catch (e) {
      return null;
    }
  }

  // Get age from birth date
  static int getAge(final DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    
    if (now.month < birthDate.month || 
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    
    return age;
  }

  // Get time difference in human readable format
  static String getTimeDifference(final DateTime start, final DateTime end) {
    final difference = end.difference(start);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} siku';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} saa';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} dakika';
    } else {
      return '${difference.inSeconds} sekunde';
    }
  }

  // Check if date is in range
  static bool isDateInRange(final DateTime date, final DateTime start, final DateTime end) => date.isAfter(start.subtract(const Duration(days: 1))) &&
           date.isBefore(end.add(const Duration(days: 1)));

  // Get next occurrence of weekday
  static DateTime getNextWeekday(final DateTime date, final int weekday) {
    final daysUntilWeekday = (weekday - date.weekday) % 7;
    return date.add(Duration(days: daysUntilWeekday == 0 ? 7 : daysUntilWeekday));
  }

  // Get previous occurrence of weekday
  static DateTime getPreviousWeekday(final DateTime date, final int weekday) {
    final daysSinceWeekday = (date.weekday - weekday) % 7;
    return date.subtract(Duration(days: daysSinceWeekday == 0 ? 7 : daysSinceWeekday));
  }

  // Format duration
  static String formatDuration(final Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  // Get business days between dates (excluding weekends)
  static int getBusinessDays(final DateTime start, final DateTime end) {
    int businessDays = 0;
    DateTime current = start;
    
    while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
      if (current.weekday < 6) { // Monday = 1, Friday = 5
        businessDays++;
      }
      current = current.add(const Duration(days: 1));
    }
    
    return businessDays;
  }
}