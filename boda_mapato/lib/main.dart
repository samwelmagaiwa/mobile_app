import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_screenutil/flutter_screenutil.dart";
import "package:provider/provider.dart";
import "package:provider/single_child_widget.dart";

import "constants/colors.dart";
import "constants/styles.dart";
import "providers/auth_provider.dart";
import "providers/device_provider.dart";
import "providers/debts_provider.dart";
import "providers/transaction_provider.dart";
import "screens/admin/admin_dashboard_screen.dart";
import "screens/admin/drivers_management_screen.dart";
import "screens/admin/vehicles_management_screen.dart";
import "screens/admin/payments_management_screen.dart";
import "screens/payments/payments_screen.dart";
import 'screens/analytics/analytics_screen.dart';
import 'screens/auth/login_screen.dart';
import "screens/dashboard/modern_dashboard_screen.dart";
import "screens/driver/driver_dashboard_screen.dart";
import "screens/reports/report_screen.dart";
import "screens/reminders/reminders_screen.dart";
import "screens/settings/settings_screen.dart";
import "screens/admin/debts_management_screen.dart";

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Test API connectivity in debug mode (disabled to reduce console noise)
  // if (kDebugMode) {
  //   await ConnectivityTest.printConnectivityReport();
  // }

  runApp(const BodaMapatoApp());
}

class BodaMapatoApp extends StatelessWidget {
  const BodaMapatoApp({super.key});

  @override
  Widget build(final BuildContext context) => ScreenUtilInit(
        designSize: const Size(375, 812), // iPhone X design size as base
        minTextAdapt: true,
        splitScreenMode: true,
        useInheritedMediaQuery: true,
        builder: (final BuildContext context, final Widget? child) =>
            MultiProvider(
          providers: <SingleChildWidget>[
            ChangeNotifierProvider<AuthProvider>(
              create: (final BuildContext _) => AuthProvider(),
            ),
            ChangeNotifierProvider<TransactionProvider>(
              create: (final BuildContext _) => TransactionProvider(),
            ),
            ChangeNotifierProvider<DeviceProvider>(
              create: (final BuildContext _) => DeviceProvider(),
            ),
            ChangeNotifierProvider<DebtsProvider>(
              create: (final BuildContext _) => DebtsProvider(),
            ),
          ],
          child: MaterialApp(
            title: "Boda Mapato",
            theme: _buildTheme(context),
            home: const AuthWrapper(),
            debugShowCheckedModeBanner: false,
            routes: <String, WidgetBuilder>{
              "/admin/dashboard": (final BuildContext context) =>
                  const AdminDashboardScreen(),
              "/modern-dashboard": (final BuildContext context) =>
                  const ModernDashboardScreen(),
              "/admin/drivers": (final BuildContext context) =>
                  const DriversManagementScreen(),
              "/admin/vehicles": (final BuildContext context) =>
                  const VehiclesManagementScreen(),
              "/admin/payments": (final BuildContext context) =>
                  const PaymentsManagementScreen(),
              "/payments": (final BuildContext context) =>
                  const PaymentsScreen(),
              "/admin/analytics": (final BuildContext context) =>
                  const AnalyticsScreen(),
              "/admin/reports": (final BuildContext context) =>
                  const ReportScreen(),
              "/admin/reminders": (final BuildContext context) =>
                  const RemindersScreen(),
              "/admin/debts": (final BuildContext context) =>
                  const DebtsManagementScreen(),
              "/settings": (final BuildContext context) =>
                  const SettingsScreen(),
            },
          ),
        ),
      );

  ThemeData _buildTheme(BuildContext context) => ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: AppColors.primary,
        visualDensity: VisualDensity.adaptivePlatformDensity,

        // Responsive theme components
        appBarTheme: AppStyles.appBarTheme(context),
        cardTheme: AppStyles.cardTheme(context),
        floatingActionButtonTheme: AppStyles.fabTheme(context),
        bottomNavigationBarTheme: AppStyles.bottomNavTheme(context),

        // Input decoration theme
        inputDecorationTheme: AppStyles.inputDecorationTheme(context),

        // Button themes
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: AppStyles.primaryButton(context),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: AppStyles.secondaryButton(context),
        ),

        // Text theme (keep Flutter defaults and app styles)
        textTheme: Theme.of(context).textTheme,

        // Responsive spacing and sizing
        materialTapTargetSize: MaterialTapTargetSize.padded,
        useMaterial3: true,
      );
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    // Initialize auth state when app starts
    WidgetsBinding.instance.addPostFrameCallback((final Duration _) async {
      await Provider.of<AuthProvider>(context, listen: false).initialize();
    });
  }

  @override
  Widget build(final BuildContext context) => Consumer<AuthProvider>(
        builder: (
          final BuildContext context,
          final AuthProvider authProvider,
          final Widget? child,
        ) {
          // Show loading screen while initializing
          if (authProvider.isLoading) {
            return Scaffold(
              backgroundColor: AppColors.background,
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const CircularProgressIndicator(),
                    SizedBox(height: 16.h),
                    Text(
                      "Inapakia...",
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // Show appropriate screen based on auth state
          if (authProvider.isAuthenticated && authProvider.user != null) {
            // User is authenticated, show dashboard based on role
            if (authProvider.user!.role == "admin" ||
                authProvider.user!.role == "super_admin") {
              return const ModernDashboardScreen();
            } else {
              return const DriverDashboardScreen();
            }
          } else {
            // User is not authenticated, show login screen
            return const LoginScreen();
          }
        },
      );
}
