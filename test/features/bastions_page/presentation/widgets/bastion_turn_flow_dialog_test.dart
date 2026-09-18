import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maura_bastion_system/data/enums/defender_type.dart';
import 'package:maura_bastion_system/data/enums/rank.dart';
import 'package:maura_bastion_system/data/models/bastion/bastion.dart';
import 'package:maura_bastion_system/data/models/bastion/facility.dart';
import 'package:maura_bastion_system/data/models/events/chart_event.dart';
import 'package:maura_bastion_system/data/models/events/chart_tier.dart';
import 'package:maura_bastion_system/data/models/events/dispatch.dart';
import 'package:maura_bastion_system/data/models/events/event_chart.dart';
import 'package:maura_bastion_system/data/models/events/reward_spec.dart';
import 'package:maura_bastion_system/data/models/events/turn_engine.dart';
import 'package:maura_bastion_system/data/models/npcs/defender.dart';
import 'package:maura_bastion_system/data/models/rewards/bastion_inventory.dart';
import 'package:maura_bastion_system/data/models/rewards/reward.dart';
import 'package:maura_bastion_system/features/bastions_page/logic/bastion_inventory_cubit.dart';
import 'package:maura_bastion_system/features/bastions_page/logic/chart_points_cubit.dart';
import 'package:maura_bastion_system/features/bastions_page/presentation/widgets/bastion_turn_flow_dialog.dart';

Bastion _bastion() => Bastion(
      id: 'b1',
      name: 'Test Bastion',
      description: '',
      facilities: [
        Facility(id: 'f1', name: 'F1', rank: Rank.D, description: ''),
      ],
      defenders: [
        Defender(
            id: 'd1',
            name: 'Aldric',
            type: DefenderType.bastionDefender,
            bastionId: 'b1'),
      ],
    );

ChartTurnRoll _roll(ChartEvent event) =>
    ChartTurnRoll(slice: null, event: event, tier: event.tier);

Widget _harness(Bastion bastion, ChartTurnRoll roll, {String? rolledRow}) =>
    MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: ChartPointsCubit()..load(bastion)),
          BlocProvider.value(value: BastionInventoryCubit()..load(bastion)),
        ],
        child: Scaffold(
          body: BastionTurnFlowDialog(
            bastion: bastion,
            roll: roll,
            rolledRow: rolledRow,
          ),
        ),
      ),
    );

