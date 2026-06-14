enum GameMode { vsGoatAi, passAndPlay }

enum PlayerSide { goats, tigers }

enum PieceType { goat, tiger }

enum GameWinner { goats, tigers, draw }

class BoardNode {
  const BoardNode({required this.id, required this.x, required this.y});

  final int id;
  final double x;
  final double y;
}

class GameAction {
  const GameAction({required this.from, required this.to, this.captured});

  final int from;
  final int to;
  final int? captured;

  bool get isCapture => captured != null;
}

class _JumpPath {
  const _JumpPath(this.middle, this.target);

  final int middle;
  final int target;
}

class _GameSnapshot {
  const _GameSnapshot({
    required this.pieces,
    required this.turn,
    required this.tigersPlaced,
    required this.goatsPlaced,
    required this.goatsCaptured,
    required this.winner,
    required this.quietTurns,
  });

  final Map<int, PieceType> pieces;
  final PlayerSide turn;
  final int tigersPlaced;
  final int goatsPlaced;
  final int goatsCaptured;
  final GameWinner? winner;
  final int quietTurns;
}

class AaduPuliGame {
  AaduPuliGame() {
    reset();
  }

  static const totalTigers = 4;
  static const totalGoats = 18;
  static const capturesToWin = 6;
  static const quietTurnsToDraw = 80;

  static final List<BoardNode> nodes = _buildNodes();
  static final List<List<int>> boardLines = _buildBoardLines();
  static final Map<int, Set<int>> adjacency = _buildAdjacency();
  static final Map<int, List<_JumpPath>> _jumpPaths = _buildJumpPaths();

  final Map<int, PieceType> pieces = {};
  final List<_GameSnapshot> _history = [];

  PlayerSide turn = PlayerSide.tigers;
  int tigersPlaced = 0;
  int goatsPlaced = 0;
  int goatsCaptured = 0;
  int? selectedNode;
  int? lastFrom;
  int? lastTo;
  int? lastCaptured;
  int quietTurns = 0;
  GameWinner? winner;

  int get tigersRemainingToPlace => totalTigers - tigersPlaced;
  int get goatsRemainingToPlace => totalGoats - goatsPlaced;
  int get goatsOnBoard =>
      pieces.values.where((piece) => piece == PieceType.goat).length;
  bool get isTigerSetup => tigersPlaced < totalTigers;
  bool get isGoatPlacement => !isTigerSetup && goatsPlaced < totalGoats;
  bool get canUndo => _history.isNotEmpty;

  void reset() {
    pieces.clear();
    turn = PlayerSide.tigers;
    tigersPlaced = 0;
    goatsPlaced = 0;
    goatsCaptured = 0;
    selectedNode = null;
    lastFrom = null;
    lastTo = null;
    lastCaptured = null;
    quietTurns = 0;
    winner = null;
    _history.clear();
  }

  PieceType? pieceAt(int node) => pieces[node];

  bool selectOrAct(int node) {
    if (winner != null) return false;

    if (isTigerSetup) {
      return placeTiger(node);
    }

    if (turn == PlayerSide.goats && isGoatPlacement) {
      return placeGoat(node);
    }

    final ownPiece = turn == PlayerSide.goats
        ? PieceType.goat
        : PieceType.tiger;
    if (pieces[node] == ownPiece) {
      selectedNode = selectedNode == node ? null : node;
      return true;
    }

    final from = selectedNode;
    if (from == null || pieces.containsKey(node)) return false;
    final action = legalActionsFor(
      from,
    ).where((move) => move.to == node).firstOrNull;
    if (action == null) return false;
    return applyAction(action);
  }

  bool placeTiger(int node) {
    if (!isTigerSetup || pieces.containsKey(node)) return false;
    _saveSnapshot();
    pieces[node] = PieceType.tiger;
    tigersPlaced++;
    selectedNode = null;
    lastFrom = null;
    lastTo = node;
    lastCaptured = null;
    if (!isTigerSetup) turn = PlayerSide.goats;
    return true;
  }

  bool placeGoat(int node) {
    if (turn != PlayerSide.goats ||
        !isGoatPlacement ||
        pieces.containsKey(node)) {
      return false;
    }
    _saveSnapshot();
    pieces[node] = PieceType.goat;
    goatsPlaced++;
    selectedNode = null;
    lastFrom = null;
    lastTo = node;
    lastCaptured = null;
    quietTurns++;
    _finishTurn();
    return true;
  }

