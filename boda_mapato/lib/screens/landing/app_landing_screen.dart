import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../services/localization_service.dart';

/// Premium animated landing screen shown once per session after language choice.
/// Showcases all three services with full-bleed slides before routing the user
/// to their bound service(s).
class AppLandingScreen extends StatefulWidget {
  const AppLandingScreen({super.key, required this.onContinue});

  /// Called when the user taps "Continue" (or auto-advances past the last slide).
  final VoidCallback onContinue;

  @override
  State<AppLandingScreen> createState() => _AppLandingScreenState();
}

class _AppLandingScreenState extends State<AppLandingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late final AnimationController _heroAnim;
  late final AnimationController _floatAnim;
  late final Animation<double> _floatOffset;

  static const List<_ServiceSlide> _slides = [
    _ServiceSlide(
      serviceKey: 'inventory',
      icon: Icons.inventory_2_rounded,
      accentColor: Color(0xFF00E5FF),
      glowColor: Color(0x5500E5FF),
      gradientTop: Color(0xFF0A1628),
      gradientBottom: Color(0xFF0D2137),
      patternColor: Color(0x1800E5FF),
      titleEn: 'Inventory & Sales',
      titleSw: 'Hisa na Mauzo',
      taglineEn: 'Full control of your\nstock and profits.',
      taglineSw: 'Udhibiti kamili wa\nhisa na faida yako.',
      features: [
        (Icons.bar_chart_rounded, 'Leo sales vs yesterday',
            'Mauzo ya Leo vs Jana'),
        (Icons.inventory_rounded, 'Live stock tracking', 'Ufuatiliaji wa Hisa'),
        (Icons.trending_up_rounded, 'Profit margins & reports',
            'Faida na Ripoti'),
        (Icons.people_alt_rounded, 'Credit & debtors', 'Mikopo na Wadai'),
      ],
    ),
    _ServiceSlide(
      serviceKey: 'rental',
      icon: Icons.apartment_rounded,
      accentColor: Color(0xFFFFB300),
      glowColor: Color(0x55FFB300),
      gradientTop: Color(0xFF12100A),
      gradientBottom: Color(0xFF1E1608),
      patternColor: Color(0x18FFB300),
      titleEn: 'Property Rental',
      titleSw: 'Panga Mali',
      taglineEn: 'Manage properties,\ntenants & collections.',
      taglineSw: 'Simamia mali, wapangaji\nna makusanyo yako.',
      features: [
        (Icons.home_work_rounded, 'Properties & houses', 'Mali na Nyumba'),
        (Icons.people_rounded, 'Tenant management', 'Usimamizi wa Wapangaji'),
        (Icons.receipt_long_rounded, 'Billing & arrears', 'Ankara na Madeni'),
        (Icons.handshake_rounded, 'Lease agreements', 'Mikataba ya Upangaji'),
      ],
    ),
    _ServiceSlide(
      serviceKey: 'transport',
      icon: Icons.local_shipping_rounded,
      accentColor: Color(0xFF00E676),
      glowColor: Color(0x5500E676),
      gradientTop: Color(0xFF091612),
      gradientBottom: Color(0xFF0D1F17),
      patternColor: Color(0x1800E676),
      titleEn: 'Transport & Fleet',
      titleSw: 'Usafiri na Magari',
      taglineEn: 'Run your fleet,\ndrivers & payments.',
      taglineSw: 'Simamia magari,\nmadereva na malipo.',
      features: [
        (Icons.directions_car_rounded, 'Vehicle management', 'Usimamizi wa Magari'),
        (Icons.person_pin_rounded, 'Driver tracking', 'Ufuatiliaji wa Madereva'),
        (Icons.payments_rounded, 'Payment collection', 'Ukusanyaji wa Malipo'),
        (Icons.analytics_rounded, 'Fleet analytics', 'Takwimu za Usafiri'),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _heroAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _floatAnim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _floatOffset = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _floatAnim, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _heroAnim.dispose();
    _floatAnim.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    } else {
      widget.onContinue();
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = LocalizationService.instance;
    final isSw = loc.isSwahili;

    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      body: Stack(
        children: [
          // Full-bleed page view
          PageView.builder(
            controller: _pageController,
            itemCount: _slides.length,
            onPageChanged: (i) {
              setState(() => _currentPage = i);
              _heroAnim
                ..reset()
                ..forward();
            },
            itemBuilder: (_, i) => _SlideView(
              slide: _slides[i],
              heroAnim: _heroAnim,
              floatOffset: _floatOffset,
              isSw: isSw,
            ),
          ),

          // Top: skip button
          Positioned(
            top: MediaQuery.of(context).padding.top + 12.h,
            right: 20.w,
            child: TextButton(
              onPressed: widget.onContinue,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white54,
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              ),
              child: Text(
                isSw ? 'Ruka' : 'Skip',
                style: TextStyle(fontSize: 14.sp, letterSpacing: 0.5),
              ),
            ),
          ),

          // Bottom: dots + CTA
          Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.of(context).padding.bottom + 24.h,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Page indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_slides.length, (i) {
                    final isActive = i == _currentPage;
                    final slide = _slides[i];
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: EdgeInsets.symmetric(horizontal: 4.w),
                      width: isActive ? 24.w : 8.w,
                      height: 8.h,
                      decoration: BoxDecoration(
                        color: isActive
                            ? slide.accentColor
                            : Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(4.r),
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: slide.accentColor.withOpacity(0.6),
                                  blurRadius: 8,
                                )
                              ]
                            : null,
                      ),
                    );
                  }),
                ),
                SizedBox(height: 24.h),

                // CTA button
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32.w),
                  child: _CTAButton(
                    slide: _slides[_currentPage],
                    isLast: _currentPage == _slides.length - 1,
                    isSw: isSw,
                    onTap: _nextPage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Individual slide ────────────────────────────────────────────────────────

class _SlideView extends StatelessWidget {
  const _SlideView({
    required this.slide,
    required this.heroAnim,
    required this.floatOffset,
    required this.isSw,
  });

  final _ServiceSlide slide;
  final AnimationController heroAnim;
  final Animation<double> floatOffset;
  final bool isSw;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Gradient background
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [slide.gradientTop, slide.gradientBottom, const Color(0xFF0A1628)],
              stops: const [0, 0.6, 1],
            ),
          ),
        ),

        // Decorative circles (background pattern)
        ..._buildDecorativeCircles(slide),

        // Content
        SafeArea(
          child: Column(
            children: [
              SizedBox(height: 48.h),

              // Big animated service icon
              AnimatedBuilder(
                animation: Listenable.merge([heroAnim, floatOffset]),
                builder: (_, __) {
                  final scale = Curves.elasticOut.transform(
                      heroAnim.value.clamp(0.0, 1.0));
                  return Transform.translate(
                    offset: Offset(0, floatOffset.value),
                    child: Transform.scale(
                      scale: 0.6 + 0.4 * scale,
                      child: Opacity(
                        opacity: heroAnim.value.clamp(0.0, 1.0),
                        child: _ServiceIconHero(slide: slide),
                      ),
                    ),
                  );
                },
              ),

              SizedBox(height: 36.h),

              // Service name
              FadeTransition(
                opacity: CurvedAnimation(
                  parent: heroAnim,
                  curve: const Interval(0.3, 1, curve: Curves.easeOut),
                ),
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.3),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: heroAnim,
                    curve: const Interval(0.3, 1, curve: Curves.easeOut),
                  )),
                  child: Text(
                    isSw ? slide.titleSw : slide.titleEn,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30.sp,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      height: 1.1,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 10.h),

              // Tagline
              FadeTransition(
                opacity: CurvedAnimation(
                  parent: heroAnim,
                  curve: const Interval(0.4, 1, curve: Curves.easeOut),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40.w),
                  child: Text(
                    isSw ? slide.taglineSw : slide.taglineEn,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 15.sp,
                      height: 1.5,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 32.h),

              // Feature chips
              FadeTransition(
                opacity: CurvedAnimation(
                  parent: heroAnim,
                  curve: const Interval(0.5, 1, curve: Curves.easeOut),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Wrap(
                    spacing: 8.w,
                    runSpacing: 8.h,
                    alignment: WrapAlignment.center,
                    children: slide.features
                        .map((f) => _FeatureChip(
                              icon: f.$1,
                              label: isSw ? f.$3 : f.$2,
                              accent: slide.accentColor,
                            ))
                        .toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildDecorativeCircles(_ServiceSlide slide) {
    return [
      Positioned(
        top: -80.h,
        right: -60.w,
        child: _GlowCircle(
          size: 240.w,
          color: slide.patternColor,
        ),
      ),
      Positioned(
        bottom: 100.h,
        left: -80.w,
        child: _GlowCircle(
          size: 200.w,
          color: slide.patternColor,
        ),
      ),
      Positioned(
        top: 200.h,
        left: 30.w,
        child: _GlowCircle(
          size: 60.w,
          color: slide.accentColor.withOpacity(0.08),
        ),
      ),
      Positioned(
        top: 300.h,
        right: 20.w,
        child: _GlowCircle(
          size: 40.w,
          color: slide.accentColor.withOpacity(0.06),
        ),
      ),
    ];
  }
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(color: color, blurRadius: size * 0.4, spreadRadius: size * 0.1),
        ],
      ),
    );
  }
}