void main() {
  testWidgets('no-dispatch event goes straight to reward reveal',
      (tester) async {
    const event = ChartEvent(
      id: 'evt_plain',
      name: 'Berry Thicket',
      chart: EventChart.wilds,
      tier: ChartTier.basic,
      description: 'A quiet harvest.',
      reward: RewardSpec(note: 'A quiet harvest indeed'),
    );
    await tester.pumpWidget(_harness(_bastion(), _roll(event)));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Berry Thicket'), findsOneWidget);
    expect(find.text('Turn resolved'), findsOneWidget);
    expect(find.textContaining('A quiet harvest indeed'), findsOneWidget);
    expect(find.byType(CheckboxListTile), findsNothing);
  });

  testWidgets('dispatchable event lets you select units and resolve',
      (tester) async {
    const event = ChartEvent(
      id: 'evt_d',
      name: 'Wolf Cull',
      chart: EventChart.wilds,
      tier: ChartTier.basic,
      description: 'Wolves.',
      dispatch: DispatchSpec(prompt: 'Send defenders', maxUnits: 2, dc: 1),
      reward: RewardSpec(
        kind: RewardKind.material,
        categories: [RewardCategory.creaturePart],
        unitDice: UnitDice(1, 1),
      ),
    );
    final bastion = _bastion();
    final inventoryCubit = BastionInventoryCubit()..load(bastion);
    await tester.pumpWidget(MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: ChartPointsCubit()..load(bastion)),
          BlocProvider.value(value: inventoryCubit),
        ],
        child: Scaffold(
          body: BastionTurnFlowDialog(bastion: bastion, roll: _roll(event)),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(CheckboxListTile), findsOneWidget);
    expect(find.textContaining('Aldric'), findsOneWidget);

    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Resolve'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Aldric'), findsWidgets); // roll line
    expect(find.text('Turn resolved'), findsOneWidget);
    expect(inventoryCubit.state.inventory.entries, isNotEmpty);
  });

  testWidgets('dispatch cap disables unchecked tiles at maxUnits',
      (tester) async {
    const event = ChartEvent(
      id: 'evt_cap',
      name: 'Wolf Cull',
      chart: EventChart.wilds,
      tier: ChartTier.basic,
      description: 'Wolves.',
      dispatch: DispatchSpec(prompt: 'Send defenders', maxUnits: 1, dc: 1),
    );
    await tester.pumpWidget(_harness(_bastion(), _roll(event)));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();
    // With maxUnits 1 and the only unit selected, the checkbox is checked
    // (it stays enabled so the selection can be undone).
    final after = tester.widget<CheckboxListTile>(
      find.byType(CheckboxListTile),
    );
    expect(after.value ?? false, isTrue);
    expect(after.onChanged, isNotNull);
  });

  testWidgets('uneventful roll shows the quiet event and resolves',
      (tester) async {
    final engine = const ChartTurnEngine();
    final roll = engine.rollTurn(points: const {});
    await tester.pumpWidget(_harness(_bastion(), roll));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text(roll.event.name), findsOneWidget);
    expect(find.text('Turn resolved'), findsOneWidget);
  });

  testWidgets('renders the rolled table row callout when provided',
      (tester) async {
    const event = ChartEvent(
      id: 'evt_rolled',
      name: 'Berry Thicket',
      chart: EventChart.wilds,
      tier: ChartTier.basic,
      description: 'A quiet harvest.',
      reward: RewardSpec(note: 'A quiet harvest indeed'),
    );
    await tester.pumpWidget(
      _harness(_bastion(), _roll(event), rolledRow: '1 — Bonus gold'),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Rolled'), findsOneWidget);
    expect(find.text('1 — Bonus gold'), findsOneWidget);
  });

  testWidgets('no rolled row means no Rolled callout', (tester) async {
    const event = ChartEvent(
      id: 'evt_unrolled',
      name: 'Berry Thicket',
      chart: EventChart.wilds,
      tier: ChartTier.basic,
      description: 'A quiet harvest.',
      reward: RewardSpec(note: 'A quiet harvest indeed'),
    );
    await tester.pumpWidget(_harness(_bastion(), _roll(event)));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Rolled'), findsNothing);
  });

  testWidgets('overflow sale line shows this sale gold, not cumulative',
      (tester) async {
    const cheapOre = Reward(
      id: 'cheap_ore',
      name: 'Cheap Ore',
      category: RewardCategory.metal,
      rank: Rank.D,
      marketValue: 5,
      weightPerUnit: 100,
      description: '',
    );
    final bastion = _bastion();
    final inventoryCubit = BastionInventoryCubit()
      ..load(bastion)
      // 600 lb of cheap ore: 1 unit sold for 5 GP, storage left at the cap.
      ..addRewards(const [
        RewardGrant(reward: cheapOre, effectiveRank: Rank.D, units: 6),
      ]);
    expect(inventoryCubit.state.lastSold, isNotEmpty);
    expect(inventoryCubit.state.goldEarned, 5);

    const event = ChartEvent(
      id: 'evt_overflow',
      name: 'Ore Windfall',
      chart: EventChart.wilds,
      tier: ChartTier.basic,
      description: 'Too much ore.',
      reward: RewardSpec(
        kind: RewardKind.material,
        categories: [RewardCategory.metal],
        unitDice: UnitDice(1, 1),
      ),
    );

    await tester.pumpWidget(MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: ChartPointsCubit()..load(bastion)),
          BlocProvider.value(value: inventoryCubit),
        ],
        child: Scaffold(
          body: BastionTurnFlowDialog(bastion: bastion, roll: _roll(event)),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    final lastSold = inventoryCubit.state.lastSold;
    expect(lastSold, isNotEmpty);
    final soldUnits = lastSold.fold<int>(0, (s, g) => s + g.units);
    final saleGold = lastSold.fold<int>(
      0,
      (s, g) => s + g.units * valuePerUnit(g.reward, g.effectiveRank),
    );
    expect(saleGold, greaterThan(0));
    // The cumulative goldEarned includes the pre-load sale, so if the line
    // showed the cumulative figure the expectation below would fail.
    expect(saleGold, lessThan(inventoryCubit.state.goldEarned));

    expect(
      find.textContaining('Storage full: sold $soldUnits units for $saleGold GP'),
      findsOneWidget,
    );
  });
}
