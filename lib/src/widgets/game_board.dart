import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../game/game_model.dart';
import '../theme/app_theme.dart';

class GameBoard extends StatelessWidget {
  const GameBoard({
    super.key,
    required this.game,
    required this.onNodeTap,
    required this.impactAnimation,
  });

  final AaduPuliGame game;
  final ValueChanged<int> onNodeTap;
  final Animation<double> impactAnimation;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = math.min(
          constraints.maxWidth,
          constraints.maxHeight * 0.94,
        );
        final height = math.min(constraints.maxHeight, width / 0.94);
        final pieceSize = (width * 0.082).clamp(27.0, 41.0);

        return Center(
          child: SizedBox(
            width: width,
            height: height,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _BoardPainter(
                      game: game,
                      impactAnimation: impactAnimation,
                    ),
                  ),
                ),
                for (final node in AaduPuliGame.nodes)
                  Positioned(
                    left: (node.x * width) - (pieceSize * 0.68),
                    top: (node.y * height) - (pieceSize * 0.68),
                    width: pieceSize * 1.36,
                    height: pieceSize * 1.36,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () => onNodeTap(node.id),
                      child: Center(
                        child: _BoardPiece(
                          piece: game.pieceAt(node.id),
                          selected: game.selectedNode == node.id,
                          destination: game.highlightedDestinations.contains(
                            node.id,
                          ),
                          size: pieceSize,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BoardPainter extends CustomPainter {
  _BoardPainter({required this.game, required this.impactAnimation})
    : super(repaint: impactAnimation);

  final AaduPuliGame game;
  final Animation<double> impactAnimation;

  Offset point(BoardNode node, Size size) {
    return Offset(node.x * size.width, node.y * size.height);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final slab = RRect.fromRectAndRadius(
      Rect.fromLTWH(3, 3, size.width - 6, size.height - 6),
      const Radius.circular(24),
    );

    canvas.drawRRect(
      slab.shift(const Offset(0, 8)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15),
    );
    canvas.drawRRect(
      slab,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF594A2D), Color(0xFF2C3426), Color(0xFF15231A)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawRRect(
      slab,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = AppColors.ember.withValues(alpha: 0.35),
    );

    final innerBorder = RRect.fromRectAndRadius(
      Rect.fromLTWH(13, 13, size.width - 26, size.height - 26),
      const Radius.circular(17),
    );
    canvas.drawRRect(
      innerBorder,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = AppColors.parchment.withValues(alpha: 0.16),
    );

    final grooveShadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.75)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    final groove = Paint()
      ..color = AppColors.parchment.withValues(alpha: 0.42)
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round;

    for (final entry in AaduPuliGame.adjacency.entries) {
      for (final neighbor in entry.value) {
        if (entry.key >= neighbor) continue;
        final from = point(AaduPuliGame.nodes[entry.key], size);
        final to = point(AaduPuliGame.nodes[neighbor], size);
        canvas.drawLine(
          from + const Offset(0, 1.5),
          to + const Offset(0, 1.5),
          grooveShadow,
        );
        canvas.drawLine(from, to, groove);
      }
    }

    if (game.lastFrom case final from?) {
      if (game.lastTo case final to?) {
        canvas.drawLine(
          point(AaduPuliGame.nodes[from], size),
          point(AaduPuliGame.nodes[to], size),
          Paint()
            ..color = AppColors.ember.withValues(alpha: 0.5)
            ..strokeWidth = 4
            ..strokeCap = StrokeCap.round,
        );
      }
    }

    final nodePaint = Paint()..color = const Color(0xFF09110D);
    final nodeRim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = AppColors.parchment.withValues(alpha: 0.42);
    for (final node in AaduPuliGame.nodes) {
      final center = point(node, size);
      canvas.drawCircle(center, 5.3, nodePaint);
      canvas.drawCircle(center, 5.3, nodeRim);
    }

    final titlePainter = TextPainter(
      text: TextSpan(
        text: 'PULI MEKA',
        style: TextStyle(
          color: AppColors.ember.withValues(alpha: 0.32),
          fontSize: size.width * 0.035,
          fontWeight: FontWeight.w900,
          letterSpacing: 3,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    titlePainter.paint(
      canvas,
      Offset((size.width - titlePainter.width) / 2, size.height * 0.955),
    );

    final captured = game.lastCaptured;
    if (captured != null && impactAnimation.isAnimating) {
      final t = Curves.easeOut.transform(impactAnimation.value);
      final center = point(AaduPuliGame.nodes[captured], size);
      final burst = Paint()
        ..color = AppColors.tiger.withValues(alpha: (1 - t) * 0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4 * (1 - t);
      canvas.drawCircle(center, 10 + (t * 42), burst);
      for (var i = 0; i < 9; i++) {
        final angle = (math.pi * 2 / 9) * i;
        final inner = Offset(
          center.dx + math.cos(angle) * 12,
          center.dy + math.sin(angle) * 12,
        );
        final outer = Offset(
          center.dx + math.cos(angle) * (20 + t * 35),
          center.dy + math.sin(angle) * (20 + t * 35),
        );
        canvas.drawLine(inner, outer, burst);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BoardPainter oldDelegate) {
    return true;
  }
}

class _BoardPiece extends StatelessWidget {
  const _BoardPiece({
    required this.piece,
    required this.selected,
    required this.destination,
    required this.size,
  });

  final PieceType? piece;
  final bool selected;
  final bool destination;
  final double size;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: selected ? 1.18 : 1,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutBack,
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _PiecePainter(
            piece: piece,
            selected: selected,
            destination: destination,
          ),
        ),
      ),
    );
  }
}

class _PiecePainter extends CustomPainter {
  const _PiecePainter({
    required this.piece,
    required this.selected,
    required this.destination,
  });

  final PieceType? piece;
  final bool selected;
  final bool destination;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide * 0.43;

    if (destination) {
      canvas.drawCircle(
        center,
        radius * 0.62,
        Paint()
          ..color = AppColors.ember.withValues(alpha: 0.22)
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        center,
        radius * 0.72,
        Paint()
          ..color = AppColors.ember
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2,
      );
    }
    if (piece == null) return;

    if (selected) {
      canvas.drawCircle(
        center,
        radius * 1.23,
        Paint()
          ..shader =
              RadialGradient(
                colors: [
                  (piece == PieceType.tiger ? AppColors.tiger : AppColors.bone)
                      .withValues(alpha: 0.5),
                  Colors.transparent,
                ],
              ).createShader(
                Rect.fromCircle(center: center, radius: radius * 1.25),
              ),
      );
    }

    canvas.drawCircle(
      center + const Offset(0, 3),
      radius,
      Paint()..color = Colors.black.withValues(alpha: 0.65),
    );

    if (piece == PieceType.tiger) {
      _paintTiger(canvas, center, radius);
    } else {
      _paintGoat(canvas, center, radius);
    }
  }

  void _paintTiger(Canvas canvas, Offset center, double radius) {
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.35, -0.45),
          colors: [Color(0xFFFFB13B), AppColors.tiger, AppColors.tigerDark],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = AppColors.ember,
    );

    final stripe = Paint()
      ..color = const Color(0xFF2A120A)
      ..strokeWidth = radius * 0.13
      ..strokeCap = StrokeCap.round;
    for (final direction in [-1.0, 1.0]) {
      canvas.drawLine(
        center + Offset(direction * radius * 0.82, -radius * 0.48),
        center + Offset(direction * radius * 0.36, -radius * 0.22),
        stripe,
      );
      canvas.drawLine(
        center + Offset(direction * radius * 0.9, radius * 0.02),
        center + Offset(direction * radius * 0.43, radius * 0.04),
        stripe,
      );
      canvas.drawLine(
        center + Offset(direction * radius * 0.75, radius * 0.53),
        center + Offset(direction * radius * 0.36, radius * 0.3),
        stripe,
      );
    }

    final eyePaint = Paint()..color = const Color(0xFFFFF0B0);
    canvas.drawOval(
      Rect.fromCenter(
        center: center + Offset(-radius * 0.32, -radius * 0.12),
        width: radius * 0.32,
        height: radius * 0.17,
      ),
      eyePaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: center + Offset(radius * 0.32, -radius * 0.12),
        width: radius * 0.32,
        height: radius * 0.17,
      ),
      eyePaint,
    );
    final pupil = Paint()..color = const Color(0xFF160A05);
    canvas.drawCircle(
      center + Offset(-radius * 0.32, -radius * 0.12),
      radius * 0.055,
      pupil,
    );
    canvas.drawCircle(
      center + Offset(radius * 0.32, -radius * 0.12),
      radius * 0.055,
      pupil,
    );
  }

  void _paintGoat(Canvas canvas, Offset center, double radius) {
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.35, -0.45),
          colors: [Color(0xFFFFF8E8), AppColors.bone, Color(0xFFC9A975)],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..color = const Color(0xFF8D7045),
    );

