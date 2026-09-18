# Chart Web A6 — Event Catalog: The Hearth & The Arcane Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Author the final two chart catalogs — The Hearth (buffs, hirelings, drama) and The Arcane (planar finds) — 12 events each, completing the six-chart set.

**Architecture:** Same as A4/A5: one file per chart under `lib/data/default_data/events/`, one test file per chart.

**Tech Stack:** Dart / Flutter. Tests with `flutter test`.

**Spec:** `docs/superpowers/specs/2026-09-18-chart-web-reward-system-design.md` (Section 3)

## Global Constraints

- 12 events per chart: **4 Basic, 4 Skilled, 3 Master, 1 Legend**.
- Hearth grants **no material rewards** (`RewardSpec.categories` stays empty — its spec categories are buffs/hirelings; gold flows through `goldDice`, recruits through `recruitHireling`/`recruitDefender`, effects through `note`).
- Arcane material categories: **herb and weave only** (its spec categories).
- Event ids prefixed `hrt_` / `arc_`; unique. Include `reward_spec.dart` import in tests for `RewardKind`.
- Descriptions: 1–2 sentences, D&D-flavored. House style: const constructors, no comments unless non-obvious.

---

### Task 1: The Hearth catalog

**Files:**
- Create: `lib/data/default_data/events/hearth_events.dart`
- Test: `test/data/default_data/events/hearth_events_test.dart`

**Interfaces:**
- Produces: `List<ChartEvent> hearthEvents()`.

- [ ] **Step 1: Write the failing test**

```dart
// test/data/default_data/events/hearth_events_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:maura_bastion_system/data/default_data/events/hearth_events.dart';
import 'package:maura_bastion_system/data/models/events/chart_event.dart';
import 'package:maura_bastion_system/data/models/events/chart_tier.dart';
import 'package:maura_bastion_system/data/models/events/event_chart.dart';
import 'package:maura_bastion_system/data/models/events/reward_spec.dart';

void main() {
  final events = hearthEvents();

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

  test('no material categories — hearth rewards are gold, recruits, or notes', () {
    for (final e in events) {
      expect(e.chart, EventChart.hearth);
      expect(e.isArchetype, isFalse);
      expect(e.reward.categories, isEmpty, reason: e.id);
      expect(
        e.reward.kind,
        isNot(RewardKind.material),
        reason: e.id,
      );
    }
  });

  test('at least two recruit events and three gold events', () {
    expect(
      events.where((e) => e.reward.kind == RewardKind.recruitHireling).length,
      greaterThanOrEqualTo(2),
    );
    expect(
      events.where((e) => e.reward.kind == RewardKind.gold).length,
      greaterThanOrEqualTo(3),
    );
  });

  test('legend event is Heart of the Bastion', () {
    final legend = events.singleWhere((e) => e.tier == ChartTier.legend);
    expect(legend.id, 'hrt_heart_of_the_bastion');
    expect(legend.name, 'Heart of the Bastion');
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/data/default_data/events/hearth_events_test.dart`
Expected: FAIL — cannot find `hearth_events.dart`.

- [ ] **Step 3: Write the catalog**

