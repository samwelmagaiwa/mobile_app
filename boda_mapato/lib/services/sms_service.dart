import 'package:flutter/foundation.dart';
import 'api_service.dart';

class SmsService {
  static final SmsService instance = SmsService._internal();
  SmsService._internal();

  final ApiService _api = ApiService();

  /// Send a bill reminder to a tenant
  Future<bool> sendBillReminder(String billId) async {
    try {
      final response = await _api.sendSmsReminder(billId);
      return response['status'] == 'success';
    } catch (e) {
      debugPrint('SmsService: Error sending bill reminder: $e');
      return false;
    }
  }

  /// Send a maintenance notification to a vendor
  Future<bool> notifyVendor(String vendorId, String requestId) async {
    try {
      // Assuming a backend endpoint exists or will be added
      final response = await _api.post('/rental/maintenance/vendors/$vendorId/notify', {
        'request_id': requestId,
      });
      return response['status'] == 'success';
    } catch (e) {
      debugPrint('SmsService: Error notifying vendor: $e');
      return false;
    }
  }

  /// Generic method to send custom SMS via backend
  Future<bool> sendCustomSms(String phone, String message) async {
    try {
      final response = await _api.post('/admin/communications/send-sms', {
        'phone': phone,
        'message': message,
      });
      return response['status'] == 'success';
    } catch (e) {
      debugPrint('SmsService: Error sending custom SMS: $e');
      return false;
    }
  }
}
