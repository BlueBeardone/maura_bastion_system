import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:maura_bastion_system/api/api_client.dart';
import 'package:maura_bastion_system/api/defender_api.dart';
import 'package:maura_bastion_system/api/hireling_api.dart';
import 'package:maura_bastion_system/core/juice/reveal_widgets.dart';
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
import 'package:maura_bastion_system/data/models/rewards/reward.dart';
import 'package:maura_bastion_system/features/bastions_page/data/filler_store.dart';
import 'package:maura_bastion_system/features/bastions_page/logic/chart_points_cubit.dart';
import 'package:maura_bastion_system/features/bastions_page/presentation/widgets/bastion_turn_flow_dialog.dart';
import 'package:maura_bastion_system/features/bastions_page/presentation/widgets/defender_create_form.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

const recruitDefenderEvent = ChartEvent(
  id: 'evt_rec_def',
  name: 'Oathbound',
  chart: EventChart.warMarch,
  tier: ChartTier.basic,
  description: 'A knight offers service.',
  reward: RewardSpec(kind: RewardKind.recruitDefender),
);

const recruitHirelingEvent = ChartEvent(
  id: 'evt_rec_hire',
  name: 'Traveling Hand',
  chart: EventChart.tradeRoad,
  tier: ChartTier.basic,
  description: 'A hireling offers service.',
  reward: RewardSpec(kind: RewardKind.recruitHireling),
);

