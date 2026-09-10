import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../widgets/backgrounds/starfield_background.dart';
import '../../widgets/flag_app_name_text.dart';

/// The first thing a user sees after the native OS launch screen hands off
/// to Flutter -- an animated brand moment (icon entrance, flag-colored app
/// name, ambient starfield) instead of a bare spinner on a flat background.
/// Shown while [AuthProvider] resolves the saved session.
class AppSplashScreen extends StatefulWidget {
  const AppSplashScreen({
    required this.appName,
    super.key,
    this.message,
  });

  final String appName;
  final String? message;

  @override
  State<AppSplashScreen> createState() => _AppSplashScreenState();
}

class _AppSplashScreenState extends State<AppSplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _iconScale;
  late final Animation<double> _iconFade;
  late final Animation<Offset> _nameSlide;
  late final Animation<double> _nameFade;
  late final Animation<double> _loaderFade;
  late final Animation<double> _glowPulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();

    _iconScale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOutBack),
      ),
    );
    _iconFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
      ),
    );
    _nameSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.30, 0.70, curve: Curves.easeOutCubic),
    ));
    _nameFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.30, 0.70, curve: Curves.easeOut),
      ),
    );
    _loaderFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.65, 1.0, curve: Curves.easeOut),
      ),
    );
    // A slow breathing glow behind the icon keeps the screen feeling alive
    // for however long the session check actually takes, past the 1.4s
    // one-shot entrance above.
    _glowPulse = TweenSequence<double>(<TweenSequenceItem<double>>[
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.35, end: 0.65)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.65, end: 0.35)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 1,
      ),
    ]).animate(
      AnimationController(vsync: this, duration: const Duration(seconds: 2))
        ..repeat(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StarfieldBackground(
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[Color(0xCC0F3B3A), Color(0xCC120B33)],
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  FadeTransition(
                    opacity: _iconFade,
                    child: ScaleTransition(
                      scale: _iconScale,
                      child: AnimatedBuilder(
                        animation: _glowPulse,
                        builder: (BuildContext context, Widget? child) =>
                            Container(
                          width: 120.w,
                          height: 120.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                color: const Color(0xFF17D3C6)
                                    .withValues(alpha: _glowPulse.value),
                                blurRadius: 40,
                                spreadRadius: 6,
                              ),
                            ],
                          ),
                          child: child,
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/app_icon.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 24.h),
                  FadeTransition(
                    opacity: _nameFade,
                    child: SlideTransition(
                      position: _nameSlide,
                      child: FlagAppNameText(widget.appName, fontSize: 34.sp),
                    ),
                  ),
                  SizedBox(height: 36.h),
                  FadeTransition(
                    opacity: _loaderFade,
                    child: Column(
                      children: <Widget>[
                        SizedBox(
                          width: 26.w,
                          height: 26.w,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white70,
                          ),
                        ),
                        if (widget.message != null) ...<Widget>[
                          SizedBox(height: 12.h),
                          Text(
                            widget.message!,
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 13.sp,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
