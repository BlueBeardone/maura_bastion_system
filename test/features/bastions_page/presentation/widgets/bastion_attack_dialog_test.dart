// test/features/bastions_page/presentation/widgets/bastion_attack_dialog_test.dart
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maura_bastion_system/data/enums/defender_type.dart';
import 'package:maura_bastion_system/data/models/events/bastion_attack.dart';
import 'package:maura_bastion_system/data/models/events/chart_tier.dart';
import 'package:maura_bastion_system/data/models/events/dispatch.dart';
import 'package:maura_bastion_system/data/models/npcs/defender.dart';
import 'package:maura_bastion_system/features/bastions_page/presentation/widgets/animated_die.dart';
import 'package:maura_bastion_system/features/bastions_page/presentation/widgets/bastion_attack_dialog.dart';

const _enemy = BastionEnemy(
  id: 'e',
  name: 'Bandit Cutthroats',
  description: 'Ragged knife-men.',
  tier: ChartTier.basic,
);

BastionCombatResult _winResult() => resolveBastionCombat(
      defenders: [
        Defender(
          id: 'd1',
          name: 'Aldric',
          type: DefenderType.knight,
          bastionId: 'b1',
        ),
      ],
      enemy: _enemy,
      enemyCount: 1,
      config: const BastionDefenseConfig(
        deathThreshold: 1,
        advantage: false,
        bastionDefenderDice: UnitDice(1, 6),
      ),
      rng: Random(1),
    );

BastionCombatResult _lossResult() => resolveBastionCombat(
      defenders: const [],
      enemy: _enemy,
      enemyCount: 2,
      config: const BastionDefenseConfig(
        deathThreshold: 4,
        advantage: false,
        bastionDefenderDice: UnitDice(1, 6),
      ),
      rng: Random(1),
    );

Widget _harness(
  BastionCombatResult result, {
  String? destroyed,
}) {
  return MaterialApp(
    home: Scaffold(
      body: BastionAttackDialog(
        enemy: _enemy,
        enemyCount: result.startingEnemies,
        result: result,
        destroyedFacilityName: destroyed,
      ),
    ),
  );
}

Future<void> _playToEnd(WidgetTester tester) async {
  await tester.tap(find.text('Fight'));
  await tester.pump();
  var iterations = 0;
  while (find.text('Skip to result').evaluate().isNotEmpty &&
      iterations < 20) {
    await tester.pump(kBastionCombatTumble);
    await tester.pump(kBastionCombatPause);
    iterations++;
  }
}

void main() {
  testWidgets('shows the roster and waits for Fight before rolling',
      (tester) async {
    await tester.pumpWidget(_harness(_winResult()));
    await tester.pump();

    expect(find.text('Bastion Attacked'), findsOneWidget);
    expect(find.text('Aldric'), findsOneWidget);
    expect(find.text('Fight'), findsOneWidget);
    expect(find.byType(AnimatedDie), findsNothing);
    expect(find.text('ATTACK REPELLED'), findsNothing);
  });

  testWidgets('tapping Fight plays to the repelled verdict',
      (tester) async {
    await tester.pumpWidget(_harness(_winResult()));
    await tester.pump();
    expect(find.text('ATTACK REPELLED'), findsNothing);

    await _playToEnd(tester);
    await tester.pumpAndSettle();

    expect(find.text('Bastion Attacked'), findsOneWidget);
    expect(find.textContaining('Bandit Cutthroats'), findsOneWidget);
    expect(find.text('Aldric'), findsOneWidget);
    expect(find.text('ATTACK REPELLED'), findsOneWidget);
    expect(find.text('Fight'), findsNothing);
  });

  testWidgets('skip reveals the verdict immediately', (tester) async {
    await tester.pumpWidget(_harness(_winResult()));
    await tester.pump();
    await tester.tap(find.text('Fight'));
    await tester.pump();
    await tester.tap(find.text('Skip to result'));
    await tester.pumpAndSettle();

    expect(find.text('ATTACK REPELLED'), findsOneWidget);
    expect(find.text('Skip to result'), findsNothing);
  });

  testWidgets('a loss shows the destroyed facility', (tester) async {
    await tester.pumpWidget(_harness(_lossResult(), destroyed: 'Kitchen'));
    await tester.pump();
    expect(find.text('BASTION FALLEN'), findsNothing);

    await tester.tap(find.text('Fight'));
    await tester.pumpAndSettle();

    expect(find.text('BASTION FALLEN'), findsOneWidget);
    expect(find.textContaining('Kitchen'), findsOneWidget);
  });

  testWidgets('a pyrrhic win shows the verdict and the slain defender',
      (tester) async {
    final defender = Defender(
      id: 'd1',
      name: 'Aldric',
      type: DefenderType.knight,
      bastionId: 'b1',
    );
    final result = BastionCombatResult(
      enemy: _enemy,
      tier: ChartTier.basic,
      startingEnemies: 1,
      rounds: const [
        CombatRound(
          enemiesAtStart: 1,
          rolls: [
            DefenderRoll(
              defenderId: 'd1',
              defenderName: 'Aldric',
              rolls: [1],
              died: true,
            ),
          ],
          enemiesKilled: 1,
          defendersLost: 1,
        ),
      ],
      survivors: const [],
      dead: [defender],
      won: true,
      deathThreshold: 4,
      advantage: false,
      roster: const [
        (
          id: 'd1',
          name: 'Aldric',
          type: DefenderType.knight,
          dice: UnitDice(1, 12),
        ),
      ],
    );

    await tester.pumpWidget(_harness(result));
    await tester.pump();
    await tester.tap(find.text('Fight'));
    await tester.pump();
    await tester.tap(find.text('Skip to result'));
    await tester.pumpAndSettle();

    expect(find.text('ATTACK REPELLED'), findsOneWidget);
    expect(find.text('slain'), findsOneWidget);
  });

  testWidgets('Done pops the dialog', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () => BastionAttackDialog.show(
                context,
                enemy: _enemy,
                enemyCount: 1,
                result: _winResult(),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Bastion Attacked'), findsOneWidget);

    await tester.tap(find.text('Fight'));
    await tester.pump();
    await tester.tap(find.text('Skip to result'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.text('Bastion Attacked'), findsNothing);
  });
}
