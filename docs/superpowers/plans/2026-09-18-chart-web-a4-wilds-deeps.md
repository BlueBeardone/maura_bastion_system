# Chart Web A4 — Event Catalog: The Wilds & The Deeps Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Author the first two Chart Web event catalogs — The Wilds (creature parts, meat, blood, herbs) and The Deeps (metals, stones) — 12 events each, using the ChartEvent/RewardSpec/DispatchSpec models from A2–A3.

**Architecture:** One file per chart under `lib/data/default_data/events/` exposing a `List<ChartEvent> xxxEvents()` function; one test file per chart. A7 will assemble all six charts into `getChartEvents()`.

**Tech Stack:** Dart / Flutter. Tests with `flutter test`.

**Spec:** `docs/superpowers/specs/2026-09-18-chart-web-reward-system-design.md` (Section 3 exemplars)

## Global Constraints

- 12 events per chart: **4 Basic, 4 Skilled, 3 Master, 1 Legend** (Legend = the chart's signature event).
- Tier caps bind rewards: Basic rolls ≤ Rank D, Skilled ≤ B, Master ≤ A, Legend ≤ S (enforced by `rollTurnReward` via `ChartTier.rewardRankCap` — catalogs only need correct categories/units).
- Every reward category used must be one of the chart's own categories: wilds = creaturePart/meat/blood/herb; deeps = metal/stone.
- Event ids are unique, prefixed `wld_` (Wilds) / `dps_` (Deeps).
- Dispatch events carry `DispatchSpec(prompt:, maxUnits:, dc:)`; no-dispatch events have `dispatch: null`.
- Descriptions: 1–2 sentences, second person, D&D-flavored, matching the spec's exemplar flavor.
- House style: const constructors, no comments unless non-obvious.

---

### Task 1: The Wilds catalog

**Files:**
- Create: `lib/data/default_data/events/wilds_events.dart`
- Test: `test/data/default_data/events/wilds_events_test.dart`

**Interfaces:**
- Consumes: `ChartEvent`, `rollTurnReward` (not needed here), `DispatchSpec`, `DispatchUnitType` not needed, `RewardSpec`, `UnitDice` (A2/A3), `EventChart`, `ChartTier` (A1).
- Produces: `List<ChartEvent> wildsEvents()`.

- [ ] **Step 1: Write the failing test**

```dart
// test/data/default_data/events/wilds_events_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:maura_bastion_system/data/default_data/events/wilds_events.dart';
import 'package:maura_bastion_system/data/models/events/chart_event.dart';
import 'package:maura_bastion_system/data/models/events/chart_tier.dart';
import 'package:maura_bastion_system/data/models/events/event_chart.dart';
import 'package:maura_bastion_system/data/models/rewards/reward.dart';

void main() {
  final events = wildsEvents();

  test('has 12 unique events', () {
    expect(events.length, 12);
    expect(events.map((e) => e.id).toSet().length, 12);
  });

  test('tier distribution is 4 basic / 4 skilled / 3 master / 1 legend', () {
    final counts = <ChartTier, int>{};
    for (final e in events) {
      counts[e.tier] = (counts[e.tier] ?? 0) + 1;
    }
    expect(counts[ChartTier.basic], 4);
    expect(counts[ChartTier.skilled], 4);
    expect(counts[ChartTier.master], 3);
    expect(counts[ChartTier.legend], 1);
  });

  test('every event belongs to the wilds chart and uses only wilds categories', () {
    final allowed = EventChart.wilds.rewardCategories.toSet();
    for (final e in events) {
      expect(e.chart, EventChart.wilds);
      expect(e.isArchetype, isFalse);
      for (final category in e.reward.categories) {
        expect(allowed.contains(category), isTrue, reason: e.id);
      }
    }
  });

  test('dispatch events are well-formed', () {
    for (final e in events) {
      if (e.dispatch == null) continue;
      expect(e.dispatch!.maxUnits, greaterThanOrEqualTo(1), reason: e.id);
      expect(e.dispatch!.dc, greaterThanOrEqualTo(1), reason: e.id);
      expect(e.dispatch!.prompt, isNotEmpty, reason: e.id);
    }
    expect(events.where((e) => e.dispatch != null).length, greaterThanOrEqualTo(8));
  });

  test('material rewards all have kind material', () {
    for (final e in events) {
      expect(e.reward.kind, RewardKind.material, reason: e.id);
      expect(e.reward.categories, isNotEmpty, reason: e.id);
    }
  });

  test('legend event is the Beast of Maura', () {
    final legend = events.singleWhere((e) => e.tier == ChartTier.legend);
    expect(legend.id, 'wld_beast_of_maura');
    expect(legend.name, 'The Beast of Maura');
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/data/default_data/events/wilds_events_test.dart`
Expected: FAIL — cannot find `wilds_events.dart`.

- [ ] **Step 3: Write the catalog**

```dart
// lib/data/default_data/events/wilds_events.dart
import 'package:maura_bastion_system/data/models/events/chart_event.dart';
import 'package:maura_bastion_system/data/models/events/chart_tier.dart';
import 'package:maura_bastion_system/data/models/events/dispatch.dart';
import 'package:maura_bastion_system/data/models/events/event_chart.dart';
import 'package:maura_bastion_system/data/models/events/reward_spec.dart';
import 'package:maura_bastion_system/data/models/rewards/reward.dart';

List<ChartEvent> wildsEvents() {
  return const [
    ChartEvent(
      id: 'wld_foraging_party',
      name: 'Foraging Party',
      chart: EventChart.wilds,
      tier: ChartTier.basic,
      description:
          'Your hirelings spent the turn combing the forest floors of Maura. Send them out again to see what the season has left behind.',
      dispatch: DispatchSpec(prompt: 'Send foragers into the forests of Maura', maxUnits: 4, dc: 12),
      reward: RewardSpec(
        kind: RewardKind.material,
        categories: [RewardCategory.herb],
        unitDice: UnitDice(1, 2),
      ),
    ),
    ChartEvent(
      id: 'wld_wolf_cull',
      name: 'Wolf Cull',
      chart: EventChart.wilds,
      tier: ChartTier.basic,
      description:
          'Wolves have grown bold near the pastures. Thin the pack and the hides are yours.',
      dispatch: DispatchSpec(prompt: 'Send defenders against the wolves', maxUnits: 2, dc: 10),
      reward: RewardSpec(
        kind: RewardKind.material,
        categories: [RewardCategory.creaturePart],
        unitDice: UnitDice(1, 1),
      ),
    ),
    ChartEvent(
      id: 'wld_berry_thicket',
      name: 'Berry Thicket',
      chart: EventChart.wilds,
      tier: ChartTier.basic,
      description:
          'A hireling found a thicket heavy with rare berries. No risk, no glory — just a basket to fill.',
      reward: RewardSpec(
        kind: RewardKind.material,
        categories: [RewardCategory.herb],
        unitDice: UnitDice(1, 2),
      ),
    ),
    ChartEvent(
      id: 'wld_tracker_signs',
      name: 'Tracker Signs',
      chart: EventChart.wilds,
      tier: ChartTier.basic,
      description:
          'Your hunters found fresh spoor and a half-eaten carcass. One clean kill was easy to claim.',
      reward: RewardSpec(
        kind: RewardKind.material,
        categories: [RewardCategory.meat],
        unitDice: UnitDice(1, 1),
      ),
    ),
    ChartEvent(
      id: 'wld_migrating_herd',
      name: 'The Migrating Herd',
      chart: EventChart.wilds,
      tier: ChartTier.skilled,
      description:
          'A great herd crosses the plains. Each hunter who lands a blow brings home meat and blood alike.',
      dispatch: DispatchSpec(prompt: 'Send hunters after the herd', maxUnits: 4, dc: 16),
      reward: RewardSpec(
        kind: RewardKind.material,
        categories: [RewardCategory.meat, RewardCategory.blood],
        picks: 2,
        unitDice: UnitDice(1, 2),
      ),
    ),
    ChartEvent(
      id: 'wld_rare_bloom',
      name: 'Rare Bloom Spotted',
      chart: EventChart.wilds,
      tier: ChartTier.skilled,
      description:
          'A ghost-pale flower blooms only in the dark. Harvest now and risk trampling it, or wait and risk losing it.',
      dispatch: DispatchSpec(prompt: 'Send gatherers to the bloom by night', maxUnits: 2, dc: 14),
      reward: RewardSpec(
        kind: RewardKind.material,
        categories: [RewardCategory.herb],
        unitDice: UnitDice(1, 2),
        note: 'Harvest at night or the bloom is lost',
      ),
    ),
    ChartEvent(
      id: 'wld_boar_hunt',
      name: 'Boar Hunt',
      chart: EventChart.wilds,
      tier: ChartTier.skilled,
      description:
          'A tusked boar has been goring livestock. Bring it down and the butchering is generous.',
      dispatch: DispatchSpec(prompt: 'Send hunters against the boar', maxUnits: 3, dc: 15),
      reward: RewardSpec(
        kind: RewardKind.material,
        categories: [RewardCategory.creaturePart, RewardCategory.meat],
        picks: 2,
        unitDice: UnitDice(1, 2),
      ),
    ),
    ChartEvent(
      id: 'wld_owlbear_den',
      name: 'Owlbear Den',
      chart: EventChart.wilds,
      tier: ChartTier.skilled,
      description:
          'An owlbear den has been found in the high crags. The mother is away — mostly.',
      dispatch: DispatchSpec(prompt: 'Raid the owlbear den', maxUnits: 3, dc: 15),
      reward: RewardSpec(
        kind: RewardKind.material,
        categories: [RewardCategory.creaturePart],
        unitDice: UnitDice(1, 2),
        note: 'Cubs may be tamed at DM discretion',
      ),
    ),
    ChartEvent(
      id: 'wld_great_stag',
      name: 'The Great Stag',
      chart: EventChart.wilds,
      tier: ChartTier.master,
      description:
          'The Great Stag of Maura haunts the deep woods. Each extra round of pursuit promises a finer trophy — and sharper antlers.',
      dispatch: DispatchSpec(prompt: 'Pursue the Great Stag', maxUnits: 3, dc: 18),
      reward: RewardSpec(
        kind: RewardKind.material,
        categories: [RewardCategory.creaturePart],
        unitDice: UnitDice(1, 2),
        note: 'Each additional pursuit round raises the reward rank',
      ),
    ),
    ChartEvent(
      id: 'wld_plains_fire',
      name: 'Plains Fire',
      chart: EventChart.wilds,
      tier: ChartTier.master,
      description:
          'Grassfire sweeps the plains and the beasts flee before it. Salvage what the smoke leaves behind.',
      dispatch: DispatchSpec(prompt: 'Salvage game from the fire line', maxUnits: 4, dc: 14),
      reward: RewardSpec(
        kind: RewardKind.material,
        categories: [RewardCategory.creaturePart, RewardCategory.meat],
        picks: 2,
        unitDice: UnitDice(1, 2),
      ),
    ),
    ChartEvent(
      id: 'wld_ancient_owl',
      name: 'The Ancient Owl',
      chart: EventChart.wilds,
      tier: ChartTier.master,
      description:
          'An owl the size of a horse has roosted in the old pines. Its feathers shed moonlight, and its nest hides herbs.',
      dispatch: DispatchSpec(prompt: 'Approach the Ancient Owl', maxUnits: 3, dc: 16),
      reward: RewardSpec(
        kind: RewardKind.material,
        categories: [RewardCategory.creaturePart, RewardCategory.herb],
        picks: 2,
        unitDice: UnitDice(1, 2),
      ),
    ),
    ChartEvent(
      id: 'wld_beast_of_maura',
      name: 'The Beast of Maura',
      chart: EventChart.wilds,
      tier: ChartTier.legend,
      description:
          'The Beast of Maura has woken. It is two turns of hunting, ruin, and terror — but a pelt of it is worth more than a small farm.',
      dispatch: DispatchSpec(prompt: 'Join the great hunt for the Beast', maxUnits: 4, dc: 20),
      reward: RewardSpec(
        kind: RewardKind.material,
        categories: [RewardCategory.creaturePart],
        unitDice: UnitDice(1, 1),
        note: 'Two-turn event: victory grants a permanent bastion title',
      ),
    ),
  ];
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/data/default_data/events/wilds_events_test.dart`
Expected: PASS (6 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/data/default_data/events/wilds_events.dart test/data/default_data/events/wilds_events_test.dart
git commit -m "feat: add The Wilds chart event catalog"
```

---

### Task 2: The Deeps catalog

**Files:**
- Create: `lib/data/default_data/events/deeps_events.dart`
- Test: `test/data/default_data/events/deeps_events_test.dart`

**Interfaces:**
- Consumes: same as Task 1.
- Produces: `List<ChartEvent> deepsEvents()`.

- [ ] **Step 1: Write the failing test**

Same test file shape as Task 1, with these differences:

```dart
// test/data/default_data/events/deeps_events_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:maura_bastion_system/data/default_data/events/deeps_events.dart';
import 'package:maura_bastion_system/data/models/events/chart_event.dart';
import 'package:maura_bastion_system/data/models/events/chart_tier.dart';
import 'package:maura_bastion_system/data/models/events/event_chart.dart';
import 'package:maura_bastion_system/data/models/rewards/reward.dart';

void main() {
  final events = deepsEvents();

  test('has 12 unique events', () {
    expect(events.length, 12);
    expect(events.map((e) => e.id).toSet().length, 12);
  });

  test('tier distribution is 4 basic / 4 skilled / 3 master / 1 legend', () {
    final counts = <ChartTier, int>{};
    for (final e in events) {
      counts[e.tier] = (counts[e.tier] ?? 0) + 1;
    }
    expect(counts[ChartTier.basic], 4);
    expect(counts[ChartTier.skilled], 4);
    expect(counts[ChartTier.master], 3);
    expect(counts[ChartTier.legend], 1);
  });

  test('every event belongs to the deeps chart and uses only deeps categories', () {
    final allowed = EventChart.deeps.rewardCategories.toSet();
    for (final e in events) {
      expect(e.chart, EventChart.deeps);
      expect(e.isArchetype, isFalse);
      for (final category in e.reward.categories) {
        expect(allowed.contains(category), isTrue, reason: e.id);
      }
    }
  });

  test('dispatch events are well-formed', () {
    for (final e in events) {
      if (e.dispatch == null) continue;
      expect(e.dispatch!.maxUnits, greaterThanOrEqualTo(1), reason: e.id);
      expect(e.dispatch!.dc, greaterThanOrEqualTo(1), reason: e.id);
      expect(e.dispatch!.prompt, isNotEmpty, reason: e.id);
    }
    expect(events.where((e) => e.dispatch != null).length, greaterThanOrEqualTo(7));
  });

  test('legend event is the Heart of the Mountain', () {
    final legend = events.singleWhere((e) => e.tier == ChartTier.legend);
    expect(legend.id, 'dps_heart_of_mountain');
    expect(legend.name, 'Heart of the Mountain');
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/data/default_data/events/deeps_events_test.dart`
Expected: FAIL — cannot find `deeps_events.dart`.

- [ ] **Step 3: Write the catalog**

```dart
// lib/data/default_data/events/deeps_events.dart
import 'package:maura_bastion_system/data/models/events/chart_event.dart';
import 'package:maura_bastion_system/data/models/events/chart_tier.dart';
import 'package:maura_bastion_system/data/models/events/dispatch.dart';
import 'package:maura_bastion_system/data/models/events/event_chart.dart';
import 'package:maura_bastion_system/data/models/events/reward_spec.dart';
import 'package:maura_bastion_system/data/models/rewards/reward.dart';

List<ChartEvent> deepsEvents() {
  return const [
    ChartEvent(
      id: 'dps_seam_strike',
      name: 'Seam Strike',
      chart: EventChart.deeps,
      tier: ChartTier.basic,
      description:
          'The picks have struck a promising seam. Work it before the shift ends.',
      dispatch: DispatchSpec(prompt: 'Work the new seam', maxUnits: 4, dc: 12),
      reward: RewardSpec(
        kind: RewardKind.material,
        categories: [RewardCategory.metal, RewardCategory.stone],
        unitDice: UnitDice(1, 2),
      ),
    ),
    ChartEvent(
      id: 'dps_quarry_flakes',
      name: 'Quarry Flakes',
      chart: EventChart.deeps,
      tier: ChartTier.basic,
      description:
          'The quarry waste piles still glint when the light is right. A slow afternoon of sorting yields a little something.',
      reward: RewardSpec(
        kind: RewardKind.material,
        categories: [RewardCategory.stone],
        unitDice: UnitDice(1, 1),
      ),
    ),
    ChartEvent(
      id: 'dps_prospector_rumors',
      name: 'Prospector Rumors',
      chart: EventChart.deeps,
      tier: ChartTier.basic,
      description:
          'A prospector at the tavern sold you a map for two coppers. Half of what he said was probably true.',
      reward: RewardSpec(
        kind: RewardKind.material,
        categories: [RewardCategory.stone],
        unitDice: UnitDice(1, 2),
        note: 'Half the tales are false',
      ),
    ),
    ChartEvent(
      id: 'dps_shoring_up',
      name: 'Shoring Up',
      chart: EventChart.deeps,
      tier: ChartTier.basic,
      description:
          'The lower galleries need new timbers. Good honest work, and the old beams can be reclaimed and sold.',
      dispatch: DispatchSpec(prompt: 'Send crews to shore the galleries', maxUnits: 3, dc: 12),
      reward: RewardSpec(
        kind: RewardKind.material,
        categories: [RewardCategory.metal],
        unitDice: UnitDice(1, 1),
        note: 'Support beams reclaimed',
      ),
    ),
    ChartEvent(
      id: 'dps_collapsed_shaft',
      name: 'Collapsed Shaft',
      chart: EventChart.deeps,
      tier: ChartTier.skilled,
      description:
          'The main shaft has caved. Dig for the trapped crew, or salvage the exposed seam while it lasts — either pays.',
      dispatch: DispatchSpec(prompt: 'Answer the collapse', maxUnits: 4, dc: 16),
      reward: RewardSpec(
        kind: RewardKind.material,
        categories: [RewardCategory.metal, RewardCategory.stone],
        picks: 2,
        unitDice: UnitDice(1, 2),
        note: 'Rescue the crew or salvage the seam',
      ),
    ),
    ChartEvent(
      id: 'dps_glowing_geode',
      name: 'Glowing Geode',
      chart: EventChart.deeps,
      tier: ChartTier.skilled,
      description:
          'A blast opened a hollow lined with softly glowing crystal. No work needed beyond a steady hand and a chisel.',
      reward: RewardSpec(
        kind: RewardKind.material,
        categories: [RewardCategory.stone],
        unitDice: UnitDice(1, 2),
      ),
    ),
    ChartEvent(
      id: 'dps_deep_vein',
      name: 'Deep Vein',
      chart: EventChart.deeps,
      tier: ChartTier.skilled,
      description:
          'The vein keeps going where the maps stop. Follow it down; the ore gets richer and the air gets worse.',
      dispatch: DispatchSpec(prompt: 'Follow the vein downward', maxUnits: 4, dc: 15),
      reward: RewardSpec(
        kind: RewardKind.material,
        categories: [RewardCategory.metal],
        unitDice: UnitDice(1, 2),
      ),
    ),
    ChartEvent(
      id: 'dps_abandoned_mine',
      name: 'The Abandoned Mine',
      chart: EventChart.deeps,
      tier: ChartTier.skilled,
      description:
          'The old mine was sealed a generation ago — for the collapse, they said. The equipment left behind was worth sealing it for.',
      dispatch: DispatchSpec(prompt: 'Explore the abandoned mine', maxUnits: 2, dc: 14),
      reward: RewardSpec(
        kind: RewardKind.material,
        categories: [RewardCategory.metal, RewardCategory.stone],
        unitDice: UnitDice(1, 2),
        note: 'The old works are not abandoned enough',
      ),
    ),
    ChartEvent(
      id: 'dps_glimmerdeep',
      name: 'The Glimmerdeep',
      chart: EventChart.deeps,
      tier: ChartTier.master,
      description:
          'Below the water table lies the Glimmerdeep, where the stone itself glitters. Every step deeper is richer — and one step too far is your last.',
      dispatch: DispatchSpec(prompt: 'Descend into the Glimmerdeep', maxUnits: 4, dc: 18),
      reward: RewardSpec(
        kind: RewardKind.material,
        categories: [RewardCategory.metal, RewardCategory.stone],
        picks: 2,
        unitDice: UnitDice(1, 2),
        note: 'Push one step deeper for a better rank — or the tunnel collapses',
      ),
    ),
    ChartEvent(
      id: 'dps_crystal_cavern',
      name: 'Crystal Cavern',
      chart: EventChart.deeps,
      tier: ChartTier.master,
      description:
          'A cavern of untouched crystal, found by a cave-in nobody survived. It will keep. Probably.',
      reward: RewardSpec(
        kind: RewardKind.material,
        categories: [RewardCategory.stone],
        unitDice: UnitDice(1, 2),
      ),
    ),
    ChartEvent(
      id: 'dps_waking_golem',
      name: 'The Waking Golem',
      chart: EventChart.deeps,
      tier: ChartTier.master,
      description:
          'The miners have uncovered a golem of living stone, dormant so far. Its body is a fortune in raw ore — if it stays asleep.',
      dispatch: DispatchSpec(prompt: 'Dismantle the sleeping golem', maxUnits: 3, dc: 17),
      reward: RewardSpec(
        kind: RewardKind.material,
        categories: [RewardCategory.metal],
        unitDice: UnitDice(1, 2),
        note: 'It wakes if you fail',
      ),
    ),
    ChartEvent(
      id: 'dps_heart_of_mountain',
      name: 'Heart of the Mountain',
      chart: EventChart.deeps,
      tier: ChartTier.legend,
      description:
          'Every miner dreams of it once: a single stone at the mountain\'s core, older than the world above. Bring it up and the deeps will remember your name.',
      dispatch: DispatchSpec(prompt: 'Descend to the mountain\'s heart', maxUnits: 4, dc: 20),
      reward: RewardSpec(
        kind: RewardKind.material,
        categories: [RewardCategory.stone],
        unitDice: UnitDice(1, 1),
        note: 'Permanent: +1 to all Deeps dispatch totals',
      ),
    ),
  ];
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/data/default_data/events/deeps_events_test.dart`
Expected: PASS (5 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/data/default_data/events/deeps_events.dart test/data/default_data/events/deeps_events_test.dart
git commit -m "feat: add The Deeps chart event catalog"
```

---

### Task 3: Verification

- [ ] **Step 1:** Run `flutter test test/data/default_data/events/ test/data/models/events/` — expect all pass.
- [ ] **Step 2:** Run `flutter test` — expect full suite pass.
- [ ] **Step 3:** Run `flutter analyze lib/data/default_data/events` — expect no issues.
