import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class StunningLoadingBanner extends StatefulWidget {
  final String message;
  const StunningLoadingBanner({super.key, required this.message});

  @override
  State<StunningLoadingBanner> createState() => _StunningLoadingBannerState();
}

class _StunningLoadingBannerState extends State<StunningLoadingBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color cyberCyan = Color(0xFF00E5FF);
    
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated Progress Bar with Glow
              Container(
                width: 200.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(2.r),
                ),
                child: Stack(
                  children: [
                    // Moving Glow Bar
                    Positioned(
                      left: _controller.value * 200.w - 80.w,
                      child: Container(
                        width: 80.w,
                        height: 4.h,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Colors.transparent,
                              cyberCyan,
                              Colors.transparent,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: cyberCyan.withValues(alpha: 0.5),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12.h),
              
              // Text with Pulse and Glitch Effect
              Stack(
                alignment: Alignment.center,
                children: [
                   // Shadow/Glitch layer 1
                  Transform.translate(
                    offset: Offset(math.sin(_controller.value * 10 * math.pi) * 0.5, 0),
                    child: Text(
                      widget.message.toUpperCase(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 8.w,
                      ),
                    ),
                  ),
                  // Main text with glow
                  Text(
                    widget.message.toUpperCase(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 8.w,
                      shadows: [
                        Shadow(
                          color: cyberCyan.withValues(alpha: 0.8),
                          blurRadius: 20 * (0.5 + 0.5 * math.sin(_controller.value * 2 * math.pi)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 8.h),
              
              // Sub-status line
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildStatusDot(0.1),
                  SizedBox(width: 8.w),
                  _buildStatusDot(0.4),
                  SizedBox(width: 8.w),
                  _buildStatusDot(0.7),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatusDot(double startOffset) {
    final double value = (_controller.value + startOffset) % 1.0;
    final double opacity = math.sin(value * math.pi).clamp(0.0, 1.0);
    
    return Container(
      width: 4.w,
      height: 4.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF00E5FF).withValues(alpha: opacity),
        boxShadow: [
          if (opacity > 0.5)
            BoxShadow(
              color: const Color(0xFF00E5FF).withValues(alpha: 0.3),
              blurRadius: 4,
              spreadRadius: 1,
            ),
        ],
      ),
    );
  }
}
