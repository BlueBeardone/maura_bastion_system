# Chart Web A8 — Turn Engine Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the Chart Web turn engine: the uneventful table, the main d100 roll that selects a chart slice and event from the player's point distribution, and the archetype side-roll.

**Architecture:** `lib/data/models/events/turn_engine.dart` — a pure, seeded-RNG-testable engine consuming `getChartEvents()`, `computeChartSlices`, and the A1 archetype unlock rules. B1/B2 UI will drive it per bastion turn.

**Tech Stack:** Dart / Flutter. Tests with `flutter test`.

**Spec:** `docs/superpowers/specs/2026-09-18-chart-web-reward-system-design.md` (Section 4, phases 1–2)

## Global Constraints

- Zero points assigned (or all ≤ 0) → the roll lands on the **Uneventful table** (4 quiet events, chart = null, no dispatch, no reward).
- Otherwise: **1d100**, chart = the slice containing the roll, tier = `ChartTier.forPoints(slice.points)!`, event = uniformly random from that chart+tier's **non-archetype** pool.
- Archetype side-roll: only when `unlocksConvergence` or `unlocksRivalry` passes; **25% chance by default**; uniformly random among archetypes whose every `relatedCharts` entry has `points >= minPointsPerChart`; null otherwise.
- Engine must be deterministic for a given seed. House style: const constructors, no comments unless non-obvious.

---

### Task 1: ChartTurnRoll + uneventful table + rollTurn

**Files:**
- Create: `lib/data/models/events/turn_engine.dart`
- Test: `test/data/models/events/turn_engine_test.dart`

**Interfaces:**
- Consumes: `ChartEvent` (A3), `ChartSlice`/`computeChartSlices` (A1), `ChartTier` (A1), `EventChart` (A1), `RewardSpec`/`RewardKind` (A3), `getChartEvents()` (`lib/data/default_data/events/chart_events_catalog.dart`).
- Produces:
  - `class ChartTurnRoll { final ChartSlice? slice; final ChartEvent event; final ChartTier tier; const ChartTurnRoll({...}); }`
  - `class ChartTurnEngine { final List<ChartEvent> Function() catalog; const ChartTurnEngine({this.catalog = getChartEvents}); ChartTurnRoll rollTurn({required Map<EventChart, int> points, Random? rng}); }`
  - Uneventful events (private const list in the engine file): ids `unt_quiet_week`, `unt_rain`, `unt_drills`, `unt_market_chatter` — `chart: null`, `tier: ChartTier.basic`, `RewardSpec(note: ...)` with no dispatch.

- [ ] **Step 1: Write the failing test**

```dart
// test/data/models/events/turn_engine_test.dart
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:maura_bastion_system/data/models/events/event_chart.dart';
import 'package:maura_bastion_system/data/models/events/reward_spec.dart';
import 'package:maura_bastion_system/data/models/events/turn_engine.dart';

void main() {
  final engine = const ChartTurnEngine();

  group('rollTurn with no points', () {
    test('lands on the uneventful table', () {
      for (var i = 0; i < 10; i++) {
        final roll = engine.rollTurn(points: {}, rng: Random(i));
        expect(roll.slice, isNull);
        expect(roll.event.chart, isNull);
        expect(roll.event.id, startsWith('unt_'));
        expect(roll.event.reward.kind, RewardKind.none);
        expect(roll.event.dispatch, isNull);
      }
    });

    test('all-zero points are also uneventful', () {
      final roll = engine.rollTurn(
        points: {EventChart.wilds: 0, EventChart.deeps: 0},
        rng: Random(1),
      );
      expect(roll.event.id, startsWith('unt_'));
    });
  });

  group('rollTurn with points', () {
    test('single-chart distribution only rolls that chart at the right tier', () {
      for (var i = 0; i < 30; i++) {
        final roll = engine.rollTurn(
          points: {EventChart.wilds: 8},
          rng: Random(i),
        );
        expect(roll.event.chart, EventChart.wilds);
        expect(roll.tier.minPoints, 8);
        expect(roll.event.isArchetype, isFalse);
        expect(roll.slice!.points, 8);
      }
    });

    test('events never come from zero-point charts', () {
      for (var i = 0; i < 100; i++) {
        final roll = engine.rollTurn(
          points: {EventChart.wilds: 6, EventChart.deeps: 6, EventChart.arcane: 0},
          rng: Random(100 + i),
        );
        expect(roll.event.chart, isNot(EventChart.arcane));
        expect({EventChart.wilds, EventChart.deeps}.contains(roll.event.chart), isTrue);
      }
    });

    test('is deterministic for a fixed seed', () {
      final a = engine.rollTurn(points: {EventChart.wilds: 8}, rng: Random(42));
      final b = engine.rollTurn(points: {EventChart.wilds: 8}, rng: Random(42));
      expect(a.event.id, b.event.id);
      expect(a.slice!.rollMin, b.slice!.rollMin);
    });

    test('mixed distribution rolls only the funded charts', () {
      for (var i = 0; i < 100; i++) {
        final roll = engine.rollTurn(
          points: {
            EventChart.wilds: 8,
            EventChart.tradeRoad: 5,
            EventChart.hearth: 3,
          },
          rng: Random(200 + i),
        );
        expect(
          {EventChart.wilds, EventChart.tradeRoad, EventChart.hearth}
              .contains(roll.event.chart),
          isTrue,
          reason: 'roll ${roll.slice} produced ${roll.event.id}',
        );
      }
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/data/models/events/turn_engine_test.dart`
Expected: FAIL — cannot find `turn_engine.dart`.

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/data/models/events/turn_engine.dart
import 'dart:math';

