# Chart Web D4 — Completed-Facility Points + Base Grant Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Chart points come from **completed** facilities only (under-construction ones earn nothing), and every bastion earns a **floor of 4 points** so small bastions still get a fun, varied event web. Formula: `earned = clamp(max(4, completedFacilities), 0, 16)`.

**Architecture:** A static `ChartPoints.earnedPointsFor(Bastion bastion)` encapsulates the rule; `ChartPointsCubit.load` uses it. The panel, D3 randomization, and engine are untouched — with all earned points auto-dealt at turn time, small bastions get Basic-tier events from random charts every turn.

**Tech Stack:** Dart / Flutter.

## Global Constraints

- Completed = `facility.constructedTurns >= facility.constructionTurns` (matches the existing turn-dialog eligibility check's construction half; hireling requirements do NOT affect points).
- Floor of **4** points for every bastion; cap **16** unchanged.
- `ChartPointsCubit` public API unchanged; only the earned-points derivation changes.

---

### Task 1: earnedPointsFor + cubit wiring

**Files:**
- Modify: `lib/data/models/events/chart_points.dart` (add static helper; needs `Bastion` import)
- Modify: `lib/features/bastions_page/logic/chart_points_cubit.dart` (use the helper)
- Test: `test/data/models/events/chart_points_test.dart` (extend) + `test/features/bastions_page/logic/chart_points_cubit_test.dart` (extend)

**Interfaces:**
- Produces: `static int earnedPointsFor(Bastion bastion)` — `clamp(max(4, completedCount), 0, maxPoints)` where completed counts facilities with `constructedTurns >= constructionTurns`.

- [ ] **Step 1: Write failing tests**

In `chart_points_test.dart` (append inside `main`; add imports for `Bastion`, `Facility`, `Rank`):

```dart
  group('earnedPointsFor', () {
    Facility facility(int constructed, int construction) => Facility(
          id: 'f',
          name: 'F',
          rank: Rank.D,
          description: '',
          constructedTurns: constructed,
          constructionTurns: construction,
        );

    test('under-construction facilities earn nothing', () {
      final bastion = Bastion(
        id: 'b',
        name: 'B',
        description: '',
        facilities: [facility(0, 3), facility(1, 2)],
      );
      expect(ChartPoints.earnedPointsFor(bastion), 4); // floor applies
    });

    test('completed facilities count', () {
      final bastion = Bastion(
        id: 'b',
        name: 'B',
        description: '',
        facilities: [facility(3, 3), facility(2, 2), facility(0, 1)],
      );
      expect(ChartPoints.earnedPointsFor(bastion), 4); // 2 completed < floor
    });

    test('floor of four', () {
      final bastion = Bastion(
        id: 'b',
        name: 'B',
        description: '',
        facilities: [facility(1, 1)],
      );
      expect(ChartPoints.earnedPointsFor(bastion), 4);
    });

    test('scales past the floor and caps at 16', () {
      final bastion = Bastion(
        id: 'b',
        name: 'B',
        description: '',
        facilities: List.generate(9, (i) => facility(1, 1)),
      );
      expect(ChartPoints.earnedPointsFor(bastion), 9);

      final huge = Bastion(
        id: 'b',
        name: 'B',
        description: '',
        facilities: List.generate(30, (i) => facility(1, 1)),
      );
      expect(ChartPoints.earnedPointsFor(huge), ChartPoints.maxPoints);
    });
  });
```

In `chart_points_cubit_test.dart` (append inside `main`; adapt the file's existing `bastionWithFacilities` helper to accept constructed/construction values or add a new helper):

```dart
  test('load counts only completed facilities and applies the floor', () {
    final bastion = Bastion(
      id: 'b1',
      name: 'T',
      description: '',
      facilities: [
        Facility(id: 'f1', name: 'F1', rank: Rank.D, description: '',
            constructedTurns: 2, constructionTurns: 2),
        Facility(id: 'f2', name: 'F2', rank: Rank.D, description: '',
            constructedTurns: 0, constructionTurns: 2),
      ],
    );
    cubit.load(bastion);
    expect(cubit.state.points.earnedPoints, 4); // 1 completed < floor 4
  });
```

NOTE: the existing cubit test 'load derives earned points from facilities, capped at 16' constructs facilities with default `constructionTurns: 0, constructedTurns: 0` — which is COMPLETED (0 >= 0), so it still passes. Verify that assumption when running.

- [ ] **Step 2: Run to verify failure**

Run: `flutter test test/data/models/events/chart_points_test.dart test/features/bastions_page/logic/chart_points_cubit_test.dart`
Expected: FAIL — no `earnedPointsFor`; cubit counts under-construction facilities.

- [ ] **Step 3: Implement**

`chart_points.dart` (add `import 'package:maura_bastion_system/data/models/bastion/bastion.dart';` — watch for import cycles; `Bastion` imports no events models, so it is safe):

```dart
  static int earnedPointsFor(Bastion bastion) {
    final completed = bastion.facilities
        .where((f) => f.constructedTurns >= f.constructionTurns)
        .length;
    return clamp(max(4, completed), 0, maxPoints);
  }
```

(`max` needs `dart:math`; write the clamp manually or use `.clamp(0, maxPoints)` on the int — `max(4, completed).clamp(0, maxPoints)` returns num; cast or use `math.max` with explicit int handling. Keep it clean.)

`chart_points_cubit.dart` `load`:

```dart
  void load(Bastion bastion) {
    emit(ChartPointsState(
      bastionId: bastion.id,
      points: ChartPoints(earnedPoints: ChartPoints.earnedPointsFor(bastion)),
    ));
  }
```

(the old `facilities.length.clamp(...)` derivation goes away)

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/data/models/events/chart_points_test.dart test/features/bastions_page/logic/chart_points_cubit_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/data/models/events/chart_points.dart lib/features/bastions_page/logic/chart_points_cubit.dart test/data/models/events/chart_points_test.dart test/features/bastions_page/logic/chart_points_cubit_test.dart
git commit -m "feat: chart points from completed facilities with a four-point floor"
```

---

### Task 2: Verification

- [ ] **Step 1:** `flutter test` — full suite pass.
- [ ] **Step 2:** `flutter analyze` — no new issues.