// ─── Hero icon with layered glow rings ──────────────────────────────────────

class _ServiceIconHero extends StatelessWidget {
  const _ServiceIconHero({required this.slide});
  final _ServiceSlide slide;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180.w,
      height: 180.w,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer glow ring
          Container(
            width: 180.w,
            height: 180.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: slide.accentColor.withOpacity(0.05),
              border: Border.all(
                color: slide.accentColor.withOpacity(0.12),
                width: 1,
              ),
            ),
          ),
          // Mid ring
          Container(
            width: 140.w,
            height: 140.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: slide.accentColor.withOpacity(0.08),
              border: Border.all(
                color: slide.accentColor.withOpacity(0.2),
                width: 1.5,
              ),
            ),
          ),
          // Inner icon container with blur
          ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
              child: Container(
                width: 100.w,
                height: 100.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      slide.accentColor.withOpacity(0.3),
                      slide.accentColor.withOpacity(0.05),
                    ],
                  ),
                  border: Border.all(
                    color: slide.accentColor.withOpacity(0.5),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: slide.accentColor.withOpacity(0.4),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(
                  slide.icon,
                  size: 48.sp,
                  color: slide.accentColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Feature chip ────────────────────────────────────────────────────────────

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({
    required this.icon,
    required this.label,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.07),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: accent.withOpacity(0.25),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14.sp, color: accent),
              SizedBox(width: 6.w),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── CTA button ──────────────────────────────────────────────────────────────

class _CTAButton extends StatelessWidget {
  const _CTAButton({
    required this.slide,
    required this.isLast,
    required this.isSw,
    required this.onTap,
  });

  final _ServiceSlide slide;
  final bool isLast;
  final bool isSw;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = isLast
        ? (isSw ? 'Anza Sasa' : 'Get Started')
        : (isSw ? 'Endelea' : 'Next');

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        height: 54.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          gradient: LinearGradient(
            colors: [
              slide.accentColor,
              slide.accentColor.withOpacity(0.7),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: slide.accentColor.withOpacity(0.45),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.black87,
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
            SizedBox(width: 8.w),
            Icon(
              isLast ? Icons.rocket_launch_rounded : Icons.arrow_forward_rounded,
              color: Colors.black87,
              size: 18.sp,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Data model ──────────────────────────────────────────────────────────────

class _ServiceSlide {
  const _ServiceSlide({
    required this.serviceKey,
    required this.icon,
    required this.accentColor,
    required this.glowColor,
    required this.gradientTop,
    required this.gradientBottom,
    required this.patternColor,
    required this.titleEn,
    required this.titleSw,
    required this.taglineEn,
    required this.taglineSw,
    required this.features,
  });

  final String serviceKey;
  final IconData icon;
  final Color accentColor;
  final Color glowColor;
  final Color gradientTop;
  final Color gradientBottom;
  final Color patternColor;
  final String titleEn;
  final String titleSw;
  final String taglineEn;
  final String taglineSw;
  final List<(IconData, String, String)> features;
}
