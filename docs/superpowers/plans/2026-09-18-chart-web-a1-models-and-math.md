# Chart Web A1 — Models & Math Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the pure-Dart foundation of the Chart Web reward system: the six event charts, tier thresholds, d100 slice allocation, and archetype unlock rules.

**Architecture:** Four small model files under `lib/data/models/events/`, each independently unit-tested. No UI, no state management — later plans (A2–A9) build dispatch resolution, reward rolling, the event catalog, the turn engine, and inventory on top of these types.

**Tech Stack:** Dart / Flutter (no new dependencies). Tests run with `flutter test`.

**Spec:** `docs/superpowers/specs/2026-09-18-chart-web-reward-system-design.md`

## Global Constraints

- Max points per bastion: **16** (1 per built facility).
- Tier thresholds: **1–3 Basic, 4–7 Skilled, 8–12 Master, 13–16 Legend**.
- Tier reward rank caps: **Basic→Rank D, Skilled→Rank B, Master→Rank A, Legend→Rank S**.
- d100 slices: proportional to points, **largest-remainder rounding**, always summing to 100; example 8/5/3 points → 1–50 / 51–81 / 82–100.
- Charts with 0 points get **no slice** (never fire).
- Convergence unlock: **4+ points in 3 different charts**. Rivalry unlock: **8+ points in 2 different charts**.
- Follow existing code style: no comments unless explaining a non-obvious rule; models are plain classes with `const` constructors (see `lib/data/models/bastion/facility.dart` for the house style).

## Remaining roadmap (context only — do NOT build in this plan)

A2 dispatch resolver, A3 reward rolling, A4–A6 event catalogs, A7 archetype events, A8 turn engine, A9 inventory, B1–B2 UI, C persistence.

---

### Task 1: EventChart enum

**Files:**
- Create: `lib/data/models/events/event_chart.dart`
- Test: `test/data/models/events/event_chart_test.dart`

**Interfaces:**
- Produces: `enum EventChart { wilds, deeps, tradeRoad, warMarch, hearth, arcane }` with `final String displayName` and `final List<RewardCategory> rewardCategories` per value.

- [ ] **Step 1: Write the failing test**

```dart
// test/data/models/events/event_chart_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:maura_bastion_system/data/models/events/event_chart.dart';
import 'package:maura_bastion_system/data/models/rewards/reward.dart';

void main() {
  test('has six charts with display names', () {
    expect(EventChart.values.length, 6);
    expect(EventChart.wilds.displayName, 'The Wilds');
    expect(EventChart.deeps.displayName, 'The Deeps');
    expect(EventChart.tradeRoad.displayName, 'The Trade Road');
    expect(EventChart.warMarch.displayName, 'The War March');
    expect(EventChart.hearth.displayName, 'The Hearth');
    expect(EventChart.arcane.displayName, 'The Arcane');
  });

  test('reward categories match the spec', () {
    expect(EventChart.wilds.rewardCategories,
        [RewardCategory.creaturePart, RewardCategory.meat, RewardCategory.blood, RewardCategory.herb]);
    expect(EventChart.deeps.rewardCategories, [RewardCategory.metal, RewardCategory.stone]);
    expect(EventChart.tradeRoad.rewardCategories, [RewardCategory.weave]);
    expect(EventChart.warMarch.rewardCategories, [RewardCategory.creaturePart]);
    expect(EventChart.hearth.rewardCategories, isEmpty);
    expect(EventChart.arcane.rewardCategories, [RewardCategory.herb, RewardCategory.weave]);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/data/models/events/event_chart_test.dart`
Expected: FAIL — cannot find `event_chart.dart` / `EventChart`.

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/data/models/events/event_chart.dart
import 'package:maura_bastion_system/data/models/rewards/reward.dart';

enum EventChart {
  wilds('The Wilds', [
    RewardCategory.creaturePart,
    RewardCategory.meat,
    RewardCategory.blood,
    RewardCategory.herb,
  ]),
  deeps('The Deeps', [RewardCategory.metal, RewardCategory.stone]),
  tradeRoad('The Trade Road', [RewardCategory.weave]),
  warMarch('The War March', [RewardCategory.creaturePart]),
  hearth('The Hearth', []),
  arcane('The Arcane', [RewardCategory.herb, RewardCategory.weave]);

