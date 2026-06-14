import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

Future<void> showRulesSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const _RulesSheet(),
  );
}

class _RulesSheet extends StatelessWidget {
  const _RulesSheet();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      minChildSize: 0.5,
      maxChildSize: 0.93,
      expand: false,
      builder: (context, controller) {
        return DecoratedBox(
          decoration: const BoxDecoration(
            color: Color(0xFF12271D),
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            border: Border(top: BorderSide(color: AppColors.tiger, width: 2)),
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 36),
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Village Rules',
                style: TextStyle(
                  color: AppColors.bone,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'A playable 4-tiger, 18-goat regional variant.',
                style: TextStyle(
                  color: AppColors.parchment.withValues(alpha: 0.68),
                ),
              ),
              const SizedBox(height: 24),
              const _Rule(
                number: '01',
                title: 'Deploy four tigers',
                body:
                    'The tiger player chooses any four empty intersections as starting points. All four tigers enter before the herd.',
              ),
              const _Rule(
                number: '02',
                title: 'Bring in the herd',
                body:
                    'Goats enter one at a time on empty intersections. After each goat enters, a tiger may move. Goats cannot move until all 18 have entered.',
              ),
              const _Rule(
                number: '03',
                title: 'Move and strike',
                body:
                    'Pieces follow the printed lines. A tiger captures by jumping over one adjacent goat into the empty point directly behind it.',
              ),
              const _Rule(
                number: '04',
                title: 'Claim victory',
                body:
                    'Goats win by trapping all four tigers. Tigers win after capturing six goats. 80 turns without a capture ends in a draw.',
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.ember.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.ember.withValues(alpha: 0.22),
                  ),
                ),
                child: const Text(
                  'The board follows the photographed Puli Meka layout: four rays, three horizontal ranks, two side rails, and a four-point base.',
                  style: TextStyle(color: AppColors.parchment, height: 1.4),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Rule extends StatelessWidget {
  const _Rule({required this.number, required this.title, required this.body});

  final String number;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            number,
            style: const TextStyle(
              color: AppColors.tiger,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.bone,
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  body,
                  style: TextStyle(
                    color: AppColors.parchment.withValues(alpha: 0.75),
                    height: 1.42,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
