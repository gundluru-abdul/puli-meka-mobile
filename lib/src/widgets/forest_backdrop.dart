import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class ForestBackdrop extends StatelessWidget {
  const ForestBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF10291F), AppColors.night, Color(0xFF030907)],
          stops: [0, 0.58, 1],
        ),
      ),
      child: CustomPaint(
        painter: _ForestPainter(),
        child: SizedBox.expand(child: child),
      ),
    );
  }
}

class _ForestPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final moonCenter = Offset(size.width * 0.8, size.height * 0.13);
    canvas.drawCircle(
      moonCenter,
      size.width * 0.18,
      Paint()
        ..shader =
            RadialGradient(
              colors: [
                AppColors.ember.withValues(alpha: 0.13),
                Colors.transparent,
              ],
            ).createShader(
              Rect.fromCircle(center: moonCenter, radius: size.width * 0.18),
            ),
    );

    final mist = Paint()
      ..color = AppColors.leaf.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 28;
    for (var i = 0; i < 4; i++) {
      final path = Path()..moveTo(-30, size.height * (0.25 + i * 0.19));
      for (var x = 0.0; x <= size.width + 60; x += 50) {
        path.quadraticBezierTo(
          x + 25,
          size.height * (0.22 + i * 0.19) + math.sin((x / 70) + i) * 15,
          x + 50,
          size.height * (0.25 + i * 0.19),
        );
      }
      canvas.drawPath(path, mist);
    }

    final treePaint = Paint()..color = Colors.black.withValues(alpha: 0.23);
    for (var i = 0; i < 7; i++) {
      final x = (i / 6) * size.width;
      final width = 12.0 + ((i * 7) % 15);
      final top = size.height * (0.15 + ((i * 11) % 18) / 100);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x - width / 2, top, width, size.height - top),
          const Radius.circular(12),
        ),
        treePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