  final String displayName;
  final List<RewardCategory> rewardCategories;

  const EventChart(this.displayName, this.rewardCategories);
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/data/models/events/event_chart_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/data/models/events/event_chart.dart test/data/models/events/event_chart_test.dart
git commit -m "feat: add EventChart enum for chart web"
```

---

### Task 2: ChartTier enum

**Files:**
- Create: `lib/data/models/events/chart_tier.dart`
- Test: `test/data/models/events/chart_tier_test.dart`

**Interfaces:**
- Produces: `enum ChartTier { basic, skilled, master, legend }` with:
  - `static ChartTier? forPoints(int points)` — null for points ≤ 0
  - `Rank get rewardRankCap`
  - `int get minPoints` / `int get maxPoints`

- [ ] **Step 1: Write the failing test**

```dart
// test/data/models/events/chart_tier_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:maura_bastion_system/data/enums/rank.dart';
import 'package:maura_bastion_system/data/models/events/chart_tier.dart';

void main() {
  test('forPoints maps tier thresholds', () {
    expect(ChartTier.forPoints(0), isNull);
    expect(ChartTier.forPoints(-2), isNull);
    expect(ChartTier.forPoints(1), ChartTier.basic);
    expect(ChartTier.forPoints(3), ChartTier.basic);
    expect(ChartTier.forPoints(4), ChartTier.skilled);
    expect(ChartTier.forPoints(7), ChartTier.skilled);
    expect(ChartTier.forPoints(8), ChartTier.master);
    expect(ChartTier.forPoints(12), ChartTier.master);
    expect(ChartTier.forPoints(13), ChartTier.legend);
    expect(ChartTier.forPoints(16), ChartTier.legend);
  });

  test('reward rank caps per spec', () {
    expect(ChartTier.basic.rewardRankCap, Rank.D);
    expect(ChartTier.skilled.rewardRankCap, Rank.B);
    expect(ChartTier.master.rewardRankCap, Rank.A);
    expect(ChartTier.legend.rewardRankCap, Rank.S);
  });

  test('point ranges are contiguous 1..16', () {
    expect(ChartTier.basic.minPoints, 1);
    expect(ChartTier.basic.maxPoints, 3);
    expect(ChartTier.skilled.minPoints, 4);
    expect(ChartTier.skilled.maxPoints, 7);
    expect(ChartTier.master.minPoints, 8);
    expect(ChartTier.master.maxPoints, 12);
    expect(ChartTier.legend.minPoints, 13);
    expect(ChartTier.legend.maxPoints, 16);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/data/models/events/chart_tier_test.dart`
Expected: FAIL — cannot find `chart_tier.dart`.

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/data/models/events/chart_tier.dart
import 'package:maura_bastion_system/data/enums/rank.dart';

enum ChartTier {
  basic,
  skilled,
  master,
  legend;

  static ChartTier? forPoints(int points) {
    if (points <= 0) return null;
    if (points <= 3) return basic;
    if (points <= 7) return skilled;
    if (points <= 12) return master;
    return legend;
  }

  /// Best reward rank this tier may roll. Rank-null materials (metals,
  /// creature parts, ...) are harvested at this rank.
  Rank get rewardRankCap {
    switch (this) {
      case basic:
        return Rank.D;
      case skilled:
        return Rank.B;
      case master:
        return Rank.A;
      case legend:
        return Rank.S;
    }
  }

  int get minPoints {
    switch (this) {
      case basic:
        return 1;
      case skilled:
        return 4;
      case master:
        return 8;
      case legend:
        return 13;
    }
  }

  int get maxPoints {
    switch (this) {
      case basic:
        return 3;
      case skilled:
        return 7;
      case master:
        return 12;
      case legend:
        return 16;
    }
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/data/models/events/chart_tier_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/data/models/events/chart_tier.dart test/data/models/events/chart_tier_test.dart
git commit -m "feat: add ChartTier thresholds and reward rank caps"
```

---

### Task 3: ChartSlice + d100 slice math

**Files:**
- Create: `lib/data/models/events/chart_slices.dart`
- Test: `test/data/models/events/chart_slices_test.dart`

**Interfaces:**
- Consumes: `EventChart` (Task 1).
- Produces: `class ChartSlice { final EventChart chart; final int points; final int rollMin; final int rollMax; bool contains(int roll); }` and `List<ChartSlice> computeChartSlices(Map<EventChart, int> points)`. Slices are ordered by points descending (ties by `EventChart` declaration order), contiguous from 1 to 100.

- [ ] **Step 1: Write the failing test**

```dart
// test/data/models/events/chart_slices_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:maura_bastion_system/data/models/events/chart_slices.dart';
import 'package:maura_bastion_system/data/models/events/event_chart.dart';

void main() {
  test('single chart owns the whole 1-100 range', () {
    final slices = computeChartSlices({EventChart.wilds: 8});
    expect(slices.length, 1);
    expect(slices.single.rollMin, 1);
    expect(slices.single.rollMax, 100);
  });

  test('spec example 8/5/3 -> 1-50, 51-81, 82-100 (largest remainder)', () {
    final slices = computeChartSlices({
      EventChart.wilds: 8,
      EventChart.tradeRoad: 5,
      EventChart.hearth: 3,
    });
    expect(slices.map((s) => s.chart), [EventChart.wilds, EventChart.tradeRoad, EventChart.hearth]);
    expect(slices[0].rollMin, 1);
    expect(slices[0].rollMax, 50);
    expect(slices[1].rollMin, 51);
    expect(slices[1].rollMax, 81);
    expect(slices[2].rollMin, 82);
    expect(slices[2].rollMax, 100);
  });

  test('tie in points breaks by chart declaration order', () {
    final slices = computeChartSlices({EventChart.deeps: 8, EventChart.wilds: 8});
    expect(slices.map((s) => s.chart), [EventChart.wilds, EventChart.deeps]);
    expect(slices[0].rollMin, 1);
    expect(slices[0].rollMax, 50);
    expect(slices[1].rollMin, 51);
    expect(slices[1].rollMax, 100);
  });

  test('charts with zero or missing points get no slice', () {
    final slices = computeChartSlices({
      EventChart.wilds: 10,
      EventChart.hearth: 0,
    });
    expect(slices.map((s) => s.chart), [EventChart.wilds]);
  });

  test('slices are contiguous and cover 1-100', () {
    final slices = computeChartSlices({
      EventChart.wilds: 4,
      EventChart.deeps: 3,
      EventChart.tradeRoad: 3,
      EventChart.arcane: 2,
      EventChart.hearth: 4,
    });
    expect(slices.first.rollMin, 1);
    expect(slices.last.rollMax, 100);
    for (var i = 1; i < slices.length; i++) {
      expect(slices[i].rollMin, slices[i - 1].rollMax + 1);
    }
    for (final s in slices) {
      expect(s.rollMax - s.rollMin + 1, greaterThanOrEqualTo(1));
      expect(s.contains(s.rollMin), isTrue);
      expect(s.contains(s.rollMax), isTrue);
      expect(s.contains(s.rollMin - 1), isFalse);
      expect(s.contains(s.rollMax + 1), isFalse);
    }
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/data/models/events/chart_slices_test.dart`
Expected: FAIL — cannot find `chart_slices.dart`.

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/data/models/events/chart_slices.dart
import 'package:maura_bastion_system/data/models/events/event_chart.dart';

class ChartSlice {
  final EventChart chart;
  final int points;
  final int rollMin;
  final int rollMax;

  const ChartSlice({
    required this.chart,
    required this.points,
    required this.rollMin,
    required this.rollMax,
  });

  bool contains(int roll) => roll >= rollMin && roll <= rollMax;
}

/// Splits the 1d100 range across charts proportionally to their assigned
/// points, using largest-remainder rounding so the slices always sum to 100.
/// Charts with 0 points get no slice. Slices are ordered by points descending
/// (ties by chart declaration order).
List<ChartSlice> computeChartSlices(Map<EventChart, int> points) {
  final active = EventChart.values
      .where((c) => (points[c] ?? 0) > 0)
      .map((c) => (chart: c, points: points[c]!))
      .toList()
    ..sort((a, b) {
      if (a.points != b.points) return b.points.compareTo(a.points);
      return a.chart.index.compareTo(b.chart.index);
    });
  if (active.isEmpty) return const [];

  final total = active.fold<int>(0, (sum, a) => sum + a.points);
  final exact =
      active.map((a) => a.points * 100 / total).toList(growable: false);
  final sizes = exact.map((v) => v.floor()).toList();
  var leftover = 100 - sizes.fold<int>(0, (s, f) => s + f);

  final order = List<int>.generate(active.length, (i) => i)
    ..sort((a, b) {
      final ra = exact[a] - exact[a].floor();
      final rb = exact[b] - exact[b].floor();
      if (rb != ra) return rb.compareTo(ra);
      return a.compareTo(b);
    });
  for (var i = 0; leftover > 0 && i < order.length; i++, leftover--) {
    sizes[order[i]] += 1;
  }

  final slices = <ChartSlice>[];
  var next = 1;
  for (var i = 0; i < active.length; i++) {
    slices.add(ChartSlice(
      chart: active[i].chart,
      points: active[i].points,
      rollMin: next,
      rollMax: next + sizes[i] - 1,
    ));
    next += sizes[i];
  }
  return slices;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/data/models/events/chart_slices_test.dart`
Expected: PASS (5 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/data/models/events/chart_slices.dart test/data/models/events/chart_slices_test.dart
git commit -m "feat: add proportional d100 slice math for chart web"
```

---

### Task 4: Archetype unlock rules

**Files:**
- Create: `lib/data/models/events/archetypes.dart`
- Test: `test/data/models/events/archetypes_test.dart`

**Interfaces:**
- Consumes: `EventChart` (Task 1).
- Produces: `bool unlocksConvergence(Map<EventChart, int> points)` and `bool unlocksRivalry(Map<EventChart, int> points)`.

- [ ] **Step 1: Write the failing test**

```dart
// test/data/models/events/archetypes_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:maura_bastion_system/data/models/events/archetypes.dart';
import 'package:maura_bastion_system/data/models/events/event_chart.dart';

void main() {
  test('convergence needs 4+ points in three different charts', () {
    expect(unlocksConvergence({EventChart.wilds: 4, EventChart.deeps: 4}), isFalse);
    expect(
        unlocksConvergence(
            {EventChart.wilds: 4, EventChart.deeps: 3, EventChart.hearth: 4}),
        isFalse);
    expect(
        unlocksConvergence(
            {EventChart.wilds: 4, EventChart.deeps: 4, EventChart.hearth: 4}),
        isTrue);
  });

  test('rivalry needs 8+ points in two different charts', () {
    expect(unlocksRivalry({EventChart.wilds: 8, EventChart.deeps: 7}), isFalse);
    expect(unlocksRivalry({EventChart.wilds: 8, EventChart.deeps: 8}), isTrue);
    expect(
        unlocksRivalry(
            {EventChart.wilds: 8, EventChart.deeps: 4, EventChart.hearth: 4}),
        isFalse);
  });

  test('missing charts count as zero points', () {
    expect(unlocksConvergence({EventChart.wilds: 16}), isFalse);
    expect(unlocksRivalry({EventChart.wilds: 16}), isFalse);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/data/models/events/archetypes_test.dart`
Expected: FAIL — cannot find `archetypes.dart`.

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/data/models/events/archetypes.dart
import 'package:maura_bastion_system/data/models/events/event_chart.dart';

/// Convergence events: 4+ points in three different charts.
bool unlocksConvergence(Map<EventChart, int> points) =>
    points.values.where((p) => p >= 4).length >= 3;

/// Rivalry events: 8+ points in two different charts (both Master tier — the
/// 16-point maximum allows exactly one such pairing).
bool unlocksRivalry(Map<EventChart, int> points) =>
    points.values.where((p) => p >= 8).length >= 2;
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/data/models/events/archetypes_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/data/models/events/archetypes.dart test/data/models/events/archetypes_test.dart
git commit -m "feat: add convergence and rivalry unlock rules"
```

---

### Task 5: Full-plan verification

- [ ] **Step 1: Run all event model tests together**

Run: `flutter test test/data/models/events/`
Expected: PASS — all 13 tests green.

- [ ] **Step 2: Run the full test suite to check for regressions**

Run: `flutter test`
Expected: PASS — no pre-existing tests broken.

- [ ] **Step 3: Verify analysis is clean**

Run: `flutter analyze lib/data/models/events`
Expected: `No issues found!`
