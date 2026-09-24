// test/features/bastions_page/presentation/widgets/combat_arena_test.dart
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maura_bastion_system/data/enums/defender_type.dart';
import 'package:maura_bastion_system/data/models/events/bastion_attack.dart';
import 'package:maura_bastion_system/data/models/events/chart_tier.dart';
import 'package:maura_bastion_system/data/models/events/dispatch.dart';
import 'package:maura_bastion_system/data/models/npcs/defender.dart';
import 'package:maura_bastion_system/features/bastions_page/presentation/widgets/animated_die.dart';
import 'package:maura_bastion_system/features/bastions_page/presentation/widgets/combat_arena.dart';

const _enemy = BastionEnemy(
  id: 'e',
  name: 'Bandits',
  description: 'Ragged knife-men.',
  tier: ChartTier.basic,
);

BastionCombatResult _result({int enemyCount = 2}) => resolveBastionCombat(
      defenders: [
        Defender(
          id: 'd1',
          name: 'Aldric',
          type: DefenderType.knight,
          bastionId: 'b1',
        ),
      ],
      enemy: _enemy,
      enemyCount: enemyCount,
      config: const BastionDefenseConfig(
        deathThreshold: 1,
        advantage: false,
        bastionDefenderDice: UnitDice(1, 6),
      ),
      rng: Random(1),
    );

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('shows the defender roster and one enemy token per enemy',
      (tester) async {
    await tester.pumpWidget(_wrap(CombatArena(
      result: _result(),
      revealedRound: -1,
      rolling: false,
    )));
    await tester.pumpAndSettle();

    expect(find.text('Aldric'), findsOneWidget);
    expect(find.text('Defenders'), findsOneWidget);
    expect(find.text('Enemies'), findsOneWidget);
    expect(find.byIcon(Icons.dangerous), findsNWidgets(2));
    expect(find.byType(AnimatedDie), findsNothing);
  });

  testWidgets('revealing a round shows dice and drops killed enemies',
      (tester) async {
    final result = _result();
    await tester.pumpWidget(_wrap(CombatArena(
      result: result,
      revealedRound: 0,
      rolling: false,
    )));
    await tester.pumpAndSettle();

    expect(find.byType(AnimatedDie), findsOneWidget);
    expect(
      find.byIcon(Icons.dangerous),
      findsNWidgets(result.startingEnemies - result.rounds[0].enemiesKilled),
    );
  });

  testWidgets('the settled die face equals the recorded roll', (tester) async {
    final result = _result();
    await tester.pumpWidget(_wrap(CombatArena(
      result: result,
      revealedRound: 0,
      rolling: false,
    )));
    await tester.pumpAndSettle();

    final text = tester.widget<Text>(find.descendant(
      of: find.byType(AnimatedDie),
      matching: find.byType(Text),
    ));
    expect(int.parse(text.data!), result.rounds[0].rolls[0].rolls[0]);
  });

  testWidgets('advantage shows one die per roll value', (tester) async {
    final result = resolveBastionCombat(
      defenders: [
        Defender(
          id: 'd1',
          name: 'Aldric',
          type: DefenderType.knight,
          bastionId: 'b1',
        ),
      ],
      enemy: _enemy,
      enemyCount: 2,
      config: const BastionDefenseConfig(
        deathThreshold: 1,
        advantage: true,
        bastionDefenderDice: UnitDice(1, 6),
      ),
      rng: Random(1),
    );
    await tester.pumpWidget(_wrap(CombatArena(
      result: result,
      revealedRound: 0,
      rolling: false,
    )));
    await tester.pumpAndSettle();

    final expected = result.rounds[0].rolls
        .fold<int>(0, (sum, roll) => sum + roll.rolls.length);
    expect(expected, 2);
    expect(find.byType(AnimatedDie), findsNWidgets(expected));
  });
}
