# Chart Web B1 — Chart Points & Allocation Panel Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let the player assign their facility-earned points to the six event charts from the bastion page, with a live preview of their personalized d100 table and tier badges.

**Architecture:** A `ChartPoints` value model (cap = built facilities, max 16), a `ChartPointsCubit` holding the player's allocation (in-memory this plan — persistence is plan C), and a `ChartWebPanel` page reachable from the bastion page. Allocation is tap-stepper based (+/- per chart), which is simple, testable, and mobile-friendly; drag comes later if wanted.

**Tech Stack:** Flutter + `flutter_bloc` (already used throughout), MedievalColors/GoogleFonts theme.

**Spec:** `docs/superpowers/specs/2026-09-18-chart-web-reward-system-design.md` (Section 4 phase 1)

## Global Constraints

- Earned points = **number of built facilities** (`bastion.facilities.length`), capped at **16**.
- Assigned total can never exceed earned; per-chart points clamp at 0.
- Zero-point charts render dark and "never fire"; the live preview shows each funded chart's **d100 slice** (via `computeChartSlices`) and **tier** (via `ChartTier.forPoints`).
- Convergence/Rivalry hint: use `unlocksConvergence`/`unlocksRivalry` for an informational line (hinting only — engine gating is per-event).
- House theme: parchment surfaces, `MedievalColors.vermillion` headers, Cinzel for headings, imFellEnglish for body (see `bastion_page.dart`).
- No comments unless non-obvious; no new dependencies.

---

### Task 1: ChartPoints model

**Files:**
- Create: `lib/data/models/events/chart_points.dart`
- Test: `test/data/models/events/chart_points_test.dart`

**Interfaces:**
- Consumes: `EventChart` (A1).
- Produces:
  - `class ChartPoints { static const int maxPoints = 16; final Map<EventChart, int> points; final int earnedPoints; const ChartPoints({this.points = const {}, required this.earnedPoints}); int get assignedTotal; int get unassigned; int operator [](EventChart chart); ChartPoints assign(EventChart chart, int delta); bool canAssign(EventChart chart, int delta); }`
    - `assign` returns a NEW ChartPoints: per-chart value clamps at 0; the assignment is rejected (returns `this`) if it would push `assignedTotal` above `earnedPoints` or above `maxPoints`.
    - `canAssign(chart, delta)` mirrors that logic.
    - `earnedPoints` itself must already be ≤ 16 (the constructor does not clamp; the cubit clamps when loading).

- [ ] **Step 1: Write the failing test**

```dart
// test/data/models/events/chart_points_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:maura_bastion_system/data/models/events/chart_points.dart';
import 'package:maura_bastion_system/data/models/events/event_chart.dart';

void main() {
  test('starts empty with unassigned equal to earned', () {
    final points = const ChartPoints(earnedPoints: 5);
    expect(points.assignedTotal, 0);
    expect(points.unassigned, 5);
    expect(points[EventChart.wilds], 0);
  });

  test('assign moves unassigned points into a chart', () {
    final points = const ChartPoints(earnedPoints: 4).assign(EventChart.wilds, 4);
    expect(points[EventChart.wilds], 4);
    expect(points.unassigned, 0);
  });

  test('cannot assign more than earned', () {
    final points = const ChartPoints(earnedPoints: 2);
    final rejected = points.assign(EventChart.deeps, 3);
    expect(identical(rejected, points), isTrue);
    final accepted = points.assign(EventChart.deeps, 2);
    expect(accepted[EventChart.deeps], 2);
  });

  test('assigning across charts respects the shared budget', () {
    final points = const ChartPoints(earnedPoints: 3).assign(EventChart.wilds, 2);
    final rejected = points.assign(EventChart.hearth, 2);
    expect(identical(rejected, points), isTrue);
    final accepted = points.assign(EventChart.hearth, 1);
    expect(accepted.assignedTotal, 3);
    expect(accepted.unassigned, 0);
  });

  test('cannot go below zero per chart', () {
    final points = const ChartPoints(earnedPoints: 4).assign(EventChart.arcane, 1);
    final rejected = points.assign(EventChart.arcane, -2);
    expect(identical(rejected, points), isTrue);
    final accepted = points.assign(EventChart.arcane, -1);
    expect(accepted[EventChart.arcane], 0);
  });

  test('reassignment between charts works', () {
    final points = const ChartPoints(earnedPoints: 4)
        .assign(EventChart.wilds, 4)
        .assign(EventChart.wilds, -2)
        .assign(EventChart.deeps, 2);
    expect(points[EventChart.wilds], 2);
    expect(points[EventChart.deeps], 2);
  });

  test('canAssign mirrors assign legality', () {
    final points = const ChartPoints(earnedPoints: 2).assign(EventChart.wilds, 1);
    expect(points.canAssign(EventChart.wilds, 1), isTrue);
    expect(points.canAssign(EventChart.wilds, 2), isFalse);
    expect(points.canAssign(EventChart.wilds, -2), isFalse);
    expect(points.canAssign(EventChart.wilds, -1), isTrue);
  });

  test('earnedPoints is expected to be pre-clamped to 16 by callers', () {
    final points = const ChartPoints(earnedPoints: 16);
    final full = points.assign(EventChart.hearth, 16);
    expect(full.assignedTotal, 16);
    expect(full.canAssign(EventChart.hearth, 1), isFalse);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/data/models/events/chart_points_test.dart`