  bool applyAction(GameAction action) {
    if (winner != null || isTigerSetup) return false;
    final piece = pieces[action.from];
    final expected = turn == PlayerSide.goats
        ? PieceType.goat
        : PieceType.tiger;
    if (piece != expected || pieces.containsKey(action.to)) return false;
    if (!legalActionsFor(action.from).any(
      (candidate) =>
          candidate.to == action.to && candidate.captured == action.captured,
    )) {
      return false;
    }

    _saveSnapshot();
    pieces
      ..remove(action.from)
      ..[action.to] = piece!;
    if (action.captured case final captured?) {
      pieces.remove(captured);
      goatsCaptured++;
      quietTurns = 0;
    } else {
      quietTurns++;
    }
    selectedNode = null;
    lastFrom = action.from;
    lastTo = action.to;
    lastCaptured = action.captured;
    _finishTurn();
    return true;
  }

  List<GameAction> legalActionsFor(int node) {
    final piece = pieces[node];
    if (piece == null || isTigerSetup) return const [];
    if (piece == PieceType.goat && isGoatPlacement) return const [];

    final moves = <GameAction>[];
    for (final destination in adjacency[node]!) {
      if (!pieces.containsKey(destination)) {
        moves.add(GameAction(from: node, to: destination));
      }
    }

    if (piece == PieceType.tiger) {
      for (final jump in _jumpPaths[node]!) {
        if (pieces[jump.middle] == PieceType.goat &&
            !pieces.containsKey(jump.target)) {
          moves.add(
            GameAction(from: node, to: jump.target, captured: jump.middle),
          );
        }
      }
    }
    return moves;
  }

  List<GameAction> get legalTigerActions {
    if (isTigerSetup) return const [];
    return pieces.entries
        .where((entry) => entry.value == PieceType.tiger)
        .expand((entry) => legalActionsFor(entry.key))
        .toList(growable: false);
  }

  Set<int> get highlightedDestinations {
    final selected = selectedNode;
    if (selected == null) return const {};
    return legalActionsFor(selected).map((action) => action.to).toSet();
  }

  int chooseGoatAiPlacement() {
    final empty = nodes
        .where((node) => !pieces.containsKey(node.id))
        .map((node) => node.id)
        .toList();
    if (empty.isEmpty) throw StateError('No empty point for a goat.');
    empty.sort((a, b) => _scoreGoatPoint(b).compareTo(_scoreGoatPoint(a)));
    return empty.first;
  }

  GameAction chooseGoatAiAction() {
    final actions = pieces.entries
        .where((entry) => entry.value == PieceType.goat)
        .expand((entry) => legalActionsFor(entry.key))
        .toList();
    if (actions.isEmpty) {
      throw StateError('Goat AI has no legal action.');
    }
    actions.sort((a, b) {
      final aScore = _scoreGoatMove(a);
      final bScore = _scoreGoatMove(b);
      return bScore.compareTo(aScore);
    });
    return actions.first;
  }

  void undo({required bool includeAiTurn}) {
    if (_history.isEmpty) return;
    _restore(_history.removeLast());
    if (includeAiTurn && turn == PlayerSide.goats && _history.isNotEmpty) {
      _restore(_history.removeLast());
    }
  }

  int _scoreGoatPoint(int node) {
    var score = adjacency[node]!.length * 2;
    for (final neighbor in adjacency[node]!) {
      if (pieces[neighbor] == PieceType.tiger) score += 18;
    }
    for (final entry in _jumpPaths.entries) {
      for (final jump in entry.value) {
        if (jump.middle == node &&
            pieces[entry.key] == PieceType.tiger &&
            !pieces.containsKey(jump.target)) {
          score -= 25;
        }
        if (jump.target == node && pieces[entry.key] == PieceType.tiger) {
          score += 12;
        }
      }
    }
    score += (node * 11 + goatsPlaced * 7) % 5;
    return score;
  }

