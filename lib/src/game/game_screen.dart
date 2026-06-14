import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import '../widgets/forest_backdrop.dart';
import '../widgets/game_board.dart';
import '../widgets/rules_sheet.dart';
import 'game_model.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.mode});

  static const routeName = '/game';

  final GameMode mode;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _impactController;
  late AaduPuliGame _game;
  Timer? _aiTimer;
  bool _aiThinking = false;
  bool _winnerShown = false;

  bool get _isAiMode => widget.mode == GameMode.vsGoatAi;

  @override
  void initState() {
    super.initState();
    _game = AaduPuliGame();
    _impactController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
  }

  @override
  void dispose() {
    _aiTimer?.cancel();
    _impactController.dispose();
    super.dispose();
  }

  void _handleNodeTap(int node) {
    if (_aiThinking || _game.winner != null) return;
    if (_isAiMode && !_game.isTigerSetup && _game.turn == PlayerSide.goats) {
      return;
    }

    final captureCount = _game.goatsCaptured;
    final changed = _game.selectOrAct(node);
    if (!changed) {
      HapticFeedback.selectionClick();
      return;
    }
    setState(() {});
    if (_game.goatsCaptured > captureCount) _playImpact();
    _afterTurn();
  }

  void _afterTurn() {
    if (_game.winner != null) {
      _showWinnerSoon();
      return;
    }
    if (_isAiMode && !_game.isTigerSetup && _game.turn == PlayerSide.goats) {
      _scheduleGoatAi();
    }
  }

  void _scheduleGoatAi() {
    _aiTimer?.cancel();
    setState(() => _aiThinking = true);
    _aiTimer = Timer(const Duration(milliseconds: 520), () async {
      if (!mounted || _game.winner != null) return;
      if (_game.isGoatPlacement) {
        final destination = _game.chooseGoatAiPlacement();
        setState(() {
          _game.placeGoat(destination);
          _aiThinking = false;
        });
      } else {
        final action = _game.chooseGoatAiAction();
        setState(() => _game.selectedNode = action.from);
        await Future<void>.delayed(const Duration(milliseconds: 320));
        if (!mounted) return;
        setState(() {
          _game.applyAction(action);
          _aiThinking = false;
        });
      }
      _afterTurn();
    });
  }

  void _playImpact() {
    HapticFeedback.heavyImpact();
    _impactController.forward(from: 0);
  }

  void _undo() {
    if (_aiThinking || !_game.canUndo) return;
    _aiTimer?.cancel();
    setState(() {
      _aiThinking = false;
      _winnerShown = false;
      _game.undo(includeAiTurn: _isAiMode);
    });
  }

  void _restart() {
    _aiTimer?.cancel();
    setState(() {
      _aiThinking = false;
      _winnerShown = false;
      _game = AaduPuliGame();
    });
  }

  Future<void> _showWinnerSoon() async {
    if (_winnerShown) return;
    _winnerShown = true;
    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;
    final winner = _game.winner!;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _VictoryDialog(
        winner: winner,
        onRematch: () {
          Navigator.of(context).pop();
          _restart();
        },
        onHome: () {
          Navigator.of(context)
            ..pop()
            ..pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final turnLabel = _game.turn == PlayerSide.goats ? 'GOATS' : 'TIGERS';
    final instruction = _instructionText();

    return Scaffold(
      body: ForestBackdrop(
        child: SafeArea(
          child: Column(
            children: [
              _GameHeader(
                mode: widget.mode,
                onBack: () => Navigator.of(context).maybePop(),
                onRules: () => showRulesSheet(context),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 8),
                child: _BattleStatus(
                  turnLabel: turnLabel,
                  instruction: instruction,
                  aiThinking: _aiThinking,
                  tigersPlaced: _game.tigersPlaced,
                  goatsPlaced: _game.goatsPlaced,
                  goatsCaptured: _game.goatsCaptured,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: AnimatedBuilder(
                    animation: _impactController,
                    builder: (context, child) {
                      final t = _impactController.value;
                      final shake = t < 0.65
                          ? (1 - t) * 7 * ((t * 45).round().isEven ? 1 : -1)
                          : 0.0;
                      return Transform.translate(
                        offset: Offset(shake, 0),
                        child: child,
                      );
                    },
                    child: GameBoard(
                      game: _game,
                      onNodeTap: _handleNodeTap,
                      impactAnimation: _impactController,
                    ),
                  ),
                ),
              ),
              _BottomControls(
                canUndo: _game.canUndo && !_aiThinking,
                onUndo: _undo,
                onRestart: _restart,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _instructionText() {
    if (_game.winner != null) return 'The battle is over';
    if (_aiThinking) return 'The herd is closing in...';
    if (_game.isTigerSetup) {
      return 'Choose a point • ${_game.tigersRemainingToPlace} tigers waiting';
    }
    if (_game.turn == PlayerSide.goats) {
      if (_game.isGoatPlacement) {
        return 'Place a goat • ${_game.goatsRemainingToPlace} waiting';
      }
      return _game.selectedNode == null
          ? 'Choose a goat to move'
          : 'Choose a glowing destination';
    }
    return _game.selectedNode == null
        ? 'Choose a tiger to move'
        : 'Move or leap across a goat';
  }
}

class _GameHeader extends StatelessWidget {
  const _GameHeader({
    required this.mode,
    required this.onBack,
    required this.onRules,
  });

  final GameMode mode;
  final VoidCallback onBack;
  final VoidCallback onRules;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Back',
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AADU PULI AATTAM',
                  style: TextStyle(
                    color: AppColors.bone,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.3,
                    fontSize: 16,
                  ),
                ),
                Text(
                  mode == GameMode.vsGoatAi
                      ? 'TIGERS VS GOAT AI'
                      : 'PASS & PLAY',
                  style: TextStyle(
                    color: AppColors.ember.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.6,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Rules',
            onPressed: onRules,
            icon: const Icon(Icons.menu_book_rounded),
          ),
        ],
      ),
    );
  }
}

class _BattleStatus extends StatelessWidget {
  const _BattleStatus({
    required this.turnLabel,
    required this.instruction,
    required this.aiThinking,
    required this.tigersPlaced,
    required this.goatsPlaced,
    required this.goatsCaptured,
  });

  final String turnLabel;
  final String instruction;
  final bool aiThinking;
  final int tigersPlaced;
  final int goatsPlaced;
  final int goatsCaptured;

  @override
  Widget build(BuildContext context) {
    final tigerTurn = turnLabel == 'TIGERS';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.stone.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            width: 10,
            height: 46,
            decoration: BoxDecoration(
              color: tigerTurn ? AppColors.tiger : AppColors.bone,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: (tigerTurn ? AppColors.tiger : AppColors.bone)
                      .withValues(alpha: 0.35),
                  blurRadius: 12,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  aiThinking ? 'GOATS ARE MOVING' : '$turnLabel TURN',
                  style: TextStyle(
                    color: tigerTurn ? AppColors.tiger : AppColors.bone,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 3),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    instruction,
                    key: ValueKey(instruction),
                    style: TextStyle(
                      color: AppColors.parchment.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 125),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                children: [
                  _TigerCounter(placed: tigersPlaced),
                  const SizedBox(width: 10),
                  _Counter(
                    value: '$goatsPlaced/18',
                    label: 'HERD',
                    color: AppColors.bone,
                  ),
                  const SizedBox(width: 10),
                  _Counter(
                    value: '$goatsCaptured/6',
                    label: 'TAKEN',
                    color: AppColors.tiger,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Counter extends StatelessWidget {
  const _Counter({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: AppColors.parchment.withValues(alpha: 0.48),
            fontSize: 8,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}

class _TigerCounter extends StatelessWidget {
  const _TigerCounter({required this.placed});

  final int placed;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var index = 0; index < AaduPuliGame.totalTigers; index++)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: index < placed
                      ? AppColors.tiger
                      : AppColors.tiger.withValues(alpha: 0.2),
                  border: Border.all(
                    color: AppColors.ember.withValues(alpha: 0.55),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'TIGERS',
          style: TextStyle(
            color: AppColors.parchment.withValues(alpha: 0.48),
            fontSize: 8,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}

class _BottomControls extends StatelessWidget {
  const _BottomControls({
    required this.canUndo,
    required this.onUndo,
    required this.onRestart,
  });

  final bool canUndo;
  final VoidCallback onUndo;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: _ControlButton(
              icon: Icons.undo_rounded,
              label: 'Undo',
              enabled: canUndo,
              onPressed: onUndo,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _ControlButton(
              icon: Icons.refresh_rounded,
              label: 'Restart',
              onPressed: onRestart,
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: enabled ? onPressed : null,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.parchment,
        disabledForegroundColor: Colors.white24,
        side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

class _VictoryDialog extends StatelessWidget {
  const _VictoryDialog({
    required this.winner,
    required this.onRematch,
    required this.onHome,
  });

  final GameWinner winner;
  final VoidCallback onRematch;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    final tigerVictory = winner == GameWinner.tigers;
    final title = switch (winner) {
      GameWinner.tigers => 'THE TIGERS FEAST',
      GameWinner.goats => 'THE HERD PREVAILS',
      GameWinner.draw => 'THE FOREST RESTS',
    };
    final body = switch (winner) {
      GameWinner.tigers =>
        'Six goats have fallen. The hunt belongs to the tigers.',
      GameWinner.goats =>
        'Every tiger is trapped. Unity has defeated strength.',
      GameWinner.draw => 'Neither side yielded after a long battle.',
    };

    return AlertDialog(
      backgroundColor: const Color(0xFF12271D),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(26),
        side: BorderSide(
          color: tigerVictory ? AppColors.tiger : AppColors.bone,
          width: 1.5,
        ),
      ),
      title: Text(
        title,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: tigerVictory ? AppColors.tiger : AppColors.bone,
          fontSize: 22,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.1,
        ),
      ),
      content: Text(
        body,
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.parchment, height: 1.45),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(onPressed: onHome, child: const Text('Home')),
        FilledButton(onPressed: onRematch, child: const Text('Rematch')),
      ],
    );
  }
}
