# Chart Web D2 — Quiet Turns from Unassigned Points Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Unspent chart points become a hidden "Quiet" share of the 1d100: a bastion that assigns all 16 points gets events every turn; unassigned points translate proportionally into quiet turns. No allocation UI changes.

**Architecture:** `ChartTurnEngine.rollTurn` gains an optional `earnedPoints` parameter. Quiet share = `earnedPoints - assignedTotal`, clamped ≥ 0, expressed as `quietShare = quiet * 100 ~/ earnedPoints` (floor). Rolls in 1..quietShare land on the existing uneventful table; the remainder maps onto the chart slices by scaling (`scaledRoll = 1 + ((roll - quietShare) * 100 - 1) ~/ (100 - quietShare)`), preserving uniformity. Existing behaviors are preserved: zero earned/assigned → always uneventful; earned == assigned → never quiet (quietShare = 0).

**Tech Stack:** Dart / Flutter.

**Spec note:** supersedes "charts with zero points never fire → always uneventful when unassigned exist" — unassigned points now buy quiet instead of nothing. The spec's Zero-points clause becomes: the Quiet share is proportional to unassigned points.

## Global Constraints

- `earnedPoints` defaults to null → old behavior exactly (quiet share 0; zero-points → uneventful). The page passes `pointsCubit.state.points.earnedPoints`.
- Quiet turns use the same 4 uneventful pseudo-events. Event turns are unaffected in distribution *relative to each other*.
- Determinism for a fixed seed (as before).
- House style: no comments unless non-obvious.

---

### Task 1: Engine quiet share + page wiring

**Files:**
- Modify: `lib/data/models/events/turn_engine.dart` (`rollTurn` signature + quiet logic)
- Modify: `lib/features/bastions_page/presentation/bastion_page.dart` (pass `earnedPoints`)
- Test: `test/data/models/events/turn_engine_test.dart` (extend) + page test stays green

**Interfaces:**
- Produces: `ChartTurnRoll rollTurn({required Map<EventChart, int> points, int? earnedPoints, Random? rng})`.

- [ ] **Step 1: Write failing tests** (append inside `main` of `turn_engine_test.dart`; `Random` already imported)

```dart
  group('quiet turns from unassigned points', () {
    test('earned == assigned never yields a quiet turn', () {
      for (var i = 0; i < 200; i++) {
        final roll = engine.rollTurn(
          points: {EventChart.wilds: 8},
          earnedPoints: 8,
          rng: Random(i),
        );
        expect(roll.event.id, isNot(startsWith('unt_')));
      }
    });

    test('all points unassigned is always quiet', () {
      for (var i = 0; i < 20; i++) {
        final roll = engine.rollTurn(
          points: const {},
          earnedPoints: 6,
          rng: Random(i),
        );
        expect(roll.event.id, startsWith('unt_'));
      }
    });

    test('half-unassigned is roughly half quiet', () {
      var quiet = 0;
      for (var i = 0; i < 1000; i++) {
        final roll = engine.rollTurn(
          points: {EventChart.wilds: 8},
          earnedPoints: 16,
          rng: Random(i),
        );
        if (roll.event.id.startsWith('unt_')) quiet++;
      }
      expect(quiet, inInclusiveRange(400, 600));
    });

    test('event turns still only come from funded charts', () {
      for (var i = 0; i < 200; i++) {
        final roll = engine.rollTurn(
          points: {EventChart.wilds: 4, EventChart.deeps: 4},
          earnedPoints: 16,
          rng: Random(500 + i),
        );
        if (roll.event.id.startsWith('unt_')) continue;
        expect({EventChart.wilds, EventChart.deeps}.contains(roll.event.chart), isTrue);
      }
    });

    test('without earnedPoints the old behavior is unchanged', () {
      var quiet = 0;
      for (var i = 0; i < 200; i++) {
        final roll = engine.rollTurn(
          points: {EventChart.wilds: 8},
          rng: Random(i),
        );
        if (roll.event.id.startsWith('unt_')) quiet++;
      }
      expect(quiet, 0);
    });
  });
```

- [ ] **Step 2: Run to verify failure**

Run: `flutter test test/data/models/events/turn_engine_test.dart`
Expected: FAIL — `earnedPoints` parameter does not exist (or quiet never fires).

- [ ] **Step 3: Implement**

`rollTurn` in `turn_engine.dart`:

```dart
  ChartTurnRoll rollTurn({
    required Map<EventChart, int> points,
    int? earnedPoints,
    Random? rng,
  }) {
    final random = rng ?? Random();
    final events = catalog();
    final assigned =
        points.values.fold(0, (sum, p) => sum + (p > 0 ? p : 0));
    final budget = earnedPoints ?? assigned;
    if (budget <= 0) {
      return ChartTurnRoll(
        slice: null,
        event: _uneventfulEvents[random.nextInt(_uneventfulEvents.length)],
        tier: ChartTier.basic,
      );
    }
    final quiet = (budget - assigned).clamp(0, budget);
    final quietShare = quiet * 100 ~/ budget;
    final roll = random.nextInt(100) + 1;
    if (roll <= quietShare) {
      return ChartTurnRoll(
        slice: null,
        event: _uneventfulEvents[random.nextInt(_uneventfulEvents.length)],
        tier: ChartTier.basic,
      );
    }
    final scaledRoll =
        1 + ((roll - quietShare) * 100 - 1) ~/ (100 - quietShare);
    final slices = computeChartSlices(points);
    final slice = slices.firstWhere((s) => s.contains(scaledRoll));
    final tier = ChartTier.forPoints(slice.points)!;
    final pool = events
        .where((e) => !e.isArchetype && e.chart == slice.chart && e.tier == tier)
        .toList();
    if (pool.isEmpty) {
      throw ArgumentError('No events for chart ${slice.chart} at tier $tier');
    }
    return ChartTurnRoll(
      slice: slice,
      event: pool[random.nextInt(pool.length)],
      tier: tier,
    );
  }
```

(This replaces the current body; keep the existing `ArgumentError` empty-pool guard semantics. If an existing test asserts a specific slice for a fixed seed and the scaling shifts it, adjust that test's expectation ONLY if it was asserting an internal roll value — the behavioral contracts above are the spec.)

Page wiring (`bastion_page.dart`): the roll call becomes

```dart
    final roll = const ChartTurnEngine().rollTurn(
      points: pointsCubit.state.points.points,
      earnedPoints: pointsCubit.state.points.earnedPoints,
    );
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/data/models/events/turn_engine_test.dart test/features/bastions_page/presentation/bastion_page_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/data/models/events/turn_engine.dart lib/features/bastions_page/presentation/bastion_page.dart test/data/models/events/turn_engine_test.dart
git commit -m "feat: unassigned chart points buy quiet turns"
```

---

### Task 2: Verification

- [ ] **Step 1:** `flutter test` — full suite pass.
- [ ] **Step 2:** `flutter analyze` — no new issues.
