/// Currency constants and utilities for the Boda Mapato app
class CurrencyConstants {
  /// The currency code used throughout the app
  static const String currencyCode = 'TSH';
  
  /// The currency symbol
  static const String currencySymbol = 'TSH';
  
  /// Full currency name
  static const String currencyName = 'Tanzanian Shilling';
  
  /// Country code for phone numbers
  static const String countryCode = '+255';
  
  /// Currency formatting utility
  static String formatCurrency(final double amount) {
    if (amount >= 1000000) {
      return '$currencySymbol ${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '$currencySymbol ${(amount / 1000).toStringAsFixed(0)}K';
    } else {
      return '$currencySymbol ${amount.toStringAsFixed(0)}';
    }
  }
  
  /// Format currency with full amount (no abbreviation)
  static String formatCurrencyFull(final double amount) => "$currencySymbol ${amount.toStringAsFixed(0)}";
  
  /// Format currency for display in forms
  static String formatCurrencyInput(final double amount) => amount.toStringAsFixed(0);
  
  /// Parse currency string to double
  static double parseCurrency(final String currencyString) {
    // Remove currency symbol and any formatting
    String cleanString = currencyString
        .replaceAll(currencySymbol, '')
        .replaceAll(',', '')
        .replaceAll(' ', '')
        .trim();
    
    // Handle K and M suffixes
    if (cleanString.endsWith('K')) {
      double value = double.tryParse(cleanString.replaceAll('K', '')) ?? 0;
      return value * 1000;
    } else if (cleanString.endsWith('M')) {
      double value = double.tryParse(cleanString.replaceAll('M', '')) ?? 0;
      return value * 1000000;
    }
    
    return double.tryParse(cleanString) ?? 0;
  }
  
  /// Validate currency amount
  static bool isValidAmount(final double amount) {
    return amount >= 0 && amount <= 999999999; // Max 999M TSH
  }
  
  /// Get currency display text for UI
  static String getCurrencyDisplayText() => "$currencyName ($currencySymbol)";
}

/// Extension methods for double to add currency formatting
extension CurrencyExtension on double {
  /// Format this double as currency
  String toCurrency() => CurrencyConstants.formatCurrency(this);
  
  /// Format this double as full currency (no abbreviation)
  String toCurrencyFull() => CurrencyConstants.formatCurrencyFull(this);
  
  /// Check if this amount is valid
  bool isValidCurrency() => CurrencyConstants.isValidAmount(this);
}

/// Extension methods for String to parse currency
extension CurrencyStringExtension on String {
  /// Parse this string as currency amount
  double parseCurrency() => CurrencyConstants.parseCurrency(this);
}