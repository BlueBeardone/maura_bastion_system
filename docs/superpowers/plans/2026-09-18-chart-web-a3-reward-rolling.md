# Chart Web A3 — Event Model & Reward Rolling Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Define the ChartEvent model (the unit the event catalogs are made of) and implement tier-gated reward rolling that turns an event's RewardSpec into concrete material grants, gold, and recruit flags.

**Architecture:** One model file `lib/data/models/events/reward_spec.dart` (RewardKind, RewardSpec, RewardGrant, TurnReward, cap logic, `rollMaterialRewards`) and one `lib/data/models/events/chart_event.dart` (ChartEvent + `rollTurnReward`). Pure Dart. A2's `DispatchSpec`/`UnitDice` are consumed; A4–A8 consume ChartEvent and `rollTurnReward`.

**Tech Stack:** Dart / Flutter. Tests with `flutter test`.

**Spec:** `docs/superpowers/specs/2026-09-18-chart-web-reward-system-design.md` (Sections 2.1 tier caps, 4 phase 5)

## Global Constraints

- Tier caps (from A1 `ChartTier.rewardRankCap`): Basic→D, Skilled→B, Master→A, Legend→S.
- Rank-null materials (metals, stones, woods, weaves, creature parts, meat, blood) are **harvested at the tier cap rank** — their `effectiveRank` equals the cap.
- A reward is within cap when `effective.index >= cap.index` (Rank enum order is S,A,B,C,D,E — higher index = lower quality).
- `picks` is clamped to the number of distinct categories offered; picks within one roll are distinct categories.
- House style: plain classes with `const` constructors; no comments unless explaining a non-obvious rule.

---

### Task 1: RewardKind, RewardSpec, RewardGrant, TurnReward + cap logic

**Files:**
- Create: `lib/data/models/events/reward_spec.dart`
- Test: `test/data/models/events/reward_spec_test.dart`

**Interfaces:**
- Consumes: `RewardCategory`, `Reward` (`lib/data/models/rewards/reward.dart`), `Rank` (`lib/data/enums/rank.dart`), `UnitDice` (A2 `dispatch.dart`).
- Produces:
  - `enum RewardKind { material, gold, recruitDefender, recruitHireling, none }`
  - `class RewardSpec { final RewardKind kind; final List<RewardCategory> categories; final int picks; final UnitDice unitDice; final UnitDice? goldDice; final String? note; const RewardSpec({kind = RewardKind.none, categories = const [], picks = 1, unitDice = const UnitDice(1, 2), goldDice, note}); }`
  - `class RewardGrant { final Reward reward; final Rank effectiveRank; final int units; const RewardGrant({...}); }`
  - `class TurnReward { final List<RewardGrant> materials; final int gold; final RewardKind recruit; final String? note; const TurnReward({...}); static const TurnReward empty = TurnReward(materials: [], gold: 0, recruit: RewardKind.none); }`
  - `bool withinRewardCap(Rank? rewardRank, Rank cap)` — see Global Constraints.

- [ ] **Step 1: Write the failing test**

```dart
// test/data/models/events/reward_spec_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:maura_bastion_system/data/enums/rank.dart';
import 'package:maura_bastion_system/data/models/events/reward_spec.dart';

void main() {
  group('withinRewardCap', () {
    test('cap D allows D and E ranks', () {
      expect(withinRewardCap(Rank.D, Rank.D), isTrue);
      expect(withinRewardCap(Rank.E, Rank.D), isTrue);
    });

    test('cap D blocks better ranks', () {
      expect(withinRewardCap(Rank.C, Rank.D), isFalse);
      expect(withinRewardCap(Rank.S, Rank.D), isFalse);
    });

    test('null rank materials pass at the cap', () {
      expect(withinRewardCap(null, Rank.D), isTrue);
      expect(withinRewardCap(null, Rank.B), isTrue);
    });

    test('cap S allows everything', () {
      for (final rank in Rank.values) {
        expect(withinRewardCap(rank, Rank.S), isTrue);
      }
      expect(withinRewardCap(null, Rank.S), isTrue);
    });
  });

  test('RewardSpec defaults', () {
    const spec = RewardSpec();
    expect(spec.kind, RewardKind.none);
    expect(spec.categories, isEmpty);
    expect(spec.picks, 1);
    expect(spec.unitDice, const UnitDice(1, 2));
    expect(spec.goldDice, isNull);
    expect(spec.note, isNull);
  });

  test('TurnReward.empty', () {
    expect(TurnReward.empty.materials, isEmpty);
    expect(TurnReward.empty.gold, 0);
    expect(TurnReward.empty.recruit, RewardKind.none);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/data/models/events/reward_spec_test.dart`
