import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalizationService extends ChangeNotifier {
  static const String _languageKey = 'selected_language';
  
  Locale _currentLocale = const Locale('sw', 'TZ'); // Default to Swahili
  
  Locale get currentLocale => _currentLocale;
  String get currentLanguage => _currentLocale.languageCode;
  bool get isSwahili => _currentLocale.languageCode == 'sw';
  bool get isEnglish => _currentLocale.languageCode == 'en';
  
  static LocalizationService? _instance;
  
  static LocalizationService get instance {
    _instance ??= LocalizationService._internal();
    return _instance!;
  }
  
  LocalizationService._internal();
  
  Future<void> initialize() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? savedLanguage = prefs.getString(_languageKey);
    
    if (savedLanguage != null) {
      _currentLocale = _getLocaleFromLanguageCode(savedLanguage);
    }
    
    notifyListeners();
  }
  
  Future<void> changeLanguage(String languageCode) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, languageCode);
    
    _currentLocale = _getLocaleFromLanguageCode(languageCode);
    notifyListeners();
  }
  
  Locale _getLocaleFromLanguageCode(String languageCode) {
    switch (languageCode) {
      case 'en':
        return const Locale('en', 'US');
      case 'sw':
      default:
        return const Locale('sw', 'TZ');
    }
  }
  
  String translate(String key) {
    return AppLocalizations.instance.translate(key);
  }
}

class AppLocalizations {
  static AppLocalizations? _instance;
  static AppLocalizations get instance {
    _instance ??= AppLocalizations._internal();
    return _instance!;
  }
  
  AppLocalizations._internal();
  
  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      // General
      'app_name': 'Boda Income',
      'dashboard': 'Dashboard',
      'settings': 'Settings',
      'profile': 'Profile',
      'logout': 'Logout',
      'login': 'Login',
      'yes': 'Yes',
      'no': 'No',
      'ok': 'OK',
      'cancel': 'Cancel',
      'save': 'Save',
      'edit': 'Edit',
      'delete': 'Delete',
      'confirm': 'Confirm',
      'loading': 'Loading...',
      'error': 'Error',
      'success': 'Success',
      'refresh': 'Refresh',
      
      // Settings Screen
      'user_profile': 'User Profile',
      'notifications': 'Notifications',
      'notifications_subtitle': 'Manage app notifications',
      'language': 'Language',
      'language_subtitle': 'Choose app language',
      'security': 'Security',
      'security_subtitle': 'Security settings',
      'backup': 'Backup',
      'backup_subtitle': 'Backup and restore data',
      'about_app': 'About App',
      'about_app_subtitle': 'App information',
      'help': 'Help',
      'help_subtitle': 'Get help using the app',
      'logout_confirm': 'Are you sure you want to logout?',
      'version': 'Version',
      'app_description': 'Motorcycle business management app',
      'copyright': '© 2024 Boda Income',
      
      // Language Selection
      'select_language': 'Select Language',
      'english': 'English',
      'swahili': 'Kiswahili',
      'language_changed': 'Language changed successfully',
      
      // Notifications Settings
      'push_notifications': 'Push Notifications',
      'email_notifications': 'Email Notifications',
      'payment_alerts': 'Payment Alerts',
      'debt_reminders': 'Debt Reminders',
      'system_updates': 'System Updates',
      
      // Security Settings
      'change_password': 'Change Password',
      'two_factor_auth': 'Two Factor Authentication',
      'login_history': 'Login History',
      'current_password': 'Current Password',
      'new_password': 'New Password',
      'confirm_password': 'Confirm Password',
'password_changed': 'Password changed successfully',
      'two_factor_enabled_msg': 'Two-factor enabled',
      'two_factor_disabled_msg': 'Two-factor disabled',
      'no_login_history': 'No login history found.',
      'failed_to_update': 'Failed to update',
      
      // Backup Settings
      'auto_backup': 'Auto Backup',
      'backup_now': 'Backup Now',
      'restore_data': 'Restore Data',
      'last_backup': 'Last Backup',
      'backup_successful': 'Backup completed successfully',
      'restore_successful': 'Data restored successfully',
      