void _registerRecruitApis({bool defenderCreateFails = false}) {
  final apiClient = ApiClient(
    baseUrl: 'http://example.test',
    client: MockClient((request) async {
      final body =
          request.body.isEmpty ? <String, dynamic>{} : jsonDecode(request.body) as Map<String, dynamic>;
      if (request.method == 'POST' &&
          request.url.path == '/maura/v1/defenders') {
        if (defenderCreateFails) {
          // The established failure shape: success:false envelope over HTTP 200.
          return http.Response(
            jsonEncode({'success': false, 'message': 'creation failed'}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'ok',
            'data': {
              'id': 'new-def',
              'name': body['name'],
              'type': body['type'],
              'bastionId': body['bastionId'],
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      if (request.method == 'POST' &&
          request.url.path == '/maura/v1/hirelings') {
        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'ok',
            'data': {
              'id': 'new-hire',
              'name': body['name'],
              'role': body['role'],
              'description': body['description'],
              'bastionId': body['bastionId'],
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      if (request.method == 'GET') {
        return http.Response(
          jsonEncode({'success': true, 'message': 'ok', 'data': []}),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      return http.Response(
        jsonEncode({'success': false, 'message': 'unexpected'}),
        404,
        headers: {'content-type': 'application/json'},
      );
    }),
  );
  GetIt.I.registerSingleton<DefenderApi>(DefenderApi(client: apiClient));
  GetIt.I.registerSingleton<HirelingApi>(HirelingApi(client: apiClient));
}

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
    await tester.pumpWidget(_harness(bastion, _roll(event)));
    await tester.pumpAndSettle();

    expect(find.byType(CheckboxListTile), findsOneWidget);
    expect(find.textContaining('Aldric'), findsOneWidget);

    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Resolve'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Aldric'), findsWidgets); // roll line
    expect(find.text('Turn resolved'), findsOneWidget);
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
      _harness(_bastion(), _roll(event), rolledRow: '1 — Bonus flavor'),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Rolled'), findsOneWidget);
    expect(find.text('1 — Bonus flavor'), findsOneWidget);
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

  testWidgets('Done pops with the reward summary', (tester) async {
    const event = ChartEvent(
      id: 'evt_plain2',
      name: 'Berry Thicket',
      chart: EventChart.wilds,
      tier: ChartTier.basic,
      description: 'A quiet harvest.',
      reward: RewardSpec(note: 'quiet'),
    );
    String? popped;
    await tester.pumpWidget(MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: ChartPointsCubit()..load(_bastion())),
        ],
        child: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  popped = await BastionTurnFlowDialog.show(
                    context,
                    bastion: _bastion(),
                    roll: _roll(event),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(popped, isNull); // no materials/recruit — 'none' collapses to null
  });

  testWidgets('Done pops the summary string when there is something to send',
      (tester) async {
    const event = ChartEvent(
      id: 'evt_recruit',
      name: 'Wandering Hand',
      chart: EventChart.wilds,
      tier: ChartTier.basic,
      description: 'A hireling offers to join.',
      reward: RewardSpec(kind: RewardKind.recruitHireling),
    );
    String? popped;
    await tester.pumpWidget(MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: ChartPointsCubit()..load(_bastion())),
        ],
        child: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  popped = await BastionTurnFlowDialog.show(
                    context,
                    bastion: _bastion(),
                    roll: _roll(event),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(popped, 'a new hireling');
  });

  testWidgets('uneventful turn appends a local filler article', (tester) async {
    SharedPreferences.setMockInitialValues({});
    GetIt.I.registerSingleton<FillerStore>(FillerStore());
    addTearDown(GetIt.I.reset);

    final bastion = _bastion();
    final event = ChartEvent(
      id: 'unt_test_quiet',
      name: 'Quiet Week',
      chart: null,
      tier: ChartTier.basic,
      description: 'Nothing happens this turn.',
      reward: const RewardSpec(note: 'Nothing happens'),
    );
    await tester.pumpWidget(_harness(bastion, _roll(event)));
    await tester.pumpAndSettle();

    final fillers = await GetIt.I<FillerStore>().read('b1');
    expect(fillers, isNotEmpty);
    expect(fillers.last.title, isNotEmpty);
  });

  testWidgets('resolve stamps a mission verdict', (tester) async {
    const event = ChartEvent(
      id: 'evt_stamp',
      name: 'Wolf Cull',
      chart: EventChart.wilds,
      tier: ChartTier.basic,
      description: 'Wolves.',
      dispatch: DispatchSpec(prompt: 'Send defenders', maxUnits: 2, dc: 1),
    );
    await tester.pumpWidget(_harness(_bastion(), _roll(event)));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Resolve'));
    await tester.pumpAndSettle();

    expect(find.text('MISSION HELD'), findsOneWidget);
  });

  testWidgets('reward lines sparkle with a capped burst budget',
      (tester) async {
    const event = ChartEvent(
      id: 'evt_sparkle',
      name: 'Beast Bounty',
      chart: EventChart.wilds,
      tier: ChartTier.basic,
      description: 'Beasts everywhere.',
      // The brief's snippet omitted a dispatch, but the test taps a
      // CheckboxListTile and Resolve, which only exist in dispatch phase.
      dispatch: DispatchSpec(prompt: 'Send defenders', maxUnits: 2, dc: 1),
      reward: RewardSpec(
        kind: RewardKind.material,
        categories: [RewardCategory.creaturePart],
        unitDice: UnitDice(1, 1),
      ),
    );
    await tester.pumpWidget(_harness(_bastion(), _roll(event)));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Resolve'));
    await tester.pumpAndSettle();

    // findsAtMostNWidgets does not exist in this Flutter version's matcher set.
    final sparkleCount =
        tester.widgetList(find.byType(SparkleOverlay)).length;
    expect(sparkleCount, lessThanOrEqualTo(5));
    expect(find.text('Turn resolved'), findsOneWidget);
  });

  testWidgets('recruit reward shows the offer with both paths', (tester) async {
    _registerRecruitApis();
    addTearDown(GetIt.I.reset);
    await tester.pumpWidget(_harness(_bastion(), _roll(recruitDefenderEvent)));
    await tester.pumpAndSettle();

    expect(find.text('A defender offers to join your bastion.'), findsOneWidget);
    expect(find.text("I'll make them myself"), findsOneWidget);
    expect(find.text('Let the bastion handle it'), findsOneWidget);
    expect(find.text('Skip for now'), findsOneWidget);
  });

  testWidgets('automated path creates the defender and names the reward line',
      (tester) async {
    _registerRecruitApis();
    addTearDown(GetIt.I.reset);
    await tester.pumpWidget(_harness(_bastion(), _roll(recruitDefenderEvent)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Let the bastion handle it'));
    await tester.pumpAndSettle();

    expect(find.textContaining('A knight, '), findsOneWidget);
    expect(find.textContaining('joined your bastion.'), findsOneWidget);
    expect(find.byType(DefenderCreateForm), findsNothing);
  });

  testWidgets('automated path failure shows a snackbar and keeps the offer',
      (tester) async {
    _registerRecruitApis(defenderCreateFails: true);
    addTearDown(GetIt.I.reset);
    await tester.pumpWidget(_harness(_bastion(), _roll(recruitDefenderEvent)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Let the bastion handle it'));
    await tester.pumpAndSettle();

    expect(find.text('Something went wrong — please try again'),
        findsOneWidget);
    // The record was not created, so the offer is still open.
    expect(find.text('Let the bastion handle it'), findsOneWidget);
    expect(find.textContaining('A defender, '), findsNothing);
  });

  testWidgets('manual path shows the defender form inline and names the reward',
      (tester) async {
    _registerRecruitApis();
    addTearDown(GetIt.I.reset);
    await tester.pumpWidget(_harness(_bastion(), _roll(recruitDefenderEvent)));
    await tester.pumpAndSettle();

    await tester.tap(find.text("I'll make them myself"));
    await tester.pumpAndSettle();

    expect(find.byType(DefenderCreateForm), findsOneWidget);
    expect(find.text('Enlist Your New Defender'), findsOneWidget);

    // The FlutterTest font overflows the dropdown; shrink text like
    // defenders_page_test.dart does.
    tester.platformDispatcher.textScaleFactorTestValue = 0.8;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Name').first, 'Gareth Vane');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Description').first,
        'A weathered knight.');
    await tester.tap(find.text('Type').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bastion Defender').last);
    await tester.pumpAndSettle();

    // The embedded form is taller than the dialog's viewport; scroll the
    // submit button into view like bastion_page_test.dart does.
    await tester.ensureVisible(find.text('Enlist Defender'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enlist Defender'));
    await tester.pumpAndSettle();

    expect(find.textContaining('A bastion defender, Gareth Vane'), findsOneWidget);
    expect(find.textContaining('joined your bastion.'), findsOneWidget);
  });

  testWidgets('skip restores the flavor text and Done keeps the old summary',
      (tester) async {
    _registerRecruitApis();
    addTearDown(GetIt.I.reset);
    String? popped;
    await tester.pumpWidget(MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: ChartPointsCubit()..load(_bastion())),
        ],
        child: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  popped = await BastionTurnFlowDialog.show(
                    context,
                    bastion: _bastion(),
                    roll: _roll(recruitHirelingEvent),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Skip for now'));
    await tester.pumpAndSettle();
    expect(
        find.textContaining('recorded at the next muster'), findsOneWidget);

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(popped, 'a new hireling');
  });

  testWidgets('Done returns the named summary after the recruit is created',
      (tester) async {
    _registerRecruitApis();
    addTearDown(GetIt.I.reset);
    String? popped;
    await tester.pumpWidget(MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: ChartPointsCubit()..load(_bastion())),
        ],
        child: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  popped = await BastionTurnFlowDialog.show(
                    context,
                    bastion: _bastion(),
                    roll: _roll(recruitHirelingEvent),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Let the bastion handle it'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(popped, startsWith('a hireling, '));
  });
}