Expected: FAIL — cannot find `reward_spec.dart`.

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/data/models/events/reward_spec.dart
import 'package:maura_bastion_system/data/enums/rank.dart';
import 'package:maura_bastion_system/data/models/events/dispatch.dart';
import 'package:maura_bastion_system/data/models/rewards/reward.dart';

enum RewardKind { material, gold, recruitDefender, recruitHireling, none }

class RewardSpec {
  final RewardKind kind;
  final List<RewardCategory> categories;
  final int picks;
  final UnitDice unitDice;
  final UnitDice? goldDice;
  final String? note;

  const RewardSpec({
    this.kind = RewardKind.none,
    this.categories = const [],
    this.picks = 1,
    this.unitDice = const UnitDice(1, 2),
    this.goldDice,
    this.note,
  });
}

/// Rank-null materials are harvested at the cap rank; higher-quality ranks
/// (lower index) are out of cap.
bool withinRewardCap(Rank? rewardRank, Rank cap) {
  final effective = rewardRank ?? cap;
  return effective.index >= cap.index;
}

class RewardGrant {
  final Reward reward;
  final Rank effectiveRank;
  final int units;

  const RewardGrant({
    required this.reward,
    required this.effectiveRank,
    required this.units,
  });
}

class TurnReward {
  final List<RewardGrant> materials;
  final int gold;
  final RewardKind recruit;
  final String? note;

  const TurnReward({
    required this.materials,
    required this.gold,
    required this.recruit,
    this.note,
  });

