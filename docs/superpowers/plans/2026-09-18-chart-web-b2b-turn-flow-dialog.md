# Chart Web B2b — Turn Flow Dialog & Page Wiring Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the passive `BastionTurnDialog` with the interactive `BastionTurnFlowDialog` (event card → dispatch mini-game → resolution → reward reveal → archetype bonus card) and wire it into the bastion turn using the A8 engine, B2a helpers, and both cubits.

**Architecture:** The page's `_takeBastionTurn` keeps its existing quest input, `advanceBastionTurn` gate, and Discord logging — only the event source changes (engine roll with the player's chart points instead of `rollIndividualBastionEvent`) and the dialog that renders it. The dialog is stateful: dispatch selection (when the event has one), then resolution + reward + bonus card. Rewards flow into `BastionInventoryCubit` (auto overflow sale is inside the cubit).

**Tech Stack:** Flutter + `flutter_bloc`, existing parchment theme.

**Spec:** `docs/superpowers/specs/2026-09-18-chart-web-reward-system-design.md` (Section 4, all five phases)

## Global Constraints

- The engine roll happens in `_takeBastionTurn` (so the Discord `BastionTurnResult` keeps its event name/description/table row); the dialog receives the `ChartTurnRoll`.
- `ChartPointsCubit.load(bastion)` must be ensured before the roll (only if `state.bastionId != bastion.id`).
- Dialog phases: **dispatch** (only when `roll.event.dispatch != null`; checkbox unit selection capped at `maxUnits`, per-unit dice label like '2d6' via `spec.diceFor(type)`) → **reward** (success banner, per-unit rolls, gold/materials/recruit/note, overflow-sale line from `BastionInventoryCubit.lastSold`). No-dispatch events go straight to reward (auto-success).
- Rewards granted exactly once (`addRewards` called once per turn) via `resolveEventRewards`.
- Bonus archetype: after rewards, `const ChartTurnEngine().maybeRollArchetype(points: ...)` — display-only card (name, description, note), never a second dispatch.
- Keep `advanceBastionTurn` + `DiscordApi().sendIndividualBastionTurn` + failure snackbar behavior identical to today.
- House theme: parchment `Dialog`, `ParchmentBorderPainter`, Cinzel headers, imFellEnglish body (copy `bastion_turn_dialog.dart`'s container styling).

---

### Task 1: BastionTurnFlowDialog

**Files:**
- Create: `lib/features/bastions_page/presentation/widgets/bastion_turn_flow_dialog.dart`
- Test: `test/features/bastions_page/presentation/widgets/bastion_turn_flow_dialog_test.dart`

**Interfaces:**
- Consumes: `ChartTurnRoll`, `ChartTurnEngine` (A8), `dispatchUnitsFromBastion`, `resolveEventDispatch`, `resolveEventRewards` (B2a), `ChartPointsCubit`, `BastionInventoryCubit` (B1/B2a), `FacilityTableView`, parchment theme.
- Produces: `class BastionTurnFlowDialog extends StatefulWidget { final Bastion bastion; final ChartTurnRoll roll; const BastionTurnFlowDialog({super.key, required this.bastion, required this.roll}); static Future<void> show(BuildContext context, {required Bastion bastion, required ChartTurnRoll roll}); }` — `show` wraps the dialog in `MultiBlocProvider` (`BlocProvider.value` for both cubits read from the caller's context) inside `showDialog`.

- [ ] **Step 1: Write the failing test**

```dart
// test/features/bastions_page/presentation/widgets/bastion_turn_flow_dialog_test.dart
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

Widget _harness(Bastion bastion, ChartTurnRoll roll) => MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: ChartPointsCubit()..load(bastion)),
          BlocProvider.value(value: BastionInventoryCubit()..load(bastion)),
        ],
        child: Scaffold(
          body: BastionTurnFlowDialog(bastion: bastion, roll: roll),
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

  testWidgets('dispatch cap hides extra selection beyond maxUnits',
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

    final checkbox = tester.widget<CheckboxListTile>(
      find.byType(CheckboxListTile),
    );
    expect(checkbox.onChanged, isNotNull);
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();
    // With maxUnits 1 and 1 unit selected, the (only) checkbox's onChanged
    // becomes null (can no longer be checked further).
    final after = tester.widget<CheckboxListTile>(
      find.byType(CheckboxListTile),
    );
    expect(after.value ?? false, isTrue);
  });

  testWidgets('uneventful roll shows the quiet event and resolves', (tester) async {
    final engine = const ChartTurnEngine();
    final roll = engine.rollTurn(points: const {});
    await tester.pumpWidget(_harness(_bastion(), roll));
    await tester.pumpAndSettle();

    expect(find.text(roll.event.name), findsOneWidget);
    expect(find.text('Turn resolved'), findsOneWidget);
  });
}
```

Note: `resolveEventRewards`/`rollTurnReward` for the material-reward test uses the real reward catalog — inventory entries non-empty is the contract; do not assert a specific reward id.

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/bastions_page/presentation/widgets/bastion_turn_flow_dialog_test.dart`
Expected: FAIL — cannot find `bastion_turn_flow_dialog.dart`.

- [ ] **Step 3: Write the dialog**

```dart
// lib/features/bastions_page/presentation/widgets/bastion_turn_flow_dialog.dart
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:maura_bastion_system/core/themes/theme_colors.dart';
import 'package:maura_bastion_system/data/models/bastion/bastion.dart';
import 'package:maura_bastion_system/data/models/bastion/table.dart';
import 'package:maura_bastion_system/data/models/events/chart_event.dart';
import 'package:maura_bastion_system/data/models/events/turn_engine.dart';
import 'package:maura_bastion_system/data/models/events/turn_flow.dart';
import 'package:maura_bastion_system/data/models/rewards/reward.dart';
import 'package:maura_bastion_system/features/bastions_page/logic/bastion_inventory_cubit.dart';
import 'package:maura_bastion_system/features/bastions_page/logic/chart_points_cubit.dart';
import 'package:maura_bastion_system/features/bastions_page/presentation/widgets/facility_table_view.dart';
import 'package:maura_bastion_system/features/news_paper/presentation/widgets/parchment_border.dart';

enum _Phase { dispatch, reward }

class BastionTurnFlowDialog extends StatefulWidget {
  final Bastion bastion;
  final ChartTurnRoll roll;

  const BastionTurnFlowDialog({
    super.key,
    required this.bastion,
    required this.roll,
  });

  static Future<void> show(
    BuildContext context, {
    required Bastion bastion,
    required ChartTurnRoll roll,
  }) {
    return showDialog(
      context: context,
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: context.read<ChartPointsCubit>()),
          BlocProvider.value(value: context.read<BastionInventoryCubit>()),
        ],
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: BastionTurnFlowDialog(bastion: bastion, roll: roll),
        ),
      ),
    );
  }

  @override
  State<BastionTurnFlowDialog> createState() => _BastionTurnFlowDialogState();
}

