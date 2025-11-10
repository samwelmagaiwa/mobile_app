import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'constants/colors.dart';
import 'constants/styles.dart';
import 'constants/theme_constants.dart';
import 'modules/inventory/providers/inventory_provider.dart';
import 'modules/inventory/screens/inventory_home.dart';
import 'providers/auth_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/debts_provider.dart';
import 'providers/device_provider.dart';
import 'providers/transaction_provider.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/admin/communications_screen.dart';
import 'screens/admin/debts_management_screen.dart';
import 'screens/admin/drivers_management_screen.dart';
import 'screens/admin/vehicles_management_screen.dart';
import 'screens/analytics/analytics_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/coming_soon_screen.dart';
import 'screens/dashboard/modern_dashboard_screen.dart';
import 'screens/demo_language_screen.dart';
import 'screens/driver/driver_dashboard_screen.dart';
import 'screens/driver/driver_payment_history_screen.dart';
import 'screens/driver/driver_receipts_screen.dart';
import 'screens/driver/driver_reminders_screen.dart';
import 'screens/payments/payments_screen.dart';
import 'screens/receipts/receipts_screen.dart';
import 'screens/reminders/reminders_screen.dart';
import 'screens/reports/report_screen.dart';
import 'screens/service_selection_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'services/app_messenger.dart';
import 'services/localization_service.dart';
import 'utils/web_keyboard_fix_stub.dart'
    if (dart.library.html) 'utils/web_keyboard_fix_web.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize web keyboard fix for Flutter web
  WebKeyboardFix.initialize();

  // Initialize localization service
  await LocalizationService.instance.initialize();

  // Debug: tag overflow issues with current page name in console
  FlutterError.onError = (FlutterErrorDetails details) {
    // Keep default behavior
    FlutterError.presentError(details);
    if (kDebugMode) {
      final String msg = details.exceptionAsString();
      if (msg.contains('RenderFlex overflowed') ||
          msg.contains('A RenderFlex overflowed')) {
        debugPrint(
            '[OVERFLOW] page=${RouteTracker.currentRouteName} -> ${details.exceptionAsString()}');
      }
    }
  };

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

// Global route tracker to know which page is active (for debug logs)
class RouteTracker extends NavigatorObserver {
  static final RouteTracker observer = RouteTracker();
  static String _current = '(unknown)';
  static String get currentRouteName => _current;

