/// Type helper utilities to prevent InvalidType compilation errors
/// 
/// This file contains utility functions and type definitions to ensure
/// proper type inference and prevent compilation issues.
library;

import 'dart:convert';

class TypeHelpers {
  /// Safely cast dynamic to Map<String, dynamic>
  static Map<String, dynamic>? safeCastToMap(final value) {
    if (value is Map<String, dynamic>) {
      return value;
    } else if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return null;
  }

  /// Safely cast dynamic to List<Map<String, dynamic>>
  static List<Map<String, dynamic>>? safeCastToMapList(final value) {
    if (value is List<Map<String, dynamic>>) {
      return value;
    } else if (value is List) {
      try {
        return value.map((final item) => Map<String, dynamic>.from(item as Map)).toList();
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  /// Safely parse JSON string to Map
  static Map<String, dynamic>? safeJsonDecode(final String? jsonString) {
    if (jsonString == null || jsonString.isEmpty) return null;
    
    try {
      final decoded = jsonDecode(jsonString);
      return safeCastToMap(decoded);
    } catch (e) {
      return null;
    }
  }

  /// Safely encode object to JSON string
  static String? safeJsonEncode(final object) {
    try {
      return jsonEncode(object);
    } catch (e) {
      return null;
    }
  }

  /// Type-safe getter for Map values
  static T? safeGet<T>(final Map<String, dynamic>? map, final String key) {
    if (map == null || !map.containsKey(key)) return null;
    
    final value = map[key];
    if (value is T) {
      return value;
    }
    return null;
  }

  /// Type-safe getter with default value
  static T safeGetWithDefault<T>(final Map<String, dynamic>? map, final String key, final T defaultValue) => safeGet<T>(map, key) ?? defaultValue;

  /// Ensure a value is of the expected type
  static T ensureType<T>(final value, final T defaultValue) {
    if (value is T) {
      return value;
    }
    return defaultValue;
  }

  /// Convert dynamic to double safely
  static double toDouble(final value, {final double defaultValue = 0.0}) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? defaultValue;
    }
    return defaultValue;
  }

  /// Convert dynamic to int safely
  static int toInt(final value, {final int defaultValue = 0}) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? defaultValue;
    }
    return defaultValue;
  }

  /// Convert dynamic to string safely
  static String toString(final value, {final String defaultValue = ''}) {
    if (value is String) return value;
    if (value != null) return value.toString();
    return defaultValue;
  }

  /// Convert dynamic to bool safely
  static bool toBool(final value, {final bool defaultValue = false}) {
    if (value is bool) return value;
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    if (value is int) {
      return value != 0;
    }
    return defaultValue;
  }

  /// Convert dynamic to DateTime safely
  static DateTime? toDateTime(final value) {
    if (value is DateTime) return value;
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  /// Create a typed list from dynamic
  static List<T> createTypedList<T>(final value, final T Function() converter) {
    if (value is List) {
      return value.map(converter).toList();
    }
    return <T>[];
  }

  /// Validate that a Map has the expected structure
  static bool validateMapStructure(final Map<String, dynamic>? map, final List<String> requiredKeys) {
    if (map == null) return false;
    
    for (final key in requiredKeys) {
      if (!map.containsKey(key)) return false;
    }
    return true;
  }
}

/// Type-safe filter options for UI components
class FilterOption {

  const FilterOption({
    required this.key,
    required this.label,
    this.description,
  });

  factory FilterOption.fromJson(final Map<String, dynamic> json) => FilterOption(
    key: TypeHelpers.toString(json["key"]),
    label: TypeHelpers.toString(json["label"]),
    description: TypeHelpers.safeGet<String>(json, "description"),
  );
  final String key;
  final String label;
  final String? description;

  Map<String, dynamic> toJson() => <String, >{
    'key': key,
    'label': label,
    if (description != null) 'description': description,
  };

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is FilterOption &&
          runtimeType == other.runtimeType &&
          key == other.key;

  @override
  int get hashCode => key.hashCode;
}

/// Common filter options for the app
class CommonFilters {
  static const List<FilterOption> transactionFilters = <FilterOption>[
    FilterOption(key: 'all', label: 'Yote'),
    FilterOption(key: 'income', label: 'Mapato'),
    FilterOption(key: 'expense', label: 'Matumizi'),
    FilterOption(key: 'today', label: 'Leo'),
    FilterOption(key: 'week', label: 'Wiki hii'),
    FilterOption(key: 'month', label: 'Mwezi huu'),
  ];

  static const List<FilterOption> paymentStatusFilters = <FilterOption>[
    FilterOption(key: 'all', label: 'Yote'),
    FilterOption(key: 'paid', label: 'Yaliyolipwa'),
    FilterOption(key: 'pending', label: 'Yanayosubiri'),
    FilterOption(key: 'overdue', label: 'Yaliyochelewa'),
  ];

  static const List<FilterOption> driverStatusFilters = <FilterOption>[
    FilterOption(key: 'all', label: 'Wote'),
    FilterOption(key: 'active', label: 'Hai'),
    FilterOption(key: 'inactive', label: 'Hahai'),
  ];
}