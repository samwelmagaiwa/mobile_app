import "package:flutter/material.dart";

import '../../constants/theme_constants.dart';
import '../../utils/responsive_helper.dart';

class SimpleDriversManagementScreen extends StatelessWidget {
  const SimpleDriversManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    ResponsiveHelper.init(context);
    return ThemeConstants.buildResponsiveScaffold(
      context,
      title: "Madereva",
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people,
              size: ResponsiveHelper.iconSizeXL * 2,
              color: Colors.white,
            ),
            ResponsiveHelper.verticalSpace(2.5),
            Text(
              "Usimamizi wa Madereva",
              style: TextStyle(
                color: Colors.white,
                fontSize: ResponsiveHelper.h2,
                fontWeight: FontWeight.bold,
              ),
            ),
            ResponsiveHelper.verticalSpace(1.2),
            Text(
              "Ukurasa huu bado unajengwa",
              style: TextStyle(
                color: Colors.white70,
                fontSize: ResponsiveHelper.bodyL,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SimpleVehiclesManagementScreen extends StatelessWidget {
  const SimpleVehiclesManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Magari"),
        backgroundColor: const Color(0xFF1E40AF),
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFF1E40AF),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.directions_car,
              size: 80,
              color: Colors.white,
            ),
            SizedBox(height: 20),
            Text(
              "Usimamizi wa Magari",
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              "Ukurasa huu bado unajengwa",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SimplePaymentsManagementScreen extends StatelessWidget {
  const SimplePaymentsManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Malipo"),
        backgroundColor: const Color(0xFF1E40AF),
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFF1E40AF),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.payment,
              size: 80,
              color: Colors.white,
            ),
            SizedBox(height: 20),
            Text(
              "Usimamizi wa Malipo",
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              "Ukurasa huu bado unajengwa",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SimpleAnalyticsScreen extends StatelessWidget {
  const SimpleAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Takwimu"),
        backgroundColor: const Color(0xFF1E40AF),
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFF1E40AF),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics,
              size: 80,
              color: Colors.white,
            ),
            SizedBox(height: 20),
            Text(
              "Takwimu",
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              "Ukurasa huu bado unajengwa",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SimpleReportsScreen extends StatelessWidget {
  const SimpleReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ripoti"),
        backgroundColor: const Color(0xFF1E40AF),
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFF1E40AF),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long,
              size: 80,
              color: Colors.white,
            ),
            SizedBox(height: 20),
            Text(
              "Ripoti",
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              "Ukurasa huu bado unajengwa",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SimpleRemindersScreen extends StatelessWidget {
  const SimpleRemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mikumbuzo"),
        backgroundColor: const Color(0xFF1E40AF),
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFF1E40AF),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications,
              size: 80,
              color: Colors.white,
            ),
            SizedBox(height: 20),
            Text(
              "Mikumbuzo",
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              "Ukurasa huu bado unajengwa",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SimpleReportScreen extends StatelessWidget {
  const SimpleReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ripoti"),
        backgroundColor: const Color(0xFF1E40AF),
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFF1E40AF),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long,
              size: 80,
              color: Colors.white,
            ),
            SizedBox(height: 20),
            Text(
              "Ripoti",
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              "Ukurasa huu bado unajengwa",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
