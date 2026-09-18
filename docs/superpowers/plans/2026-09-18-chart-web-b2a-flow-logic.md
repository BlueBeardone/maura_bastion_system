# Chart Web B2a — Inventory Cubit & Turn-Flow Logic Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Provide the state + logic the turn-flow dialog (B2b) will drive: a `BastionInventoryCubit` that stores rewards and auto-sells overflow, and pure helpers that map bastion people into dispatch units and resolve an event's dispatch/rewards in one call.

**Architecture:** `bastion_storage_max_weight` constant + entry merge on the existing `BastionInventory`; a new cubit under `lib/features/bastions_page/logic/`; pure flow helpers in `lib/data/models/events/turn_flow.dart`. No UI changes in this plan (B2b owns the dialog + page wiring).

**Tech Stack:** Flutter + `flutter_bloc`. Tests with `flutter test`.

**Spec:** `docs/superpowers/specs/2026-09-18-chart-web-reward-system-design.md` (Section 4 phases 3–5, Section 6 storage-full rule)

## Global Constraints

- **Bastion storage cap: 500 lbs** (`bastionStorageMaxWeight = 500.0` in `lib/data/models/rewards/bastion_inventory.dart`).
- Overflow: auto-sold via `BastionInventory.sellDownTo` (cheapest first), gold credited, sold units reported.
- Dispatch unit mapping: `DefenderType.knight → knight`, `bastionDefender → bastionDefender`, `beast → beast`; every `Hireling → hireling`. Display name = entity name, else a readable fallback ('Defender', 'Hireling').
- No-dispatch events auto-succeed (`success = dispatch == null ? true : dispatch.success`).
- House style: const constructors, part-file pattern for cubit/state, no comments unless non-obvious.

---

### Task 1: Storage cap + BastionInventoryCubit

**Files:**
- Modify: `lib/data/models/rewards/bastion_inventory.dart` (add `const double bastionStorageMaxWeight = 500.0;`)
- Create: `lib/features/bastions_page/logic/bastion_inventory_cubit.dart`
- Create: `lib/features/bastions_page/logic/bastion_inventory_state.dart`
- Test: `test/features/bastions_page/logic/bastion_inventory_cubit_test.dart`

**Interfaces:**
- Consumes: `BastionInventory`, `RewardGrant` (`lib/data/models/events/reward_spec.dart`), `Bastion` (for load parity with `ChartPointsCubit`).
- Produces:
  - `class BastionInventoryState extends Equatable { final String? bastionId; final BastionInventory inventory; final int goldEarned; final List<RewardGrant> lastSold; const BastionInventoryState({bastionId, inventory = const BastionInventory(), goldEarned = 0, lastSold = const []}); }`
  - `class BastionInventoryCubit extends Cubit<BastionInventoryState> { void load(Bastion bastion); void addRewards(List<RewardGrant> grants); }`
    - `load` resets to an empty inventory for the bastion (persistence is plan C).
    - `addRewards` merges grants; if `totalWeight() > bastionStorageMaxWeight`, runs `sellDownTo(maxWeight: bastionStorageMaxWeight)`, adds `goldGained` to `goldEarned`, and records the sold grants in `lastSold` (empty list when no sale happened).

- [ ] **Step 1: Write the failing test**

