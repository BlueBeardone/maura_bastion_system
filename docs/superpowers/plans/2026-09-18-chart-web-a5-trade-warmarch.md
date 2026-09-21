# Chart Web A5 — Event Catalog: The Trade Road & The War March Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Author the Trade Road (weaves, gold, recruits) and War March (combat loot, defenders) chart catalogs — 12 events each.

**Architecture:** Same as A4: one file per chart under `lib/data/default_data/events/`, one test file per chart.

**Tech Stack:** Dart / Flutter. Tests with `flutter test`.

**Spec:** `docs/superpowers/specs/2026-09-18-chart-web-reward-system-design.md` (Section 3)

## Global Constraints

- 12 events per chart: **4 Basic, 4 Skilled, 3 Master, 1 Legend**.
- Reward categories used must be the chart's own: tradeRoad = weave (gold via `goldDice`, not a category); warMarch = creaturePart (gold via `goldDice`).
- Known test gap from A4: test files need `import 'package:maura_bastion_system/data/models/events/reward_spec.dart';` for `RewardKind` — include it.
- Event ids prefixed `trd_` / `wrm_`; unique.
- Descriptions: 1–2 sentences, D&D-flavored.
- House style: const constructors, no comments unless non-obvious.

---

### Task 1: The Trade Road catalog

**Files:**
- Create: `lib/data/default_data/events/trade_road_events.dart`
- Test: `test/data/default_data/events/trade_road_events_test.dart`

**Interfaces:**
- Produces: `List<ChartEvent> tradeRoadEvents()`.

- [ ] **Step 1: Write the failing test**

```dart
// test/data/default_data/events/trade_road_events_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:maura_bastion_system/data/default_data/events/trade_road_events.dart';
import 'package:maura_bastion_system/data/models/events/chart_event.dart';
import 'package:maura_bastion_system/data/models/events/chart_tier.dart';
import 'package:maura_bastion_system/data/models/events/event_chart.dart';
import 'package:maura_bastion_system/data/models/rewards/reward.dart';

void main() {
  final events = tradeRoadEvents();

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

  test('material categories are weave-only', () {
    for (final e in events) {
      expect(e.chart, EventChart.tradeRoad);
      expect(e.isArchetype, isFalse);
      for (final category in e.reward.categories) {
        expect(category, RewardCategory.weave, reason: e.id);
      }
    }
  });

  test('gold-heavy events roll gold dice', () {
    final goldEvents =
        events.where((e) => e.reward.kind == RewardKind.gold).toList();
    expect(goldEvents.length, greaterThanOrEqualTo(5));
    for (final e in goldEvents) {
      expect(e.reward.goldDice, isNotNull, reason: e.id);
    }
  });

  test('dispatch events are well-formed', () {
    for (final e in events) {
      if (e.dispatch == null) continue;
      expect(e.dispatch!.maxUnits, greaterThanOrEqualTo(1), reason: e.id);
      expect(e.dispatch!.dc, greaterThanOrEqualTo(1), reason: e.id);
      expect(e.dispatch!.prompt, isNotEmpty, reason: e.id);
    }
    expect(events.where((e) => e.dispatch != null).length, greaterThanOrEqualTo(3));
  });

  test('legend event is The Merchant Prince', () {
    final legend = events.singleWhere((e) => e.tier == ChartTier.legend);
    expect(legend.id, 'trd_merchant_prince');
    expect(legend.name, 'The Merchant Prince');
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/data/default_data/events/trade_road_events_test.dart`
Expected: FAIL — cannot find `trade_road_events.dart`.

- [ ] **Step 3: Write the catalog**