  int _scoreGoatMove(GameAction action) {
    final before = legalTigerActions.length;
    final goat = pieces.remove(action.from);
    pieces[action.to] = goat!;
    final after = legalTigerActions.length;
    final pointScore = _scoreGoatPoint(action.to);
    pieces
      ..remove(action.to)
      ..[action.from] = goat;
    return ((before - after) * 20) + pointScore;
  }

  void _finishTurn() {
    if (goatsCaptured >= capturesToWin) {
      winner = GameWinner.tigers;
      return;
    }
    if (quietTurns >= quietTurnsToDraw) {
      winner = GameWinner.draw;
      return;
    }
    if (turn == PlayerSide.goats && legalTigerActions.isEmpty) {
      winner = GameWinner.goats;
      return;
    }
    turn = turn == PlayerSide.goats ? PlayerSide.tigers : PlayerSide.goats;
  }

  void _saveSnapshot() {
    _history.add(
      _GameSnapshot(
        pieces: Map.of(pieces),
        turn: turn,
        tigersPlaced: tigersPlaced,
        goatsPlaced: goatsPlaced,
        goatsCaptured: goatsCaptured,
        winner: winner,
        quietTurns: quietTurns,
      ),
    );
  }

  void _restore(_GameSnapshot snapshot) {
    pieces
      ..clear()
      ..addAll(snapshot.pieces);
    turn = snapshot.turn;
    tigersPlaced = snapshot.tigersPlaced;
    goatsPlaced = snapshot.goatsPlaced;
    goatsCaptured = snapshot.goatsCaptured;
    winner = snapshot.winner;
    quietTurns = snapshot.quietTurns;
    selectedNode = null;
    lastFrom = null;
    lastTo = null;
    lastCaptured = null;
  }

  static List<BoardNode> _buildNodes() {
    const coordinates = [
      (0.50, 0.06),
      (0.05, 0.30),
      (0.29, 0.30),
      (0.43, 0.30),
      (0.57, 0.30),
      (0.71, 0.30),
      (0.95, 0.30),
      (0.05, 0.47),
      (0.21, 0.47),
      (0.40, 0.47),
      (0.60, 0.47),
      (0.79, 0.47),
      (0.95, 0.47),
      (0.05, 0.64),
      (0.13, 0.64),
      (0.36, 0.64),
      (0.64, 0.64),
      (0.87, 0.64),
      (0.95, 0.64),
      (0.05, 0.92),
      (0.36, 0.92),
      (0.64, 0.92),
      (0.95, 0.92),
    ];
    return List.unmodifiable([
      for (var id = 0; id < coordinates.length; id++)
        BoardNode(id: id, x: coordinates[id].$1, y: coordinates[id].$2),
    ]);
  }

  static List<List<int>> _buildBoardLines() {
    return const [
      [1, 2, 3, 4, 5, 6],
      [7, 8, 9, 10, 11, 12],
      [13, 14, 15, 16, 17, 18],
      [19, 20, 21, 22],
      [1, 7, 13],
      [6, 12, 18],
      [0, 2, 8, 14, 19],
      [0, 3, 9, 15, 20],
      [0, 4, 10, 16, 21],
      [0, 5, 11, 17, 22],
    ];
  }

  static Map<int, Set<int>> _buildAdjacency() {
    final result = <int, Set<int>>{for (final node in nodes) node.id: <int>{}};
    for (final line in boardLines) {
      for (var index = 0; index < line.length - 1; index++) {
        result[line[index]]!.add(line[index + 1]);
        result[line[index + 1]]!.add(line[index]);
      }
    }
    return Map.unmodifiable({
      for (final entry in result.entries)
        entry.key: Set.unmodifiable(entry.value),
    });
  }

  static Map<int, List<_JumpPath>> _buildJumpPaths() {
    final result = <int, List<_JumpPath>>{
      for (final node in nodes) node.id: <_JumpPath>[],
    };
    for (final line in boardLines) {
      for (var index = 0; index < line.length - 2; index++) {
        final first = line[index];
        final middle = line[index + 1];
        final last = line[index + 2];
        result[first]!.add(_JumpPath(middle, last));
        result[last]!.add(_JumpPath(middle, first));
      }
    }
    return Map<int, List<_JumpPath>>.unmodifiable({
      for (final entry in result.entries)
        entry.key: List<_JumpPath>.unmodifiable(entry.value),
    });
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