      // Dashboard
      'daily_revenue': 'Daily Revenue',
      'weekly_revenue': 'Weekly Revenue',
      'monthly_revenue': 'Monthly Revenue',
      'drivers': 'Drivers',
      'vehicles': 'Vehicles',
      'receipts_generated': 'Receipts Generated',
      'pending_receipts': 'Pending Receipts',
      'unpaid_debts': 'Unpaid Debts',
      
      // Receipts
      'receipts': 'Receipts',
      'generate_receipt': 'Generate Receipt',
      'pending': 'Pending',
      'all': 'All',
      'receipt_management': 'Receipt Management',
      'generate_and_send_receipts': 'Generate and send receipts to drivers',
      'no_pending_receipts': 'No pending receipts',
      'no_receipts_generated': 'No receipts generated',
      'receipts_list_empty': 'You will see all receipts here',
      'all_payments_have_receipts': 'All payments already have receipts generated',
      
      // Common Buttons/Actions
      'view_details': 'View Details',
      'view_all': 'View All',
      'add_new': 'Add New',
      'search': 'Search',
      'filter': 'Filter',
      'export': 'Export',
      'import': 'Import',
      'print': 'Print',
      'share': 'Share',
      'send': 'Send',
      
      // Navigation Drawer (additional entries)
      'payments': 'Payments',
      'debt_records': 'Debt Records',
      'analytics': 'Analytics',
      'reports': 'Reports',
      'reminders': 'Reminders',
      'communications': 'Communications',
      'loading_dashboard': 'Loading Dashboard...',
      
      // Drivers Management Screen
      'drivers_management': 'Drivers Management',
      'add_driver': 'Add Driver',
      'driver_name': 'Driver Name',
      'driver_phone': 'Phone Number',
      'driver_email': 'Email Address',
      'driver_license': 'License Number',
      'driver_status': 'Status',
      'active_driver': 'Active',
      'inactive_driver': 'Inactive',
      'edit_driver': 'Edit Driver',
      'delete_driver': 'Delete Driver',
      'driver_details': 'Driver Details',
      'total_drivers': 'Total Drivers',
      'active_drivers': 'Active Drivers',
      'driver_added_successfully': 'Driver added successfully',
      'driver_updated_successfully': 'Driver updated successfully',
      'driver_deleted_successfully': 'Driver deleted successfully',
      'confirm_delete_driver': 'Are you sure you want to delete this driver?',
      'no_drivers_found': 'No drivers found',
      'search_drivers': 'Search drivers...',
      
      // Vehicles Management Screen
      'vehicles_management': 'Vehicles Management',
      'add_vehicle': 'Add Vehicle',
      'vehicle_plate': 'Plate Number',
      'vehicle_model': 'Vehicle Model',
      'vehicle_year': 'Year',
      'vehicle_type': 'Vehicle Type',
      'vehicle_status': 'Status',
      'active_vehicle': 'Active',
      'inactive_vehicle': 'Inactive',
      'edit_vehicle': 'Edit Vehicle',
      'delete_vehicle': 'Delete Vehicle',
      'vehicle_details': 'Vehicle Details',
      'total_vehicles': 'Total Vehicles',
      'active_vehicles': 'Active Vehicles',
      'vehicle_added_successfully': 'Vehicle added successfully',
      'vehicle_updated_successfully': 'Vehicle updated successfully',
      'vehicle_deleted_successfully': 'Vehicle deleted successfully',
      'confirm_delete_vehicle': 'Are you sure you want to delete this vehicle?',
      'no_vehicles_found': 'No vehicles found',
      'search_vehicles': 'Search vehicles...',
      
