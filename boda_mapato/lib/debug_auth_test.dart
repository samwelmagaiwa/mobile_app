import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';

class DebugAuthTest extends StatefulWidget {
  const DebugAuthTest({super.key});

  @override
  State<DebugAuthTest> createState() => _DebugAuthTestState();
}

class _DebugAuthTestState extends State<DebugAuthTest> {
  String _debugInfo = 'Loading...';

  @override
  void initState() {
    super.initState();
    _runDebugTests();
  }

  Future<void> _runDebugTests() async {
    final StringBuffer info = StringBuffer();
    
    try {
      // Check SharedPreferences directly
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? authToken = prefs.getString('auth_token');
      final String? userData = prefs.getString('user_data');
      
      info.writeln('=== DEBUG AUTH INFO ===');
      info.writeln('Token exists: ${authToken != null}');
      if (authToken != null) {
        info.writeln('Token: ${authToken.substring(0, 20)}...');
      }
      info.writeln('User data exists: ${userData != null}');
      if (userData != null) {
        info.writeln('User data: ${userData.substring(0, 100)}...');
      }
      
      // Test AuthService methods
      info.writeln('\n=== AUTH SERVICE ===');
      info.writeln('isAuthenticated: ${await AuthService.isAuthenticated()}');
      
      final userData2 = await AuthService.getUserData();
      if (userData2 != null) {
        info.writeln('User role: ${userData2['role']}');
        info.writeln('User name: ${userData2['name']}');
      }
      
      // Test API service
      info.writeln('\n=== API SERVICE ===');
      final ApiService apiService = ApiService();
      
      try {
        final response = await apiService.getDashboardData();
        info.writeln('Dashboard API call: SUCCESS');
        info.writeln('Response keys: ${response.keys.toList()}');
      } catch (e) {
        info.writeln('Dashboard API call: FAILED');
        info.writeln('Error: $e');
      }
      
      try {
        final response = await apiService.getActiveDriversCount();
        info.writeln('Active drivers API: SUCCESS');
        info.writeln('Count: ${response['data']?['count'] ?? 'N/A'}');
      } catch (e) {
        info.writeln('Active drivers API: FAILED');
        info.writeln('Error: $e');
      }
      
    } catch (e) {
      info.writeln('DEBUG ERROR: $e');
    }
    
    if (mounted) {
      setState(() {
        _debugInfo = info.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DEBUG AUTH')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton(
              onPressed: _runDebugTests,
              child: const Text('Refresh Debug Info'),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                _debugInfo,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}