  static const TurnReward empty =
      TurnReward(materials: [], gold: 0, recruit: RewardKind.none);
}
```

Note: the test imports `UnitDice` transitively via the model file — if the analyzer complains about `const UnitDice(1, 2)` in the test, add `import 'package:maura_bastion_system/data/models/events/dispatch.dart';` to the test.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/data/models/events/reward_spec_test.dart`
Expected: PASS (7 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/data/models/events/reward_spec.dart test/data/models/events/reward_spec_test.dart
git commit -m "feat: add reward spec model and tier cap logic"
```

---

### Task 2: rollMaterialRewards

**Files:**
- Modify: `lib/data/models/events/reward_spec.dart`
- Test: `test/data/models/events/reward_spec_test.dart` (append inside `main`)

**Interfaces:**
- Consumes: `getDefaultRewards()` (`lib/data/default_data/rewards/default_reward_data.dart`), `withinRewardCap`, `RewardGrant`, `UnitDice` (Task 1 / A2).
- Produces: `List<RewardGrant> rollMaterialRewards({required List<RewardCategory> categories, required int picks, required Rank cap, required UnitDice unitDice, Random? rng})` — picks `min(picks, distinct categories offered)` distinct random categories; for each, picks one random reward of that category that is within cap, rolls units, sets `effectiveRank` = `reward.rank ?? cap`. Throws `ArgumentError` if no category has any eligible reward.

- [ ] **Step 1: Write the failing test** (append inside `main`; add imports: `dart:math`, `reward.dart` model, `default_reward_data.dart`)

```dart
  group('rollMaterialRewards', () {
    test('grants respect category and cap', () {
      for (var i = 0; i < 50; i++) {
        final grants = rollMaterialRewards(
          categories: [RewardCategory.herb],
          picks: 1,
          cap: Rank.D,
          unitDice: const UnitDice(1, 2),
          rng: Random(i),
        );
        expect(grants.length, 1);
        expect(grants.single.reward.category, RewardCategory.herb);
        expect(withinRewardCap(grants.single.reward.rank, Rank.D), isTrue);
        expect(grants.single.units, inInclusiveRange(1, 2));
      }
    });

    test('null-rank materials harvest at the cap rank', () {
      final grants = rollMaterialRewards(
        categories: [RewardCategory.metal],
        picks: 1,
        cap: Rank.B,
        unitDice: const UnitDice(1, 1),
        rng: Random(3),
      );
      expect(grants.single.effectiveRank, Rank.B);
    });

    test('explicit ranks carry through', () {
      final grants = rollMaterialRewards(
        categories: [RewardCategory.herb],
        picks: 1,
        cap: Rank.B,
        unitDice: const UnitDice(1, 1),
        rng: Random(3),
      );
      expect(grants.single.effectiveRank, grants.single.reward.rank);
      expect(grants.single.effectiveRank, isNotNull);
    });

    test('picks are distinct categories and clamped to the pool', () {
      final grants = rollMaterialRewards(
        categories: [RewardCategory.metal, RewardCategory.stone],
        picks: 5,
        cap: Rank.S,
        unitDice: const UnitDice(1, 1),
        rng: Random(5),
      );
      expect(grants.length, 2);
      expect(grants.map((g) => g.reward.category).toSet().length, 2);
    });

    test('throws when no category has eligible rewards', () {
      expect(
        () => rollMaterialRewards(
          categories: [RewardCategory.herb],
          picks: 1,
          cap: Rank.E,
          unitDice: const UnitDice(1, 2),
          rng: Random(1),
        ),
        throwsArgumentError,
      );
    });
  });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/data/models/events/reward_spec_test.dart`
Expected: FAIL — `rollMaterialRewards` is not defined.

- [ ] **Step 3: Write minimal implementation** (append to `reward_spec.dart`)

```dart
import 'dart:math';

import 'package:maura_bastion_system/data/default_data/rewards/default_reward_data.dart';

List<RewardGrant> rollMaterialRewards({
  required List<RewardCategory> categories,
  required int picks,
  required Rank cap,
  required UnitDice unitDice,
  Random? rng,
}) {
  final random = rng ?? Random();
  final pool = categories.toSet().toList()..shuffle(random);
  final chosen = pool.take(picks.clamp(0, pool.length)).toList();
  if (chosen.isEmpty) {
    throw ArgumentError('No categories offered for material rewards');
  }
  final grants = <RewardGrant>[];
  for (final category in chosen) {
    final candidates = getDefaultRewards()
        .where((r) => r.category == category && withinRewardCap(r.rank, cap))
        .toList();
    if (candidates.isEmpty) {
      throw ArgumentError('No rewards within cap for $category');
    }
    final reward = candidates[random.nextInt(candidates.length)];
    grants.add(RewardGrant(
      reward: reward,
      effectiveRank: reward.rank ?? cap,
      units: unitDice.roll(random),
    ));
  }
  return grants;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/data/models/events/reward_spec_test.dart`
Expected: PASS (12 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/data/models/events/reward_spec.dart test/data/models/events/reward_spec_test.dart
git commit -m "feat: add tier-gated material reward rolling"
```

---

### Task 3: ChartEvent + rollTurnReward

**Files:**
- Create: `lib/data/models/events/chart_event.dart`
- Test: `test/data/models/events/chart_event_test.dart`

**Interfaces:**
- Consumes: `EventChart` (A1), `ChartTier` (A1), `DispatchSpec` (A2), `FacilityTable` (`lib/data/models/bastion/table.dart`), `RewardSpec`/`RewardGrant`/`TurnReward`/`rollMaterialRewards` (Tasks 1–2).
- Produces:
  - `class ChartEvent { final String id; final String name; final EventChart? chart; final ChartTier tier; final String description; final DispatchSpec? dispatch; final RewardSpec reward; final Set<EventChart> relatedCharts; final int minPointsPerChart; final FacilityTable? table; const ChartEvent({required id, required name, required chart, required tier, required description, dispatch, reward = const RewardSpec(), relatedCharts = const {}, minPointsPerChart = 0, table}); bool get isArchetype; }` — `chart` is null only for the uneventful pseudo-events; `isArchetype` is `relatedCharts.isNotEmpty`.
  - `TurnReward rollTurnReward({required ChartEvent event, required ChartTier tier, required bool success, Random? rng})`:
    - on `!success`: returns `TurnReward(materials: [], gold: 0, recruit: RewardKind.none, note: event.reward.note)`.
    - `RewardSpec.kind == none`: materials empty, gold 0, note passthrough.
    - otherwise: materials = `rollMaterialRewards(categories: spec.categories, picks: spec.picks, cap: tier.rewardRankCap, unitDice: spec.unitDice, rng)` **only when** `spec.categories` is non-empty (else empty); gold = `spec.goldDice?.roll(rng) ?? 0`; recruit = kind when kind is `recruitDefender`/`recruitHireling` else `RewardKind.none`; note passthrough.

- [ ] **Step 1: Write the failing test**

```dart
// test/data/models/events/chart_event_test.dart
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:maura_bastion_system/data/enums/rank.dart';
import 'package:maura_bastion_system/data/models/events/chart_event.dart';
import 'package:maura_bastion_system/data/models/events/dispatch.dart';
import 'package:maura_bastion_system/data/models/events/event_chart.dart';
import 'package:maura_bastion_system/data/models/events/chart_tier.dart';
import 'package:maura_bastion_system/data/models/events/reward_spec.dart';

ChartEvent eventWith(RewardSpec reward) => ChartEvent(
      id: 'evt_test',
      name: 'Test Event',
      chart: EventChart.wilds,
      tier: ChartTier.basic,
      description: 'desc',
      reward: reward,
    );

void main() {
  test('isArchetype reflects relatedCharts', () {
    const plain = ChartEvent(
      id: 'a', name: 'A', chart: EventChart.wilds, tier: ChartTier.basic,
      description: 'd',
    );
    final archetype = ChartEvent(
      id: 'b', name: 'B', chart: EventChart.wilds, tier: ChartTier.basic,
      description: 'd',
      relatedCharts: {EventChart.wilds, EventChart.arcane},
      minPointsPerChart: 4,
    );
    expect(plain.isArchetype, isFalse);
    expect(archetype.isArchetype, isTrue);
    expect(plain.minPointsPerChart, 0);
  });

  group('rollTurnReward', () {
    test('failure yields only the note', () {
      final result = rollTurnReward(
        event: eventWith(const RewardSpec(
          kind: RewardKind.material,
          categories: [RewardCategory.herb],
          note: 'lost',
        )),
        tier: ChartTier.basic,
        success: false,
        rng: Random(1),
      );
      expect(result.materials, isEmpty);
      expect(result.gold, 0);
      expect(result.recruit, RewardKind.none);
      expect(result.note, 'lost');
    });

    test('kind none yields nothing but the note', () {
      final result = rollTurnReward(
        event: eventWith(const RewardSpec(note: 'quiet')),
        tier: ChartTier.master,
        success: true,
        rng: Random(1),
      );
      expect(result, isA<TurnReward>());
      expect(result.materials, isEmpty);
      expect(result.gold, 0);
      expect(result.note, 'quiet');
    });

    test('material success grants within the tier cap', () {
      final result = rollTurnReward(
        event: eventWith(const RewardSpec(
          kind: RewardKind.material,
          categories: [RewardCategory.herb],
          unitDice: UnitDice(1, 2),
        )),
        tier: ChartTier.basic,
        success: true,
        rng: Random(2),
      );
      expect(result.materials.length, 1);
      expect(withinRewardCap(result.materials.single.reward.rank, Rank.D), isTrue);
    });

    test('gold success rolls the gold dice', () {
      for (var i = 0; i < 20; i++) {
        final result = rollTurnReward(
          event: eventWith(RewardSpec(
            kind: RewardKind.gold,
            goldDice: const UnitDice(2, 10),
          )),
          tier: ChartTier.skilled,
          success: true,
          rng: Random(100 + i),
        );
        expect(result.gold, inInclusiveRange(2, 20));
      }
    });

    test('recruit kind carries through', () {
      final result = rollTurnReward(
        event: eventWith(const RewardSpec(kind: RewardKind.recruitHireling)),
        tier: ChartTier.basic,
        success: true,
        rng: Random(1),
      );
      expect(result.recruit, RewardKind.recruitHireling);
      expect(result.materials, isEmpty);
    });

    test('material + gold combine for mixed rewards', () {
      final result = rollTurnReward(
        event: eventWith(const RewardSpec(
          kind: RewardKind.material,
          categories: [RewardCategory.stone],
          goldDice: UnitDice(2, 10),
        )),
        tier: ChartTier.basic,
        success: true,
        rng: Random(4),
      );
      expect(result.materials.length, 1);
      expect(result.gold, inInclusiveRange(2, 20));
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/data/models/events/chart_event_test.dart`
Expected: FAIL — cannot find `chart_event.dart`.

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/data/models/events/chart_event.dart
import 'dart:math';

import 'package:maura_bastion_system/data/models/bastion/table.dart';
import 'package:maura_bastion_system/data/models/events/chart_tier.dart';
import 'package:maura_bastion_system/data/models/events/dispatch.dart';
import 'package:maura_bastion_system/data/models/events/event_chart.dart';
import 'package:maura_bastion_system/data/models/events/reward_spec.dart';

class ChartEvent {
  final String id;
  final String name;

  /// Null only for the uneventful pseudo-events (no points allocated).
  final EventChart? chart;
  final ChartTier tier;
  final String description;
  final DispatchSpec? dispatch;
  final RewardSpec reward;

  /// Archetype gating: the charts this convergence/rivalry event involves.
  final Set<EventChart> relatedCharts;
  final int minPointsPerChart;
  final FacilityTable? table;

  const ChartEvent({
    required this.id,
    required this.name,
    required this.chart,
    required this.tier,
    required this.description,
    this.dispatch,
    this.reward = const RewardSpec(),
    this.relatedCharts = const {},
    this.minPointsPerChart = 0,
    this.table,
  });

  bool get isArchetype => relatedCharts.isNotEmpty;
}

TurnReward rollTurnReward({
  required ChartEvent event,
  required ChartTier tier,
  required bool success,
  Random? rng,
}) {
  final spec = event.reward;
  if (!success || spec.kind == RewardKind.none) {
    return TurnReward(
      materials: const [],
      gold: 0,
      recruit: RewardKind.none,
      note: spec.note,
    );
  }
  final materials = spec.categories.isEmpty
      ? const <RewardGrant>[]
      : rollMaterialRewards(
          categories: spec.categories,
          picks: spec.picks,
          cap: tier.rewardRankCap,
          unitDice: spec.unitDice,
          rng: rng,
        );
  final gold = spec.goldDice?.roll(rng ?? Random()) ?? 0;
  final recruit = spec.kind == RewardKind.recruitDefender ||
          spec.kind == RewardKind.recruitHireling
      ? spec.kind
      : RewardKind.none;
  return TurnReward(
    materials: materials,
    gold: gold,
    recruit: recruit,
    note: spec.note,
  );
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/data/models/events/chart_event_test.dart`
Expected: PASS (8 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/data/models/events/chart_event.dart test/data/models/events/chart_event_test.dart
git commit -m "feat: add ChartEvent model and turn reward rolling"
```

---

### Task 4: Verification

- [ ] **Step 1:** Run `flutter test test/data/models/events/` — expect all pass.
- [ ] **Step 2:** Run `flutter test` — expect full suite pass.
- [ ] **Step 3:** Run `flutter analyze lib/data/models/events` — expect no issues.