      // Payments Screen
      'payments_management': 'Payments Management',
      'payment_amount': 'Amount',
      'payment_date': 'Payment Date',
      'payment_method': 'Payment Method',
      'payment_status': 'Status',
      'payment_reference': 'Reference',
      'payment_driver': 'Driver',
      'payment_vehicle': 'Vehicle',
      'add_payment': 'Add Payment',
      'edit_payment': 'Edit Payment',
      'delete_payment': 'Delete Payment',
      'payment_details': 'Payment Details',
      'total_payments': 'Total Payments',
      'paid_payments': 'Paid',
      'pending_payments': 'Pending',
      'payment_added_successfully': 'Payment added successfully',
      'payment_updated_successfully': 'Payment updated successfully',
      'payment_deleted_successfully': 'Payment deleted successfully',
      'confirm_delete_payment': 'Are you sure you want to delete this payment?',
      'no_payments_found': 'No payments found',
      'search_payments': 'Search payments...',
      'cash': 'Cash',
      'mobile_money': 'Mobile Money',
      'bank_transfer': 'Bank Transfer',
      'paid': 'Paid',
'overdue': 'Overdue',
      
      // Debts Management Screen
      'debts_management': 'Debts Management',
      'debt_amount': 'Debt Amount',
      'debt_date': 'Debt Date',
      'debt_due_date': 'Due Date',
      'debt_status': 'Status',
      'debt_driver': 'Driver',
      'debt_description': 'Description',
      'add_debt': 'Add Debt',
      'edit_debt': 'Edit Debt',
      'delete_debt': 'Delete Debt',
      'debt_details': 'Debt Details',
'total_debts': 'Total Debts',
      'paid_debts': 'Paid Debts',
      'debt_added_successfully': 'Debt added successfully',
      'debt_updated_successfully': 'Debt updated successfully',
      'debt_deleted_successfully': 'Debt deleted successfully',
      'confirm_delete_debt': 'Are you sure you want to delete this debt?',
      'no_debts_found': 'No debts found',
      'search_debts': 'Search debts...',
      'mark_as_paid': 'Mark as Paid',
      'mark_as_unpaid': 'Mark as Unpaid',
      
      // Analytics Screen
      'analytics_dashboard': 'Analytics Dashboard',
      'revenue_analytics': 'Revenue Analytics',
      'driver_analytics': 'Driver Analytics',
      'vehicle_analytics': 'Vehicle Analytics',
      'payment_analytics': 'Payment Analytics',
      'performance_metrics': 'Performance Metrics',
      'revenue_trends': 'Revenue Trends',
      'top_drivers': 'Top Drivers',
      'active_vehicles_chart': 'Active Vehicles',
      'monthly_comparison': 'Monthly Comparison',
      'yearly_comparison': 'Yearly Comparison',
      'export_analytics': 'Export Analytics',
      'date_range': 'Date Range',
      'from_date': 'From Date',
      'to_date': 'To Date',
      'apply_filter': 'Apply Filter',
      'clear_filter': 'Clear Filter',
      
      // Reports Screen
      'reports_dashboard': 'Reports Dashboard',
      'generate_report': 'Generate Report',
      'driver_report': 'Driver Report',
      'vehicle_report': 'Vehicle Report',
      'payment_report': 'Payment Report',
      'debt_report': 'Debt Report',
      'revenue_report': 'Revenue Report',
      'monthly_report': 'Monthly Report',
      'yearly_report': 'Yearly Report',
      'custom_report': 'Custom Report',
      'report_type': 'Report Type',
      'report_period': 'Report Period',
      'report_format': 'Report Format',
      'pdf_format': 'PDF',
      'excel_format': 'Excel',
      'csv_format': 'CSV',
      'download_report': 'Download Report',
      'email_report': 'Email Report',
      'report_generated_successfully': 'Report generated successfully',
      'report_generation_failed': 'Report generation failed',
      