```dart
// test/features/bastions_page/logic/bastion_inventory_cubit_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:maura_bastion_system/data/enums/rank.dart';
import 'package:maura_bastion_system/data/models/bastion/bastion.dart';
import 'package:maura_bastion_system/data/models/events/reward_spec.dart';
import 'package:maura_bastion_system/data/models/rewards/bastion_inventory.dart';
import 'package:maura_bastion_system/data/models/rewards/reward.dart';
import 'package:maura_bastion_system/features/bastions_page/logic/bastion_inventory_cubit.dart';

Reward _metal(String id) => Reward(
      id: id,
      name: id,
      category: RewardCategory.metal,
      weightPerUnit: 5,
      description: 'test',
    );

RewardGrant _grant(Reward reward, int units) => RewardGrant(
      reward: reward,
      effectiveRank: Rank.D,
      units: units,
    );

Bastion _bastion() => Bastion(id: 'b1', name: 'T', description: '', facilities: const []);

void main() {
  late BastionInventoryCubit cubit;

  setUp(() => cubit = BastionInventoryCubit());
  tearDown(() => cubit.close());

  test('initial state is empty', () {
    expect(cubit.state.bastionId, isNull);
    expect(cubit.state.inventory.entries, isEmpty);
    expect(cubit.state.goldEarned, 0);
  });

  test('load resets per bastion', () {
    cubit.load(_bastion());
    cubit.addRewards([_grant(_metal('rew_m'), 2)]);
    cubit.load(_bastion());
    expect(cubit.state.inventory.entries, isEmpty);
    expect(cubit.state.bastionId, 'b1');
  });

  test('addRewards stores grants without a sale under the cap', () {
    cubit.load(_bastion());
    cubit.addRewards([_grant(_metal('rew_m'), 2)]);
    expect(cubit.state.inventory.totalWeight(), 10.0);
    expect(cubit.state.goldEarned, 0);
    expect(cubit.state.lastSold, isEmpty);
  });

  test('overflow auto-sells cheapest first and credits gold', () {
    cubit.load(_bastion());
    // 101 metal units = 505 lbs > 500 lbs cap -> sell 1 unit (150 GP at D).
    cubit.addRewards([_grant(_metal('rew_m'), 101)]);
    expect(cubit.state.inventory.totalWeight(), lessThanOrEqualTo(500));
    expect(cubit.state.goldEarned, 150);
    expect(cubit.state.lastSold.single.reward.id, 'rew_m');
    expect(cubit.state.lastSold.single.units, 1);
  });

  test('gold accumulates across overflow sales', () {
    cubit.load(_bastion());
    cubit.addRewards([_grant(_metal('rew_m'), 101)]);
    cubit.addRewards([_grant(_metal('rew_m'), 1)]);
    expect(cubit.state.goldEarned, 300);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/bastions_page/logic/bastion_inventory_cubit_test.dart`
Expected: FAIL — cannot find `bastion_inventory_cubit.dart`.

- [ ] **Step 3: Write minimal implementation**

Add to `lib/data/models/rewards/bastion_inventory.dart` (top level):

```dart
const double bastionStorageMaxWeight = 500.0;
```

```dart
// lib/features/bastions_page/logic/bastion_inventory_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maura_bastion_system/data/models/bastion/bastion.dart';
import 'package:maura_bastion_system/data/models/events/reward_spec.dart';
import 'package:maura_bastion_system/data/models/rewards/bastion_inventory.dart';

part 'bastion_inventory_state.dart';

class BastionInventoryCubit extends Cubit<BastionInventoryState> {
  BastionInventoryCubit() : super(const BastionInventoryState());

  void load(Bastion bastion) {
    emit(BastionInventoryState(bastionId: bastion.id));
  }

  void addRewards(List<RewardGrant> grants) {
    var inventory = state.inventory.addGrants(grants);
    var gold = state.goldEarned;
    var sold = const <RewardGrant>[];
    if (inventory.totalWeight() > bastionStorageMaxWeight) {
      final result =
          inventory.sellDownTo(maxWeight: bastionStorageMaxWeight);
      inventory = result.inventory;
      gold += result.goldGained;
      sold = result.sold;
    }
    emit(BastionInventoryState(
      bastionId: state.bastionId,
      inventory: inventory,
      goldEarned: gold,
      lastSold: sold,
    ));
  }
}
```

