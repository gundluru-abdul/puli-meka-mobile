import 'package:flutter/material.dart';

import 'game/game_model.dart';
import 'game/game_screen.dart';
import 'home/home_screen.dart';
import 'theme/app_theme.dart';

class AaduPuliApp extends StatelessWidget {
  const AaduPuliApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aadu Puli Aattam',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const HomeScreen(),
      onGenerateRoute: (settings) {
        if (settings.name == GameScreen.routeName) {
          final mode = settings.arguments as GameMode? ?? GameMode.vsGoatAi;
          return PageRouteBuilder<void>(
            pageBuilder: (context, animation, secondaryAnimation) =>
                GameScreen(mode: mode),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(
                    opacity: CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                    child: child,
                  );
                },
          );
        }
        return null;
      },
    );
  }
}
