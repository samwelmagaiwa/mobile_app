import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../constants/colors.dart';
import '../../constants/strings.dart';
import '../../constants/styles.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/responsive_wrapper.dart';
import '../../providers/auth_provider.dart';
import '../../utils/responsive_utils.dart';

class DriverDashboardScreen extends StatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _dashboardData = <String, dynamic>{};

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Load dashboard data from API
      await Future.delayed(const Duration(seconds: 1)); // Simulate API call
      
      // Mock data
      _dashboardData = <String, dynamic>{
        'assigned_vehicle': <String, String>{
          'name': 'Bajaji ya Kwanza',
          'type': 'bajaji',
          'plate_number': 'T123ABC',
        },
        'payments_today': 15000.0,
        'payments_this_week': 85000.0,
        'payments_this_month': 320000.0,
        'total_trips': 156,
        'total_earnings': 1250000.0,
        'rating': 4.5,
      };
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hitilafu: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(final BuildContext context) => ResponsiveScaffold(
      backgroundColor: AppColors.background,
      body: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            "Dashboard ya Dereva",
            style: AppStyles.heading2(context).copyWith(color: Colors.white),
          ),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          toolbarHeight: ResponsiveUtils.getResponsiveAppBarHeight(context),
          actions: <Widget>[
            IconButton(
              onPressed: _loadDashboardData,
              icon: Icon(
                Icons.refresh,
                size: ResponsiveUtils.getResponsiveIconSize(context, 24),
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (final String value) {
                if (value == "logout") {
                  _handleLogout();
                }
              },
              itemBuilder: (final BuildContext context) => <PopupMenuEntry<String>>[
                PopupMenuItem(
                  value: "logout",
                  child: ResponsiveRow(
                    spacing: ResponsiveUtils.getResponsiveSpacing(context, 8),
                    children: <Widget>[
                      Icon(
                        Icons.logout,
                        color: AppColors.error,
                        size: ResponsiveUtils.getResponsiveIconSize(context, 20),
                      ),
                      Text(
                        "Toka",
                        style: AppStyles.bodyMedium(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: _isLoading
            ? Center(
                child: SizedBox(
                  width: ResponsiveUtils.getResponsiveIconSize(context, 40),
                  height: ResponsiveUtils.getResponsiveIconSize(context, 40),
                  child: CircularProgressIndicator(
                    strokeWidth: 3.w,
                  ),
                ),
              )
            : RefreshIndicator(
                onRefresh: _loadDashboardData,
                child: SingleChildScrollView(
                  padding: ResponsiveUtils.getResponsivePadding(context),
                  child: ResponsiveColumn(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: ResponsiveUtils.getResponsiveSpacing(context, 24),
                    children: <Widget>[
                      // Welcome message
                      CustomCard(
                        child: ResponsiveContainer(
                          child: ResponsiveRow(
                            spacing: ResponsiveUtils.getResponsiveSpacing(context, 16),
                            children: <Widget>[
                              Icon(
                                Icons.person,
                                size: ResponsiveUtils.getResponsiveIconSize(context, 48),
                                color: AppColors.primary,
                              ),
                              Expanded(
                                child: ResponsiveColumn(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  spacing: ResponsiveUtils.getResponsiveSpacing(context, 8),
                                  children: <Widget>[
                                    Text(
                                      "Karibu, Dereva!",
                                      style: AppStyles.heading3(context),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                    Text(
                                      "Angalia takwimu zako za malipo",
                                      style: AppStyles.bodyMedium(context).copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Assigned Vehicle
                      if (_dashboardData["assigned_vehicle"] != null) ...<Widget>[
                        Text(
                          "Gari Lako",
                          style: AppStyles.heading3(context),
                        ),
                        CustomCard(
                          child: ResponsiveContainer(
                            child: ResponsiveRow(
                              spacing: ResponsiveUtils.getResponsiveSpacing(context, 16),
                              children: <Widget>[
                                Container(
                                  width: ResponsiveUtils.getResponsiveIconSize(context, 60),
                                  height: ResponsiveUtils.getResponsiveIconSize(context, 60),
                                  decoration: BoxDecoration(
                                    color: AppColors.secondary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(
                                      ResponsiveUtils.getResponsiveBorderRadius(context, 12),
                                    ),
                                  ),
                                  child: Icon(
                                    _getVehicleIcon(_dashboardData["assigned_vehicle"]["type"]),
                                    color: AppColors.secondary,
                                    size: ResponsiveUtils.getResponsiveIconSize(context, 32),
                                  ),
                                ),
                                Expanded(
                                  child: ResponsiveColumn(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    spacing: ResponsiveUtils.getResponsiveSpacing(context, 4),
                                    children: <Widget>[
                                      Text(
                                        _dashboardData["assigned_vehicle"]["name"],
                                        style: AppStyles.bodyLarge(context).copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                      Text(
                                        'Nambari: ${_dashboardData['assigned_vehicle']['plate_number']}',
                                        style: AppStyles.bodyMedium(context).copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: ResponsiveUtils.getResponsiveSpacing(context, 8),
                                          vertical: ResponsiveUtils.getResponsiveSpacing(context, 4),
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.success.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            ResponsiveUtils.getResponsiveBorderRadius(context, 4),
                                          ),
                                        ),
                                        child: Text(
                                          "Inatumika",
                                          style: AppStyles.bodySmall(context).copyWith(
                                            color: AppColors.success,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],

                      // Payment Statistics
                      Text(
                        "Takwimu za Malipo",
                        style: AppStyles.heading3(context),
                      ),
                      CustomStatCard(
                        title: "Malipo ya Leo",
                        value: 'TSh ${(_dashboardData['payments_today'] ?? 0).toStringAsFixed(0)}',
                        icon: Icons.today,
                        color: AppColors.success,
                      ),
                      ResponsiveRow(
                        spacing: ResponsiveUtils.getResponsiveSpacing(context, 16),
                        children: <Widget>[
                          Expanded(
                            child: CustomStatCard(
                              title: "Wiki Hii",
                              value: 'TSh ${(_dashboardData['payments_this_week'] ?? 0).toStringAsFixed(0)}',
                              icon: Icons.date_range,
                              color: AppColors.info,
                            ),
                          ),
                          Expanded(
                            child: CustomStatCard(
                              title: "Mwezi Huu",
                              value: 'TSh ${(_dashboardData['payments_this_month'] ?? 0).toStringAsFixed(0)}',
                              icon: Icons.calendar_month,
                              color: AppColors.warning,
                            ),
                          ),
                        ],
                      ),

                      // Performance Stats
                      Text(
                        "Utendaji Wako",
                        style: AppStyles.heading3(context),
                      ),
                      ResponsiveRow(
                        spacing: ResponsiveUtils.getResponsiveSpacing(context, 16),
                        children: <Widget>[
                          Expanded(
                            child: CustomStatCard(
                              title: "Jumla ya Safari",
                              value: '${_dashboardData['total_trips'] ?? 0}',
                              icon: Icons.route,
                              color: AppColors.primary,
                            ),
                          ),
                          Expanded(
                            child: CustomStatCard(
                              title: "Ukadiriaji",
                              value: '${_dashboardData['rating'] ?? 0.0}/5.0',
                              icon: Icons.star,
                              color: AppColors.warning,
                            ),
                          ),
                        ],
                      ),

                      // Quick Actions
                      Text(
                        "Vitendo vya Haraka",
                        style: AppStyles.heading3(context),
                      ),
                      ResponsiveGridView(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: ResponsiveUtils.getResponsiveValue(
                          context,
                          mobile: 2,
                          tablet: 3,
                          desktop: 4,
                        ),
                        childAspectRatio: ResponsiveUtils.getResponsiveValue(
                          context,
                          mobile: 1.2,
                          tablet: 1.1,
                          desktop: 1.0,
                        ),
                        spacing: ResponsiveUtils.getResponsiveSpacing(context, 16),
                        children: <Widget>[
                          _QuickActionCard(
                            title: "Omba Malipo",
                            icon: Icons.request_quote,
                            color: AppColors.success,
                            onTap: _showPaymentRequestDialog,
                          ),
                          _QuickActionCard(
                            title: "Historia ya Malipo",
                            icon: Icons.history,
                            color: AppColors.primary,
                            onTap: _navigateToPaymentHistory,
                          ),
                          _QuickActionCard(
                            title: "Risiti",
                            icon: Icons.receipt,
                            color: AppColors.info,
                            onTap: _navigateToReceipts,
                          ),
                          _QuickActionCard(
                            title: "Vikumbusho",
                            icon: Icons.notifications,
                            color: AppColors.warning,
                            onTap: _navigateToReminders,
                          ),
                        ],
                      ),

                      // Total Earnings Card
                      CustomCard(
                        child: ResponsiveContainer(
                          child: ResponsiveColumn(
                            spacing: ResponsiveUtils.getResponsiveSpacing(context, 16),
                            children: <Widget>[
                              Icon(
                                Icons.account_balance_wallet,
                                size: ResponsiveUtils.getResponsiveIconSize(context, 48),
                                color: AppColors.success,
                              ),
                              Text(
                                "Jumla ya Mapato",
                                style: AppStyles.bodyLarge(context),
                              ),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'TSh ${(_dashboardData['total_earnings'] ?? 0).toStringAsFixed(0)}',
                                  style: AppStyles.heading1(context).copyWith(
                                    color: AppColors.success,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Text(
                                "Tangu uanze kufanya kazi",
                                style: AppStyles.bodySmall(context).copyWith(
                                  color: AppColors.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );

  IconData _getVehicleIcon(final String type) {
    switch (type) {
      case 'bajaji':
        return Icons.directions_car; // three_wheeler not available, using car icon
      case 'pikipiki':
        return Icons.motorcycle;
      case 'gari':
        return Icons.directions_car;
      default:
        return Icons.directions_car;
    }
  }

  void _showPaymentRequestDialog() {
    showDialog(
      context: context,
      builder: (final context) => _PaymentRequestDialog(),
    );
  }

  void _navigateToPaymentHistory() {
    Navigator.pushNamed(context, '/driver/payment-history');
  }

  void _navigateToReceipts() {
    Navigator.pushNamed(context, '/driver/receipts');
  }

  void _navigateToReminders() {
    Navigator.pushNamed(context, '/driver/reminders');
  }

  Future<void> _handleLogout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();
  }
}

class _QuickActionCard extends StatelessWidget {

  const _QuickActionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(final BuildContext context) {
    final iconContainerSize = ResponsiveUtils.getResponsiveIconSize(context, 48);
    
    return CustomCard(
      onTap: onTap,
      child: ResponsiveContainer(
        child: ResponsiveColumn(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: ResponsiveUtils.getResponsiveSpacing(context, 16),
          children: <Widget>[
            Container(
              width: iconContainerSize,
              height: iconContainerSize,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(
                  ResponsiveUtils.getResponsiveBorderRadius(context, 12),
                ),
              ),
              child: Icon(
                icon,
                color: color,
                size: ResponsiveUtils.getResponsiveIconSize(context, 24),
              ),
            ),
            Text(
              title,
              style: AppStyles.bodyMedium(context).copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentRequestDialog extends StatefulWidget {
  @override
  State<_PaymentRequestDialog> createState() => _PaymentRequestDialogState();
}

class _PaymentRequestDialogState extends State<_PaymentRequestDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String _paymentMethod = 'cash';
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitPaymentRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Submit payment request to API
      await Future.delayed(const Duration(seconds: 2)); // Simulate API call

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ombi la malipo limetumwa. Inasubiri idhini ya admin.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hitilafu: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(final BuildContext context) => Dialog(
      child: ConstrainedBox(
        constraints: AppStyles.dialogConstraints(context),
        child: ResponsiveContainer(
          child: Form(
            key: _formKey,
            child: ResponsiveColumn(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: ResponsiveUtils.getResponsiveSpacing(context, 16),
              children: <Widget>[
                Text(
                  "Omba Malipo",
                  style: AppStyles.heading3(context),
                ),
              
                TextFormField(
                  controller: _amountController,
                  style: AppStyles.bodyMedium(context),
                  decoration: AppStyles.inputDecoration(context).copyWith(
                    labelText: "Kiasi (TSh)",
                    prefixText: "TSh ",
                  ),
                  keyboardType: TextInputType.number,
                  validator: (final String? value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Kiasi kinahitajika";
                    }
                    if (double.tryParse(value) == null || double.parse(value) <= 0) {
                      return "Kiasi si sahihi";
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _descriptionController,
                  style: AppStyles.bodyMedium(context),
                  decoration: AppStyles.inputDecoration(context).copyWith(
                    labelText: "Maelezo",
                  ),
                  maxLines: 3,
                  validator: (final String? value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Maelezo yanahitajika";
                    }
                    return null;
                  },
                ),
                DropdownButtonFormField<String>(
                  value: _paymentMethod,
                  style: AppStyles.bodyMedium(context),
                  decoration: AppStyles.inputDecoration(context).copyWith(
                    labelText: "Njia ya Malipo",
                  ),
                  items: <DropdownMenuItem<String>>[
                    DropdownMenuItem(
                      value: "cash",
                      child: Text(
                        "Fedha Taslimu",
                        style: AppStyles.bodyMedium(context),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    DropdownMenuItem(
                      value: "mobile_money",
                      child: Text(
                        "Pesa za Simu",
                        style: AppStyles.bodyMedium(context),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    DropdownMenuItem(
                      value: "bank_transfer",
                      child: Text(
                        "Uhamisho wa Benki",
                        style: AppStyles.bodyMedium(context),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                  onChanged: (final String? value) {
                    setState(() {
                      _paymentMethod = value!;
                    });
                  },
                ),
                ResponsiveRow(
                  spacing: ResponsiveUtils.getResponsiveSpacing(context, 16),
                  children: <Widget>[
                    Expanded(
                      child: CustomButton(
                        text: "Ghairi",
                        onPressed: () => Navigator.pop(context),
                        isOutlined: true,
                      ),
                    ),
                    Expanded(
                      child: CustomButton(
                        text: _isLoading ? "Inatuma..." : "Tuma Ombi",
                        onPressed: _isLoading ? null : _submitPaymentRequest,
                        isLoading: _isLoading,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
}