      // Reminders Screen
      'reminders_management': 'Reminders Management',
      'add_reminder': 'Add Reminder',
      'reminder_title': 'Reminder Title',
      'reminder_message': 'Message',
      'reminder_date': 'Reminder Date',
      'reminder_time': 'Reminder Time',
      'reminder_type': 'Type',
      'payment_reminder': 'Payment Reminder',
      'maintenance_reminder': 'Maintenance Reminder',
      'general_reminder': 'General Reminder',
      'reminder_status': 'Status',
      'active_reminder': 'Active',
      'completed_reminder': 'Completed',
      'edit_reminder': 'Edit Reminder',
      'delete_reminder': 'Delete Reminder',
      'reminder_details': 'Reminder Details',
      'total_reminders': 'Total Reminders',
      'active_reminders': 'Active Reminders',
      'completed_reminders': 'Completed',
      'reminder_added_successfully': 'Reminder added successfully',
      'reminder_updated_successfully': 'Reminder updated successfully',
      'reminder_deleted_successfully': 'Reminder deleted successfully',
      'confirm_delete_reminder': 'Are you sure you want to delete this reminder?',
      'no_reminders_found': 'No reminders found',
      'search_reminders': 'Search reminders...',
      'mark_as_completed': 'Mark as Completed',
      'send_reminder': 'Send Reminder',
      
      // Communications Screen
      'communications_management': 'Communications',
      'send_message': 'Send Message',
      'message_title': 'Message Title',
      'message_content': 'Message Content',
      'message_recipients': 'Recipients',
      'all_drivers': 'All Drivers',
      'selected_drivers': 'Selected Drivers',
      'message_type': 'Message Type',
      'sms_message': 'SMS',
      'email_message': 'Email',
      'push_notification': 'Push Notification',
      'send_immediately': 'Send Immediately',
      'schedule_message': 'Schedule Message',
      'scheduled_date': 'Scheduled Date',
      'scheduled_time': 'Scheduled Time',
      'message_history': 'Message History',
      'sent_messages': 'Sent Messages',
      'scheduled_messages': 'Scheduled Messages',
      'message_status': 'Status',
      'message_sent': 'Sent',
      'message_scheduled': 'Scheduled',
      'message_failed': 'Failed',
      'message_delivered': 'Delivered',
      'message_sent_successfully': 'Message sent successfully',
      'message_scheduled_successfully': 'Message scheduled successfully',
      'message_failed_to_send': 'Failed to send message',
      'no_messages_found': 'No messages found',
      'search_messages': 'Search messages...',
      'select_recipients': 'Select Recipients',
      
