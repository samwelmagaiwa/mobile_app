import "dart:ui";
import "package:flutter/material.dart";
import "package:flutter_screenutil/flutter_screenutil.dart";
import "package:provider/provider.dart";

import "../../constants/theme_constants.dart";
import "../../providers/auth_provider.dart";
import "../../services/localization_service.dart";
import "../../widgets/backgrounds/starfield_background.dart";

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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fillDemoCredentials();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final AuthProvider authProvider = Provider.of<AuthProvider>(context, listen: false);
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
        if (mounted) {
          _showSnackBar(LocalizationService.instance.translate('login_successful'), Colors.green);
          Navigator.of(context).pop();
        }
      } else {
        if (mounted) {
          _showSnackBar(authProvider.errorMessage ?? LocalizationService.instance.translate('login_failed'), Colors.red);
        }
      }
    } on Exception catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showSnackBar("${LocalizationService.instance.translate('login_error')}${e.toString().replaceAll("Exception: ", "")}", Colors.red);
      }
    }
  }

  void _showSnackBar(final String message, final Color backgroundColor) {
    if (mounted) {
      if (backgroundColor == Colors.green) {
        ThemeConstants.showSuccessSnackBar(context, message);
      } else {
        ThemeConstants.showErrorSnackBar(context, message);
      }
    }
  }

  void _fillDemoCredentials() {
    _emailController.text = "admin@gmail.com";
    _phoneController.text = "+255743519104";
    _passwordController.text = "12345678";
  }

  void _handleForgotPassword() {
    showDialog(
      context: context,
      builder: (final BuildContext context) => AlertDialog(
        backgroundColor: const Color(0xFF001D3D),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Text("Umesahau Nywila?", style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.bold)),
        content: Text("Kipengele hiki kinatengenezwa. Kwa sasa tumia taarifa za demo.", style: TextStyle(color: Colors.white70, fontSize: 14.sp)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Sawa", style: TextStyle(color: const Color(0xFF00E5FF)))),
        ],
      ),
    );
  }

  @override
  Widget build(final BuildContext context) {
    final Color cyberCyan = const Color(0xFF00E5FF);

    return StarfieldBackground(
      child: Consumer<LocalizationService>(
        builder: (context, localizationService, child) => Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              // Nebula Glow
              Positioned(
                top: -100.h,
                right: -50.w,
                child: Container(
                  width: 400.w,
                  height: 400.h,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        cyberCyan.withValues(alpha: 0.12),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: constraints.maxHeight),
                        child: IntrinsicHeight(
                          child: AnimatedOpacity(
                            opacity: _isLoading ? 0.3 : 1.0,
                            duration: const Duration(milliseconds: 500),
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 24.w),
                              child: Column(
                                children: [
                                  SizedBox(height: 50.h),
                                  
                                  // Hero Logo Section
                                  TweenAnimationBuilder<double>(
                                    tween: Tween(begin: 0.0, end: 1.0),
                                    duration: const Duration(seconds: 2),
                                    builder: (context, val, child) {
                                      return Transform.scale(
                                        scale: 0.9 + (0.1 * val),
                                        child: Container(
                                          padding: EdgeInsets.all(4.w),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(color: cyberCyan.withValues(alpha: 0.5 * val), width: 2),
                                            boxShadow: [
                                              BoxShadow(
                                                color: cyberCyan.withValues(alpha: 0.2 * val),
                                                blurRadius: 30 * val,
                                                spreadRadius: 5 * val,
                                              ),
                                            ],
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(70.r),
                                            child: Image.asset(
                                              'assets/images/app_icon.png',
                                              width: 110.w,
                                              height: 110.w,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  
                                  SizedBox(height: 16.h),
                                  
                                  Text(
                                    localizationService.translate('app_name').toUpperCase(),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 28.sp,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 4.w,
                                    ),
                                  ),
                                  
                                  SizedBox(height: 60.h),
                                  
                                  // Glass Card Form
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(24.r),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                                      child: Container(
                                        padding: EdgeInsets.all(24.w),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.05),
                                          borderRadius: BorderRadius.circular(24.r),
                                          border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
                                        ),
                                        child: Form(
                                          key: _formKey,
                                          child: Column(
                                            children: [
                                              _buildModernField(
                                                controller: _emailController,
                                                label: localizationService.translate('email'),
                                                icon: Icons.email_outlined,
                                                cyberCyan: cyberCyan,
                                              ),
                                              SizedBox(height: 20.h),
                                              _buildModernField(
                                                controller: _phoneController,
                                                label: localizationService.translate('phone_number'),
                                                icon: Icons.phone_android_outlined,
                                                cyberCyan: cyberCyan,
                                              ),
                                              SizedBox(height: 20.h),
                                              _buildModernField(
                                                controller: _passwordController,
                                                label: localizationService.translate('password'),
                                                icon: Icons.lock_outline,
                                                obscureText: _obscurePassword,
                                                cyberCyan: cyberCyan,
                                                suffix: IconButton(
                                                  icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off, color: Colors.white38, size: 20.sp),
                                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                                ),
                                              ),
                                              SizedBox(height: 32.h),
                                              
                                              // Login Button
                                              GestureDetector(
                                                onTap: _handleLogin,
                                                child: Container(
                                                  height: 56.h,
                                                  width: double.infinity,
                                                  decoration: BoxDecoration(
                                                    borderRadius: BorderRadius.circular(16.r),
                                                    gradient: LinearGradient(
                                                      colors: [cyberCyan, const Color(0xFF00B8D4)],
                                                    ),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: cyberCyan.withValues(alpha: 0.3),
                                                        blurRadius: 15,
                                                        offset: const Offset(0, 5),
                                                      ),
                                                    ],
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      localizationService.translate('signin').toUpperCase(),
                                                      style: TextStyle(
                                                        color: Colors.black,
                                                        fontSize: 16.sp,
                                                        fontWeight: FontWeight.w900,
                                                        letterSpacing: 2.w,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              
                                              SizedBox(height: 16.h),
                                              
                                              TextButton(
                                                onPressed: _handleForgotPassword,
                                                child: Text(
                                                  localizationService.translate('forgot_password'),
                                                  style: TextStyle(color: Colors.white38, fontSize: 13.sp),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  
                                  SizedBox(height: 20.h),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Loading Overlay
              if (_isLoading)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.8),
                    child: Center(
                      child: ThemeConstants.buildResponsiveLoadingWidget(
                        context,
                        message: localizationService.translate('signing_in'),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    Widget? suffix,
    required Color cyberCyan,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(color: Colors.white54, fontSize: 11.sp, fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
        SizedBox(height: 8.h),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.white12),
          ),
          child: TextFormField(
            controller: controller,
            obscureText: obscureText,
            style: const TextStyle(color: Colors.white, decoration: TextDecoration.none),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.transparent,
              prefixIcon: Icon(icon, color: cyberCyan.withValues(alpha: 0.6), size: 20.sp),
              suffixIcon: suffix,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            ),
          ),
        ),
      ],
    );
  }
}
