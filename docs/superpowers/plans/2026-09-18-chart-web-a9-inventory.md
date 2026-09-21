# Chart Web A9 — Bastion Inventory Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Track harvested materials per bastion — units, weight — and implement the overflow rule (sell the cheapest units first at market value when storage is full).

**Architecture:** `lib/data/models/rewards/bastion_inventory.dart`. Entries are keyed by `rewardId|rank` because rank-null materials (metals, meat, blood...) harvested in different tiers have different effective ranks and therefore different values. B1/B2 UI and plan C persistence consume this.

**Tech Stack:** Dart / Flutter. Tests with `flutter test`.

**Spec:** `docs/superpowers/specs/2026-09-18-chart-web-reward-system-design.md` (Section 4 phase 5, Section 6 storage-full rule)

## Global Constraints

- Value per unit: explicit `reward.marketValue` when present (herbs); meat/blood use `mainChartMeatBloodValueByRank[effectiveRank]`; all other rank-null materials use `mainChartValueByRank[effectiveRank]` (both maps in `lib/data/models/rewards/reward_harvest_rules.dart`).
- Weight = `reward.weightPerUnit * units`.
- Overflow sale: **lowest value-per-unit first**, until total weight ≤ `maxWeight`; gold gained = Σ value×units sold.
- Entries with the same reward but different effective ranks stay separate.
- House style: plain classes with const constructors, no comments unless non-obvious.

---

### Task 1: Inventory entries, addGrants, totalWeight

**Files:**
- Create: `lib/data/models/rewards/bastion_inventory.dart`
- Test: `test/data/models/rewards/bastion_inventory_test.dart`

**Interfaces:**
- Consumes: `Reward` (`reward.dart`), `Rank` (`rank.dart`), `RewardGrant` (`lib/data/models/events/reward_spec.dart`).
- Produces:
  - `class BastionInventoryEntry { final Reward reward; final Rank effectiveRank; final int units; const BastionInventoryEntry({...}); }`
  - `class BastionInventory { final Map<String, BastionInventoryEntry> entries; const BastionInventory({this.entries = const {}}); String static entryKey(String rewardId, Rank effectiveRank) => '$rewardId|${effectiveRank.name}'; BastionInventory addGrants(List<RewardGrant> grants); double totalWeight(); }`
    - `addGrants` returns a NEW inventory with grants merged into entries (units summed per key); grants with `units <= 0` are ignored.

- [ ] **Step 1: Write the failing test**

```dart
// test/data/models/rewards/bastion_inventory_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:maura_bastion_system/data/enums/rank.dart';
import 'package:maura_bastion_system/data/models/events/reward_spec.dart';
import 'package:maura_bastion_system/data/models/rewards/bastion_inventory.dart';
import 'package:maura_bastion_system/data/models/rewards/reward.dart';

Reward herb(String id, Rank rank, int value) => Reward(
      id: id,
      name: id,
      category: RewardCategory.herb,
      rank: rank,
      marketValue: value,
      weightPerUnit: 0.5,
      description: 'test',
    );

Reward metal(String id) => Reward(
      id: id,
      name: id,
      category: RewardCategory.metal,
      weightPerUnit: 5,
      description: 'test',
    );

Grant grant(Reward reward, Rank effective, int units) =>
    RewardGrant(reward: reward, effectiveRank: effective, units: units);

void main() {
  test('addGrants merges by reward and rank', () {
    final a = herb('rew_a', Rank.D, 150);
    final inventory = const BastionInventory()
        .addGrants([grant(a, Rank.D, 2)])
        .addGrants([grant(a, Rank.D, 3)]);
    expect(inventory.entries.length, 1);
    expect(inventory.entries.values.single.units, 5);
  });

  test('same reward at different ranks stays separate', () {
    final m = metal('rew_m');
    final inventory = const BastionInventory()
        .addGrants([grant(m, Rank.D, 2), grant(m, Rank.B, 1)]);
    expect(inventory.entries.length, 2);
    expect(inventory.totalWeight(), 15.0);
  });

  test('totalWeight sums weightPerUnit times units', () {
    final inventory = const BastionInventory().addGrants([
      grant(herb('rew_a', Rank.E, 15), Rank.E, 4),
      grant(metal('rew_m'), Rank.D, 3),
    ]);
    expect(inventory.totalWeight(), 4 * 0.5 + 3 * 5);
  });

  test('grants with zero or negative units are ignored', () {
    final inventory = const BastionInventory()
        .addGrants([grant(herb('rew_a', Rank.E, 15), Rank.E, 0)]);
    expect(inventory.entries, isEmpty);
  });

  test('addGrants does not mutate the source inventory', () {
    final a = herb('rew_a', Rank.E, 15);
    final original = const BastionInventory().addGrants([grant(a, Rank.E, 1)]);
    final updated = original.addGrants([grant(a, Rank.E, 1)]);
    expect(original.entries.values.single.units, 1);
    expect(updated.entries.values.single.units, 2);
  });
}
```

