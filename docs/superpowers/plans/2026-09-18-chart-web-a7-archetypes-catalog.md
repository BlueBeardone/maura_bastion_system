# Chart Web A7 — Archetype Events & Assembled Catalog Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Author the 8 archetype events (6 Convergence, 2 Rivalry) and assemble all six charts into one `getChartEvents()` catalog.

**Architecture:** `lib/data/default_data/events/archetype_events.dart` plus `lib/data/default_data/events/chart_events_catalog.dart` (the aggregation point A8's turn engine will use).

**Tech Stack:** Dart / Flutter. Tests with `flutter test`.

**Spec:** `docs/superpowers/specs/2026-09-18-chart-web-reward-system-design.md` (Section 2.2)

## Global Constraints

- 8 archetype events: **6 Convergence** (`minPointsPerChart: 4`, 2–3 related charts) + **2 Rivalry** (`minPointsPerChart: 8`, exactly 2 related charts).
- `relatedCharts` non-empty on all archetype events; each event's material categories must belong to one of its related charts.
- `chart` field = the first related chart (used only for grouping; gating uses `relatedCharts`).
- Assembled catalog: **80 events** (72 chart events + 8 archetypes), all unique ids.
- Event id prefixes `cvr_` / `rvl_`.

---

### Task 1: Archetype events

**Files:**
- Create: `lib/data/default_data/events/archetype_events.dart`
- Test: `test/data/default_data/events/archetype_events_test.dart`

**Interfaces:**
- Produces: `List<ChartEvent> archetypeEvents()`.

- [ ] **Step 1: Write the failing test**

```dart
// test/data/default_data/events/archetype_events_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:maura_bastion_system/data/default_data/events/archetype_events.dart';
import 'package:maura_bastion_system/data/models/events/chart_event.dart';
import 'package:maura_bastion_system/data/models/events/chart_tier.dart';

void main() {
  final events = archetypeEvents();

  test('has 8 unique archetype events: 6 convergence + 2 rivalry', () {
    expect(events.length, 8);
    expect(events.map((e) => e.id).toSet().length, 8);
    expect(events.where((e) => e.minPointsPerChart == 4).length, 6);
    expect(events.where((e) => e.minPointsPerChart == 8).length, 2);
  });

  test('all are archetypes with tiered charts and related charts', () {
    for (final e in events) {
      expect(e.isArchetype, isTrue, reason: e.id);
      expect(e.relatedCharts.length, inInclusiveRange(2, 3), reason: e.id);
      expect(e.chart, isIn(e.relatedCharts), reason: e.id);
      expect(e.tier, isNot(ChartTier.legend), reason: e.id);
    }
  });

  test('rivalry events involve exactly two related charts', () {
    final rivalries = events.where((e) => e.minPointsPerChart == 8).toList();
    expect(rivalries.map((e) => e.id).toSet(),
        {'rvl_green_vs_deep', 'rvl_coin_vs_steel'});
    for (final e in rivalries) {
      expect(e.relatedCharts.length, 2);
    }
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/data/default_data/events/archetype_events_test.dart`
Expected: FAIL — cannot find `archetype_events.dart`.

- [ ] **Step 3: Write the catalog**

```dart
// lib/data/default_data/events/archetype_events.dart
import 'package:maura_bastion_system/data/models/events/chart_event.dart';
import 'package:maura_bastion_system/data/models/events/chart_tier.dart';
import 'package:maura_bastion_system/data/models/events/dispatch.dart';
import 'package:maura_bastion_system/data/models/events/event_chart.dart';
import 'package:maura_bastion_system/data/models/events/reward_spec.dart';
import 'package:maura_bastion_system/data/models/rewards/reward.dart';

List<ChartEvent> archetypeEvents() {
  return const [
    ChartEvent(
      id: 'cvr_alchemists_commission',
      name: "The Alchemist's Commission",
      chart: EventChart.wilds,
      tier: ChartTier.skilled,
      description:
          'An alchemist of the Arcane court posts a commission: planar-touched game, taken alive or fresh. The hunters who can read the marks will eat well this winter.',
      dispatch: DispatchSpec(prompt: 'Hunt planar-touched game', maxUnits: 3, dc: 16),
      reward: RewardSpec(
        kind: RewardKind.material,
        categories: [RewardCategory.herb],
        unitDice: UnitDice(1, 2),
      ),
      relatedCharts: {EventChart.wilds, EventChart.arcane},
      minPointsPerChart: 4,
    ),
    ChartEvent(
      id: 'cvr_caravan_ore',
      name: 'Caravan of Ore',
      chart: EventChart.deeps,
      tier: ChartTier.basic,
      description:
          'A Trade Road caravan arrived heavier than it left — and its manifest has learned some interesting new words. The ore is good; the price is quiet.',
      reward: RewardSpec(
        kind: RewardKind.material,
        categories: [RewardCategory.metal],
        unitDice: UnitDice(1, 1),
        goldDice: UnitDice(2, 10),
      ),
      relatedCharts: {EventChart.deeps, EventChart.tradeRoad},
      minPointsPerChart: 4,
    ),
    ChartEvent(
      id: 'cvr_hunters_feast',
      name: "The Hunters' Feast",
      chart: EventChart.wilds,
      tier: ChartTier.basic,
      description:
          'The bastion holds its feast day and the hunting has been generous. A wandering hand asks to stay and help with the smoking racks.',
      reward: RewardSpec(
        kind: RewardKind.material,
        categories: [RewardCategory.meat],
        unitDice: UnitDice(1, 2),
        goldDice: null,
        note: 'A feast-hand asks to stay',
      ),
      relatedCharts: {EventChart.wilds, EventChart.hearth},
      minPointsPerChart: 4,
    ),
    ChartEvent(
      id: 'cvr_miners_fair',
      name: "The Miners' Fair",
      chart: EventChart.deeps,
      tier: ChartTier.basic,
      description:
          'The deeps send up a wagon of show-stone for the fair, and the fair sends down coin and cheer. Everyone profits; a few even profit honestly.',
      reward: RewardSpec(
        kind: RewardKind.material,
        categories: [RewardCategory.stone],
        unitDice: UnitDice(1, 2),
        goldDice: UnitDice(2, 10),
      ),
      relatedCharts: {EventChart.deeps, EventChart.tradeRoad, EventChart.hearth},
      minPointsPerChart: 4,
    ),
    ChartEvent(
      id: 'cvr_beast_broker',
      name: 'The Beast Broker',
      chart: EventChart.wilds,
      tier: ChartTier.skilled,
      description:
          'A broker arrives with papers, cages, and an eye for your banners: he trades in war-beasts, and today he is selling.',
      reward: RewardSpec(
        kind: RewardKind.recruitDefender,
        note: 'A tamed war-beast arrives with papers',
      ),
      relatedCharts: {EventChart.wilds, EventChart.tradeRoad, EventChart.warMarch},
      minPointsPerChart: 4,
    ),
    ChartEvent(
      id: 'cvr_guild_charter',
      name: 'The Guild Charter',
      chart: EventChart.tradeRoad,
      tier: ChartTier.skilled,
      description:
          'A guild scribe arrives with a charter, a wax seal, and a proposal: your bastion as the charter-house for three trades at once.',
      reward: RewardSpec(
        kind: RewardKind.gold,
        goldDice: UnitDice(3, 10),
        note: 'Charter-sealing fees and goodwill',
      ),
      relatedCharts: {EventChart.tradeRoad, EventChart.hearth, EventChart.arcane},
      minPointsPerChart: 4,
    ),
    ChartEvent(
      id: 'rvl_green_vs_deep',
      name: 'Green Against Deep',
      chart: EventChart.wilds,
      tier: ChartTier.skilled,
      description:
          'The same ridge promised to the foresters is wanted by the mine. Both crews are yours, and only one survey can be filed this turn.',
      dispatch: DispatchSpec(prompt: 'File the survey — forest or mine?', maxUnits: 3, dc: 16),
      reward: RewardSpec(
        kind: RewardKind.material,
        categories: [RewardCategory.herb, RewardCategory.stone],
        unitDice: UnitDice(1, 2),
        note: "Charter favor: the forest's find or the mine's",
      ),
      relatedCharts: {EventChart.wilds, EventChart.deeps},
      minPointsPerChart: 8,
    ),
    ChartEvent(
      id: 'rvl_coin_vs_steel',
      name: 'Coin Against Steel',
      chart: EventChart.tradeRoad,
      tier: ChartTier.skilled,
      description:
          'The roads are dangerous and the pay for guards is high — but your own walls are hungry for hands. Escort the shipment, or garrison the bastion?',
      dispatch: DispatchSpec(prompt: 'Escort fee or the wall?', maxUnits: 3, dc: 16),
      reward: RewardSpec(
        kind: RewardKind.gold,
        goldDice: UnitDice(4, 10),
        note: 'Escort pay — hard coin for a hard road',
      ),
      relatedCharts: {EventChart.tradeRoad, EventChart.warMarch},
      minPointsPerChart: 8,
    ),
  ];
}
```

Note: `goldDice: null` in `cvr_hunters_feast` is redundant (field default) — remove it and write the RewardSpec without the `goldDice` argument.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/data/default_data/events/archetype_events_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/data/default_data/events/archetype_events.dart test/data/default_data/events/archetype_events_test.dart
git commit -m "feat: add convergence and rivalry archetype events"
```

---

### Task 2: Assembled catalog getChartEvents

**Files:**
- Create: `lib/data/default_data/events/chart_events_catalog.dart`
- Test: `test/data/default_data/events/chart_events_catalog_test.dart`

**Interfaces:**
- Consumes: all six chart functions + `archetypeEvents()` (Task 1).
- Produces: `List<ChartEvent> getChartEvents()` — every chart event + archetype events, 80 unique ids total. This is the entry point the A8 turn engine consumes.

- [ ] **Step 1: Write the failing test**

```dart
// test/data/default_data/events/chart_events_catalog_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:maura_bastion_system/data/default_data/events/chart_events_catalog.dart';
import 'package:maura_bastion_system/data/models/events/chart_event.dart';
import 'package:maura_bastion_system/data/models/events/chart_tier.dart';
import 'package:maura_bastion_system/data/models/events/event_chart.dart';

void main() {
  final events = getChartEvents();

  test('has 80 unique events', () {
    expect(events.length, 80);
    expect(events.map((e) => e.id).toSet().length, 80);
  });

  test('every non-archetype chart has 12 events', () {
    for (final chart in EventChart.values) {
      final count =
          events.where((e) => !e.isArchetype && e.chart == chart).length;
      expect(count, 12, reason: chart.name);
    }
  });

  test('every chart has exactly one legend event', () {
    for (final chart in EventChart.values) {
      final legends = events
          .where((e) => e.chart == chart && e.tier == ChartTier.legend)
          .toList();
      expect(legends.length, 1, reason: chart.name);
    }
  });

  test('no event has an empty description or blank name', () {
    for (final e in events) {
      expect(e.name.trim(), isNotEmpty, reason: e.id);
      expect(e.description.trim(), isNotEmpty, reason: e.id);
    }
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/data/default_data/events/chart_events_catalog_test.dart`
Expected: FAIL — cannot find `chart_events_catalog.dart`.

- [ ] **Step 3: Write the catalog**

```dart
// lib/data/default_data/events/chart_events_catalog.dart
import 'package:maura_bastion_system/data/default_data/events/arcane_events.dart';
import 'package:maura_bastion_system/data/default_data/events/archetype_events.dart';
import 'package:maura_bastion_system/data/default_data/events/deeps_events.dart';
import 'package:maura_bastion_system/data/default_data/events/hearth_events.dart';
import 'package:maura_bastion_system/data/default_data/events/trade_road_events.dart';
import 'package:maura_bastion_system/data/default_data/events/war_march_events.dart';
import 'package:maura_bastion_system/data/default_data/events/wilds_events.dart';
import 'package:maura_bastion_system/data/models/events/chart_event.dart';

List<ChartEvent> getChartEvents() {
  return [
    ...wildsEvents(),
    ...deepsEvents(),
    ...tradeRoadEvents(),
    ...warMarchEvents(),
    ...hearthEvents(),
    ...arcaneEvents(),
    ...archetypeEvents(),
  ];
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/data/default_data/events/chart_events_catalog_test.dart`
Expected: PASS (4 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/data/default_data/events/chart_events_catalog.dart test/data/default_data/events/chart_events_catalog_test.dart
git commit -m "feat: assemble chart web event catalog"
```

---

### Task 3: Verification

- [ ] **Step 1:** Run `flutter test test/data/default_data/events/` — expect all pass.
- [ ] **Step 2:** Run `flutter test` — expect full suite pass.
- [ ] **Step 3:** Run `flutter analyze lib/data/default_data/events` — expect no issues.
