# Chart Web D3 — Random Assignment of Unspent Points at Turn Time Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** When an individual turn is rolled, any points the player left unassigned are distributed randomly across the six charts for that turn. The player's saved allocation is never modified — randomization is per-turn and non-destructive (they keep full control in the panel). With this, quiet-from-unassigned effectively disappears (every point is in play each turn).

**Architecture:** A pure helper on `ChartPoints` produces the effective allocation map; `_takeBastionTurn` uses it before the engine roll. `ChartTurnEngine` is unchanged (its quiet-share path simply receives a fully-assigned map).

**Tech Stack:** Dart / Flutter.

**Spec note:** supersedes D2's "unassigned points buy quiet turns" behavior at the call site. The engine's quiet-share logic remains (harmless, still covered by tests) but the app no longer reaches it.

## Global Constraints

- Randomization happens at roll time only; `ChartPointsCubit` state and the persisted allocation are untouched.
- Explicit assignments are preserved exactly; only `unassigned` points are spread, one point per pick, uniformly at random over the six charts (repetition allowed).
- The effective map's total always equals `earnedPoints` (when earned > 0).
- House style: no comments unless non-obvious.

---

### Task 1: randomizedAllocation helper + page wiring

**Files:**
- Modify: `lib/data/models/events/chart_points.dart` (add helper)
- Modify: `lib/features/bastions_page/presentation/bastion_page.dart` (use it at the roll)
- Test: `test/data/models/events/chart_points_test.dart` (extend) + page test stays green

**Interfaces:**
- Produces: `Map<EventChart, int> randomizedAllocation({Random? rng})` on `ChartPoints` — returns a new map (never mutates `points`): explicit assignments copied verbatim, then `unassigned` points distributed by picking a uniformly random chart per point (repetition allowed). Uses `dart:math`.

- [ ] **Step 1: Write failing tests** (append inside `main` of `chart_points_test.dart`; add `dart:math` import)

```dart
  group('randomizedAllocation', () {
    test('fully assigned allocation is returned unchanged', () {
      final points = const ChartPoints(earnedPoints: 4).assign(EventChart.wilds, 4);
      final effective = points.randomizedAllocation(rng: Random(1));
      expect(effective, {EventChart.wilds: 4});
    });

    test('explicit assignments are preserved and totals fill to earned', () {
      final points = const ChartPoints(earnedPoints: 6)
          .assign(EventChart.wilds, 2)
          .assign(EventChart.deeps, 1);
      for (var i = 0; i < 20; i++) {
        final effective = points.randomizedAllocation(rng: Random(i));
        expect(effective[EventChart.wilds], 2);
        expect(effective[EventChart.deeps], 1);
        final total = EventChart.values.fold<int>(0, (s, c) => s + (effective[c] ?? 0));
        expect(total, 6);
      }
    });

    test('source allocation is not mutated', () {
      final points = const ChartPoints(earnedPoints: 3);
      points.randomizedAllocation(rng: Random(1));
      expect(points.assignedTotal, 0);
      expect(points.unassigned, 3);
    });

    test('zero earned points yields an empty map', () {
      const points = ChartPoints(earnedPoints: 0);
      expect(points.randomizedAllocation(rng: Random(1)), isEmpty);
    });
  });
```

- [ ] **Step 2: Run to verify failure**

Run: `flutter test test/data/models/events/chart_points_test.dart`
Expected: FAIL — no `randomizedAllocation`.

- [ ] **Step 3: Implement**

In `chart_points.dart` (add `import 'dart:math';` and the `EventChart` import already exists):

```dart
  Map<EventChart, int> randomizedAllocation({Random? rng}) {
    final random = rng ?? Random();
    final effective = Map<EventChart, int>.from(points);
    var remaining = unassigned;
    while (remaining > 0) {
      final chart = EventChart.values[random.nextInt(EventChart.values.length)];
      effective[chart] = (effective[chart] ?? 0) + 1;
      remaining--;
    }
    return effective;
  }
```

Page wiring (`bastion_page.dart`, in `_takeBastionTurn` where the roll happens):

```dart
    final chartPoints = pointsCubit.state.points;
    final roll = const ChartTurnEngine().rollTurn(
      points: chartPoints.randomizedAllocation(),
      earnedPoints: chartPoints.earnedPoints,
    );
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/data/models/events/chart_points_test.dart test/features/bastions_page/presentation/bastion_page_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/data/models/events/chart_points.dart lib/features/bastions_page/presentation/bastion_page.dart test/data/models/events/chart_points_test.dart
git commit -m "feat: auto-assign unspent points randomly at turn time"
```

---

### Task 2: Verification

- [ ] **Step 1:** `flutter test` — full suite pass.
- [ ] **Step 2:** `flutter analyze` — no new issues.