import 'package:maura_bastion_system/data/default_data/events/chart_events_catalog.dart';
import 'package:maura_bastion_system/data/models/events/chart_event.dart';
import 'package:maura_bastion_system/data/models/events/chart_slices.dart';
import 'package:maura_bastion_system/data/models/events/chart_tier.dart';
import 'package:maura_bastion_system/data/models/events/event_chart.dart';
import 'package:maura_bastion_system/data/models/events/reward_spec.dart';

class ChartTurnRoll {
  final ChartSlice? slice;
  final ChartEvent event;
  final ChartTier tier;

  const ChartTurnRoll({required this.slice, required this.event, required this.tier});
}

class ChartTurnEngine {
  final List<ChartEvent> Function() catalog;

  const ChartTurnEngine({this.catalog = getChartEvents});

  ChartTurnRoll rollTurn({required Map<EventChart, int> points, Random? rng}) {
    final random = rng ?? Random();
    final events = catalog();
    if (points.values.every((p) => p <= 0)) {
      return ChartTurnRoll(
        slice: null,
        event: _uneventfulEvents[random.nextInt(_uneventfulEvents.length)],
        tier: ChartTier.basic,
      );
    }
    final slices = computeChartSlices(points);
    final roll = random.nextInt(100) + 1;
    final slice = slices.firstWhere((s) => s.contains(roll));
    final tier = ChartTier.forPoints(slice.points)!;
    final pool = events
        .where((e) =>
            !e.isArchetype && e.chart == slice.chart && e.tier == tier)
        .toList();
    return ChartTurnRoll(
      slice: slice,
      event: pool[random.nextInt(pool.length)],
      tier: tier,
    );
  }
}

const List<ChartEvent> _uneventfulEvents = [
  ChartEvent(
    id: 'unt_quiet_week',
    name: 'Quiet Week',
    chart: null,
    tier: ChartTier.basic,
    description: 'Nothing happens this turn. The walls stand; the stores hold.',
    reward: RewardSpec(note: 'Allocate points to your charts to shape your turns'),
  ),
  ChartEvent(
    id: 'unt_rain',
    name: 'A Week of Rain',
    chart: null,
    tier: ChartTier.basic,
    description: 'The ditches run full and the walls drip. Nothing happens.',
    reward: RewardSpec(note: 'Allocate points to your charts to shape your turns'),
  ),
  ChartEvent(
    id: 'unt_drills',
    name: 'Drill and Repair',
    chart: null,
    tier: ChartTier.basic,
    description:
        'The defenders drill in the yard and the carpenter patches the battlements. Nothing happens.',
    reward: RewardSpec(note: 'Allocate points to your charts to shape your turns'),
  ),
  ChartEvent(
    id: 'unt_market_chatter',
    name: 'Market Chatter',
    chart: null,
    tier: ChartTier.basic,
    description: 'Gossip, prices, and small news drift up from the town. Nothing happens.',
    reward: RewardSpec(note: 'Allocate points to your charts to shape your turns'),
  ),
];
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/data/models/events/turn_engine_test.dart`
Expected: PASS (6 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/data/models/events/turn_engine.dart test/data/models/events/turn_engine_test.dart
git commit -m "feat: add chart web turn engine with uneventful table"
```