Note: the test's `Grant` helper aliases `RewardGrant` — write `typedef Grant = RewardGrant;` or use `RewardGrant` directly; keep whichever compiles cleanest.

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/data/models/rewards/bastion_inventory_test.dart`
Expected: FAIL — cannot find `bastion_inventory.dart`.

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/data/models/rewards/bastion_inventory.dart
import 'package:maura_bastion_system/data/enums/rank.dart';
import 'package:maura_bastion_system/data/models/events/reward_spec.dart';
import 'package:maura_bastion_system/data/models/rewards/reward.dart';

class BastionInventoryEntry {
  final Reward reward;
  final Rank effectiveRank;
  final int units;

  const BastionInventoryEntry({
    required this.reward,
    required this.effectiveRank,
    required this.units,
  });
}

class BastionInventory {
  final Map<String, BastionInventoryEntry> entries;

  const BastionInventory({this.entries = const {}});

  static String entryKey(String rewardId, Rank effectiveRank) =>
      '$rewardId|${effectiveRank.name}';

  BastionInventory addGrants(List<RewardGrant> grants) {
    final merged = Map<String, BastionInventoryEntry>.from(entries);
    for (final g in grants) {
      if (g.units <= 0) continue;
      final key = entryKey(g.reward.id, g.effectiveRank);
      final existing = merged[key];
      merged[key] = BastionInventoryEntry(
        reward: g.reward,
        effectiveRank: g.effectiveRank,
        units: (existing?.units ?? 0) + g.units,
      );
    }
    return BastionInventory(entries: merged);
  }

  double totalWeight() {
    return entries.values.fold(
      0,
      (sum, e) => sum + e.reward.weightPerUnit * e.units,
    ).toDouble();
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/data/models/rewards/bastion_inventory_test.dart`
Expected: PASS (5 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/data/models/rewards/bastion_inventory.dart test/data/models/rewards/bastion_inventory_test.dart
git commit -m "feat: add bastion inventory model with weight tracking"
```

---

### Task 2: valuePerUnit + sellDownTo overflow sale

**Files:**
- Modify: `lib/data/models/rewards/bastion_inventory.dart`
- Test: `test/data/models/rewards/bastion_inventory_test.dart` (append inside `main`)

**Interfaces:**
- Consumes: `mainChartValueByRank`, `mainChartMeatBloodValueByRank` (`reward_harvest_rules.dart`).
- Produces:
  - `int valuePerUnit(Reward reward, Rank effectiveRank)` (top-level function in the same file) — see Global Constraints.
  - `class SellOverflowResult { final BastionInventory inventory; final int goldGained; final List<RewardGrant> sold; const SellOverflowResult({...}); }`
  - `SellOverflowResult sellDownTo({required double maxWeight})` on `BastionInventory` — sells lowest value-per-unit entries first, wholly or partially (partial entries shrink `units`; entry removed at 0), until total weight ≤ maxWeight. Returns the remaining inventory, gold gained, and what was sold as `RewardGrant`s (partial sales get the units actually sold).

- [ ] **Step 1: Write the failing test** (append inside `main`)

```dart
  group('sellDownTo', () {
    test('inventory under the limit sells nothing', () {
      final inventory = const BastionInventory().addGrants([
        grant(herb('rew_a', Rank.E, 15), Rank.E, 4),
        grant(metal('rew_m'), Rank.D, 2),
      ]);
      final result = inventory.sellDownTo(maxWeight: 100);
      expect(result.goldGained, 0);
      expect(result.sold, isEmpty);
      expect(result.inventory.totalWeight(), inventory.totalWeight());
    });

    test('sells cheapest first until the weight fits', () {
      final cheap = herb('rew_cheap', Rank.E, 15);
      final pricey = herb('rew_pricey', Rank.D, 150);
      final inventory = const BastionInventory().addGrants([
        grant(cheap, Rank.E, 10), // 5 lbs, value 150
        grant(pricey, Rank.D, 10), // 5 lbs, value 1500
      ]);
      final result = inventory.sellDownTo(maxWeight: 8);
      expect(result.sold.single.reward.id, 'rew_cheap');
      expect(result.sold.single.units, 2);
      expect(result.goldGained, 2 * 15);
      expect(result.inventory.totalWeight(), lessThanOrEqualTo(8));
      expect(result.inventory.entries['rew_cheap|E'], isNull);
      expect(result.inventory.entries['rew_pricey|D']!.units, 10);
    });

    test('partial sale shrinks the cheapest entry', () {
      final cheap = herb('rew_cheap', Rank.E, 15);
      final inventory = const BastionInventory().addGrants([
        grant(cheap, Rank.E, 10), // 5 lbs
        grant(metal('rew_m'), Rank.D, 3), // 15 lbs
      ]);
      final result = inventory.sellDownTo(maxWeight: 17);
      expect(result.inventory.entries['rew_cheap|E']!.units, 6);
      expect(result.sold.single.units, 4);
      expect(result.goldGained, 4 * 15);
    });

    test('rank-null meat values come from the meat/blood chart', () {
      final meat = Reward(
        id: 'rew_meat',
        name: 'Meat',
        category: RewardCategory.meat,
        weightPerUnit: 2,
        description: 'test',
      );
      final inventory = const BastionInventory().addGrants([
        grant(herb('rew_pricey', Rank.D, 150), Rank.D, 10), // 5 lbs, 1500
        grant(meat, Rank.E, 10), // 20 lbs, 3/unit
      ]);
      final result = inventory.sellDownTo(maxWeight: 10);
      expect(result.sold.single.reward.id, 'rew_meat');
      expect(result.sold.single.units, 10);
      expect(result.goldGained, 10 * 3);
    });
  });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/data/models/rewards/bastion_inventory_test.dart`
Expected: FAIL — `sellDownTo` is not defined.

- [ ] **Step 3: Write minimal implementation**

```dart
int valuePerUnit(Reward reward, Rank effectiveRank) {
  if (reward.marketValue != null) return reward.marketValue!;
  if (reward.category == RewardCategory.meat ||
      reward.category == RewardCategory.blood) {
    return mainChartMeatBloodValueByRank[effectiveRank]!;
  }
  return mainChartValueByRank[effectiveRank]!;
}
```

(plus, on `BastionInventory`)

```dart
  SellOverflowResult sellDownTo({required double maxWeight}) {
    var inventory = this;
    var gold = 0;
    final sold = <RewardGrant>[];
    while (inventory.totalWeight() > maxWeight) {
      final sellable = inventory.entries.values
          .where((e) => e.units > 0)
          .toList()
        ..sort((a, b) => valuePerUnit(a.reward, a.effectiveRank)
            .compareTo(valuePerUnit(b.reward, b.effectiveRank)));
      if (sellable.isEmpty) break;
      final target = sellable.first;
      final overweight = inventory.totalWeight() - maxWeight;
      final weightPerUnit = target.reward.weightPerUnit;
      final unitsToSell = weightPerUnit <= 0
          ? target.units
          : (overweight / weightPerUnit).ceil().clamp(1, target.units);
      sold.add(RewardGrant(
        reward: target.reward,
        effectiveRank: target.effectiveRank,
        units: unitsToSell,
      ));
      gold += unitsToSell * valuePerUnit(target.reward, target.effectiveRank);
      final key = entryKey(target.reward.id, target.effectiveRank);
      final remainingUnits = target.units - unitsToSell;
      final merged = Map<String, BastionInventoryEntry>.from(inventory.entries);
      if (remainingUnits <= 0) {
        merged.remove(key);
      } else {
        merged[key] = BastionInventoryEntry(
          reward: target.reward,
          effectiveRank: target.effectiveRank,
          units: remainingUnits,
        );
      }
      inventory = BastionInventory(entries: merged);
    }
    return SellOverflowResult(inventory: inventory, goldGained: gold, sold: sold);
  }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/data/models/rewards/bastion_inventory_test.dart`
Expected: PASS (9 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/data/models/rewards/bastion_inventory.dart test/data/models/rewards/bastion_inventory_test.dart
git commit -m "feat: add inventory overflow sale at market value"
```

---

### Task 3: Verification

- [ ] **Step 1:** Run `flutter test test/data/models/rewards/` — expect all pass.
- [ ] **Step 2:** Run `flutter test` — expect full suite pass.
- [ ] **Step 3:** Run `flutter analyze lib/data/models/rewards` — expect no issues.
