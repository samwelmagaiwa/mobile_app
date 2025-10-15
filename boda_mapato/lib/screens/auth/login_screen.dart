import "package:flutter/material.dart";
import "package:flutter_screenutil/flutter_screenutil.dart";
import "package:provider/provider.dart";

import "../../constants/styles.dart";
import "../../constants/theme_constants.dart";
import "../../providers/auth_provider.dart";
import "../../services/localization_service.dart";
import "../../utils/responsive_utils.dart";
import "../../widgets/custom_button.dart";

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final AuthProvider authProvider =
          Provider.of<AuthProvider>(context, listen: false);

      final bool success = await authProvider.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        phoneNumber: _phoneController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

      if (success) {
        // Show success message
        if (mounted) {
          _showSnackBar(LocalizationService.instance.translate('login_successful'), Colors.green);
        }
        // Navigation will be handled by AuthWrapper
      } else {
        // Show error message
        if (mounted) {
          _showSnackBar(
            authProvider.errorMessage ?? LocalizationService.instance.translate('login_failed'),
            Colors.red,
          );
        }
      }
    } on Exception catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

      if (mounted) {
        _showSnackBar(
          "${LocalizationService.instance.translate('login_error')}${e.toString().replaceAll("Exception: ", "")}",
          Colors.red,
        );
      }
    }
  }

  // Show snackbar message
  void _showSnackBar(final String message, final Color backgroundColor) {
    if (mounted) {
      if (backgroundColor == Colors.green) {
        ThemeConstants.showSuccessSnackBar(context, message);
      } else {
        ThemeConstants.showErrorSnackBar(context, message);
      }
    }
  }

  // Auto-fill demo credentials
  void _fillDemoCredentials() {
    _emailController.text = "admin@gmail.com";
    _phoneController.text = "+255743519104";
    _passwordController.text = "12345678";

    _showSnackBar(LocalizationService.instance.translate('demo_credentials_filled'), Colors.blue);
  }

  // Fill actual database credentials
  void _fillDatabaseCredentials() {
    _emailController.text = "admin@";
    _phoneController.text = "+255743519104";
    _passwordController.text = "12345678";

    _showSnackBar(LocalizationService.instance.translate('database_credentials_filled'), Colors.orange);
  }

  // Forgot password functionality
  void _handleForgotPassword() {
    showDialog(
      context: context,
      builder: (final BuildContext context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Umesahau Nywila?"),
        content: const SelectableText(
          "Kipengele cha kurudisha nywila kinatengenezwa. Kwa sasa, tumia taarifa za demo au wasiliana na msimamizi.",
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Sawa"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _fillDatabaseCredentials();
            },
            child: const Text("Tumia Database"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(final BuildContext context) {
    final bool isLandscape = ResponsiveUtils.isLandscape(context);

    return Consumer<LocalizationService>(
      builder: (context, localizationService, child) => Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) =>
              SingleChildScrollView(
            padding: ResponsiveUtils.getResponsivePadding(context),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
                maxWidth: ResponsiveUtils.getResponsiveMaxWidth(context),
              ),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    SizedBox(height: isLandscape ? 20.h : 60.h),

                    // Logo and Title
                    Container(
                      alignment: Alignment.center,
                      child: Column(
                        children: <Widget>[
                          Container(
                            width: ResponsiveUtils.getResponsiveIconSize(
                              context,
                              100,
                            ),
                            height: ResponsiveUtils.getResponsiveIconSize(
                              context,
                              100,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E40AF),
                              borderRadius: BorderRadius.circular(
                                ResponsiveUtils.getResponsiveIconSize(
                                  context,
                                  50,
                                ),
                              ),
                              boxShadow: <BoxShadow>[
                                BoxShadow(
                                  color:
                                      const Color(0xFF1E40AF).withOpacity(0.3),
                                  blurRadius:
                                      ResponsiveUtils.getResponsiveSpacing(
                                    context,
                                    20,
                                  ),
                                  offset: Offset(0, 10.h),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.motorcycle,
                              color: Colors.white,
                              size: ResponsiveUtils.getResponsiveIconSize(
                                context,
                                50,
                              ),
                            ),
                          ),
                          SizedBox(
                            height: ResponsiveUtils.getResponsiveSpacing(
                              context,
                              24,
                            ),
                          ),
                          Text(
                            localizationService.translate('app_name'),
                            style:
                                AppStyles.heading1Responsive(context).copyWith(
                              color: const Color(0xFF1F2937),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(
                            height: ResponsiveUtils.getResponsiveSpacing(
                              context,
                              8,
                            ),
                          ),
                          Text(
                            localizationService.translate('app_description'),
                            style:
                                AppStyles.bodyLargeResponsive(context).copyWith(
                              color: Colors.black54,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: isLandscape ? 30.h : 60.h),

                    // Login Form
                    Container(
                      constraints: BoxConstraints(
                        maxWidth:
                            ResponsiveUtils.getResponsiveDialogWidth(context),
                      ),
                      padding:
                          ResponsiveUtils.getResponsiveCardPadding(context),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(
                          ResponsiveUtils.getResponsiveBorderRadius(
                            context,
                            16,
                          ),
                        ),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: ResponsiveUtils.getResponsiveSpacing(
                              context,
                              20,
                            ),
                            offset: Offset(0, 10.h),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            Text(
                              localizationService.translate('signin'),
                              style: AppStyles.heading2Responsive(context)
                                  .copyWith(
                                color: const Color(0xFF1F2937),
                              ),
                              textAlign: TextAlign.center,
                            ),

                            SizedBox(
                              height: ResponsiveUtils.getResponsiveSpacing(
                                context,
                                32,
                              ),
                            ),

                            // Email Field
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: AppStyles.bodyMediumResponsive(context),
                              decoration:
                                  AppStyles.inputDecoration(context).copyWith(
                                labelText: localizationService.translate('email'),
                                hintText: "${localizationService.translate('email')} (admin@gmail.com)",
                                prefixIcon: Icon(
                                  Icons.email_outlined,
                                  size: ResponsiveUtils.getResponsiveIconSize(
                                    context,
                                    20,
                                  ),
                                ),
                              ),
                              validator: (final String? value) {
                                if (value == null || value.trim().isEmpty) {
                                  return "Tafadhali ingiza barua pepe";
                                }
                                // Allow incomplete email for database compatibility
                                if (value.trim() != "admin@" &&
                                    !RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$")
                                        .hasMatch(value.trim())) {
                                  return "Ingiza barua pepe sahihi";
                                }
                                return null;
                              },
                            ),

                            SizedBox(
                              height: ResponsiveUtils.getResponsiveSpacing(
                                context,
                                16,
                              ),
                            ),

                            // Phone Field
                            TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              style: AppStyles.bodyMediumResponsive(context),
                              decoration:
                                  AppStyles.inputDecoration(context).copyWith(
                                labelText: localizationService.translate('phone_number'),
                                hintText: "${localizationService.translate('phone_number')} (+255743519104)",
                                prefixIcon: Icon(
                                  Icons.phone_outlined,
                                  size: ResponsiveUtils.getResponsiveIconSize(
                                    context,
                                    20,
                                  ),
                                ),
                              ),
                              validator: (final String? value) {
                                if (value == null || value.trim().isEmpty) {
                                  return "Tafadhali ingiza namba ya simu";
                                }
                                if (!RegExp(r"^\+?[0-9]{10,15}$")
                                    .hasMatch(value.replaceAll(" ", ""))) {
                                  return "Ingiza namba ya simu sahihi";
                                }
                                return null;
                              },
                            ),

                            SizedBox(
                              height: ResponsiveUtils.getResponsiveSpacing(
                                context,
                                16,
                              ),
                            ),

                            // Password Field
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              style: AppStyles.bodyMediumResponsive(context),
                              decoration:
                                  AppStyles.inputDecoration(context).copyWith(
                                labelText: localizationService.translate('password'),
                                hintText: localizationService.translate('password'),
                                prefixIcon: Icon(
                                  Icons.lock_outlined,
                                  size: ResponsiveUtils.getResponsiveIconSize(
                                    context,
                                    20,
                                  ),
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    size: ResponsiveUtils.getResponsiveIconSize(
                                      context,
                                      20,
                                    ),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                              validator: (final String? value) {
                                if (value == null || value.isEmpty) {
                                  return "Tafadhali ingiza nywila";
                                }
                                if (value.length < 8) {
                                  return "Nywila lazima iwe na angalau herufi 8";
                                }
                                return null;
                              },
                            ),

                            SizedBox(
                              height: ResponsiveUtils.getResponsiveSpacing(
                                context,
                                32,
                              ),
                            ),

                            // Login Button
                            CustomButton(
                              text: localizationService.translate('signin'),
                              onPressed: _isLoading ? null : _handleLogin,
                              isLoading: _isLoading,
                              backgroundColor: const Color(0xFF1E40AF),
                              height: ResponsiveUtils.getResponsiveButtonHeight(
                                context,
                              ),
                            ),

                            SizedBox(
                              height: ResponsiveUtils.getResponsiveSpacing(
                                context,
                                16,
                              ),
                            ),

                            // Forgot Password Link
                            TextButton(
                              onPressed: _handleForgotPassword,
                              child: Text(
                                "Umesahau nywila?",
                                style: AppStyles.bodyMediumResponsive(context)
                                    .copyWith(
                                  color: const Color(0xFF1E40AF),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),

                            SizedBox(
                              height: ResponsiveUtils.getResponsiveSpacing(
                                context,
                                16,
                              ),
                            ),

                            // Credentials Section
                            Container(
                              padding: ResponsiveUtils.getResponsiveCardPadding(
                                context,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(
                                  ResponsiveUtils.getResponsiveBorderRadius(
                                    context,
                                    12,
                                  ),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    "Taarifa za Kuingia:",
                                    style:
                                        AppStyles.bodyMediumResponsive(context)
                                            .copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF1F2937),
                                    ),
                                  ),
                                  SizedBox(
                                    height:
                                        ResponsiveUtils.getResponsiveSpacing(
                                      context,
                                      8,
                                    ),
                                  ),
                                  SelectableText(
                                    "Database: admin@gmail.com / +255743519104",
                                    style:
                                        AppStyles.bodySmallResponsive(context)
                                            .copyWith(
                                      color: Colors.black54,
                                    ),
                                  ),
                                  SelectableText(
                                    "Demo: admin@gmail.com / +255743519104",
                                    style:
                                        AppStyles.bodySmallResponsive(context)
                                            .copyWith(
                                      color: Colors.black54,
                                    ),
                                  ),
                                  SelectableText(
                                    "Nywila: 12345678",
                                    style:
                                        AppStyles.bodyMediumResponsive(context)
                                            .copyWith(
                                      color: Colors.black54,
                                    ),
                                  ),
                                  SizedBox(
                                    height:
                                        ResponsiveUtils.getResponsiveSpacing(
                                      context,
                                      8,
                                    ),
                                  ),
                                  Row(
                                    children: <Widget>[
                                      Expanded(
                                        child: TextButton(
                                          onPressed: _fillDatabaseCredentials,
                                          child: Text(
                                            "Database",
                                            style:
                                                AppStyles.bodySmallResponsive(
                                              context,
                                            ).copyWith(
                                              color: const Color(0xFFF97316),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: TextButton(
                                          onPressed: _fillDemoCredentials,
                                          child: Text(
                                            "Demo",
                                            style:
                                                AppStyles.bodySmallResponsive(
                                              context,
                                            ).copyWith(
                                              color: const Color(0xFF1E40AF),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(
                      height: ResponsiveUtils.getResponsiveSpacing(context, 32),
                    ),

                    // Footer
                    Text(
                      "Imetengenezwa kwa ajili ya biashara za boda boda",
                      style: AppStyles.bodyMediumResponsive(context).copyWith(
                        color: Colors.black45,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }
}
