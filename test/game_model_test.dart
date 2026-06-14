import 'package:aadu_puli_aattam/src/game/game_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Puli Meka board', () {
    test('matches the 23-point reference layout', () {
      expect(AaduPuliGame.nodes, hasLength(23));
      expect(AaduPuliGame.boardLines, hasLength(10));
      expect(AaduPuliGame.adjacency[0], unorderedEquals([2, 3, 4, 5]));
      expect(AaduPuliGame.adjacency[7], unorderedEquals([1, 8, 13]));
    });
  });

  group('setup and turns', () {
    test('player freely places all four tigers first', () {
      final game = AaduPuliGame();

      for (final node in [0, 6, 13, 22]) {
        expect(game.selectOrAct(node), isTrue);
      }

      expect(game.tigersPlaced, 4);
      expect(
        game.pieces.values.where((piece) => piece == PieceType.tiger),
        hasLength(4),
      );
      expect(game.turn, PlayerSide.goats);
      expect(game.isTigerSetup, isFalse);
    });

    test('goat enters after tiger setup and then gives tigers the turn', () {
      final game = _gameAfterTigerSetup();

      expect(game.placeGoat(1), isTrue);

      expect(game.goatsPlaced, 1);
      expect(game.pieceAt(1), PieceType.goat);
      expect(game.turn, PlayerSide.tigers);
      expect(game.legalActionsFor(1), isEmpty);
    });
  });

  group('movement and captures', () {
    test('tiger jumps over a goat on a printed straight line', () {
      final game = _captureScenario();
      final action = game
          .legalActionsFor(0)
          .singleWhere((action) => action.to == 8);

      expect(action.captured, 2);
      expect(game.applyAction(action), isTrue);
      expect(game.goatsCaptured, 1);
      expect(game.pieceAt(2), isNull);
      expect(game.pieceAt(8), PieceType.tiger);
    });

    test('tigers win on their sixth capture', () {
      final game = _captureScenario()..goatsCaptured = 5;
      final action = game
          .legalActionsFor(0)
          .singleWhere((candidate) => candidate.to == 8);

      game.applyAction(action);

      expect(game.winner, GameWinner.tigers);
    });

    test('goats win when all tigers are trapped', () {
      final game = AaduPuliGame();
      const tigerNodes = {0, 1, 6, 19};
      const openNodes = {15, 16};
      game.pieces.clear();
      for (final node in AaduPuliGame.nodes) {
        if (openNodes.contains(node.id)) continue;
        game.pieces[node.id] = tigerNodes.contains(node.id)
            ? PieceType.tiger
            : PieceType.goat;
      }
      game
        ..tigersPlaced = 4
        ..goatsPlaced = 17
        ..turn = PlayerSide.goats;

      expect(game.placeGoat(16), isTrue);
      expect(game.winner, GameWinner.goats);
    });

    test('undo removes the last deployed tiger', () {
      final game = AaduPuliGame()..placeTiger(0);

      game.undo(includeAiTurn: false);

      expect(game.pieceAt(0), isNull);
      expect(game.tigersPlaced, 0);
      expect(game.turn, PlayerSide.tigers);
    });
  });

  test('goat AI chooses an empty board point', () {
    final game = _gameAfterTigerSetup();

    final choice = game.chooseGoatAiPlacement();

    expect(game.pieceAt(choice), isNull);
    expect(AaduPuliGame.nodes.map((node) => node.id), contains(choice));
  });
}

AaduPuliGame _gameAfterTigerSetup() {
  final game = AaduPuliGame();
  for (final node in [0, 6, 13, 22]) {
    game.placeTiger(node);
  }
  return game;
}

AaduPuliGame _captureScenario() {
  final game = AaduPuliGame();
  game.pieces
    ..clear()
    ..addAll({
      0: PieceType.tiger,
      2: PieceType.goat,
      6: PieceType.tiger,
      13: PieceType.tiger,
      22: PieceType.tiger,
    });
  game
    ..tigersPlaced = 4
    ..goatsPlaced = 1
    ..turn = PlayerSide.tigers;
  return game;
}
