import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'stunning_loading_banner.dart';

class Faux3DLoadingWidget extends StatefulWidget {
  final String? message;
  const Faux3DLoadingWidget({super.key, this.message});

  @override
  State<Faux3DLoadingWidget> createState() => _Faux3DLoadingWidgetState();
}

class _Faux3DLoadingWidgetState extends State<Faux3DLoadingWidget>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _floatController;
  late AnimationController _scanController;
  late AnimationController _particleController;

  final List<Particle> _particles = List.generate(20, (index) => Particle());

  @override
  void initState() {
    super.initState();
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _mainController.dispose();
    _floatController.dispose();
    _scanController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color holoColor = Color(0xFF00E5FF);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 200.w,
          height: 200.h,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Bottom Decorative Floor (Grid)
              CustomPaint(
                painter: HologramFloorPainter(_mainController),
                size: Size(200.w, 100.h),
              ),

              // Particles
              CustomPaint(
                painter: ParticlePainter(_particleController, _particles, holoColor),
                size: Size(200.w, 200.h),
              ),

              // Light Rays / Beams
              CustomPaint(
                painter: HologramBeamPainter(_floatController, _scanController, holoColor),
                size: Size(180.w, 180.h),
              ),

              // The Base Platform (Glow Base)
              Positioned(
                bottom: 10.h,
                child: Transform(
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.002)
                    ..rotateX(1.1),
                  alignment: Alignment.center,
                  child: Container(
                    width: 140.w,
                    height: 140.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          holoColor.withValues(alpha: 0.8),
                          holoColor.withValues(alpha: 0.2),
                          Colors.transparent,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: holoColor.withValues(alpha: 0.5),
                          blurRadius: 40,
                          spreadRadius: 15,
                        ),
                      ],
                      border: Border.all(
                        color: holoColor.withValues(alpha: 0.6),
                        width: 3,
                      ),
                    ),
                  ),
                ),
              ),

              // Floating Central Logo
              AnimatedBuilder(
                animation: Listenable.merge([_mainController, _floatController]),
                builder: (context, child) {
                  final floatValue = _floatController.value;
                  final rotationValue = _mainController.value * 2 * math.pi;

                  return Positioned(
                    top: 25.h - (floatValue * 25.h),
                    child: Transform(
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateY(math.sin(rotationValue) * 0.15)
                        ..rotateX(math.cos(rotationValue) * 0.1),
                      alignment: Alignment.center,
                      child: Container(
                        padding: EdgeInsets.all(4.w),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: holoColor.withValues(alpha: 0.8),
                            width: 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: holoColor.withValues(alpha: 0.4 + (floatValue * 0.2)),
                              blurRadius: 20 + (floatValue * 10),
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(60.r),
                          child: Image.asset(
                            'assets/images/app_icon.png',
                            width: 85.w,
                            height: 85.w,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        SizedBox(height: 40.h),
        
        // New Stunning Loading Banner
        StunningLoadingBanner(message: widget.message ?? "SYSTEM ACCESSING"),
      ],
    );
  }
}

class Particle {
  late double x, y, size, speed;
  Particle() {
    reset();
  }
  void reset() {
    x = math.Random().nextDouble() * 200;
    y = 200.0 + math.Random().nextDouble() * 50;
    size = 1.0 + math.Random().nextDouble() * 3;
    speed = 0.5 + math.Random().nextDouble() * 1.5;
  }
}

class ParticlePainter extends CustomPainter {
  final Animation<double> animation;
  final List<Particle> particles;
  final Color color;

  ParticlePainter(this.animation, this.particles, this.color) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withValues(alpha: 0.5);
    for (final p in particles) {
      double currentY = p.y - (animation.value * 200 * p.speed);
      if (currentY < 0) currentY += 200;
      
      final double opacity = (currentY / 200).clamp(0.0, 1.0);
      paint.color = color.withValues(alpha: opacity * 0.5);
      
      canvas.drawCircle(Offset(p.x, currentY), p.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class HologramBeamPainter extends CustomPainter {
  final Animation<double> floatAnimation;
  final Animation<double> scanAnimation;
  final Color beamColor;

  HologramBeamPainter(this.floatAnimation, this.scanAnimation, this.beamColor)
      : super(repaint: Listenable.merge([floatAnimation, scanAnimation]));

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          beamColor.withValues(alpha: 0.5),
          beamColor.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final double centerX = size.width / 2;
    final double bottomY = size.height - 20;

    for (int i = -4; i <= 4; i++) {
      final double xOffset = i * 25.w;
      final Path path = Path();
      path.moveTo(centerX + xOffset - 12.w, bottomY);
      path.lineTo(centerX + xOffset + 12.w, bottomY);
      path.lineTo(centerX + (xOffset * 0.1), 0);
      path.close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class HologramFloorPainter extends CustomPainter {
  final Animation<double> animation;
  HologramFloorPainter(this.animation) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.1)
      ..strokeWidth = 1.2;

    final double centerX = size.width / 2;
    final double centerY = size.height / 2;

    // Perspective lines
    for (int i = -8; i <= 8; i++) {
        canvas.drawLine(
          Offset(centerX, centerY + 20),
          Offset(centerX + (i * 60.w), size.height + 60.h),
          paint,
        );
    }
    
    // Horizontal lines for grid
    for (int j = 1; j <= 5; j++) {
      final double y = centerY + 20 + (j * 15.h);
      final double widthFactor = 1 + (j * 0.5);
      canvas.drawLine(
        Offset(centerX - 100 * widthFactor, y),
        Offset(centerX + 100 * widthFactor, y),
        paint..color = const Color(0xFF00E5FF).withValues(alpha: 0.1 - (j * 0.01)),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
