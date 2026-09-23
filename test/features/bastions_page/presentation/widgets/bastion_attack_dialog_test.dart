// test/features/bastions_page/presentation/widgets/bastion_attack_dialog_test.dart
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maura_bastion_system/data/enums/defender_type.dart';
import 'package:maura_bastion_system/data/models/events/bastion_attack.dart';
import 'package:maura_bastion_system/data/models/events/chart_tier.dart';
import 'package:maura_bastion_system/data/models/events/dispatch.dart';
import 'package:maura_bastion_system/data/models/npcs/defender.dart';
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

Widget _harness(BastionCombatResult result, {String? destroyed}) => MaterialApp(
      home: Scaffold(
        body: BastionAttackDialog(
          enemy: _enemy,
          enemyCount: 1,
          result: result,
          destroyedFacilityName: destroyed,
        ),
      ),
    );

void main() {
  testWidgets('shows the enemy, roster rolls and the repelled verdict',
      (tester) async {
    await tester.pumpWidget(_harness(_winResult()));
    await tester.pumpAndSettle();

    expect(find.text('Bastion Attacked'), findsOneWidget);
    expect(find.textContaining('Bandit Cutthroats'), findsOneWidget);
    expect(find.textContaining('Aldric'), findsWidgets);
    expect(find.text('Aldric: d12'), findsOneWidget);
    expect(find.text('ATTACK REPELLED'), findsOneWidget);
  });

  testWidgets('a loss shows the destroyed facility', (tester) async {
    final result = resolveBastionCombat(
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
    await tester.pumpWidget(_harness(result, destroyed: 'Kitchen'));
    await tester.pumpAndSettle();

    expect(find.text('BASTION FALLEN'), findsOneWidget);
    expect(find.textContaining('Kitchen'), findsOneWidget);
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
    await tester.pumpAndSettle();
    expect(find.text('Bastion Attacked'), findsOneWidget);

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.text('Bastion Attacked'), findsNothing);
  });
}
