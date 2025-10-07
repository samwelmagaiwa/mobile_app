class ValidationUtils {
  // Email validation
  static bool isValidEmail(final String email) {
    if (email.isEmpty) return false;
    
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  // Phone number validation (Tanzanian format)
  static bool isValidPhoneNumber(final String phone) {
    if (phone.isEmpty) return false;
    
    // Remove spaces and special characters
    final cleanPhone = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    
    // Tanzanian phone number patterns
    final phoneRegex = RegExp(
      r'^(\+255|0)(6[0-9]|7[0-9])[0-9]{7}$',
    );
    return phoneRegex.hasMatch(cleanPhone);
  }

  // Password validation
  static bool isValidPassword(final String password) {
    if (password.isEmpty) return false;
    
    // At least 8 characters, contains uppercase, lowercase, and number
    final passwordRegex = RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)[a-zA-Z\d@$!%*?&]{8,}$',
    );
    return passwordRegex.hasMatch(password);
  }

  // Simple password validation (less strict)
  static bool isValidSimplePassword(final String password) => password.length >= 6;

  // Amount validation
  static bool isValidAmount(final String amount) {
    if (amount.isEmpty) return false;
    
    final amountRegex = RegExp(r'^\d+(\.\d{1,2})?$');
    return amountRegex.hasMatch(amount) && double.parse(amount) > 0;
  }

  // Plate number validation (Tanzanian format)
  static bool isValidPlateNumber(final String plateNumber) {
    if (plateNumber.isEmpty) return false;
    
    // Tanzanian plate number format: T123ABC or similar
    final plateRegex = RegExp(
      r'^[A-Z]{1,2}\s?\d{3}\s?[A-Z]{3}$',
      caseSensitive: false,
    );
    return plateRegex.hasMatch(plateNumber.toUpperCase());
  }

  // Name validation
  static bool isValidName(final String name) {
    if (name.isEmpty) return false;
    
    // At least 2 characters, only letters and spaces
    final nameRegex = RegExp(r'^[a-zA-Z\s]{2,}$');
    return nameRegex.hasMatch(name.trim());
  }

  // License number validation
  static bool isValidLicenseNumber(final String licenseNumber) {
    if (licenseNumber.isEmpty) return false;
    
    // Basic format: letters and numbers, at least 5 characters
    final licenseRegex = RegExp(r'^[A-Z0-9]{5,}$', caseSensitive: false);
    return licenseRegex.hasMatch(licenseNumber);
  }

  // Receipt number validation
  static bool isValidReceiptNumber(final String receiptNumber) {
    if (receiptNumber.isEmpty) return false;
    
    // Format: R followed by numbers
    final receiptRegex = RegExp(r'^R\d+$', caseSensitive: false);
    return receiptRegex.hasMatch(receiptNumber);
  }

  // Date validation
  static bool isValidDate(final String date) {
    if (date.isEmpty) return false;
    
    try {
      final parts = date.split('/');
      if (parts.length != 3) return false;
      
      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);
      
      if (day < 1 || day > 31) return false;
      if (month < 1 || month > 12) return false;
      if (year < 1900 || year > DateTime.now().year + 10) return false;
      
      // Try to create a valid date
      DateTime(year, month, day);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Time validation (HH:MM format)
  static bool isValidTime(final String time) {
    if (time.isEmpty) return false;
    
    final timeRegex = RegExp(r'^([01]?[0-9]|2[0-3]):[0-5][0-9]$');
    return timeRegex.hasMatch(time);
  }

  // URL validation
  static bool isValidUrl(final String url) {
    if (url.isEmpty) return false;
    
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  // Numeric validation
  static bool isNumeric(final String value) {
    if (value.isEmpty) return false;
    return double.tryParse(value) != null;
  }

  // Integer validation
  static bool isInteger(final String value) {
    if (value.isEmpty) return false;
    return int.tryParse(value) != null;
  }

  // Positive number validation
  static bool isPositiveNumber(final String value) {
    if (!isNumeric(value)) return false;
    return double.parse(value) > 0;
  }

  // Range validation for numbers
  static bool isInRange(final String value, final double min, final double max) {
    if (!isNumeric(value)) return false;
    final number = double.parse(value);
    return number >= min && number <= max;
  }

  // Length validation
  static bool hasValidLength(final String value, final int minLength, [final int? maxLength]) {
    if (value.length < minLength) return false;
    if (maxLength != null && value.length > maxLength) return false;
    return true;
  }

  // Contains only letters
  static bool isAlphabetic(final String value) {
    if (value.isEmpty) return false;
    final alphabeticRegex = RegExp(r'^[a-zA-Z]+$');
    return alphabeticRegex.hasMatch(value);
  }

  // Contains only letters and spaces
  static bool isAlphabeticWithSpaces(final String value) {
    if (value.isEmpty) return false;
    final alphabeticRegex = RegExp(r'^[a-zA-Z\s]+$');
    return alphabeticRegex.hasMatch(value);
  }

  // Contains only alphanumeric characters
  static bool isAlphanumeric(final String value) {
    if (value.isEmpty) return false;
    final alphanumericRegex = RegExp(r'^[a-zA-Z0-9]+$');
    return alphanumericRegex.hasMatch(value);
  }

  // Custom validation with regex
  static bool matchesPattern(final String value, final String pattern) {
    if (value.isEmpty) return false;
    final regex = RegExp(pattern);
    return regex.hasMatch(value);
  }

  // Validation error messages
  static String? getEmailError(final String email) {
    if (email.isEmpty) return 'Barua pepe inahitajika';
    if (!isValidEmail(email)) return 'Barua pepe si sahihi';
    return null;
  }

  static String? getPhoneError(final String phone) {
    if (phone.isEmpty) return 'Nambari ya simu inahitajika';
    if (!isValidPhoneNumber(phone)) return 'Nambari ya simu si sahihi';
    return null;
  }

  static String? getPasswordError(final String password) {
    if (password.isEmpty) return 'Nenosiri linahitajika';
    if (!isValidSimplePassword(password)) return 'Nenosiri lazima liwe na angalau herufi 6';
    return null;
  }

  static String? getStrongPasswordError(final String password) {
    if (password.isEmpty) return 'Nenosiri linahitajika';
    if (!isValidPassword(password)) {
      return 'Nenosiri lazima liwe na angalau herufi 8, herufi kubwa, ndogo na nambari';
    }
    return null;
  }

  static String? getAmountError(final String amount) {
    if (amount.isEmpty) return 'Kiasi kinahitajika';
    if (!isValidAmount(amount)) return 'Kiasi si sahihi';
    return null;
  }

  static String? getNameError(final String name) {
    if (name.isEmpty) return 'Jina linahitajika';
    if (!isValidName(name)) return 'Jina si sahihi';
    return null;
  }

  static String? getPlateNumberError(final String plateNumber) {
    if (plateNumber.isEmpty) return 'Nambari ya bango inahitajika';
    if (!isValidPlateNumber(plateNumber)) return 'Nambari ya bango si sahihi';
    return null;
  }

  static String? getRequiredFieldError(final String value, final String fieldName) {
    if (value.trim().isEmpty) return '$fieldName inahitajika';
    return null;
  }

  static String? getLengthError(final String value, final String fieldName, final int minLength, [final int? maxLength]) {
    if (value.length < minLength) {
      return '$fieldName lazima iwe na angalau herufi $minLength';
    }
    if (maxLength != null && value.length > maxLength) {
      return '$fieldName haiwezi kuwa na herufi zaidi ya $maxLength';
    }
    return null;
  }

  // Confirm password validation
  static String? getConfirmPasswordError(final String password, final String confirmPassword) {
    if (confirmPassword.isEmpty) return 'Thibitisha nenosiri';
    if (password != confirmPassword) return 'Nenosiri hazifanani';
    return null;
  }

  // Date range validation
  static String? getDateRangeError(final DateTime? startDate, final DateTime? endDate) {
    if (startDate == null) return 'Tarehe ya mwanzo inahitajika';
    if (endDate == null) return 'Tarehe ya mwisho inahitajika';
    if (startDate.isAfter(endDate)) return 'Tarehe ya mwanzo haiwezi kuwa baada ya tarehe ya mwisho';
    return null;
  }

  // Future date validation
  static String? getFutureDateError(final DateTime? date) {
    if (date == null) return 'Tarehe inahitajika';
    if (date.isBefore(DateTime.now())) return 'Tarehe lazima iwe ya baadaye';
    return null;
  }

  // Past date validation
  static String? getPastDateError(final DateTime? date) {
    if (date == null) return 'Tarehe inahitajika';
    if (date.isAfter(DateTime.now())) return 'Tarehe lazima iwe ya zamani';
    return null;
  }
}