```dart
// lib/features/bastions_page/logic/bastion_inventory_state.dart
part of 'bastion_inventory_cubit.dart';

class BastionInventoryState extends Equatable {
  final String? bastionId;
  final BastionInventory inventory;
  final int goldEarned;
  final List<RewardGrant> lastSold;

  const BastionInventoryState({
    this.bastionId,
    this.inventory = const BastionInventory(),
    this.goldEarned = 0,
    this.lastSold = const [],
  });

  @override
  List<Object?> get props => [bastionId, inventory, goldEarned, lastSold];
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/bastions_page/logic/bastion_inventory_cubit_test.dart`
Expected: PASS (5 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/data/models/rewards/bastion_inventory.dart lib/features/bastions_page/logic/bastion_inventory_cubit.dart lib/features/bastions_page/logic/bastion_inventory_state.dart test/features/bastions_page/logic/bastion_inventory_cubit_test.dart
git commit -m "feat: add bastion inventory cubit with overflow sale"
```

---

### Task 2: Turn-flow logic helpers

**Files:**
- Create: `lib/data/models/events/turn_flow.dart`
- Test: `test/data/models/events/turn_flow_test.dart`

**Interfaces:**
- Consumes: `ChartEvent` (A3), `DispatchSpec`/`DispatchUnit`/`DispatchResult`/`resolveDispatch`/`DispatchUnitType` (A2), `TurnReward`/`rollTurnReward` (A3), `Defender`/`DefenderType` (`lib/data/models/npcs/defender.dart`, `lib/data/enums/defender_type.dart`), `Hireling` (`lib/data/models/npcs/hireling.dart`), `Bastion`.
- Produces:
  - `DispatchUnitType dispatchTypeForDefender(DefenderType type)` — knight→knight, bastionDefender→bastionDefender, beast→beast.
  - `List<DispatchUnit> dispatchUnitsFromBastion(Bastion bastion)` — defenders first (id, name ?? 'Defender', mapped type), then hirelings (id, name ?? 'Hireling', `DispatchUnitType.hireling`).
  - `DispatchResult? resolveEventDispatch({required ChartEvent event, required List<DispatchUnit> selected, Random? rng})` — null when the event has no dispatch; otherwise `resolveDispatch(spec: event.dispatch!, units: selected, rng: rng)`.
  - `TurnReward resolveEventRewards({required ChartEvent event, DispatchResult? dispatch, Random? rng})` — `rollTurnReward(event: event, success: dispatch == null ? true : dispatch.success, rng: rng)`.

- [ ] **Step 1: Write the failing test**

```dart
// test/data/models/events/turn_flow_test.dart
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:maura_bastion_system/data/enums/defender_type.dart';
import 'package:maura_bastion_system/data/models/bastion/bastion.dart';
import 'package:maura_bastion_system/data/models/events/chart_event.dart';
import 'package:maura_bastion_system/data/models/events/chart_tier.dart';
import 'package:maura_bastion_system/data/models/events/dispatch.dart';
import 'package:maura_bastion_system/data/models/events/event_chart.dart';
import 'package:maura_bastion_system/data/models/events/turn_flow.dart';
import 'package:maura_bastion_system/data/models/npcs/defender.dart';
import 'package:maura_bastion_system/data/models/npcs/hireling.dart';

ChartEvent _dispatchable() => const ChartEvent(
      id: 'evt_d',
      name: 'Dispatchable',
      chart: EventChart.wilds,
      tier: ChartTier.basic,
      description: 'd',
      dispatch: DispatchSpec(prompt: 'p', maxUnits: 2, dc: 1),
    );

ChartEvent _plain() => const ChartEvent(
      id: 'evt_p',
      name: 'Plain',
      chart: EventChart.wilds,
      tier: ChartTier.basic,
      description: 'd',
    );

void main() {
  test('dispatchTypeForDefender maps all defender types', () {
    expect(dispatchTypeForDefender(DefenderType.knight), DispatchUnitType.knight);
    expect(
        dispatchTypeForDefender(DefenderType.bastionDefender),
        DispatchUnitType.bastionDefender);
    expect(dispatchTypeForDefender(DefenderType.beast), DispatchUnitType.beast);
  });

  test('dispatchUnitsFromBastion maps defenders then hirelings', () {
    final bastion = Bastion(
      id: 'b1',
      name: 'T',
      description: '',
      facilities: const [],
      defenders: [
        Defender(id: 'd1', name: 'Aldric', type: DefenderType.knight, bastionId: 'b1'),
        Defender(id: 'd2', type: DefenderType.beast, bastionId: 'b1'),
      ],
      hirelings: [
        Hireling(id: 'h1', name: 'Mira', bastionId: 'b1'),
      ],
    );
    final units = dispatchUnitsFromBastion(bastion);
    expect(units.length, 3);
    expect(units[0].type, DispatchUnitType.knight);
    expect(units[0].name, 'Aldric');
    expect(units[1].type, DispatchUnitType.beast);
    expect(units[1].name, 'Defender');
    expect(units[2].type, DispatchUnitType.hireling);
    expect(units[2].name, 'Mira');
  });

  test('resolveEventDispatch returns null for plain events', () {
    expect(
      resolveEventDispatch(event: _plain(), selected: const [], rng: Random(1)),
      isNull,
    );
  });

  test('resolveEventDispatch resolves with dice for dispatchable events', () {
    final result = resolveEventDispatch(
      event: _dispatchable(),
      selected: const [
        DispatchUnit(id: 'a', name: 'A', type: DispatchUnitType.knight),
      ],
      rng: Random(3),
    );
    expect(result, isNotNull);
    expect(result!.unitRolls.single.rolls, isNotEmpty);
  });

  test('resolveEventRewards auto-succeeds plain events', () {
    final reward = resolveEventRewards(event: _plain());
    expect(reward.recruit, RewardKind.none);
  });
}
```

Note: check `Hireling`'s constructor (does it require fields beyond id/name/bastionId?) and adapt the test's hireling construction to the real model — the assertions on mapping stay as written.

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/data/models/events/turn_flow_test.dart`
Expected: FAIL — cannot find `turn_flow.dart`.

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/data/models/events/turn_flow.dart
import 'dart:math';

import 'package:maura_bastion_system/data/enums/defender_type.dart';
import 'package:maura_bastion_system/data/models/bastion/bastion.dart';
import 'package:maura_bastion_system/data/models/events/chart_event.dart';
import 'package:maura_bastion_system/data/models/events/dispatch.dart';
import 'package:maura_bastion_system/data/models/events/reward_spec.dart';
import 'package:maura_bastion_system/data/models/npcs/defender.dart';
import 'package:maura_bastion_system/data/models/npcs/hireling.dart';

DispatchUnitType dispatchTypeForDefender(DefenderType type) {
  switch (type) {
    case DefenderType.knight:
      return DispatchUnitType.knight;
    case DefenderType.bastionDefender:
      return DispatchUnitType.bastionDefender;
    case DefenderType.beast:
      return DispatchUnitType.beast;
  }
}

List<DispatchUnit> dispatchUnitsFromBastion(Bastion bastion) {
  return [
    for (final d in bastion.defenders)
      DispatchUnit(
        id: d.id,
        name: d.name ?? 'Defender',
        type: dispatchTypeForDefender(d.type),
      ),
    for (final h in bastion.hirelings)
      DispatchUnit(
        id: h.id,
        name: h.name ?? 'Hireling',
        type: DispatchUnitType.hireling,
      ),
  ];
}

DispatchResult? resolveEventDispatch({
  required ChartEvent event,
  required List<DispatchUnit> selected,
  Random? rng,
}) {
  final spec = event.dispatch;
  if (spec == null) return null;
  return resolveDispatch(spec: spec, units: selected, rng: rng);
}

TurnReward resolveEventRewards({
  required ChartEvent event,
  DispatchResult? dispatch,
  Random? rng,
}) {
  return rollTurnReward(
    event: event,
    success: dispatch == null ? true : dispatch.success,
    rng: rng,
  );
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/data/models/events/turn_flow_test.dart`
Expected: PASS (5 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/data/models/events/turn_flow.dart test/data/models/events/turn_flow_test.dart
git commit -m "feat: add turn flow dispatch/reward helpers"
```

---

### Task 3: Verification

- [ ] **Step 1:** Run `flutter test` — expect full suite pass.
- [ ] **Step 2:** Run `flutter analyze` — expect no new issues.
