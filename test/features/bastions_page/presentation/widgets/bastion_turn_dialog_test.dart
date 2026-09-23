import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maura_bastion_system/data/enums/rank.dart';
import 'package:maura_bastion_system/data/models/bastion/bastion_turn_facility_buff.dart';
import 'package:maura_bastion_system/data/models/bastion/bastion_turn_result.dart';
import 'package:maura_bastion_system/data/models/bastion/facility.dart';
import 'package:maura_bastion_system/data/models/bastion/table.dart';
import 'package:maura_bastion_system/data/models/events/chart_event.dart';
import 'package:maura_bastion_system/data/models/events/chart_tier.dart';
import 'package:maura_bastion_system/data/models/events/event_chart.dart';
import 'package:maura_bastion_system/data/models/events/reward_spec.dart';
import 'package:maura_bastion_system/features/bastions_page/presentation/widgets/bastion_turn_dialog.dart';
import 'package:maura_bastion_system/features/bastions_page/presentation/widgets/facility_buff_card.dart';

const _event = ChartEvent(
  id: 'evt_berry',
  name: 'Berry Thicket',
  chart: EventChart.wilds,
  tier: ChartTier.basic,
  description: 'A quiet harvest.',
  reward: RewardSpec(note: 'A quiet harvest indeed'),
);

Facility _facility({
  required int constructedTurns,
  required int constructionTurns,
  String name = 'Kitchen',
  String description = '',
}) =>
    Facility(
      id: 'f1',
      name: name,
      rank: Rank.D,
      description: description,
      constructedTurns: constructedTurns,
      constructionTurns: constructionTurns,
    );

Widget _harness({
  Facility? advancedFacility,
  ChartEvent? event,
  BastionTurnResult? result,
  int? eventRollNumber,
  List<BastionTurnFacilityBuff> facilityBuffs = const [],
}) =>
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: BastionTurnDialog(
            advancedFacility: advancedFacility,
            event: event,
            result: result,
            eventRollNumber: eventRollNumber,
            facilityBuffs: facilityBuffs,
          ),
        ),
      ),
    );

void main() {
  testWidgets('in-progress construction shows the progress line',
      (tester) async {
    await tester.pumpWidget(_harness(
      advancedFacility:
          _facility(constructedTurns: 1, constructionTurns: 2),
    ));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Construction advanced: Kitchen (1/2 turns)'),
      findsOneWidget,
    );
  });

  testWidgets('completed construction shows the Completed! callout',
      (tester) async {
    await tester.pumpWidget(_harness(
      advancedFacility:
          _facility(constructedTurns: 2, constructionTurns: 2),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Completed!'), findsOneWidget);
    expect(find.text('Kitchen'), findsOneWidget);
  });

  testWidgets('no construction shows the empty state', (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    expect(find.text('No facilities under construction.'), findsOneWidget);
  });

  testWidgets('event section shows name, description, rolled number and row',
      (tester) async {
    await tester.pumpWidget(_harness(
      event: _event,
      eventRollNumber: 2,
      result: const BastionTurnResult(
        bastionId: 'b',
        bastionName: 'n',
        quest: 'q',
        event: BastionTurnEventResult(
          name: 'Berry Thicket',
          description: 'A quiet harvest.',
          rolledRow: '2 | Sweet berries',
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Berry Thicket'), findsOneWidget);
    expect(find.text('A quiet harvest.'), findsOneWidget);
    expect(find.text('Rolled 2'), findsOneWidget);
    expect(find.text('2 | Sweet berries'), findsOneWidget);
  });

  testWidgets('event section shows reward summary and dispatch outcome',
      (tester) async {
    await tester.pumpWidget(_harness(
      event: _event,
      result: const BastionTurnResult(
        bastionId: 'b',
        bastionName: 'n',
        quest: 'q',
        event: BastionTurnEventResult(
          name: 'Berry Thicket',
          description: 'A quiet harvest.',
          rewardSummary: '3 \u00d7 Herbs',
          dispatch: BastionTurnDispatchResult(
            units: [
              BastionTurnDispatchUnitResult(
                name: 'Sgt. Bram',
                rolls: [4, 5],
                subtotal: 9,
              ),
            ],
            bonus: 1,
            total: 10,
            dc: 12,
            success: false,
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Reward'), findsOneWidget);
    expect(find.text('3 \u00d7 Herbs'), findsOneWidget);
    expect(find.text('Dispatch'), findsOneWidget);
    expect(find.text('Sgt. Bram: 9 (4, 5)'), findsOneWidget);
    expect(find.textContaining('Total 10 vs DC 12'), findsOneWidget);
  });

  testWidgets('facility buffs render one card per facility', (tester) async {
    await tester.pumpWidget(_harness(
      facilityBuffs: [
        BastionTurnFacilityBuff(
          facility: _facility(constructedTurns: 2, constructionTurns: 2),
          hirelingCount: 1,
        ),
      ],
    ));
    await tester.pumpAndSettle();

    expect(find.text('Facilities granting benefits'), findsOneWidget);
    expect(find.byType(FacilityBuffCard), findsOneWidget);
    expect(find.text('Kitchen'), findsOneWidget);
  });

  testWidgets('tapping a facility buff card reveals its rolled result',
      (tester) async {
    await tester.pumpWidget(_harness(
      facilityBuffs: [
        BastionTurnFacilityBuff(
          facility: Facility(
            id: 'f1',
            name: 'Training Area',
            rank: Rank.B,
            description: 'You gain one Trainer benefit.',
            table: FacilityTable(table: [
              ['Trainer', 'Benefit'],
              ['Weapon Expert', '+1 to hit with melee weapons'],
            ]),
          ),
          hirelingCount: 4,
          rolledNumber: 1,
          rolledRow: '1 | Weapon Expert | +1 to hit with melee weapons',
        ),
      ],
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Training Area'));
    await tester.pumpAndSettle();

    expect(find.text('You gain one Trainer benefit.'), findsOneWidget);
    expect(find.text('Rolled 1'), findsOneWidget);
    expect(
      find.text('1 | Weapon Expert | +1 to hit with melee weapons'),
      findsOneWidget,
    );
  });

  testWidgets('empty facility buffs shows the empty state', (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    expect(
      find.text('No facilities are granting benefits this turn.'),
      findsOneWidget,
    );
  });
}