      // Login Screen
      'login_successful': 'Login successful!',
      'login_failed': 'Login failed',
      'login_error': 'Error during login: ',
      'demo_credentials_filled': 'Demo credentials filled',
      'database_credentials_filled': 'Database credentials filled',
      'forgot_password': 'Forgot Password?',
      'forgot_password_message': 'Password reset feature is under development. For now, use demo credentials or contact the administrator.',
      'use_database': 'Use Database',
      'email': 'Email',
      'password': 'Password',
      'phone_number': 'Phone Number',
      'signin': 'Sign In',
      'welcome_back': 'Welcome Back',
      'signin_subtitle': 'Sign in to continue to your account',
    },
    'sw': {
      // General
      'app_name': 'Boda Mapato',
      'dashboard': 'Dashibodi',
      'settings': 'Mipangilio',
      'profile': 'Wasifu',
      'logout': 'Toka',
      'login': 'Ingia',
      'yes': 'Ndio',
      'no': 'Hapana',
      'ok': 'Sawa',
      'cancel': 'Sitisha',
      'save': 'Hifadhi',
      'edit': 'Hariri',
      'delete': 'Futa',
      'confirm': 'Thibitisha',
      'loading': 'Inapakia...',
      'error': 'Hitilafu',
      'success': 'Imefanikiwa',
      'refresh': 'Onyesha upya',
      
      // Settings Screen
      'user_profile': 'Wasifu wa Mtumiaji',
      'notifications': 'Arifa',
      'notifications_subtitle': 'Dhibiti arifa za programu',
      'language': 'Lugha',
      'language_subtitle': 'Chagua lugha ya programu',
      'security': 'Usalama',
      'security_subtitle': 'Mipangilio ya usalama',
      'backup': 'Hifadhi',
      'backup_subtitle': 'Hifadhi na rejesha data',
      'about_app': 'Kuhusu Programu',
      'about_app_subtitle': 'Maelezo ya programu',
      'help': 'Msaada',
      'help_subtitle': 'Pata msaada wa kutumia programu',
      'logout_confirm': 'Je, una uhakika unataka kutoka?',
      'version': 'Toleo',
      'app_description': 'Programu ya kusimamia biashara za pikipiki',
      'copyright': '© 2024 Boda Mapato',
      
      // Language Selection
      'select_language': 'Chagua Lugha',
      'english': 'Kiingereza',
      'swahili': 'Kiswahili',
      'language_changed': 'Lugha imebadilishwa kikamilifu',
      
      // Notifications Settings
      'push_notifications': 'Arifa za Kusukuma',
      'email_notifications': 'Arifa za Barua pepe',
      'payment_alerts': 'Arifa za Malipo',
      'debt_reminders': 'Mikumbuzo ya Madeni',
      'system_updates': 'Masasisho ya Mfumo',
      
      // Security Settings
      'change_password': 'Badilisha Neno la Siri',
      'two_factor_auth': 'Uthibitisho wa Hatua Mbili',
      'login_history': 'Historia ya Kuingia',
      'current_password': 'Neno la Siri la Sasa',
      'new_password': 'Neno la Siri Jipya',
      'confirm_password': 'Thibitisha Neno la Siri',
'password_changed': 'Neno la siri limebadilishwa kikamilifu',
      'two_factor_enabled_msg': 'Uthibitisho wa hatua mbili umewezeshwa',
      'two_factor_disabled_msg': 'Uthibitisho wa hatua mbili umelemazwa',
      'no_login_history': 'Hakuna historia ya kuingia kupatikana.',
      'failed_to_update': 'Imeshindikana kusasisha',
      
      // Backup Settings
      'auto_backup': 'Hifadhi Otomatiki',
      'backup_now': 'Hifadhi Sasa',
      'restore_data': 'Rejesha Data',
      'last_backup': 'Hifadhi ya Mwisho',
      'backup_successful': 'Hifadhi imekamilika kikamilifu',
      'restore_successful': 'Data imerejeshwa kikamilifu',
      
      // Dashboard
      'daily_revenue': 'Mapato ya Siku',
      'weekly_revenue': 'Mapato ya Wiki',
      'monthly_revenue': 'Mapato ya Mwezi',
      'drivers': 'Madereva',
      'vehicles': 'Vyombo vya Usafiri',
      'receipts_generated': 'Malipo Yenye Risiti',
      'pending_receipts': 'Yamelipwa Bado Risiti',
      'unpaid_debts': 'Malipo Yasiyolipwa',
      
      // Receipts
      'receipts': 'Risiti',
      'generate_receipt': 'Tengeneza Risiti',
      'pending': 'Zinazosubiri',
      'all': 'Zote',
      'receipt_management': 'Uongozi wa Risiti',
      'generate_and_send_receipts': 'Tengeneza na tuma risiti kwa madereva',
      'no_pending_receipts': 'Hakuna malipo yanayosubiri risiti',
      'no_receipts_generated': 'Hakuna risiti zilizozalishwa',
      'receipts_list_empty': 'Utaona orodha ya risiti zote hapa',
      'all_payments_have_receipts': 'Malipo yote yamesha tengenezwa risiti',
      
      // Common Buttons/Actions
      'view_details': 'Ona Maelezo',
      'view_all': 'Ona Zote',
      'add_new': 'Ongeza Mpya',
      'search': 'Tafuta',
      'filter': 'Chuja',
      'export': 'Hamisha',
      'import': 'Ingiza',
      'print': 'Chapisha',
      'share': 'Shiriki',
      'send': 'Tuma',
      
      // Navigation Drawer (additional entries)
      'payments': 'Malipo',
      'debt_records': 'Rekodi Madeni',
      'analytics': 'Takwimu',
      'reports': 'Ripoti',
      'reminders': 'Mikumbuzo',
      'communications': 'Mawasiliano',
      'loading_dashboard': 'Inapakia Dashboard...',
      
      // Drivers Management Screen
      'drivers_management': 'Usimamizi wa Madereva',
      'add_driver': 'Ongeza Dereva',
      'driver_name': 'Jina la Dereva',
      'driver_phone': 'Nambari ya Simu',
      'driver_email': 'Anwani ya Barua Pepe',
      'driver_license': 'Nambari ya Leseni',
      'driver_status': 'Hali',
      'active_driver': 'Hai',
      'inactive_driver': 'Hahai',
      'edit_driver': 'Hariri Dereva',
      'delete_driver': 'Futa Dereva',
      'driver_details': 'Maelezo ya Dereva',
      'total_drivers': 'Madereva Wote',
      'active_drivers': 'Madereva Hai',
      'driver_added_successfully': 'Dereva ameongezwa kikamilifu',
      'driver_updated_successfully': 'Dereva amebadilishwa kikamilifu',
      'driver_deleted_successfully': 'Dereva amefutwa kikamilifu',
      'confirm_delete_driver': 'Je, una uhakika unataka kumfuta dereva huyu?',
      'no_drivers_found': 'Hakuna madereva waliopatikana',
      'search_drivers': 'Tafuta madereva...',
      
      // Vehicles Management Screen
      'vehicles_management': 'Usimamizi wa Vyombo vya Usafiri',
      'add_vehicle': 'Ongeza Gari',
      'vehicle_plate': 'Nambari ya Gari',
      'vehicle_model': 'Aina ya Gari',
      'vehicle_year': 'Mwaka',
      'vehicle_type': 'Aina ya Chombo',
      'vehicle_status': 'Hali',
      'active_vehicle': 'Hai',
      'inactive_vehicle': 'Hahai',
      'edit_vehicle': 'Hariri Gari',
      'delete_vehicle': 'Futa Gari',
      'vehicle_details': 'Maelezo ya Gari',
      'total_vehicles': 'Magari Yote',
      'active_vehicles': 'Magari Yanayotumika',
      'vehicle_added_successfully': 'Gari limeongezwa kikamilifu',
      'vehicle_updated_successfully': 'Gari limebadilishwa kikamilifu',
      'vehicle_deleted_successfully': 'Gari limefutwa kikamilifu',
      'confirm_delete_vehicle': 'Je, una uhakika unataka kufuta gari hili?',
      'no_vehicles_found': 'Hakuna magari yaliyopatikana',
      'search_vehicles': 'Tafuta magari...',
      
      // Payments Screen
      'payments_management': 'Usimamizi wa Malipo',
      'payment_amount': 'Kiasi',
      'payment_date': 'Tarehe ya Malipo',
      'payment_method': 'Njia ya Malipo',
      'payment_status': 'Hali',
      'payment_reference': 'Nambari ya Kumbukumbu',
      'payment_driver': 'Dereva',
      'payment_vehicle': 'Gari',
      'add_payment': 'Ongeza Malipo',
      'edit_payment': 'Hariri Malipo',
      'delete_payment': 'Futa Malipo',
      'payment_details': 'Maelezo ya Malipo',
      'total_payments': 'Malipo Yote',
      'paid_payments': 'Yamelipwa',
      'pending_payments': 'Yanasubiri',
      'payment_added_successfully': 'Malipo yameongezwa kikamilifu',
      'payment_updated_successfully': 'Malipo yamebadilishwa kikamilifu',
      'payment_deleted_successfully': 'Malipo yamefutwa kikamilifu',
      'confirm_delete_payment': 'Je, una uhakika unataka kufuta malipo haya?',
      'no_payments_found': 'Hakuna malipo yaliyopatikana',
      'search_payments': 'Tafuta malipo...',
      'cash': 'Fedha Taslimu',
      'mobile_money': 'Pesa za Simu',
      'bank_transfer': 'Uhamisho wa Benki',
      'paid': 'Yamelipwa',
'overdue': 'Yamechelewa',
      
      // Debts Management Screen
      'debts_management': 'Usimamizi wa Madeni',
      'debt_amount': 'Kiasi cha Deni',
      'debt_date': 'Tarehe ya Deni',
      'debt_due_date': 'Tarehe ya Mwisho',
      'debt_status': 'Hali',
      'debt_driver': 'Dereva',
      'debt_description': 'Maelezo',
      'add_debt': 'Ongeza Deni',
      'edit_debt': 'Hariri Deni',
      'delete_debt': 'Futa Deni',
      'debt_details': 'Maelezo ya Deni',
'total_debts': 'Madeni Yote',
      'paid_debts': 'Madeni Yaliyolipwa',
      'debt_added_successfully': 'Deni limeongezwa kikamilifu',
      'debt_updated_successfully': 'Deni limebadilishwa kikamilifu',
      'debt_deleted_successfully': 'Deni limefutwa kikamilifu',
      'confirm_delete_debt': 'Je, una uhakika unataka kufuta deni hili?',
      'no_debts_found': 'Hakuna madeni yaliyopatikana',
      'search_debts': 'Tafuta madeni...',
      'mark_as_paid': 'Weka kama Yamelipwa',
      'mark_as_unpaid': 'Weka kama Hayajalipwa',
      
      // Analytics Screen
      'analytics_dashboard': 'Dashibodi ya Takwimu',
      'revenue_analytics': 'Takwimu za Mapato',
      'driver_analytics': 'Takwimu za Madereva',
      'vehicle_analytics': 'Takwimu za Magari',
      'payment_analytics': 'Takwimu za Malipo',
      'performance_metrics': 'Vipimo vya Utendaji',
      'revenue_trends': 'Mwelekeo wa Mapato',
      'top_drivers': 'Madereva Bora',
      'active_vehicles_chart': 'Magari Yanayotumika',
      'monthly_comparison': 'Ulinganishi wa Mwezi',
      'yearly_comparison': 'Ulinganishi wa Mwaka',
      'export_analytics': 'Hamisha Takwimu',
      'date_range': 'Kipindi cha Tarehe',
      'from_date': 'Kutoka Tarehe',
      'to_date': 'Hadi Tarehe',
      'apply_filter': 'Tumia Kichuja',
      'clear_filter': 'Futa Kichuja',
      
      // Reports Screen
      'reports_dashboard': 'Dashibodi ya Ripoti',
      'generate_report': 'Tengeneza Ripoti',
      'driver_report': 'Ripoti ya Madereva',
      'vehicle_report': 'Ripoti ya Magari',
      'payment_report': 'Ripoti ya Malipo',
      'debt_report': 'Ripoti ya Madeni',
      'revenue_report': 'Ripoti ya Mapato',
      'monthly_report': 'Ripoti ya Mwezi',
      'yearly_report': 'Ripoti ya Mwaka',
      'custom_report': 'Ripoti Maalum',
      'report_type': 'Aina ya Ripoti',
      'report_period': 'Kipindi cha Ripoti',
      'report_format': 'Muundo wa Ripoti',
      'pdf_format': 'PDF',
      'excel_format': 'Excel',
      'csv_format': 'CSV',
      'download_report': 'Pakua Ripoti',
      'email_report': 'Tuma Ripoti kwa Barua Pepe',
      'report_generated_successfully': 'Ripoti imetengenezwa kikamilifu',
      'report_generation_failed': 'Kutengeneza ripoti kumeshindikana',
      
      // Reminders Screen
      'reminders_management': 'Usimamizi wa Mikumbuzo',
      'add_reminder': 'Ongeza Ukumbusho',
      'reminder_title': 'Kichwa cha Ukumbusho',
      'reminder_message': 'Ujumbe',
      'reminder_date': 'Tarehe ya Ukumbusho',
      'reminder_time': 'Muda wa Ukumbusho',
      'reminder_type': 'Aina',
      'payment_reminder': 'Ukumbusho wa Malipo',
      'maintenance_reminder': 'Ukumbusho wa Matengenezo',
      'general_reminder': 'Ukumbusho wa Jumla',
      'reminder_status': 'Hali',
      'active_reminder': 'Hai',
      'completed_reminder': 'Umekamilika',
      'edit_reminder': 'Hariri Ukumbusho',
      'delete_reminder': 'Futa Ukumbusho',
      'reminder_details': 'Maelezo ya Ukumbusho',
      'total_reminders': 'Mikumbuzo Yote',
      'active_reminders': 'Mikumbuzo Hai',
      'completed_reminders': 'Zilizokamilika',
      'reminder_added_successfully': 'Ukumbusho umeongezwa kikamilifu',
      'reminder_updated_successfully': 'Ukumbusho umebadilishwa kikamilifu',
      'reminder_deleted_successfully': 'Ukumbusho umefutwa kikamilifu',
      'confirm_delete_reminder': 'Je, una uhakika unataka kufuta ukumbusho huu?',
      'no_reminders_found': 'Hakuna mikumbuzo iliyopatikana',
      'search_reminders': 'Tafuta mikumbuzo...',
      'mark_as_completed': 'Weka kama Umekamilika',
      'send_reminder': 'Tuma Ukumbusho',
      
      // Communications Screen
      'communications_management': 'Mawasiliano',
      'send_message': 'Tuma Ujumbe',
      'message_title': 'Kichwa cha Ujumbe',
      'message_content': 'Maudhui ya Ujumbe',
      'message_recipients': 'Wapokeaji',
      'all_drivers': 'Madereva Wote',
      'selected_drivers': 'Madereva Waliochaguliwa',
      'message_type': 'Aina ya Ujumbe',
      'sms_message': 'SMS',
      'email_message': 'Barua Pepe',
      'push_notification': 'Arifa ya Kusukuma',
      'send_immediately': 'Tuma Mara Moja',
      'schedule_message': 'Ratibisha Ujumbe',
      'scheduled_date': 'Tarehe Iliyoratibishwa',
      'scheduled_time': 'Muda Ulioratibishwa',
      'message_history': 'Historia ya Ujumbe',
      'sent_messages': 'Ujumbe Uliotumwa',
      'scheduled_messages': 'Ujumbe Ulioratibishwa',
      'message_status': 'Hali',
      'message_sent': 'Umetumwa',
      'message_scheduled': 'Umeratibishwa',
      'message_failed': 'Umeshindikana',
      'message_delivered': 'Umefika',
      'message_sent_successfully': 'Ujumbe umetumwa kikamilifu',
      'message_scheduled_successfully': 'Ujumbe umeratibishwa kikamilifu',
      'message_failed_to_send': 'Kutuma ujumbe kumeshindikana',
      'no_messages_found': 'Hakuna ujumbe uliopatikana',
      'search_messages': 'Tafuta ujumbe...',
      'select_recipients': 'Chagua Wapokeaji',
      
      // Login Screen
      'login_successful': 'Umeingia kikamilifu!',
      'login_failed': 'Kuingia kumeshindikana',
      'login_error': 'Hitilafu katika kuingia: ',
      'demo_credentials_filled': 'Taarifa za demo zimejazwa',
      'database_credentials_filled': 'Taarifa za database zimejazwa',
      'forgot_password': 'Umesahau Nywila?',
      'forgot_password_message': 'Kipengele cha kurudisha nywila kinatengenezwa. Kwa sasa, tumia taarifa za demo au wasiliana na msimamizi.',
      'use_database': 'Tumia Database',
      'email': 'Barua pepe',
      'password': 'Neno la siri',
      'phone_number': 'Nambari ya simu',
      'signin': 'Ingia',
      'welcome_back': 'Karibu Tena',
      'signin_subtitle': 'Ingia ili kuendelea kwenye akaunti yako',
    },
  };
  
  String translate(String key) {
    final String languageCode = LocalizationService.instance.currentLanguage;
    return _localizedValues[languageCode]?[key] ?? key;
  }
}