  void _setCurrent(Route<dynamic>? route) {
    final Route<dynamic>? r = route;
    final String name =
        r?.settings.name ?? r?.runtimeType.toString() ?? '(unknown)';
    // Some MaterialPageRoutes might not have names; also try widget type if available
    _current = name;
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _setCurrent(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _setCurrent(previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _setCurrent(newRoute);
  }
}

class BodaMapatoApp extends StatelessWidget {
  const BodaMapatoApp({super.key});

  @override
  Widget build(final BuildContext context) => ScreenUtilInit(
        minTextAdapt: true,
        splitScreenMode: true,
        useInheritedMediaQuery: true,
        builder: (final BuildContext context, final Widget? child) =>
            MultiProvider(
          providers: <SingleChildWidget>[
            ChangeNotifierProvider<LocalizationService>.value(
              value: LocalizationService.instance,
            ),
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
            ChangeNotifierProvider<DashboardProvider>(
              create: (final BuildContext _) => DashboardProvider()..loadAll(),
            ),
            ChangeNotifierProvider<InventoryProvider>(
              create: (final BuildContext _) => InventoryProvider()..bootstrap(),
            ),
          ],
          child: Consumer<LocalizationService>(
            builder: (context, localizationService, child) => MaterialApp(
              title: localizationService.translate('app_name'),
              theme: _buildTheme(context),
              scaffoldMessengerKey: AppMessenger.key,
              locale: localizationService.currentLocale,
              navigatorObservers: <NavigatorObserver>[RouteTracker.observer],
              supportedLocales: const [
                Locale('en', 'US'),
                Locale('sw', 'TZ'),
              ],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              home: const AuthWrapper(),
              debugShowCheckedModeBanner: false,
              routes: <String, WidgetBuilder>{
                "/receipts": (final BuildContext context) =>
                    const ReceiptsScreen(),
                "/driver/receipts": (final BuildContext context) =>
                    const DriverReceiptsScreen(),
                "/driver/payment-history": (final BuildContext context) =>
                    const DriverPaymentHistoryScreen(),
                "/admin/dashboard": (final BuildContext context) =>
                    const AdminDashboardScreen(),
                "/modern-dashboard": (final BuildContext context) =>
                    const ModernDashboardScreen(),
                "/admin/drivers": (final BuildContext context) =>
                    const DriversManagementScreen(),
                "/admin/vehicles": (final BuildContext context) =>
                    const VehiclesManagementScreen(),
                "/payments": (final BuildContext context) =>
                    const PaymentsScreen(),
                "/admin/analytics": (final BuildContext context) =>
                    const AnalyticsScreen(),
                "/admin/reports": (final BuildContext context) =>
                    const ReportScreen(),
                "/admin/reminders": (final BuildContext context) =>
                    const RemindersScreen(),
                "/driver/reminders": (final BuildContext context) =>
                    const DriverRemindersScreen(),
                "/admin/debts": (final BuildContext context) =>
                    const DebtsManagementScreen(),
                "/admin/communications": (final BuildContext context) =>
                    const CommunicationsScreen(),
                "/settings": (final BuildContext context) =>
                    const SettingsScreen(),
                "/demo": (final BuildContext context) =>
                    const DemoLanguageScreen(),
                "/select-service": (final BuildContext context) =>
                    const ServiceSelectionScreen(),
                "/inventory": (final BuildContext context) =>
                    const InventoryHome(),
                "/coming-soon": (final BuildContext context) =>
                    const ComingSoonScreen(),
              },
            ),
          ),
        ),
      );

  ThemeData _buildTheme(BuildContext context) => ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: AppColors.primary,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'NotoSans',

        // Responsive theme components
        appBarTheme: AppStyles.appBarTheme(context),
        cardTheme: AppStyles.cardTheme(context),
        floatingActionButtonTheme: AppStyles.fabTheme(context),
        bottomNavigationBarTheme: AppStyles.bottomNavTheme(context),

        // Date picker styling to align with brand blue background
        datePickerTheme: DatePickerThemeData(
          backgroundColor: ThemeConstants.primaryBlue,
          headerBackgroundColor: ThemeConstants.primaryBlue,
          headerForegroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          dayForegroundColor: const WidgetStatePropertyAll<Color>(Colors.white),
          yearForegroundColor:
              const WidgetStatePropertyAll<Color>(Colors.white),
          weekdayStyle: const TextStyle(color: Colors.white70),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        dialogTheme: const DialogTheme(
          backgroundColor: ThemeConstants.primaryBlue,
          surfaceTintColor: Colors.transparent,
        ),

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

class _LanguageGateLoading extends StatelessWidget {
  const _LanguageGateLoading();
  @override
  Widget build(BuildContext context) => const Scaffold(
        backgroundColor: ThemeConstants.primaryBlue,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
}

class _LanguageSelectionPage extends StatelessWidget {
  const _LanguageSelectionPage({required this.onSelected});
  final Future<void> Function(String code) onSelected;

  @override
  Widget build(BuildContext context) {
    final loc = LocalizationService.instance;
    return Scaffold(
      backgroundColor: ThemeConstants.primaryBlue,
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ThemeConstants.primaryBlue,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white24),
          ),
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                loc.translate('select_language'),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => onSelected('sw'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(loc.translate('swahili')),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => onSelected('en'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade700,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(loc.translate('english')),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _languageChosenThisSession = false;

  @override
  void initState() {
    super.initState();
    // Initialize auth state when app starts
    WidgetsBinding.instance.addPostFrameCallback((final Duration _) async {
      await Provider.of<AuthProvider>(context, listen: false).initialize();
    });
  }

  Future<void> _onLanguageChosen(String code) async {
    final loc = LocalizationService.instance;
    await loc.changeLanguage(code);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_language', code);
    if (mounted) {
      setState(() {
        _languageChosenThisSession = true;
      });
    }
  }

  @override
  Widget build(final BuildContext context) =>
      Consumer2<AuthProvider, LocalizationService>(
        builder: (
          final BuildContext context,
          final AuthProvider authProvider,
          final LocalizationService localizationService,
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
                      localizationService.translate('loading'),
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
            // Always show the language selection immediately after login for this session
            if (!_languageChosenThisSession) {
              return _LanguageSelectionPage(onSelected: _onLanguageChosen);
            }
            // After choosing language, route by last selected service (persisted)
            return FutureBuilder<SharedPreferences>(
              future: SharedPreferences.getInstance(),
              builder: (context, snap) {
                if (!snap.hasData) return const _LanguageGateLoading();
                final prefs = snap.data!;
                final service = prefs.getString('selected_service');
                // No service yet: ask user to choose
                if (service == null) {
                  return const ServiceSelectionScreen();
                }
                if (service == 'inventory') {
                  return const InventoryHome();
                }
                if (service == 'transport') {
                  return const ModernDashboardScreen();
                }
                if (service == 'rental') {
                  return ComingSoonScreen(service: service);
                }
                // Fallback to existing role-based dashboards
                if (authProvider.user!.role == "admin" ||
                    authProvider.user!.role == "super_admin") {
                  return const ModernDashboardScreen();
                }
                return const DriverDashboardScreen();
              },
            );
          } else {
            // User is not authenticated, show login screen
            return const LoginScreen();
          }
        },
      );
}