---

### Task 2: maybeRollArchetype

**Files:**
- Modify: `lib/data/models/events/turn_engine.dart`
- Test: `test/data/models/events/turn_engine_test.dart` (append group inside `main`)

**Interfaces:**
- Consumes: `unlocksConvergence`/`unlocksRivalry` (A1).
- Produces: `ChartEvent? maybeRollArchetype({required Map<EventChart, int> points, Random? rng, double chance = 0.25})` on `ChartTurnEngine` — see Global Constraints for semantics.

- [ ] **Step 1: Write the failing test** (append inside `main`)

```dart
  group('maybeRollArchetype', () {
    test('never fires without an unlocked archetype', () {
      for (var i = 0; i < 20; i++) {
        expect(
          engine.maybeRollArchetype(
            points: {EventChart.wilds: 16},
            rng: Random(i),
            chance: 1.0,
          ),
          isNull,
        );
      }
    });

    test('chance 0 never fires even when unlocked', () {
      expect(
        engine.maybeRollArchetype(
          points: {
            EventChart.wilds: 4,
            EventChart.deeps: 4,
            EventChart.arcane: 4,
          },
          rng: Random(1),
          chance: 0.0,
        ),
        isNull,
      );
    });

    test('chance 1 fires an eligible convergence archetype', () {
      final archetype = engine.maybeRollArchetype(
        points: {
          EventChart.wilds: 4,
          EventChart.deeps: 4,
          EventChart.arcane: 4,
        },
        rng: Random(1),
        chance: 1.0,
      );
      expect(archetype, isNotNull);
      expect(archetype!.isArchetype, isTrue);
      expect(archetype.minPointsPerChart, lessThanOrEqualTo(4));
    });

    test('only rivalry events are eligible at 8/8', () {
      for (var i = 0; i < 10; i++) {
        final archetype = engine.maybeRollArchetype(
          points: {EventChart.wilds: 8, EventChart.deeps: 8},
          rng: Random(i),
          chance: 1.0,
        );
        expect(archetype, isNotNull);
        expect(archetype!.minPointsPerChart, 8);
      }
    });

    test('default chance fires roughly a quarter of the time', () {
      var fired = 0;
      for (var i = 0; i < 1000; i++) {
        if (engine.maybeRollArchetype(
              points: {
                EventChart.wilds: 4,
                EventChart.deeps: 4,
                EventChart.arcane: 4,
              },
              rng: Random(i),
            ) !=
            null) {
          fired++;
        }
      }
      expect(fired, inInclusiveRange(150, 350));
    });
  });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/data/models/events/turn_engine_test.dart`
Expected: FAIL — `maybeRollArchetype` is not defined.

- [ ] **Step 3: Write minimal implementation** (add method to `ChartTurnEngine`, plus import of `archetypes.dart`)

```dart
  ChartEvent? maybeRollArchetype({
    required Map<EventChart, int> points,
    Random? rng,
    double chance = 0.25,
  }) {
    if (!unlocksConvergence(points) && !unlocksRivalry(points)) return null;
    final random = rng ?? Random();
    if (random.nextDouble() >= chance) return null;
    final eligible = catalog()
        .where((e) =>
            e.isArchetype &&
            e.relatedCharts
                .every((c) => (points[c] ?? 0) >= e.minPointsPerChart))
        .toList();
    if (eligible.isEmpty) return null;
    return eligible[random.nextInt(eligible.length)];
  }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/data/models/events/turn_engine_test.dart`
Expected: PASS (11 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/data/models/events/turn_engine.dart test/data/models/events/turn_engine_test.dart
git commit -m "feat: add archetype side-roll to chart web turn engine"
```

---

### Task 3: Verification

- [ ] **Step 1:** Run `flutter test test/data/models/events/` — expect all pass.
- [ ] **Step 2:** Run `flutter test` — expect full suite pass.
- [ ] **Step 3:** Run `flutter analyze lib/data/models/events` — expect no issues.
