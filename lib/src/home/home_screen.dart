import 'package:flutter/material.dart';

import '../game/game_model.dart';
import '../game/game_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/forest_backdrop.dart';
import '../widgets/rules_sheet.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ForestBackdrop(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxHeight < 720;
              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(24, compact ? 16 : 32, 24, 28),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 48,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        children: [
                          _HeroMark(compact: compact),
                          SizedBox(height: compact ? 20 : 38),
                          const Text(
                            'AADU\nPULI AATTAM',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.bone,
                              fontSize: 42,
                              height: 0.88,
                              letterSpacing: 2.8,
                              fontWeight: FontWeight.w900,
                              shadows: [
                                Shadow(
                                  color: Colors.black87,
                                  blurRadius: 20,
                                  offset: Offset(0, 6),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'THE HUNT BEGINS',
                            style: TextStyle(
                              color: AppColors.ember.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              letterSpacing: 5,
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 34),
                        child: Column(
                          children: [
                            _MenuButton(
                              icon: Icons.local_fire_department_rounded,
                              label: 'Lead the Tigers',
                              subtitle: 'Place 4 tigers and hunt the herd',
                              primary: true,
                              onPressed: () =>
                                  _openGame(context, GameMode.vsGoatAi),
                            ),
                            const SizedBox(height: 12),
                            _MenuButton(
                              icon: Icons.people_alt_rounded,
                              label: 'Pass & Play',
                              subtitle: 'Two players, one battlefield',
                              onPressed: () =>
                                  _openGame(context, GameMode.passAndPlay),
                            ),
                            const SizedBox(height: 12),
                            TextButton.icon(
                              onPressed: () => showRulesSheet(context),
                              icon: const Icon(
                                Icons.menu_book_rounded,
                                size: 19,
                              ),
                              label: const Text('Learn the village rules'),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.parchment,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _openGame(BuildContext context, GameMode mode) {
    Navigator.of(context).pushNamed(GameScreen.routeName, arguments: mode);
  }
}

class _HeroMark extends StatelessWidget {
  const _HeroMark({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 150.0 : 190.0;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _HeroMarkPainter()),
    );
  }
}

class _HeroMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [AppColors.tiger.withValues(alpha: 0.35), Colors.transparent],
      ).createShader(Rect.fromCircle(center: center, radius: size.width / 2));
    canvas.drawCircle(center, size.width / 2, glow);

    final triangle = Path()
      ..moveTo(center.dx, size.height * 0.1)
      ..lineTo(size.width * 0.14, size.height * 0.84)
      ..lineTo(size.width * 0.86, size.height * 0.84)
      ..close();
    canvas.drawPath(
      triangle,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = AppColors.ember.withValues(alpha: 0.8),
    );

    final eye = Path()
      ..moveTo(size.width * 0.23, center.dy)
      ..quadraticBezierTo(
        center.dx,
        size.height * 0.3,
        size.width * 0.77,
        center.dy,
      )
      ..quadraticBezierTo(
        center.dx,
        size.height * 0.7,
        size.width * 0.23,
        center.dy,
      )
      ..close();
    canvas.drawPath(eye, Paint()..color = AppColors.tiger);
    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: size.width * 0.13,
        height: size.height * 0.34,
      ),
      Paint()..color = AppColors.night,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: size.width * 0.035,
        height: size.height * 0.22,
      ),
      Paint()..color = AppColors.ember,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onPressed,
    this.primary = false,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onPressed;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 430),
      child: Material(
        color: primary
            ? AppColors.tiger
            : AppColors.stone.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: primary
                    ? AppColors.ember.withValues(alpha: 0.7)
                    : Colors.white.withValues(alpha: 0.09),
              ),
              boxShadow: [
                BoxShadow(
                  color: (primary ? AppColors.tiger : Colors.black).withValues(
                    alpha: 0.28,
                  ),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 30,
                  color: primary ? AppColors.night : AppColors.ember,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          color: primary ? AppColors.night : AppColors.bone,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: primary
                              ? AppColors.night.withValues(alpha: 0.7)
                              : AppColors.parchment.withValues(alpha: 0.68),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: primary ? AppColors.night : AppColors.parchment,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