    final horn = Paint()
      ..color = const Color(0xFF5F472D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.14
      ..strokeCap = StrokeCap.round;
    final leftHorn = Path()
      ..moveTo(center.dx - radius * 0.2, center.dy - radius * 0.25)
      ..quadraticBezierTo(
        center.dx - radius * 0.75,
        center.dy - radius * 0.62,
        center.dx - radius * 0.58,
        center.dy - radius * 0.86,
      );
    final rightHorn = Path()
      ..moveTo(center.dx + radius * 0.2, center.dy - radius * 0.25)
      ..quadraticBezierTo(
        center.dx + radius * 0.75,
        center.dy - radius * 0.62,
        center.dx + radius * 0.58,
        center.dy - radius * 0.86,
      );
    canvas.drawPath(leftHorn, horn);
    canvas.drawPath(rightHorn, horn);

    final face = Paint()..color = const Color(0xFF5F472D);
    canvas.drawOval(
      Rect.fromCenter(
        center: center + Offset(0, radius * 0.12),
        width: radius * 0.56,
        height: radius * 0.72,
      ),
      face,
    );
    final eye = Paint()..color = AppColors.bone;
    canvas.drawCircle(
      center + Offset(-radius * 0.14, -radius * 0.02),
      radius * 0.055,
      eye,
    );
    canvas.drawCircle(
      center + Offset(radius * 0.14, -radius * 0.02),
      radius * 0.055,
      eye,
    );
  }

  @override
  bool shouldRepaint(covariant _PiecePainter oldDelegate) {
    return oldDelegate.piece != piece ||
        oldDelegate.selected != selected ||
        oldDelegate.destination != destination;
  }
}