Expected: FAIL — cannot find `chart_points.dart`.

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/data/models/events/chart_points.dart
import 'package:maura_bastion_system/data/models/events/event_chart.dart';

class ChartPoints {
  static const int maxPoints = 16;

  final Map<EventChart, int> points;
  final int earnedPoints;

  const ChartPoints({this.points = const {}, required this.earnedPoints});

  int get assignedTotal =>
      points.values.fold(0, (sum, p) => sum + (p > 0 ? p : 0));

  int get unassigned => earnedPoints - assignedTotal;

  int operator [](EventChart chart) => points[chart] ?? 0;

  bool canAssign(EventChart chart, int delta) {
    final next = this[chart] + delta;
    if (next < 0) return false;
    return assignedTotal - (this[chart] < 0 ? this[chart] : 0) + delta <=
        earnedPoints;
  }

  ChartPoints assign(EventChart chart, int delta) {
    if (!canAssign(chart, delta)) return this;
    final next = this[chart] + delta;
    final updated = Map<EventChart, int>.from(points)..[chart] = next;
    return ChartPoints(points: updated, earnedPoints: earnedPoints);
  }
}
```

Note: `canAssign`'s budget check must compute the would-be total correctly for the negative-delta case (moving points between charts frees budget first). If the expression above mis-handles a case from the tests, adjust the implementation — the TESTS are the contract, and they all must pass.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/data/models/events/chart_points_test.dart`
Expected: PASS (8 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/data/models/events/chart_points.dart test/data/models/events/chart_points_test.dart
git commit -m "feat: add ChartPoints allocation model"
```

---

### Task 2: ChartPointsCubit

**Files:**
- Create: `lib/features/bastions_page/logic/chart_points_cubit.dart`
- Create: `lib/features/bastions_page/logic/chart_points_state.dart` (part file, following the `bastion_cubit.dart`/`bastion_state.dart` part pattern)
- Test: `test/features/bastions_page/logic/chart_points_cubit_test.dart`

**Interfaces:**
- Consumes: `ChartPoints`, `EventChart`, `Bastion` (`lib/data/models/bastion/bastion.dart`).
- Produces:
  - `class ChartPointsState extends Equatable { final String? bastionId; final ChartPoints points; const ChartPointsState({this.bastionId, this.points = const ChartPoints(earnedPoints: 0)}); }`
  - `class ChartPointsCubit extends Cubit<ChartPointsState> { ChartPointsCubit(); void load(Bastion bastion); void assign(EventChart chart, int delta); }`
    - `load` sets bastionId and `ChartPoints(earnedPoints: bastion.facilities.length.clamp(0, ChartPoints.maxPoints), points: const {})` — a fresh allocation per load (plan C adds persistence).
    - `assign` calls `state.points.assign(...)` and emits only when the model returned a new instance.

- [ ] **Step 1: Write the failing test**

```dart
// test/features/bastions_page/logic/chart_points_cubit_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:maura_bastion_system/data/models/bastion/bastion.dart';
import 'package:maura_bastion_system/data/models/events/chart_points.dart';
import 'package:maura_bastion_system/data/models/events/event_chart.dart';
import 'package:maura_bastion_system/data/models/npcs/defender.dart';
import 'package:maura_bastion_system/data/enums/defender_type.dart';
import 'package:maura_bastion_system/features/bastions_page/logic/chart_points_cubit.dart';

Bastion bastionWithFacilities(int count) => Bastion(
      id: 'b1',
      name: 'Test',
      description: '',
      facilities: List.generate(
        count,
        (i) => Facility(
          id: 'f$i',
          name: 'F$i',
          rank: Rank.D,
          description: '',
        ),
      ),
      defenders: [
        Defender(id: 'd1', type: DefenderType.bastionDefender, bastionId: 'b1'),
      ],
    );

void main() {
  late ChartPointsCubit cubit;

  setUp(() {
    cubit = ChartPointsCubit();
  });

  tearDown(() async {
    await cubit.close();
  });

  test('initial state is empty', () {
    expect(cubit.state.bastionId, isNull);
    expect(cubit.state.points.earnedPoints, 0);
  });

  test('load derives earned points from facilities, capped at 16', () {
    cubit.load(bastionWithFacilities(3));
    expect(cubit.state.bastionId, 'b1');
    expect(cubit.state.points.earnedPoints, 3);

    cubit.load(bastionWithFacilities(20));
    expect(cubit.state.points.earnedPoints, ChartPoints.maxPoints);
  });

  test('assign updates points within the loaded budget', () {
    cubit.load(bastionWithFacilities(3));
    cubit.assign(EventChart.wilds, 3);
    expect(cubit.state.points[EventChart.wilds], 3);
    cubit.assign(EventChart.wilds, 1);
    expect(cubit.state.points[EventChart.wilds], 3);
    cubit.assign(EventChart.wilds, -1);
    expect(cubit.state.points[EventChart.wilds], 2);
  });

  test('loading a different bastion resets the allocation', () {
    cubit.load(bastionWithFacilities(4));
    cubit.assign(EventChart.wilds, 4);
    cubit.load(bastionWithFacilities(2));
    expect(cubit.state.points.assignedTotal, 0);
    expect(cubit.state.points.earnedPoints, 2);
  });
}
```

Note: the test needs `import 'package:maura_bastion_system/data/models/bastion/facility.dart';` and `import 'package:maura_bastion_system/data/enums/rank.dart';` for `Facility`/`Rank` — add them.

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/bastions_page/logic/chart_points_cubit_test.dart`
Expected: FAIL — cannot find `chart_points_cubit.dart`.

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/features/bastions_page/logic/chart_points_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maura_bastion_system/data/models/bastion/bastion.dart';
import 'package:maura_bastion_system/data/models/events/chart_points.dart';
import 'package:maura_bastion_system/data/models/events/event_chart.dart';

part 'chart_points_state.dart';

class ChartPointsCubit extends Cubit<ChartPointsState> {
  ChartPointsCubit() : super(const ChartPointsState());

  void load(Bastion bastion) {
    emit(ChartPointsState(
      bastionId: bastion.id,
      points: ChartPoints(
        earnedPoints: bastion.facilities.length.clamp(0, ChartPoints.maxPoints),
      ),
    ));
  }

  void assign(EventChart chart, int delta) {
    final next = state.points.assign(chart, delta);
    if (!identical(next, state.points)) {
      emit(ChartPointsState(bastionId: state.bastionId, points: next));
    }
  }
}
```

```dart
// lib/features/bastions_page/logic/chart_points_state.dart
part of 'chart_points_cubit.dart';

class ChartPointsState extends Equatable {
  final String? bastionId;
  final ChartPoints points;

  const ChartPointsState({
    this.bastionId,
    this.points = const ChartPoints(earnedPoints: 0),
  });

  @override
  List<Object?> get props => [bastionId, points];
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/bastions_page/logic/chart_points_cubit_test.dart`
Expected: PASS (4 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/features/bastions_page/logic/chart_points_cubit.dart lib/features/bastions_page/logic/chart_points_state.dart test/features/bastions_page/logic/chart_points_cubit_test.dart
git commit -m "feat: add ChartPointsCubit for chart allocation"
```

---

### Task 3: ChartWebPanel page

**Files:**
- Create: `lib/features/bastions_page/presentation/chart_web_panel.dart`
- Test: `test/features/bastions_page/presentation/chart_web_panel_test.dart`

**Interfaces:**
- Consumes: `ChartPointsCubit` (Task 2), `computeChartSlices` + `ChartSlice` (A1), `ChartTier` (A1), `unlocksConvergence`/`unlocksRivalry` (A1), theme (`MedievalColors`, `GoogleFonts`), `ParchmentBorderPainter` (used by `bastion_turn_dialog.dart`).
- Produces: `class ChartWebPanel extends StatelessWidget { static Future<void> show(BuildContext context); const ChartWebPanel({super.key}); }` — `show` pushes a `MaterialPageRoute` to a `BlocProvider.value`-wrapped panel (the caller provides the cubit; the panel assumes one exists above it in the tree when used inside the bastions flow).
  - Layout: title 'The Chart Web'; header line 'X of Y points assigned' (unassigned/earned); six chart rows in a `ListView`: each row shows chart name (Cinzel), a minus button, the point count, a plus button (both disabled when `canAssign` fails), the tier badge ('—' when 0, else tier name), and the slice preview text ('rolls 1–50' from `computeChartSlices`; 'never fires' when 0). Rows with 0 points render dimmed (`sepiaMuted`).
  - A footer hint line: 'Convergence events unlocked' / 'Rivalry events unlocked' / 'Spread points to unlock Convergence events' based on the two predicates.
  - Close button.

- [ ] **Step 1: Write the failing test**

```dart
// test/features/bastions_page/presentation/chart_web_panel_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maura_bastion_system/features/bastions_page/logic/chart_points_cubit.dart';
import 'package:maura_bastion_system/features/bastions_page/presentation/chart_web_panel.dart';
import 'package:maura_bastion_system/data/models/events/event_chart.dart';

Widget harness({required ChartPointsCubit cubit}) => MaterialApp(
      home: BlocProvider.value(
        value: cubit,
        child: const ChartWebPanel(),
      ),
    );

void main() {
  testWidgets('shows all six charts and the points header', (tester) async {
    final cubit = ChartPointsCubit();
    cubit.load(_bastion(6));
    await tester.pumpWidget(harness(cubit: cubit));
    await tester.pumpAndSettle();

    expect(find.text('The Chart Web'), findsOneWidget);
    expect(find.textContaining('The Wilds'), findsOneWidget);
    expect(find.textContaining('The Arcane'), findsOneWidget);
    expect(find.text('4 of 6 points unassigned'), findsOneWidget);
    expect(find.text('never fires'), findsNWidgets(6));
  });

  testWidgets('plus button assigns a point and preview updates',
      (tester) async {
    final cubit = ChartPointsCubit();
    cubit.load(_bastion(2));
    await tester.pumpWidget(harness(cubit: cubit));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add).first);
    await tester.pumpAndSettle();

    expect(cubit.state.points[EventChart.wilds], 1);
    expect(find.text('1 of 2 points unassigned'), findsOneWidget);
    expect(find.textContaining('rolls 1'), findsOneWidget);
    expect(find.textContaining('Basic'), findsWidgets);
  });

  testWidgets('minus button unassigns and clamps at zero', (tester) async {
    final cubit = ChartPointsCubit();
    cubit.load(_bastion(1));
    await tester.pumpWidget(harness(cubit: cubit));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.add).first);
    await tester.pumpAndSettle();
    expect(cubit.state.points[EventChart.wilds], 1);
    expect(tester.widgetList(find.byIcon(Icons.add).first), isNotNull);

    await tester.tap(find.byIcon(Icons.remove).first);
    await tester.pumpAndSettle();
    expect(cubit.state.points[EventChart.wilds], 0);

    await tester.tap(find.byIcon(Icons.remove).first);
    await tester.pumpAndSettle();
    expect(cubit.state.points[EventChart.wilds], 0);
  });

  testWidgets('shows convergence hint when unlocked', (tester) async {
    final cubit = ChartPointsCubit();
    cubit.load(_bastion(16));
    cubit.assign(EventChart.wilds, 4);
    cubit.assign(EventChart.deeps, 4);
    cubit.assign(EventChart.hearth, 4);
    await tester.pumpWidget(harness(cubit: cubit));
    await tester.pumpAndSettle();

    expect(find.textContaining('Convergence'), findsOneWidget);
  });
}

// Local helper: a Bastion with [count] minimal facilities.
dynamic _bastion(int count) => throw UnimplementedError();
```

NOTE: `_bastion` must be implemented in the test as a real `Bastion` with `count` minimal `Facility` entries (same shape as the cubit test's `bastionWithFacilities` helper) — copy that helper's construction. The `dynamic ... throw UnimplementedError()` stub above exists only to show where it goes; replace it entirely.

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/bastions_page/presentation/chart_web_panel_test.dart`
Expected: FAIL — cannot find `chart_web_panel.dart`.

- [ ] **Step 3: Write the widget**

```dart
// lib/features/bastions_page/presentation/chart_web_panel.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:maura_bastion_system/core/themes/theme_colors.dart';
import 'package:maura_bastion_system/data/models/events/archetypes.dart';
import 'package:maura_bastion_system/data/models/events/chart_points.dart';
import 'package:maura_bastion_system/data/models/events/chart_slices.dart';
import 'package:maura_bastion_system/data/models/events/chart_tier.dart';
import 'package:maura_bastion_system/data/models/events/event_chart.dart';
import 'package:maura_bastion_system/features/bastions_page/logic/chart_points_cubit.dart';

class ChartWebPanel extends StatelessWidget {
  const ChartWebPanel({super.key});

  static Future<void> show(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<ChartPointsCubit>(),
          child: const ChartWebPanel(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<ChartPointsCubit>();
    final points = cubit.state.points;
    final slices = computeChartSlices(points.points);
    String hint;
    if (unlocksRivalry(points.points)) {
      hint = 'Rivalry events unlocked';
    } else if (unlocksConvergence(points.points)) {
      hint = 'Convergence events unlocked';
    } else {
      hint = 'Spread points to unlock Convergence events';
    }

    return Scaffold(
      backgroundColor: MedievalColors.parchment,
      appBar: AppBar(
        backgroundColor: MedievalColors.parchmentDark,
        title: Text(
          'The Chart Web',
          style: GoogleFonts.cinzel(
            color: MedievalColors.vermillion,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              '${points.unassigned} of ${points.earnedPoints} points unassigned',
              style: GoogleFonts.imFellEnglish(
                fontSize: 16,
                color: MedievalColors.sepiaInk,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                for (final chart in EventChart.values)
                  _ChartRow(
                    chart: chart,
                    points: points,
                    slice: slices.where((s) => s.chart == chart).firstOrNull,
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              hint,
              style: GoogleFonts.imFellEnglish(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: MedievalColors.sepiaSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartRow extends StatelessWidget {
  final EventChart chart;
  final ChartPoints points;
  final ChartSlice? slice;

  const _ChartRow({
    required this.chart,
    required this.points,
    required this.slice,
  });

  String get _sliceText {
    final value = points[chart];
    if (value == 0) return 'never fires';
    return 'rolls ${slice!.rollMin}\u2013${slice!.rollMax}';
  }

  @override
  Widget build(BuildContext context) {
    final value = points[chart];
    final dimmed = value == 0;
    final color = dimmed ? MedievalColors.sepiaMuted : MedievalColors.sepiaInk;
    final tier = ChartTier.forPoints(value);

    return ListTile(
      title: Text(
        chart.displayName,
        style: GoogleFonts.cinzel(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
      subtitle: Text(
        '$value points \u00b7 ${tier == null ? '\u2014' : tier.name} \u00b7 $_sliceText',
        style: GoogleFonts.imFellEnglish(fontSize: 14, color: color),
      ),
      leading: IconButton(
        icon: const Icon(Icons.remove),
        onPressed: points.canAssign(chart, -1)
            ? () => context.read<ChartPointsCubit>().assign(chart, -1)
            : null,
      ),
      trailing: IconButton(
        icon: const Icon(Icons.add),
        onPressed: points.canAssign(chart, 1)
            ? () => context.read<ChartPointsCubit>().assign(chart, 1)
            : null,
      ),
    );
  }
}
```

Note: `firstOrNull` requires `package:collection` (already a transitive Flutter dep) — add `import 'package:collection/collection.dart';`. If the project's analyzer flags it, replace with a manual `where(...).isEmpty ? null : slices.where(...).first`.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/bastions_page/presentation/chart_web_panel_test.dart`
Expected: PASS (4 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/features/bastions_page/presentation/chart_web_panel.dart test/features/bastions_page/presentation/chart_web_panel_test.dart
git commit -m "feat: add Chart Web allocation panel"
```

---

### Task 4: Entry point on the bastion page

**Files:**
- Modify: `lib/features/bastions_page/presentation/bastion_page.dart`
- Test: `test/features/bastions_page/presentation/bastion_page_test.dart` (extend)

**Interfaces:**
- Consumes: `ChartPointsCubit` (Task 2), `ChartWebPanel.show` (Task 3), the existing `BastionLoadedState`/`BastionCubit` wiring in `bastion_page.dart`.
- Produces: the bastion page provides `BlocProvider(create: ChartPointsCubit(), ...)` above its build (or nests a `BlocProvider.value` if a parent already provides it — match the page's existing provider structure), and renders a **'Chart Web' button** between the description and `_buildRankedFacilities`, calling `ChartPointsCubit.load(bastion)` on tap then `ChartWebPanel.show(context)`.

- [ ] **Step 1: Write the failing test** (extend `bastion_page_test.dart`)

```dart
  testWidgets('Chart Web button opens the allocation panel', (tester) async {
    // Arrange: use the file's existing pumped-bastion-page harness (same
    // setup as the file's other tests — GetIt mocks, BlocProviders, and a
    // BastionLoadedState with a user bastion). Pump it, then:
    await tester.tap(find.text('Chart Web'));
    await tester.pumpAndSettle();
    expect(find.text('The Chart Web'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsWidgets);
  });
```

NOTE: adapt to the file's actual existing harness (the file already has tests that pump the bastion page with a loaded bastion — reuse that setup verbatim; the assertion above is the contract: tapping 'Chart Web' shows 'The Chart Web' panel). If a provider error appears for `ChartPointsCubit`, ensure the page's provider wiring supplies it (that is the production change under test).

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/bastions_page/presentation/bastion_page_test.dart`
Expected: FAIL — no 'Chart Web' button on the page yet.

- [ ] **Step 3: Implement the wiring**

In `bastion_page.dart`: wrap the page body's existing Bloc structure so a `ChartPointsCubit` is available (add `BlocProvider(create: (_) => ChartPointsCubit())` alongside the existing providers in the page's build tree), and insert between the description block and `_buildRankedFacilities(context, bastion, allBuilt)`:

```dart
                    Center(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.hub_outlined),
                        label: Text(
                          'Chart Web',
                          style: GoogleFonts.cinzel(
                            color: MedievalColors.vermillion,
                          ),
                        ),
                        onPressed: () {
                          context.read<ChartPointsCubit>().load(bastion);
                          ChartWebPanel.show(context);
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
```

Add the imports for `ChartPointsCubit` and `ChartWebPanel`. Match the surrounding indentation of the description/facilities blocks exactly.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/bastions_page/presentation/bastion_page_test.dart`
Expected: PASS (all tests in the file, including the new one).

- [ ] **Step 5: Commit**

```bash
git add lib/features/bastions_page/presentation/bastion_page.dart test/features/bastions_page/presentation/bastion_page_test.dart
git commit -m "feat: add Chart Web entry point to bastion page"
```

---

### Task 5: Verification

- [ ] **Step 1:** Run `flutter test` — expect full suite pass.
- [ ] **Step 2:** Run `flutter analyze` — expect no new issues (existing pre-existing infos are acceptable; report them).