```dart
// lib/data/default_data/events/trade_road_events.dart
import 'package:maura_bastion_system/data/models/events/chart_event.dart';
import 'package:maura_bastion_system/data/models/events/chart_tier.dart';
import 'package:maura_bastion_system/data/models/events/dispatch.dart';
import 'package:maura_bastion_system/data/models/events/event_chart.dart';
import 'package:maura_bastion_system/data/models/events/reward_spec.dart';
import 'package:maura_bastion_system/data/models/rewards/reward.dart';

List<ChartEvent> tradeRoadEvents() {
  return const [
    ChartEvent(
      id: 'trd_peddlers_cart',
      name: "Peddlers' Cart",
      chart: EventChart.tradeRoad,
      tier: ChartTier.basic,
      description:
          'A peddler\'s cart creaks up to your gates, full of things nobody needs and everybody wants.',
      reward: RewardSpec(
        kind: RewardKind.gold,
        goldDice: UnitDice(2, 10),
        note: 'Trinkets and pin-money',
      ),
    ),
    ChartEvent(
      id: 'trd_market_day',
      name: 'Market Day',
      chart: EventChart.tradeRoad,
      tier: ChartTier.basic,
      description:
          'Tolls, stall rents, and a small cut of everything sold. Market day is a good day.',
      reward: RewardSpec(
        kind: RewardKind.gold,
        goldDice: UnitDice(3, 10),
      ),
    ),
    ChartEvent(
      id: 'trd_letter_of_credit',
      name: 'Letter of Credit',
      chart: EventChart.tradeRoad,
      tier: ChartTier.basic,
      description:
          'A merchant house settles an old debt with a letter of credit. It is worth the ink it is written in — this time.',
      reward: RewardSpec(
        kind: RewardKind.gold,
        goldDice: UnitDice(2, 12),
      ),
    ),
    ChartEvent(
      id: 'trd_debt_collector',
      name: 'The Debt Collector',
      chart: EventChart.tradeRoad,
      tier: ChartTier.basic,
      description:
          'A collector arrives with a ledger and no sense of humor. One of your hirelings owes money to dangerous people.',
      reward: RewardSpec(
        note: 'Pay 50 GP or lose one hireling this turn (choice at resolution)',
      ),
    ),
    ChartEvent(
      id: 'trd_the_fair',
      name: 'The Fair Comes to Maura',
      chart: EventChart.tradeRoad,
      tier: ChartTier.skilled,
      description:
          'A traveling fair sets up beneath your walls. A rented stall and a generous purse of prizes draw the crowds — and their coin.',
      reward: RewardSpec(
        kind: RewardKind.gold,
        goldDice: UnitDice(4, 10),
        note: 'After 25 GP of stall fees',
      ),
    ),
    ChartEvent(
      id: 'trd_silk_shipment',
      name: 'Silk Shipment',
      chart: EventChart.tradeRoad,
      tier: ChartTier.skilled,
      description:
          'A shipment of exotic weave needs an armed escort over the ford. Honest pay for honest work.',
      dispatch: DispatchSpec(prompt: 'Escort the silk shipment', maxUnits: 2, dc: 14),
      reward: RewardSpec(
        kind: RewardKind.material,
        categories: [RewardCategory.weave],
        unitDice: UnitDice(1, 2),
      ),
    ),
    ChartEvent(
      id: 'trd_exotic_market',
      name: 'Exotic Market',
      chart: EventChart.tradeRoad,
      tier: ChartTier.skilled,
      description:
          'A caravanserai of strange goods pitches camp for a night. You could take coin, or take something rarer.',
      reward: RewardSpec(
        kind: RewardKind.material,
        categories: [RewardCategory.weave],
        unitDice: UnitDice(1, 2),
        note: 'Or take 150 GP instead (choice at resolution)',
      ),
    ),
    ChartEvent(
      id: 'trd_guest_sanctuary',
      name: 'Seeking Sanctuary',
      chart: EventChart.tradeRoad,
      tier: ChartTier.skilled,
      description:
          'A Notable arrives at your gates asking only for shelter and silence for a turn. Gratitude like that pays well.',
      reward: RewardSpec(
        kind: RewardKind.recruitHireling,
        note: 'A notable seeking sanctuary repays kindness with a gift on leaving',
      ),
    ),
    ChartEvent(
      id: 'trd_diamond_rough',
      name: 'Diamond in the Rough',
      chart: EventChart.tradeRoad,
      tier: ChartTier.master,
      description:
          'A desperate traveler sells you a battered case of oddities for pocket change. Appraising it takes a careful eye — and a willingness to be wrong.',
      reward: RewardSpec(
        kind: RewardKind.gold,
        goldDice: UnitDice(6, 10),
        note: 'Buy low, sell high — or keep it',
      ),
    ),
    ChartEvent(
      id: 'trd_caravan_contract',
      name: 'Caravan Contract',
      chart: EventChart.tradeRoad,
      tier: ChartTier.master,
      description:
          'A great caravan offers a standing contract: guard it across the wild country and share in the profits.',
      dispatch: DispatchSpec(prompt: 'Guard the caravan', maxUnits: 4, dc: 16),
      reward: RewardSpec(
        kind: RewardKind.material,
        categories: [RewardCategory.weave],
        unitDice: UnitDice(1, 2),
        goldDice: UnitDice(3, 10),
      ),
    ),
    ChartEvent(
      id: 'trd_merchant_rival',
      name: 'The Merchant Rival',
      chart: EventChart.tradeRoad,
      tier: ChartTier.master,
      description:
          'A rival house has been undercutting your trade routes for a season. Sit them down at the table and out-haggle them.',
      dispatch: DispatchSpec(prompt: 'Out-negotiate the rival house', maxUnits: 2, dc: 15),
      reward: RewardSpec(
        kind: RewardKind.gold,
        goldDice: UnitDice(4, 10),
        note: 'The rival signs favorable terms',
      ),
    ),
    ChartEvent(
      id: 'trd_merchant_prince',
      name: 'The Merchant Prince',
      chart: EventChart.tradeRoad,
      tier: ChartTier.legend,
      description:
          'The Merchant Prince of Maura invites you to dine, and leaves the port side of the table empty — a sign of respect. His contracts are worth a fortune.',
      reward: RewardSpec(
        kind: RewardKind.material,
        categories: [RewardCategory.weave],
        unitDice: UnitDice(1, 2),
        note: 'Exclusive contract: +50 GP to every future Trade Road reward (permanent)',
      ),
    ),
  ];
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/data/default_data/events/trade_road_events_test.dart`
Expected: PASS (6 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/data/default_data/events/trade_road_events.dart test/data/default_data/events/trade_road_events_test.dart
git commit -m "feat: add The Trade Road chart event catalog"
```

---

### Task 2: The War March catalog

**Files:**
- Create: `lib/data/default_data/events/war_march_events.dart`
- Test: `test/data/default_data/events/war_march_events_test.dart`

**Interfaces:**
- Produces: `List<ChartEvent> warMarchEvents()`.

- [ ] **Step 1: Write the failing test**

```dart
// test/data/default_data/events/war_march_events_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:maura_bastion_system/data/default_data/events/war_march_events.dart';
import 'package:maura_bastion_system/data/models/events/chart_event.dart';
import 'package:maura_bastion_system/data/models/events/chart_tier.dart';
import 'package:maura_bastion_system/data/models/events/dispatch.dart';
import 'package:maura_bastion_system/data/models/events/event_chart.dart';
import 'package:maura_bastion_system/data/models/rewards/reward.dart';

void main() {
  final events = warMarchEvents();

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

  test('material categories are creaturePart-only', () {
    for (final e in events) {
      expect(e.chart, EventChart.warMarch);
      expect(e.isArchetype, isFalse);
      for (final category in e.reward.categories) {
        expect(category, RewardCategory.creaturePart, reason: e.id);
      }
    }
  });

  test('dispatch events are well-formed and never exceed 4 units', () {
    for (final e in events) {
      if (e.dispatch == null) continue;
      expect(e.dispatch!.maxUnits, inInclusiveRange(1, 4), reason: e.id);
      expect(e.dispatch!.dc, greaterThanOrEqualTo(1), reason: e.id);
      expect(e.dispatch!.prompt, isNotEmpty, reason: e.id);
    }
    expect(events.where((e) => e.dispatch != null).length, greaterThanOrEqualTo(7));
  });

  test('the duel is a single-knight affair with a dice override', () {
    final duel = events.singleWhere((e) => e.id == 'wrm_duel');
    expect(duel.dispatch!.maxUnits, 1);
    expect(
      duel.dispatch!.diceOverride![DispatchUnitType.knight],
      const UnitDice(2, 6),
    );
  });

  test('legend event is The Black Banner', () {
    final legend = events.singleWhere((e) => e.tier == ChartTier.legend);
    expect(legend.id, 'wrm_the_black_banner');
    expect(legend.name, 'The Black Banner');
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/data/default_data/events/war_march_events_test.dart`
Expected: FAIL — cannot find `war_march_events.dart`.

- [ ] **Step 3: Write the catalog**

```dart
// lib/data/default_data/events/war_march_events.dart
import 'package:maura_bastion_system/data/models/events/chart_event.dart';
import 'package:maura_bastion_system/data/models/events/chart_tier.dart';
import 'package:maura_bastion_system/data/models/events/dispatch.dart';
import 'package:maura_bastion_system/data/models/events/event_chart.dart';
import 'package:maura_bastion_system/data/models/events/reward_spec.dart';
import 'package:maura_bastion_system/data/models/rewards/reward.dart';

List<ChartEvent> warMarchEvents() {
  return const [
    ChartEvent(
      id: 'wrm_wolf_pack',
      name: 'Wolf Pack',
      chart: EventChart.warMarch,
      tier: ChartTier.basic,
      description:
          'A pack of dire wolves has been shadowing your supply carts. Drive them off and take the pelts.',
      dispatch: DispatchSpec(prompt: 'Drive off the wolf pack', maxUnits: 2, dc: 12),
      reward: RewardSpec(
        kind: RewardKind.material,
        categories: [RewardCategory.creaturePart],
        unitDice: UnitDice(1, 1),
      ),
    ),
    ChartEvent(
      id: 'wrm_scavenger_band',
      name: 'Scavenger Band',
      chart: EventChart.warMarch,
      tier: ChartTier.basic,
      description:
          'Deserters turned scavengers have been raiding the fields. Run them off and reclaim what they stole.',
      dispatch: DispatchSpec(prompt: 'Rout the scavengers', maxUnits: 2, dc: 12),
      reward: RewardSpec(
        kind: RewardKind.gold,
        goldDice: UnitDice(2, 10),
        note: 'Recovered stolen goods',
      ),
    ),
    ChartEvent(
      id: 'wrm_lost_patrol',
      name: 'Lost Patrol',
      chart: EventChart.warMarch,
      tier: ChartTier.basic,
      description:
          'Two soldiers from a broken company stagger up to your gates. They fought well; they are yours if you will have them.',
      reward: RewardSpec(
        kind: RewardKind.recruitDefender,
        note: 'Stragglers from a broken company ask to stay',
      ),
    ),
    ChartEvent(
      id: 'wrm_lookout_duty',
      name: 'Lookout Duty',
      chart: EventChart.warMarch,
      tier: ChartTier.basic,
      description:
          'A quiet turn on the walls. The watch counts stars, and nothing stirs.',
      reward: RewardSpec(
        note: 'Nothing stirs tonight',
      ),
    ),
    ChartEvent(
      id: 'wrm_bandit_camp',
      name: 'Bandit Camp',
      chart: EventChart.warMarch,
      tier: ChartTier.skilled,
      description:
          'Your outriders found the bandit camp that has been bleeding the roads. Take it, and everything in it.',
      dispatch: DispatchSpec(prompt: 'Storm the bandit camp', maxUnits: 3, dc: 14),
      reward: RewardSpec(
        kind: RewardKind.gold,
        goldDice: UnitDice(4, 10),
        categories: [RewardCategory.creaturePart],
        unitDice: UnitDice(1, 1),
      ),
    ),
    ChartEvent(
      id: 'wrm_duel',
      name: 'The Duel',
      chart: EventChart.warMarch,
      tier: ChartTier.skilled,
      description:
          'A wandering knight rides up to your gates and demands single combat with your champion. Beat him, and his sword is yours.',
      dispatch: DispatchSpec(
        prompt: 'Send your champion',
        maxUnits: 1,
        dc: 15,
        diceOverride: {DispatchUnitType.knight: UnitDice(2, 6)},
      ),
      reward: RewardSpec(
        kind: RewardKind.recruitDefender,
        note: 'The wandering knight joins if defeated',
      ),
    ),
    ChartEvent(
      id: 'wrm_raider_raid',
      name: 'Raid the Raiders',
      chart: EventChart.warMarch,
      tier: ChartTier.skilled,
      description:
          'The raiders who burned the east fields are camped, drunk, and unaware. Return the favor.',
      dispatch: DispatchSpec(prompt: 'Raid the raiders\' camp', maxUnits: 4, dc: 16),
      reward: RewardSpec(
        kind: RewardKind.gold,
        goldDice: UnitDice(2, 10),
        categories: [RewardCategory.creaturePart],
        unitDice: UnitDice(1, 1),
        note: 'Recovered loot and war-beast remains',
      ),
    ),
    ChartEvent(
      id: 'wrm_siege_scare',
      name: 'Siege Scare',
      chart: EventChart.warMarch,
      tier: ChartTier.skilled,
      description:
          'Raiders prowl your walls all night looking for a way in. A stubborn watch sends them looking for easier pickings.',
      dispatch: DispatchSpec(prompt: 'Hold the walls through the night', maxUnits: 4, dc: 15),
      reward: RewardSpec(
        kind: RewardKind.gold,
        goldDice: UnitDice(3, 10),
        note: 'The raiders withdraw before dawn',
      ),
    ),
    ChartEvent(
      id: 'wrm_champion_challenge',
      name: 'Champion\'s Challenge',
      chart: EventChart.warMarch,
      tier: ChartTier.master,
      description:
          'A warlord of Maura sends a formal challenge: her champion against yours, winner takes the field and the warlord\'s purse.',
      dispatch: DispatchSpec(prompt: 'Answer the challenge', maxUnits: 2, dc: 18),
      reward: RewardSpec(
        kind: RewardKind.gold,
        goldDice: UnitDice(2, 10),
        categories: [RewardCategory.creaturePart],
        unitDice: UnitDice(1, 2),
      ),
    ),
    ChartEvent(
      id: 'wrm_lieutenant_offer',
      name: 'The Lieutenant\'s Offer',
      chart: EventChart.warMarch,
      tier: ChartTier.master,
      description:
          'A veteran lieutenant, unattached since her lord fell, offers you her banner and her blade. She does not offer twice.',
      reward: RewardSpec(
        kind: RewardKind.recruitDefender,
        note: 'A veteran lieutenant offers her banner',
      ),
    ),
    ChartEvent(
      id: 'wrm_enemy_forge',
      name: 'The Enemy Forge',
      chart: EventChart.warMarch,
      tier: ChartTier.master,
      description:
          'The war-camp arming Maura\'s enemies has a forge that never cools. Break it, and carry off whatever they were stockpiling.',
      dispatch: DispatchSpec(prompt: 'Break the enemy forge', maxUnits: 4, dc: 17),
      reward: RewardSpec(
        kind: RewardKind.gold,
        goldDice: UnitDice(4, 10),
        note: 'Break the forge, carry off the stock',
      ),
    ),
    ChartEvent(
      id: 'wrm_the_black_banner',
      name: 'The Black Banner',
      chart: EventChart.warMarch,
      tier: ChartTier.legend,
      description:
          'The Black Banner — the war-band that has never lost a siege — marches on Maura, and yours stands in its road. Beat it, and the legend is yours.',
      dispatch: DispatchSpec(prompt: 'Face the Black Banner', maxUnits: 4, dc: 20),
      reward: RewardSpec(
        kind: RewardKind.gold,
        goldDice: UnitDice(2, 4),
        categories: [RewardCategory.creaturePart],
        unitDice: UnitDice(1, 1),
        note: '250 GP per rank on victory; the banner\'s knight joins your bastion',
      ),
    ),
  ];
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/data/default_data/events/war_march_events_test.dart`
Expected: PASS (6 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/data/default_data/events/war_march_events.dart test/data/default_data/events/war_march_events_test.dart
git commit -m "feat: add The War March chart event catalog"
```

---

### Task 3: Verification

- [ ] **Step 1:** Run `flutter test test/data/default_data/events/ test/data/models/events/` — expect all pass.
- [ ] **Step 2:** Run `flutter test` — expect full suite pass.
- [ ] **Step 3:** Run `flutter analyze lib/data/default_data/events` — expect no issues.