```dart
// lib/data/default_data/events/hearth_events.dart
import 'package:maura_bastion_system/data/models/events/chart_event.dart';
import 'package:maura_bastion_system/data/models/events/chart_tier.dart';
import 'package:maura_bastion_system/data/models/events/dispatch.dart';
import 'package:maura_bastion_system/data/models/events/event_chart.dart';
import 'package:maura_bastion_system/data/models/events/reward_spec.dart';

List<ChartEvent> hearthEvents() {
  return const [
    ChartEvent(
      id: 'hrt_quiet_evening',
      name: 'Quiet Evening',
      chart: EventChart.hearth,
      tier: ChartTier.basic,
      description:
          'The fire is lit, the stew is good, and nobody is bleeding. A quiet evening at the bastion.',
      reward: RewardSpec(
        note: 'The bastion is warm and quiet',
      ),
    ),
    ChartEvent(
      id: 'hrt_loose_boardwork',
      name: 'Loose Boardwork',
      chart: EventChart.hearth,
      tier: ChartTier.basic,
      description:
          'A hireling swears the floorboards creak louder than yesterday. The carpenter wants paying either way.',
      reward: RewardSpec(
        note: 'Pay 10 GP or a hireling grumbles (+2 DC on the next Hearth dispatch)',
      ),
    ),
    ChartEvent(
      id: 'hrt_kitchen_fire',
      name: 'Kitchen Fire',
      chart: EventChart.hearth,
      tier: ChartTier.basic,
      description:
          'The kitchen caught alight mid-roast. Save the stores and there may be salvage worth keeping.',
      dispatch: DispatchSpec(prompt: 'Fight the kitchen fire', maxUnits: 2, dc: 10),
      reward: RewardSpec(
        kind: RewardKind.gold,
        goldDice: UnitDice(1, 6),
        note: 'Salvaged what the flames spared',
      ),
    ),
    ChartEvent(
      id: 'hrt_cellar_rats',
      name: 'Cellar Rats',
      chart: EventChart.hearth,
      tier: ChartTier.basic,
      description:
          'The cellar rats have grown fat, bold, and enormous. The village pays a bounty per tail.',
      dispatch: DispatchSpec(prompt: 'Clear the cellar rats', maxUnits: 2, dc: 12),
      reward: RewardSpec(
        kind: RewardKind.gold,
        goldDice: UnitDice(2, 10),
        note: 'Rat-catching bounty',
      ),
    ),
    ChartEvent(
      id: 'hrt_giant_bees',
      name: 'Giant Honeybees',
      chart: EventChart.hearth,
      tier: ChartTier.skilled,
      description:
          'A swarm of giant honeybees has settled in the barn. They can be driven off — or a brave soul might domesticate them.',
      dispatch: DispatchSpec(prompt: 'Deal with the bees', maxUnits: 2, dc: 14),
      reward: RewardSpec(
        note: 'Domesticate for a permanent +1 to herb rewards, or drive them off',
      ),
    ),
    ChartEvent(
      id: 'hrt_criminal_hireling',
      name: 'Criminal Hireling',
      chart: EventChart.hearth,
      tier: ChartTier.skilled,
      description:
          'One of your hirelings has a past, and the past has caught up. A collector waits at the gate with paperwork.',
      reward: RewardSpec(
        note: 'Pay 60 GP or lose one hireling (choice at resolution)',
      ),
    ),
    ChartEvent(
      id: 'hrt_wandering_professional',
      name: 'Wandering Professional',
      chart: EventChart.hearth,
      tier: ChartTier.skilled,
      description:
          'A tinker of rare skill passes through, admires the bastion, and asks to stay. Free, and worth every copper.',
      reward: RewardSpec(
        kind: RewardKind.recruitHireling,
        note: 'A wandering professional asks to join for free',
      ),
    ),
    ChartEvent(
      id: 'hrt_harvest_festival',
      name: 'Harvest Festival',
      chart: EventChart.hearth,
      tier: ChartTier.skilled,
      description:
          'The bastion hosts the season\'s festival. Stall fees, drinking songs, and a remarkably honest dice game.',
      reward: RewardSpec(
        kind: RewardKind.gold,
        goldDice: UnitDice(2, 10),
        note: 'Stall fees and games',
      ),
    ),
    ChartEvent(
      id: 'hrt_famed_bard',
      name: 'The Famed Bard',
      chart: EventChart.hearth,
      tier: ChartTier.master,
      description:
          'A bard whose name opens doors in three kingdoms has chosen YOUR common room for a residency. The crowds follow.',
      reward: RewardSpec(
        kind: RewardKind.gold,
        goldDice: UnitDice(4, 10),
        note: 'The common room is full for a week',
      ),
    ),
    ChartEvent(
      id: 'hrt_grievance',
      name: 'The Grievance',
      chart: EventChart.hearth,
      tier: ChartTier.master,
      description:
          'Half the hirelings have signed a complaint about the other half. Settle it fairly and morale soars; fumble it and the work suffers.',
      dispatch: DispatchSpec(prompt: 'Hear the grievance', maxUnits: 2, dc: 16),
      reward: RewardSpec(
        note: 'Settled fairly: +2 to the next Hearth dispatch',
      ),
    ),
    ChartEvent(
      id: 'hrt_masterwork_order',
      name: 'Masterwork Order',
      chart: EventChart.hearth,
      tier: ChartTier.master,
      description:
          'A visiting tailor has seen your workshops and wants a commission done to your house\'s standard. Payment is generous; the deadline is not.',
      dispatch: DispatchSpec(prompt: 'Fulfil the masterwork order', maxUnits: 2, dc: 15),
      reward: RewardSpec(
        kind: RewardKind.gold,
        goldDice: UnitDice(2, 10),
        note: 'A visiting tailor commissions work',
      ),
    ),
    ChartEvent(
      id: 'hrt_heart_of_the_bastion',
      name: 'Heart of the Bastion',
      chart: EventChart.hearth,
      tier: ChartTier.legend,
      description:
          'For one golden turn, everything works: the fires burn clean, the ale is sweet, and every hireling remembers why they came. Something like this can last, if you tend it.',
      dispatch: DispatchSpec(prompt: 'Tend the heart of the bastion', maxUnits: 4, dc: 18),
      reward: RewardSpec(
        kind: RewardKind.recruitHireling,
        note: 'Permanent: +1 to all Hearth dispatch totals',
      ),
    ),
  ];
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/data/default_data/events/hearth_events_test.dart`
Expected: PASS (5 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/data/default_data/events/hearth_events.dart test/data/default_data/events/hearth_events_test.dart
git commit -m "feat: add The Hearth chart event catalog"
```

---

### Task 2: The Arcane catalog

**Files:**
- Create: `lib/data/default_data/events/arcane_events.dart`
- Test: `test/data/default_data/events/arcane_events_test.dart`

**Interfaces:**
- Produces: `List<ChartEvent> arcaneEvents()`.

- [ ] **Step 1: Write the failing test**

```dart
// test/data/default_data/events/arcane_events_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:maura_bastion_system/data/default_data/events/arcane_events.dart';
import 'package:maura_bastion_system/data/models/events/chart_event.dart';
import 'package:maura_bastion_system/data/models/events/chart_tier.dart';
import 'package:maura_bastion_system/data/models/events/event_chart.dart';
import 'package:maura_bastion_system/data/models/rewards/reward.dart';

void main() {
  final events = arcaneEvents();

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

  test('material categories are herb and weave only', () {
    final allowed = EventChart.arcane.rewardCategories.toSet();
    for (final e in events) {
      expect(e.chart, EventChart.arcane);
      expect(e.isArchetype, isFalse);
      for (final category in e.reward.categories) {
        expect(allowed.contains(category), isTrue, reason: e.id);
      }
    }
  });

  test('legend event is The Door in the Hill', () {
    final legend = events.singleWhere((e) => e.tier == ChartTier.legend);
    expect(legend.id, 'arc_door_in_hill');
    expect(legend.name, 'The Door in the Hill');
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/data/default_data/events/arcane_events_test.dart`
Expected: FAIL — cannot find `arcane_events.dart`.

- [ ] **Step 3: Write the catalog**

```dart
// lib/data/default_data/events/arcane_events.dart
import 'package:maura_bastion_system/data/models/events/chart_event.dart';
import 'package:maura_bastion_system/data/models/events/chart_tier.dart';
import 'package:maura_bastion_system/data/models/events/dispatch.dart';
import 'package:maura_bastion_system/data/models/events/event_chart.dart';
import 'package:maura_bastion_system/data/models/events/reward_spec.dart';
import 'package:maura_bastion_system/data/models/rewards/reward.dart';

List<ChartEvent> arcaneEvents() {
  return const [
    ChartEvent(
      id: 'arc_planar_whisper',
      name: 'Planar Whisper',
      chart: EventChart.arcane,
      tier: ChartTier.basic,
      description:
          'The stable cat stared at an empty corner all night, and in the morning you know the name of a herb that should not grow here — but does.',
      reward: RewardSpec(
        kind: RewardKind.material,
        categories: [RewardCategory.herb],
        unitDice: UnitDice(1, 2),
        note: 'The whisper names a herb worth finding',
      ),
    ),
    ChartEvent(
      id: 'arc_moth_lights',
      name: 'Moth Lights',
      chart: EventChart.arcane,
      tier: ChartTier.basic,
      description:
          'Pale lights the size of hands drift over the hedgerows at dusk. Where they land, strange flora blooms.',
      dispatch: DispatchSpec(prompt: 'Follow the moth lights', maxUnits: 2, dc: 12),
      reward: RewardSpec(
        kind: RewardKind.material,
        categories: [RewardCategory.herb],
        unitDice: UnitDice(1, 2),
      ),
    ),
    ChartEvent(
      id: 'arc_fey_trinket',
      name: 'Fey Trinket',
      chart: EventChart.arcane,
      tier: ChartTier.basic,
      description:
          'A child of the bastion traded lunch for a little brass thing to a stranger with too many fingers. It appraises well.',
      reward: RewardSpec(
        kind: RewardKind.gold,
        goldDice: UnitDice(3, 6),
      ),
    ),
    ChartEvent(
      id: 'arc_cold_spot',
      name: 'The Cold Spot',
      chart: EventChart.arcane,
      tier: ChartTier.basic,
      description:
          'One flagstone in the east hall is cold enough to frost breath. The chaplain sprinkles salt on it and says to leave it be. For now.',
      reward: RewardSpec(
        note: 'Nothing happens — yet',
      ),
    ),
    ChartEvent(
      id: 'arc_fey_bargain',
      name: 'Fey Bargain',
      chart: EventChart.arcane,
      tier: ChartTier.skilled,
      description:
          'A voice under the garden offers a deal: one oddity of yours, one oddity of theirs. Their oddities are better. Their prices are odd.',
      reward: RewardSpec(
        kind: RewardKind.material,
        categories: [RewardCategory.weave],
        unitDice: UnitDice(1, 2),
        note: 'The price: one random material from your stores',
      ),
    ),
    ChartEvent(
      id: 'arc_ley_bloom',
      name: 'Ley Bloom',
      chart: EventChart.arcane,
      tier: ChartTier.skilled,
      description:
          'Where two ley lines cross in the orchard, the trees have flowered out of season. The blooms hum faintly in a chord.',
      dispatch: DispatchSpec(prompt: 'Gather the ley blooms', maxUnits: 3, dc: 15),
      reward: RewardSpec(
        kind: RewardKind.material,
        categories: [RewardCategory.herb],
        unitDice: UnitDice(1, 2),
      ),
    ),
    ChartEvent(
      id: 'arc_blink_dog',
      name: 'The Blink Dog',
      chart: EventChart.arcane,
      tier: ChartTier.skilled,
      description:
          'A blink dog has adopted the bastion: here, then gone, then here with a rabbit. It seems to intend to stay.',
      reward: RewardSpec(
        kind: RewardKind.recruitDefender,
        note: 'A blink dog adoptee (beast defender)',
      ),
    ),
    ChartEvent(
      id: 'arc_star_chart',
      name: 'The Star Chart',
      chart: EventChart.arcane,
      tier: ChartTier.skilled,
      description:
          'A chart fell from nowhere onto the scriptorium desk, inked in no constellation you know. A collector in town pays handsomely for the impossible.',
      reward: RewardSpec(
        kind: RewardKind.gold,
        goldDice: UnitDice(2, 10),
        note: 'Sold to a collector',
      ),
    ),
    ChartEvent(
      id: 'arc_star_fall',
      name: 'The Star Fall',
      chart: EventChart.arcane,
      tier: ChartTier.master,
      description:
          'A star came down in the night, trailing glass, and now half of Maura is racing to the crater. The flora growing in its light is the real prize.',
      dispatch: DispatchSpec(prompt: 'Race to the crater', maxUnits: 4, dc: 18),
      reward: RewardSpec(
        kind: RewardKind.material,
        categories: [RewardCategory.weave],
        unitDice: UnitDice(1, 2),
        note: 'Race the other claim-jumpers to the crater',
      ),
    ),
    ChartEvent(
      id: 'arc_dreaming_grove',
      name: 'The Dreaming Grove',
      chart: EventChart.arcane,
      tier: ChartTier.master,
      description:
          'Sleepers all across the bastion dream of the same grove, and those who walk there wake with loam under their nails and pockets full.',
      reward: RewardSpec(
        kind: RewardKind.material,
        categories: [RewardCategory.herb, RewardCategory.weave],
        picks: 2,
        unitDice: UnitDice(1, 2),
      ),
    ),
    ChartEvent(
      id: 'arc_planar_wandering',
      name: 'Planar Wandering',
      chart: EventChart.arcane,
      tier: ChartTier.master,
      description:
          'A lost creature of elsewhere stands in the cattle field, homesick and enormous. Guide it home and it will pay in things from beyond.',
      dispatch: DispatchSpec(prompt: 'Guide the wanderer home', maxUnits: 3, dc: 16),
      reward: RewardSpec(
        kind: RewardKind.material,
        categories: [RewardCategory.weave],
        unitDice: UnitDice(1, 2),
        note: 'Guide the lost planar home for a fee',
      ),
    ),
    ChartEvent(
      id: 'arc_door_in_hill',
      name: 'The Door in the Hill',
      chart: EventChart.arcane,
      tier: ChartTier.legend,
      description:
          'A door stands open in the hillside that was solid earth last week. Beyond it: a hall of everything anyone has ever lost, and a price for everything taken.',
      dispatch: DispatchSpec(prompt: 'Enter the door in the hill', maxUnits: 4, dc: 20),
      reward: RewardSpec(
        kind: RewardKind.material,
        categories: [RewardCategory.herb, RewardCategory.weave],
        unitDice: UnitDice(1, 2),
        note: 'Walk away and the door takes a point from your chart',
      ),
    ),
  ];
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/data/default_data/events/arcane_events_test.dart`
Expected: PASS (4 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/data/default_data/events/arcane_events.dart test/data/default_data/events/arcane_events_test.dart
git commit -m "feat: add The Arcane chart event catalog"
```

---

### Task 3: Verification

- [ ] **Step 1:** Run `flutter test test/data/default_data/events/` — expect all pass.
- [ ] **Step 2:** Run `flutter test` — expect full suite pass.
- [ ] **Step 3:** Run `flutter analyze lib/data/default_data/events` — expect no issues.
