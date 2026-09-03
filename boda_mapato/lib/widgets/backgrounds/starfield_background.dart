import 'dart:math' as math;
import 'package:flutter/material.dart';

class StarfieldBackground extends StatefulWidget {
  final Widget child;
  const StarfieldBackground({super.key, required this.child});

  @override
  State<StarfieldBackground> createState() => _StarfieldBackgroundState();
}

class _StarfieldBackgroundState extends State<StarfieldBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: Container(color: Colors.black)),
        Positioned.fill(
          child: CustomPaint(
            painter: StarfieldPainter(_controller),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class StarfieldPainter extends CustomPainter {
  final Animation<double> animation;
  final List<Star> stars;

  StarfieldPainter(this.animation) 
      : stars = List.generate(
          120, 
          (index) => Star(
            math.Random().nextDouble(), 
            math.Random().nextDouble(), 
            0.5 + math.Random().nextDouble() * 1.5,
            0.3 + math.Random().nextDouble() * 0.7,
          ),
        ),
        super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    for (var star in stars) {
      final double x = star.x * size.width;
      final double y = (star.y * size.height + animation.value * size.height) % size.height;
      
      canvas.drawCircle(
        Offset(x, y), 
        star.size, 
        paint..color = Colors.white.withValues(alpha: star.opacity),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class Star {
  final double x;
  final double y;
  final double size;
  final double opacity;
  Star(this.x, this.y, this.size, this.opacity);
}
