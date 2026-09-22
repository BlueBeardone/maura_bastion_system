import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maura_bastion_system/data/enums/rank.dart';
import 'package:maura_bastion_system/data/models/bastion/bastion_turn_result.dart';
import 'package:maura_bastion_system/data/models/bastion/facility.dart';
import 'package:maura_bastion_system/data/models/events/chart_event.dart';
import 'package:maura_bastion_system/data/models/events/chart_tier.dart';
import 'package:maura_bastion_system/data/models/events/event_chart.dart';
import 'package:maura_bastion_system/data/models/events/reward_spec.dart';
import 'package:maura_bastion_system/features/bastions_page/presentation/widgets/bastion_turn_dialog.dart';

const _event = ChartEvent(
  id: 'evt_berry',
  name: 'Berry Thicket',
  chart: EventChart.wilds,
  tier: ChartTier.basic,
  description: 'A quiet harvest.',
  reward: RewardSpec(note: 'A quiet harvest indeed'),
);

Facility _facility({required int constructedTurns, required int constructionTurns}) =>
    Facility(
      id: 'f1',
      name: 'Kitchen',
      rank: Rank.D,
      description: '',
      constructedTurns: constructedTurns,
      constructionTurns: constructionTurns,
    );

Widget _harness({
  Facility? advancedFacility,
  ChartEvent? event,
  BastionTurnResult? result,
  List<BastionTurnFacilityResult> facilityResults = const [],
}) =>
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: BastionTurnDialog(
            advancedFacility: advancedFacility,
            event: event,
            result: result,
            facilityResults: facilityResults,
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

  testWidgets('facility results show one callout per result', (tester) async {
    await tester.pumpWidget(_harness(
      facilityResults: [
        const BastionTurnFacilityResult(
          name: 'Kitchen',
          rolledRow: '3 | Hearty meal | Everyone is fed',
        ),
        const BastionTurnFacilityResult(
          name: 'Training Yard',
          rolledRow: '7 | Drills | Defenders train',
        ),
      ],
    ));
    await tester.pumpAndSettle();

    expect(find.text('Facility Results'), findsOneWidget);
    expect(find.text('Kitchen'), findsOneWidget);
    expect(find.text('3 | Hearty meal | Everyone is fed'), findsOneWidget);
    expect(find.text('7 | Drills | Defenders train'), findsOneWidget);
  });

  testWidgets('facility results without rolled rows are skipped',
      (tester) async {
    await tester.pumpWidget(_harness(
      facilityResults: const [
        BastionTurnFacilityResult(name: 'Training Yard'),
      ],
    ));
    await tester.pumpAndSettle();

    expect(find.text('Your facilities yielded nothing this turn.'),
        findsOneWidget);
    expect(find.text('Training Yard'), findsNothing);
  });

  testWidgets('event section shows name, description and rolled row',
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
          rolledRow: '2 | Sweet berries',
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Berry Thicket'), findsOneWidget);
    expect(find.text('A quiet harvest.'), findsOneWidget);
    expect(find.text('Rolled'), findsOneWidget);
    expect(find.text('2 | Sweet berries'), findsOneWidget);
  });
}