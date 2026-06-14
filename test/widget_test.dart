import 'package:aadu_puli_aattam/src/app.dart';
import 'package:aadu_puli_aattam/src/game/game_model.dart';
import 'package:aadu_puli_aattam/src/game/game_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('home screen exposes both game modes', (tester) async {
    await tester.pumpWidget(const AaduPuliApp());

    expect(find.text('AADU\nPULI AATTAM'), findsOneWidget);
    expect(find.text('Lead the Tigers'), findsOneWidget);
    expect(find.text('Pass & Play'), findsOneWidget);
  });

  testWidgets('home screen remains usable on a compact phone', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const AaduPuliApp());
    await tester.pumpAndSettle();

    expect(find.text('Lead the Tigers'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('game board fits a compact portrait screen', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(home: GameScreen(mode: GameMode.passAndPlay)),
    );
    await tester.pumpAndSettle();

    expect(find.text('TIGERS TURN'), findsOneWidget);
    expect(find.text('Restart'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