class _BastionTurnFlowDialogState extends State<BastionTurnFlowDialog> {
  late _Phase _phase;
  final Set<String> _selectedIds = {};
  DispatchResult? _dispatchResult;
  TurnReward? _reward;
  ChartEvent? _bonusArchetype;
  bool _granted = false;

  @override
  void initState() {
    super.initState();
    _phase = widget.roll.event.dispatch == null ? _Phase.reward : _Phase.dispatch;
    if (_phase == _Phase.reward) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _finalize());
    }
  }

  List<DispatchUnit> get _availableUnits =>
      dispatchUnitsFromBastion(widget.bastion);

  String _diceLabel(DispatchUnit unit) {
    final spec = widget.roll.event.dispatch!;
    final dice = spec.diceFor(unit.type);
    return '${dice.count}d${dice.faces}';
  }

  void _resolve() {
    final selected = _availableUnits
        .where((u) => _selectedIds.contains(u.id))
        .toList();
    setState(() {
      _dispatchResult = resolveEventDispatch(
        event: widget.roll.event,
        selected: selected,
      );
    });
    _finalize();
  }

  void _finalize() {
    if (_granted) return;
    _granted = true;
    _reward = resolveEventRewards(
      event: widget.roll.event,
      dispatch: _dispatchResult,
    );
    context.read<BastionInventoryCubit>().addRewards(_reward!.materials);
    final pointsCubit = context.read<ChartPointsCubit>();
    _bonusArchetype = const ChartTurnEngine().maybeRollArchetype(
      points: pointsCubit.state.points.points,
      rng: Random(),
    );
    setState(() => _phase = _Phase.reward);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: 480,
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        gradient: const RadialGradient(
          center: Alignment.center,
          radius: 0.9,
          colors: [MedievalColors.parchmentLight, MedievalColors.parchmentDark],
          stops: [0.6, 1.0],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(50),
            blurRadius: 6,
            offset: const Offset(2, 3),
          ),
        ],
      ),
      child: CustomPaint(
        painter: ParchmentBorderPainter(),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Bastion Turn',
                textAlign: TextAlign.center,
                style: GoogleFonts.cinzel(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: MedievalColors.vermillion,
                ),
              ),
              const SizedBox(height: 8),
              Flexible(child: SingleChildScrollView(child: _buildBody())),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    final event = widget.roll.event;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Individual Event',
          style: GoogleFonts.imFellEnglish(
            fontSize: 14,
            color: MedievalColors.sepiaSecondary,
          ),
        ),
        Text(
          event.name,
          style: GoogleFonts.cinzel(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: MedievalColors.vermillion,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          event.description,
          style: GoogleFonts.imFellEnglish(
            fontSize: 15,
            height: 1.4,
            color: MedievalColors.sepiaInk,
          ),
        ),
        if (event.table != null) ...[
          const SizedBox(height: 8),
          FacilityTableView(table: event.table!),
        ],
        const SizedBox(height: 12),
        if (_phase == _Phase.dispatch) _buildDispatchSection(),
        if (_phase == _Phase.reward) _buildRewardSection(),
      ],
    );
  }

  Widget _buildDispatchSection() {
    final spec = widget.roll.event.dispatch!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          spec.prompt,
          style: GoogleFonts.imFellEnglish(
            fontSize: 15,
            color: MedievalColors.sepiaInk,
          ),
        ),
        const SizedBox(height: 4),
        ..._availableUnits.map(_buildUnitTile),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: _resolve,
          child: const Text('Resolve'),
        ),
      ],
    );
  }

  Widget _buildUnitTile(DispatchUnit unit) {
    final checked = _selectedIds.contains(unit.id);
    final atCap = _selectedIds.length >= widget.roll.event.dispatch!.maxUnits;
    return CheckboxListTile(
      value: checked,
      onChanged: (checked || !atCap)
          ? (_) => setState(() {
                checked
                    ? _selectedIds.remove(unit.id)
                    : _selectedIds.add(unit.id);
              })
          : null,
      title: Text(
        unit.name,
        style: GoogleFonts.imFellEnglish(
          fontSize: 15,
          color: MedievalColors.sepiaInk,
        ),
      ),
      subtitle: Text(
        _diceLabel(unit),
        style: GoogleFonts.imFellEnglish(
          fontSize: 13,
          color: MedievalColors.sepiaSecondary,
        ),
      ),
    );
  }

  Widget _buildRewardSection() {
    final reward = _reward!;
    final inventory = context.watch<BastionInventoryCubit>().state;
    final dispatch = _dispatchResult;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Turn resolved',
          style: GoogleFonts.cinzel(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: MedievalColors.vermillion,
          ),
        ),
        if (dispatch != null) ...[
          const SizedBox(height: 4),
          ...dispatch.unitRolls.map(
            (r) => Text(
              '${r.unit.name}: ${r.subtotal} (${r.rolls.join(', ')})',
              style: GoogleFonts.imFellEnglish(
                fontSize: 14,
                color: MedievalColors.sepiaInk,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            dispatch.success
                ? 'Total ${dispatch.total} vs DC ${dispatch.dc} — success!'
                : 'Total ${dispatch.total} vs DC ${dispatch.dc} — failure.',
            style: GoogleFonts.imFellEnglish(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: dispatch.success
                  ? MedievalColors.sepiaInk
                  : MedievalColors.sepiaMuted,
            ),
          ),
        ],
        if (reward.gold > 0) ...[
          const SizedBox(height: 8),
          Text(
            '${reward.gold} GP',
            style: GoogleFonts.cinzel(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: MedievalColors.vermillion,
            ),
          ),
        ],
        if (reward.materials.isNotEmpty) ...[
          const SizedBox(height: 8),
          for (final grant in reward.materials)
            Text(
              '${grant.units} \u00d7 ${grant.reward.name} (Rank ${grant.effectiveRank.title})',
              style: GoogleFonts.imFellEnglish(
                fontSize: 15,
                color: MedievalColors.sepiaInk,
              ),
            ),
        ],
        if (reward.recruit == RewardKind.recruitDefender)
          _rewardLine('A new defender joins the bastion!'),
        if (reward.recruit == RewardKind.recruitHireling)
          _rewardLine('A new hireling joins the bastion!'),
        if (inventory.lastSold.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'Storage full: sold ${inventory.lastSold.fold<int>(0, (s, g) => s + g.units)} units for ${inventory.goldEarned} GP',
            style: GoogleFonts.imFellEnglish(
              fontSize: 14,
              fontStyle: FontStyle.italic,
              color: MedievalColors.sepiaSecondary,
            ),
          ),
        ],
        if (reward.note != null) _rewardLine(reward.note!),
        if (_bonusArchetype != null) ...[
          const SizedBox(height: 12),
          Text(
            'Convergence: ${_bonusArchetype!.name}',
            style: GoogleFonts.cinzel(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: MedievalColors.vermillion,
            ),
          ),
          Text(
            _bonusArchetype!.description,
            style: GoogleFonts.imFellEnglish(
              fontSize: 14,
              height: 1.4,
              color: MedievalColors.sepiaInk,
            ),
          ),
        ],
      ],
    );
  }

  Widget _rewardLine(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        text,
        style: GoogleFonts.imFellEnglish(
          fontSize: 15,
          height: 1.4,
          color: MedievalColors.sepiaInk,
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/bastions_page/presentation/widgets/bastion_turn_flow_dialog_test.dart`
Expected: PASS (4 tests). If the no-dispatch path races the post-frame callback, use `await tester.pumpAndSettle()` after an extra `await tester.pump()`.

- [ ] **Step 5: Commit**

```bash
git add lib/features/bastions_page/presentation/widgets/bastion_turn_flow_dialog.dart test/features/bastions_page/presentation/widgets/bastion_turn_flow_dialog_test.dart
git commit -m "feat: add interactive bastion turn flow dialog"
```

---

### Task 2: Wire the engine + dialog into the bastion turn

**Files:**
- Modify: `lib/features/bastions_page/presentation/bastion_page.dart` (`_takeBastionTurn` + add `BastionInventoryCubit` provider next to the B1 `ChartPointsCubit` provider)
- Test: `test/features/bastions_page/presentation/bastion_page_test.dart` (extend/adapt)

**Interfaces:**
- Consumes: `ChartTurnEngine.rollTurn` (A8), `ChartPointsCubit` (B1), `BastionInventoryCubit` (B2a), `BastionTurnFlowDialog.show` (Task 1).
- Produces: `_takeBastionTurn` now: ensures `ChartPointsCubit.load(bastion)` when `state.bastionId != bastion.id`; rolls `const ChartTurnEngine().rollTurn(points: pointsCubit.state.points.points)`; builds `BastionTurnEventResult` from `roll.event` (name, description, table row via `rollTableResult` when a table exists); the Discord gate and `advanceBastionTurn` flow remain byte-for-byte what they are today; on success shows `BastionTurnFlowDialog.show(context, bastion: bastion, roll: roll)` instead of `BastionTurnDialog.show(...)`. The `rollIndividualBastionEvent` import is removed. The old `BastionTurnDialog` file is left in place (retired, unused).

- [ ] **Step 1: Write the failing test** (extend the page test file, adapting to its existing harness as in B1 Task 4)

```dart
  testWidgets('bastion turn uses the chart web flow dialog', (tester) async {
    // Arrange: reuse the file's existing loaded-page harness (with the same
    // GetIt/ApiClient mocks the turn tests already use — including the
    // mock route for the individual-bastion-turn Discord POST and the turn
    // advance PUT). Complete the QuestInputDialog (enter text, confirm).
    await tester.tap(find.byIcon(Icons.autorenew)); // existing turn FAB icon
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'quest');
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    // The new flow dialog is up (either phase) — old dialog title is gone.
    expect(find.text('Bastion Turn'), findsOneWidget);
    expect(find.text('Individual Event'), findsOneWidget);
  });
```

NOTE: adapt the FAB icon, quest dialog completion, and mock routes to the file's existing turn tests (there are existing tests that already drive a full turn — copy their arrange/act steps and change the final assertions to the two expects above). If the existing tests assert old-dialog-specific content (e.g. 'No individual event this turn.'), update those assertions to the new dialog's markers ('Individual Event' still exists; 'No facilities ready to grant buffs this turn.' does NOT — the new dialog drops the facility-construction section, which the old dialog showed. Keep the new dialog without it per this plan).

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/bastions_page/presentation/bastion_page_test.dart`
Expected: FAIL — the flow still shows the old dialog's distinctive content (or lacks 'Individual Event' depending on current dialog content).

- [ ] **Step 3: Implement the wiring**

Per the Interfaces block above. Concretely in `_takeBastionTurn`:

```dart
    final pointsCubit = context.read<ChartPointsCubit>();
    if (pointsCubit.state.bastionId != bastion.id) {
      pointsCubit.load(bastion);
    }
    final roll =
        const ChartTurnEngine().rollTurn(points: pointsCubit.state.points.points);
    final eventResult = BastionTurnEventResult(
      name: roll.event.name,
      description: roll.event.description,
      rolledRow:
          roll.event.table == null ? null : rollTableResult(roll.event.table!),
    );
```

…and replace the final `BastionTurnDialog.show` call with:

```dart
    await BastionTurnFlowDialog.show(
      context,
      bastion: bastion,
      roll: roll,
    );
```

Add the `BastionInventoryCubit` provider beside the existing `ChartPointsCubit` provider (same nesting level), and fix imports (add `turn_engine.dart`, `bastion_turn_flow_dialog.dart`, `bastion_inventory_cubit.dart`; remove `individual_bastion_events_catalog.dart` if now unused).

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/bastions_page/presentation/bastion_page_test.dart`
Expected: PASS — all tests in the file, including existing turn tests updated where they asserted old-dialog-only content.

- [ ] **Step 5: Commit**

```bash
git add lib/features/bastions_page/presentation/bastion_page.dart test/features/bastions_page/presentation/bastion_page_test.dart
git commit -m "feat: drive bastion turn from chart web engine with flow dialog"
```

---

### Task 3: Verification

- [ ] **Step 1:** Run `flutter test` — expect full suite pass.
- [ ] **Step 2:** Run `flutter analyze` — expect no new issues.
