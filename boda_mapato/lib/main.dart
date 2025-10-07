import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nested/nested.dart';
import 'package:provider/provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/admin/drivers_management_screen.dart';
import 'screens/admin/vehicles_management_screen.dart';
import 'screens/admin/payments_management_screen.dart';
import 'screens/admin/record_payment_screen.dart';
import 'screens/driver/driver_dashboard_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/transaction_provider.dart';
import 'providers/device_provider.dart';
import 'services/api_service.dart';
import 'constants/colors.dart';
import 'constants/styles.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  
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
      builder: (final BuildContext context, final Widget? child) => MultiProvider(
        providers: <SingleChildWidget>[
          ChangeNotifierProvider(create: (final _) => AuthProvider()),
          ChangeNotifierProvider(create: (final _) => TransactionProvider()),
          ChangeNotifierProvider(create: (final _) => DeviceProvider()),
        ],
        child: MaterialApp(
          title: "Boda Mapato",
          theme: _buildTheme(context),
          home: const AuthWrapper(),
          debugShowCheckedModeBanner: false,
          routes: <String, WidgetBuilder>{
            "/admin/dashboard": (final BuildContext context) => const AdminDashboardScreen(),
            "/admin/drivers": (final BuildContext context) => const DriversManagementScreen(),
            "/admin/vehicles": (final BuildContext context) => const VehiclesManagementScreen(),
            "/admin/payments": (final BuildContext context) => const PaymentsManagementScreen(),
            "/admin/record-payment": (final BuildContext context) => const RecordPaymentScreen(),
          },
        ),
      ),
    );
  
  ThemeData _buildTheme(BuildContext context) {
    return ThemeData(
      primarySwatch: Colors.blue,
      primaryColor: AppColors.primary,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      fontFamily: "Inter",
      
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
      
      // Text theme with responsive sizes
      textTheme: TextTheme(
        displayLarge: AppStyles.heading1(context),
        displayMedium: AppStyles.heading2(context),
        displaySmall: AppStyles.heading3(context),
        headlineMedium: AppStyles.heading4(context),
        bodyLarge: AppStyles.bodyLarge(context),
        bodyMedium: AppStyles.bodyMedium(context),
        bodySmall: AppStyles.bodySmall(context),
        labelSmall: AppStyles.caption(context),
      ),
      
      // Responsive spacing and sizing
      materialTapTargetSize: MaterialTapTargetSize.padded,
      useMaterial3: true,
    );
  }
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
    WidgetsBinding.instance.addPostFrameCallback((final _) {
      Provider.of<AuthProvider>(context, listen: false).initialize();
    });
  }

  @override
  Widget build(final BuildContext context) => Consumer<AuthProvider>(builder: (final BuildContext context, final AuthProvider authProvider, final Widget? child) {
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
        if (authProvider.user!.role == "admin" || authProvider.user!.role == "super_admin") {
          return const AdminDashboardScreen();
        } else {
          return const DriverDashboardScreen();
        }
      } else {
        // User is not authenticated, show login screen
        return const LoginScreen();
      }
    },);
}