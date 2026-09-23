# Bastion Attacks Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a chance that a Bastion turn is interrupted by a tier-scaled enemy attack resolved as round-based combat between the bastion's defenders and the attackers, with a random facility destroyed on a loss.

**Architecture:** A new pure model `bastion_attack.dart` holds the eligibility gate, facility-derived defense config, and combat/loot functions. A tiered enemy catalog lives in `enemy_catalog.dart`. A new `BastionAttackDialog` renders the fight. `bastion_page._takeBastionTurn` branches to an attack path before the normal event flow, reusing existing defender/facility cubits and the existing Discord/turn-result logging.

**Tech Stack:** Flutter, Dart, flutter_bloc, get_it, flutter_test.

## Global Constraints

- Attack chance is a named constant `defaultAttackChance = 0.25`.
- Minimum earned points to be attackable: `attackMinEarnedPoints = 6`.
- An operational Humble Exterior (`cat_humble_exterior`, `constructedTurns >= constructionTurns`) blocks attacks entirely.
- Enemy count = `1d4` × tier multiplier: `basic` 1, `skilled` 2, `master` 3, `legend` 4.
- Default death threshold 4; a defender dies when its roll is strictly less than the threshold.
- Threshold reductions stack and **floor at 1**.
- Armory operational: threshold −1, or −2 at rank A/S.
- Battlements operational: threshold −1 per two ranks above D.
- Armory + Battlements both operational: bastion defenders roll `1d8` instead of `1d6`.
- War Room operational: defenders roll at advantage (two dice, keep the higher).
- A defender always kills one enemy even if it dies. Last enemy killed = win. No defenders = auto-loss.
- Dead defenders are removed via `DefendersCubit.removeDefender`; a lost facility is destroyed via `BastionCubit.removeFacility`.
- Do not add comments to source files unless the existing file already uses them.

---

### Task 1: Attack gate, defense config, and enemy roll

**Files:**
- Create: `lib/data/models/events/bastion_attack.dart`
- Test: `test/data/models/events/bastion_attack_test.dart`

**Interfaces:**
- Consumes: `ChartPoints.earnedPointsFor(Bastion)`, `Facility`, `Bastion`, `ChartTier`, `UnitDice`, `defaultDiceFor`, `Rank`, `DefenderType`.
- Produces:
  - `const double defaultAttackChance`
  - `const int attackMinEarnedPoints`
  - `class BastionEnemy { String id; String name; String description; ChartTier tier; }`
  - `int enemyMultiplier(ChartTier tier)`
  - `int rollEnemyCount(ChartTier tier, Random rng)`
  - `bool bastionIsAttackEligible(Bastion bastion)`
  - `bool shouldRollBastionAttack(Bastion bastion, {Random? rng, double chance})`
  - `class BastionDefenseConfig { int deathThreshold; bool advantage; UnitDice bastionDefenderDice; }`
  - `BastionDefenseConfig bastionDefenseConfig(Bastion bastion)`
  - `UnitDice defenderDiceFor(DefenderType type, BastionDefenseConfig config)`

- [ ] **Step 1: Write the failing tests**

Create `test/data/models/events/bastion_attack_test.dart`:

```dart
// test/data/models/events/bastion_attack_test.dart
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:maura_bastion_system/data/enums/defender_type.dart';
import 'package:maura_bastion_system/data/enums/rank.dart';
import 'package:maura_bastion_system/data/models/bastion/bastion.dart';
import 'package:maura_bastion_system/data/models/bastion/facility.dart';
import 'package:maura_bastion_system/data/models/events/bastion_attack.dart';
import 'package:maura_bastion_system/data/models/events/chart_tier.dart';
import 'package:maura_bastion_system/data/models/npcs/defender.dart';

Facility _facility(
  String id, {
  Rank rank = Rank.D,
  int constructed = 0,
  int total = 0,
}) =>
    Facility(
      id: id,
      name: id,
      rank: rank,
      description: '',
      constructedTurns: constructed,
      constructionTurns: total,
    );

Bastion _bastion({
  List<Facility> facilities = const [],
  List<Defender> defenders = const [],
}) =>
    Bastion(
      id: 'b1',
      name: 'B',
      description: '',
      facilities: facilities,
      defenders: defenders,
    );

List<Facility> _completedFacilities(int count) =>
    List.generate(count, (i) => _facility('f$i'));

void main() {
  group('eligibility', () {
    test('requires at least 6 earned points', () {
      expect(
        bastionIsAttackEligible(_bastion(facilities: _completedFacilities(5))),
        isFalse,
      );
      expect(
        bastionIsAttackEligible(_bastion(facilities: _completedFacilities(6))),
        isTrue,
      );
    });

    test('operational Humble Exterior blocks attacks', () {
      final bastion = _bastion(facilities: [
        ..._completedFacilities(6),
        _facility('cat_humble_exterior', constructed: 2, total: 2),
      ]);
      expect(bastionIsAttackEligible(bastion), isFalse);
    });

    test('under-construction Humble Exterior does not block', () {
      final bastion = _bastion(facilities: [
        ..._completedFacilities(6),
        _facility('cat_humble_exterior', constructed: 1, total: 2),
      ]);
      expect(bastionIsAttackEligible(bastion), isTrue);
    });
  });

  group('shouldRollBastionAttack', () {
    test('chance 1 always fires for an eligible bastion', () {
      final bastion = _bastion(facilities: _completedFacilities(6));
      for (var i = 0; i < 10; i++) {
        expect(
          shouldRollBastionAttack(bastion, rng: Random(i), chance: 1.0),
          isTrue,
        );
      }
    });

    test('chance 0 never fires', () {
      final bastion = _bastion(facilities: _completedFacilities(6));
      for (var i = 0; i < 10; i++) {
        expect(
          shouldRollBastionAttack(bastion, rng: Random(i), chance: 0.0),
          isFalse,
        );
      }
    });

    test('never fires when ineligible even at chance 1', () {
      expect(
        shouldRollBastionAttack(_bastion(), rng: Random(1), chance: 1.0),
        isFalse,
      );
    });
  });

  group('defense config', () {
    test('defaults to threshold 4, no advantage, d6', () {
      final config = bastionDefenseConfig(_bastion());
      expect(config.deathThreshold, 4);
      expect(config.advantage, isFalse);
      expect(config.bastionDefenderDice.faces, 6);
    });

    test('Armory at C reduces threshold by 1', () {
      final config = bastionDefenseConfig(
        _bastion(facilities: [_facility('cat_armory', rank: Rank.C)]),
      );
      expect(config.deathThreshold, 3);
    });

    test('Armory at A reduces threshold by 2', () {
      final config = bastionDefenseConfig(
        _bastion(facilities: [_facility('cat_armory', rank: Rank.A)]),
      );
      expect(config.deathThreshold, 2);
    });

    test('Battlements at B reduces threshold by 1', () {
      final config = bastionDefenseConfig(
        _bastion(facilities: [_facility('cat_battlements', rank: Rank.B)]),
      );
      expect(config.deathThreshold, 3);
    });

    test('Battlements at S reduces threshold by 2', () {
      final config = bastionDefenseConfig(
        _bastion(facilities: [_facility('cat_battlements', rank: Rank.S)]),
      );
      expect(config.deathThreshold, 2);
    });

    test('stacked reductions floor at 1', () {
      final config = bastionDefenseConfig(_bastion(facilities: [
        _facility('cat_armory', rank: Rank.S),
        _facility('cat_battlements', rank: Rank.S),
      ]));
      expect(config.deathThreshold, 1);
    });

    test('Armory and Battlements upgrade bastion defender dice to d8', () {
      final config = bastionDefenseConfig(_bastion(facilities: [
        _facility('cat_armory', rank: Rank.C),
        _facility('cat_battlements', rank: Rank.D),
      ]));
      expect(config.bastionDefenderDice.faces, 8);
    });

    test('War Room grants advantage', () {
      final config = bastionDefenseConfig(
        _bastion(facilities: [_facility('cat_war_room', rank: Rank.B)]),
      );
      expect(config.advantage, isTrue);
    });

    test('under-construction facilities do not count', () {
      final config = bastionDefenseConfig(
        _bastion(facilities: [
          _facility('cat_armory', rank: Rank.C, constructed: 1, total: 2),
        ]),
      );
      expect(config.deathThreshold, 4);
    });
  });

  group('defenderDiceFor', () {
    final config = bastionDefenseConfig(_bastion());

    test('knight d12, beast d10, bastion defender d6', () {
      expect(defenderDiceFor(DefenderType.knight, config).faces, 12);
      expect(defenderDiceFor(DefenderType.beast, config).faces, 10);
      expect(defenderDiceFor(DefenderType.bastionDefender, config).faces, 6);
    });
  });

  group('rollEnemyCount', () {
    test('is the 1d4 base times the tier multiplier', () {
      for (var i = 0; i < 50; i++) {
        final count = rollEnemyCount(ChartTier.skilled, Random(i));
        expect(count, inInclusiveRange(2, 8));
        expect(count % 2, 0);
      }
      expect(
        rollEnemyCount(ChartTier.legend, Random(3)),
        inInclusiveRange(4, 16),
      );
    });
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/data/models/events/bastion_attack_test.dart`
Expected: FAIL — `bastion_attack.dart` / symbols not defined.

- [ ] **Step 3: Write the minimal implementation**

Create `lib/data/models/events/bastion_attack.dart`:

```dart
import 'dart:math';

import 'package:maura_bastion_system/data/enums/defender_type.dart';
import 'package:maura_bastion_system/data/enums/rank.dart';
import 'package:maura_bastion_system/data/models/bastion/bastion.dart';
import 'package:maura_bastion_system/data/models/bastion/facility.dart';
import 'package:maura_bastion_system/data/models/events/chart_points.dart';
import 'package:maura_bastion_system/data/models/events/chart_tier.dart';
import 'package:maura_bastion_system/data/models/events/dispatch.dart';

const double defaultAttackChance = 0.25;
const int attackMinEarnedPoints = 6;
const int _defaultDeathThreshold = 4;

class BastionEnemy {
  final String id;
  final String name;
  final String description;
  final ChartTier tier;

  const BastionEnemy({
    required this.id,
    required this.name,
    required this.description,
    required this.tier,
  });
}

int enemyMultiplier(ChartTier tier) {
  switch (tier) {
    case ChartTier.basic:
      return 1;
    case ChartTier.skilled:
      return 2;
    case ChartTier.master:
      return 3;
    case ChartTier.legend:
      return 4;
  }
}

int rollEnemyCount(ChartTier tier, Random rng) =>
    (rng.nextInt(4) + 1) * enemyMultiplier(tier);

bool _isOperational(Facility facility, String catalogId) =>
    facility.id == catalogId &&
    facility.constructedTurns >= facility.constructionTurns;

bool _hasOperationalHumbleExterior(Bastion bastion) =>
    bastion.facilities.any((f) => _isOperational(f, 'cat_humble_exterior'));

bool bastionIsAttackEligible(Bastion bastion) =>
    ChartPoints.earnedPointsFor(bastion) >= attackMinEarnedPoints &&
    !_hasOperationalHumbleExterior(bastion);

bool shouldRollBastionAttack(
  Bastion bastion, {
  Random? rng,
  double chance = defaultAttackChance,
}) {
  if (!bastionIsAttackEligible(bastion)) return false;
  final random = rng ?? Random();
  return random.nextDouble() < chance;
}

class BastionDefenseConfig {
  final int deathThreshold;
  final bool advantage;
  final UnitDice bastionDefenderDice;

  const BastionDefenseConfig({
    required this.deathThreshold,
    required this.advantage,
    required this.bastionDefenderDice,
  });
}

const List<Rank> _ranksFromD = [Rank.D, Rank.C, Rank.B, Rank.A, Rank.S];

int _stepsAboveD(Rank rank) {
  final index = _ranksFromD.indexOf(rank);
  return index < 0 ? 0 : index;
}

BastionDefenseConfig bastionDefenseConfig(Bastion bastion) {
  final armory = bastion.facilities
      .where((f) => _isOperational(f, 'cat_armory'))
      .toList();
  final battlements = bastion.facilities
      .where((f) => _isOperational(f, 'cat_battlements'))
      .toList();

  var threshold = _defaultDeathThreshold;
  if (armory.isNotEmpty) {
    threshold -= armory.first.rank.index <= Rank.A.index ? 2 : 1;
  }
  for (final b in battlements) {
    threshold -= _stepsAboveD(b.rank) ~/ 2;
  }
  if (threshold < 1) threshold = 1;

  final hasWarRoom =
      bastion.facilities.any((f) => _isOperational(f, 'cat_war_room'));
  final dice = armory.isNotEmpty && battlements.isNotEmpty
      ? const UnitDice(1, 8)
      : const UnitDice(1, 6);

  return BastionDefenseConfig(
    deathThreshold: threshold,
    advantage: hasWarRoom,
    bastionDefenderDice: dice,
  );
}

UnitDice defenderDiceFor(DefenderType type, BastionDefenseConfig config) {
  switch (type) {
    case DefenderType.knight:
      return defaultDiceFor(DispatchUnitType.knight);
    case DefenderType.beast:
      return defaultDiceFor(DispatchUnitType.beast);
    case DefenderType.bastionDefender:
      return config.bastionDefenderDice;
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/data/models/events/bastion_attack_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/data/models/events/bastion_attack.dart test/data/models/events/bastion_attack_test.dart
git commit -m "feat: add bastion attack gate and defense config"
```

---

### Task 2: Combat resolution and loot

**Files:**
- Modify: `lib/data/models/events/bastion_attack.dart`
- Modify: `test/data/models/events/bastion_attack_test.dart`

**Interfaces:**
- Consumes: `BastionEnemy`, `BastionDefenseConfig`, `enemyMultiplier`, `defenderDiceFor`, `defaultDiceFor`, `UnitDice`, `rollMaterialRewards`, `TurnReward`, `RewardKind`, `RewardCategory`.
- Produces:
  - `class DefenderRoll { String defenderId; String defenderName; List<int> rolls; bool died; int best; }`
  - `class CombatRound { int enemiesAtStart; List<DefenderRoll> rolls; int enemiesKilled; int defendersLost; }`
  - `class BastionCombatResult { BastionEnemy enemy; ChartTier tier; int startingEnemies; List<CombatRound> rounds; List<Defender> survivors; List<Defender> dead; bool won; int deathThreshold; bool advantage; }`
  - `BastionCombatResult resolveBastionCombat({required List<Defender> defenders, required BastionEnemy enemy, required int enemyCount, required BastionDefenseConfig config, Random? rng})`
  - `TurnReward rollCombatLoot(BastionEnemy enemy, {Random? rng})`

- [ ] **Step 1: Write the failing tests**

Append these imports to the top of `test/data/models/events/bastion_attack_test.dart`:

```dart
import 'package:maura_bastion_system/data/models/events/dispatch.dart';
import 'package:maura_bastion_system/data/models/events/reward_spec.dart';
```

Append these groups before the final closing brace of `void main()`:

```dart
  group('resolveBastionCombat', () {
    Defender defender(String id) => Defender(
          id: id,
          name: id,
          type: DefenderType.bastionDefender,
          bastionId: 'b1',
        );

    const enemy = BastionEnemy(
      id: 'e',
      name: 'Enemy',
      description: 'd',
      tier: ChartTier.basic,
    );

    test('auto-loses with no defenders and no rounds', () {
      final result = resolveBastionCombat(
        defenders: const [],
        enemy: enemy,
        enemyCount: 3,
        config: bastionDefenseConfig(_bastion()),
        rng: Random(1),
      );
      expect(result.won, isFalse);
      expect(result.rounds, isEmpty);
      expect(result.dead, isEmpty);
    });

    test('pyrrhic win when the last defender dies killing the last enemy', () {
      const config = BastionDefenseConfig(
        deathThreshold: 7,
        advantage: false,
        bastionDefenderDice: UnitDice(1, 6),
      );
      final result = resolveBastionCombat(
        defenders: [defender('d1')],
        enemy: enemy,
        enemyCount: 1,
        config: config,
        rng: Random(1),
      );
      expect(result.won, isTrue);
      expect(result.dead, hasLength(1));
      expect(result.survivors, isEmpty);
    });

    test('invincible defenders clear a larger force over multiple rounds', () {
      const config = BastionDefenseConfig(
        deathThreshold: 1,
        advantage: false,
        bastionDefenderDice: UnitDice(1, 6),
      );
      final result = resolveBastionCombat(
        defenders: [defender('d1')],
        enemy: enemy,
        enemyCount: 3,
        config: config,
        rng: Random(2),
      );
      expect(result.won, isTrue);
      expect(result.rounds, hasLength(3));
      expect(result.dead, isEmpty);
    });

    test('advantage rolls two dice per defender', () {
      const config = BastionDefenseConfig(
        deathThreshold: 1,
        advantage: true,
        bastionDefenderDice: UnitDice(1, 6),
      );
      final result = resolveBastionCombat(
        defenders: [defender('d1')],
        enemy: enemy,
        enemyCount: 1,
        config: config,
        rng: Random(1),
      );
      expect(result.rounds.single.rolls.single.rolls, hasLength(2));
    });

    test('records the config on the result', () {
      final config = bastionDefenseConfig(
        _bastion(facilities: [_facility('cat_war_room', rank: Rank.B)]),
      );
      final result = resolveBastionCombat(
        defenders: [defender('d1')],
        enemy: enemy,
        enemyCount: 0,
        config: config,
        rng: Random(1),
      );
      expect(result.deathThreshold, config.deathThreshold);
      expect(result.advantage, isTrue);
    });
  });

  group('rollCombatLoot', () {
    test('returns a single material grant', () {
      const enemy = BastionEnemy(
        id: 'e',
        name: 'Enemy',
        description: 'd',
        tier: ChartTier.skilled,
      );
      final loot = rollCombatLoot(enemy, rng: Random(1));
      expect(loot.materials, hasLength(1));
      expect(loot.recruit, RewardKind.none);
      expect(loot.materials.single.units, greaterThan(0));
    });
  });
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/data/models/events/bastion_attack_test.dart`
Expected: FAIL — `resolveBastionCombat` / `rollCombatLoot` not defined.

- [ ] **Step 3: Write the minimal implementation**

Append to `lib/data/models/events/bastion_attack.dart`. Add these imports at the top:

```dart
import 'package:maura_bastion_system/data/models/events/reward_spec.dart';
import 'package:maura_bastion_system/data/models/npcs/defender.dart';
import 'package:maura_bastion_system/data/models/rewards/reward.dart';
```

Append these definitions:

```dart
class DefenderRoll {
  final String defenderId;
  final String defenderName;
  final List<int> rolls;
  final bool died;

  const DefenderRoll({
    required this.defenderId,
    required this.defenderName,
    required this.rolls,
    required this.died,
  });

  int get best => rolls.reduce(max);
}

class CombatRound {
  final int enemiesAtStart;
  final List<DefenderRoll> rolls;
  final int enemiesKilled;
  final int defendersLost;

  const CombatRound({
    required this.enemiesAtStart,
    required this.rolls,
    required this.enemiesKilled,
    required this.defendersLost,
  });
}

class BastionCombatResult {
  final BastionEnemy enemy;
  final ChartTier tier;
  final int startingEnemies;
  final List<CombatRound> rounds;
  final List<Defender> survivors;
  final List<Defender> dead;
  final bool won;
  final int deathThreshold;
  final bool advantage;

  const BastionCombatResult({
    required this.enemy,
    required this.tier,
    required this.startingEnemies,
    required this.rounds,
    required this.survivors,
    required this.dead,
    required this.won,
    required this.deathThreshold,
    required this.advantage,
  });
}

BastionCombatResult resolveBastionCombat({
  required List<Defender> defenders,
  required BastionEnemy enemy,
  required int enemyCount,
  required BastionDefenseConfig config,
  Random? rng,
}) {
  final random = rng ?? Random();
  final alive = List<Defender>.from(defenders);
  final dead = <Defender>[];
  final rounds = <CombatRound>[];
  var remaining = enemyCount;

  while (remaining > 0 && alive.isNotEmpty) {
    final enemiesAtStart = remaining;
    final fighting = min(alive.length, remaining);
    final rolls = <DefenderRoll>[];
    final lost = <Defender>[];

    for (var i = 0; i < fighting; i++) {
      final defender = alive[i];
      final dice = defenderDiceFor(defender.type, config);
      final values = List.generate(
        config.advantage ? 2 : 1,
        (_) => dice.roll(random),
      );
      final died = values.reduce(max) < config.deathThreshold;
      rolls.add(DefenderRoll(
        defenderId: defender.id,
        defenderName: defender.name ?? 'Defender',
        rolls: values,
        died: died,
      ));
      if (died) lost.add(defender);
    }

    remaining -= fighting;
    for (final defender in lost) {
      alive.removeWhere((d) => d.id == defender.id);
      dead.add(defender);
    }

    rounds.add(CombatRound(
      enemiesAtStart: enemiesAtStart,
      rolls: rolls,
      enemiesKilled: fighting,
      defendersLost: lost.length,
    ));
  }

  return BastionCombatResult(
    enemy: enemy,
    tier: enemy.tier,
    startingEnemies: enemyCount,
    rounds: rounds,
    survivors: alive,
    dead: dead,
    won: remaining <= 0,
    deathThreshold: config.deathThreshold,
    advantage: config.advantage,
  );
}

TurnReward rollCombatLoot(BastionEnemy enemy, {Random? rng}) {
  final grants = rollMaterialRewards(
    categories: const [RewardCategory.creaturePart, RewardCategory.metal],
    picks: 1,
    cap: enemy.tier.rewardRankCap,
    unitDice: const UnitDice(1, 4),
    rng: rng,
  );
  return TurnReward(
    materials: grants,
    recruit: RewardKind.none,
    note: 'The ${enemy.name} are broken; the field yields spoils.',
  );
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/data/models/events/bastion_attack_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/data/models/events/bastion_attack.dart test/data/models/events/bastion_attack_test.dart
git commit -m "feat: add bastion combat resolution and loot"
```

---

### Task 3: Tiered enemy catalog

**Files:**
- Create: `lib/data/default_data/events/enemy_catalog.dart`
- Test: `test/data/default_data/events/enemy_catalog_test.dart`

**Interfaces:**
- Consumes: `BastionEnemy`, `ChartTier`.
- Produces:
  - `List<BastionEnemy> getEnemyCatalog()`
  - `BastionEnemy randomEnemyForTier(ChartTier tier, {Random? rng})`

- [ ] **Step 1: Write the failing tests**

Create `test/data/default_data/events/enemy_catalog_test.dart`:

```dart
// test/data/default_data/events/enemy_catalog_test.dart
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:maura_bastion_system/data/default_data/events/enemy_catalog.dart';
import 'package:maura_bastion_system/data/models/events/chart_tier.dart';

void main() {
  test('every tier has at least one enemy', () {
    final catalog = getEnemyCatalog();
    for (final tier in ChartTier.values) {
      expect(
        catalog.where((e) => e.tier == tier),
        isNotEmpty,
        reason: '$tier',
      );
    }
  });

  test('randomEnemyForTier returns an enemy of the requested tier', () {
    for (final tier in ChartTier.values) {
      for (var i = 0; i < 20; i++) {
        expect(randomEnemyForTier(tier, rng: Random(i)).tier, tier);
      }
    }
  });

  test('enemy ids are unique', () {
    final ids = getEnemyCatalog().map((e) => e.id).toList();
    expect(ids.toSet().length, ids.length);
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/data/default_data/events/enemy_catalog_test.dart`
Expected: FAIL — `enemy_catalog.dart` not found.

- [ ] **Step 3: Write the minimal implementation**

Create `lib/data/default_data/events/enemy_catalog.dart`:

```dart
// lib/data/default_data/events/enemy_catalog.dart
import 'dart:math';

import 'package:maura_bastion_system/data/models/events/bastion_attack.dart';
import 'package:maura_bastion_system/data/models/events/chart_tier.dart';

List<BastionEnemy> getEnemyCatalog() {
  return const [
    BastionEnemy(
      id: 'enm_bandit_cutthroats',
      name: 'Bandit Cutthroats',
      tier: ChartTier.basic,
      description:
          'A ragged band of road bandits, more knife than soldier, testing the fences for a weakness.',
    ),
    BastionEnemy(
      id: 'enm_starving_wolf_pack',
      name: 'Starving Wolf Pack',
      tier: ChartTier.basic,
      description:
          'Lean wolves driven by a hard winter to press against the bastion walls.',
    ),
    BastionEnemy(
      id: 'enm_cult_of_the_ember',
      name: 'Cult of the Ember',
      tier: ChartTier.skilled,
      description:
          'Hooded zealots who chant as they burn their way toward the gate.',
    ),
    BastionEnemy(
      id: 'enm_marsh_reavers',
      name: 'Marsh Reavers',
      tier: ChartTier.skilled,
      description:
          'Mud-caked raiders out of the fens, patient and well armed.',
    ),
    BastionEnemy(
      id: 'enm_feral_manticore',
      name: 'Feral Manticore',
      tier: ChartTier.master,
      description:
          'A wounded manticore and its brood, hunting the smell of meat.',
    ),
    BastionEnemy(
      id: 'enm_ashbound_warpriests',
      name: 'Ashbound Warpriests',
      tier: ChartTier.master,
      description:
          'Armored priests of a burned god, marching behind a wall of shields.',
    ),
    BastionEnemy(
      id: 'enm_the_warlords_horde',
      name: "The Warlord's Horde",
      tier: ChartTier.legend,
      description:
          'A disciplined war-band with siege ladders and no intention of turning back.',
    ),
    BastionEnemy(
      id: 'enm_the_tyrant_beast',
      name: 'The Tyrant Beast',
      tier: ChartTier.legend,
      description:
          'A titanic monster that has broken stronger walls than these.',
    ),
  ];
}

BastionEnemy randomEnemyForTier(ChartTier tier, {Random? rng}) {
  final random = rng ?? Random();
  final pool = getEnemyCatalog().where((e) => e.tier == tier).toList();
  if (pool.isEmpty) return getEnemyCatalog().first;
  return pool[random.nextInt(pool.length)];
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/data/default_data/events/enemy_catalog_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/data/default_data/events/enemy_catalog.dart test/data/default_data/events/enemy_catalog_test.dart
git commit -m "feat: add tiered enemy catalog"
```

---

### Task 4: BastionAttackDialog

**Files:**
- Create: `lib/features/bastions_page/presentation/widgets/bastion_attack_dialog.dart`
- Test: `test/features/bastions_page/presentation/widgets/bastion_attack_dialog_test.dart`

**Interfaces:**
- Consumes: `BastionEnemy`, `BastionCombatResult`, `TurnReward`, `MedievalColors`, `ParchmentBorderPainter`, `FadeSlide`, `StampIn`, `SfxClip`, `resolveBastionCombat`, `BastionDefenseConfig`, `UnitDice`.
- Produces:
  - `class BastionAttackDialog extends StatelessWidget`
  - `static Future<void> BastionAttackDialog.show(BuildContext context, {required BastionEnemy enemy, required int enemyCount, required BastionCombatResult result, TurnReward? loot, String? destroyedFacilityName})`

- [ ] **Step 1: Write the failing tests**

Create `test/features/bastions_page/presentation/widgets/bastion_attack_dialog_test.dart`:

```dart
// test/features/bastions_page/presentation/widgets/bastion_attack_dialog_test.dart
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maura_bastion_system/data/enums/defender_type.dart';
import 'package:maura_bastion_system/data/models/events/bastion_attack.dart';
import 'package:maura_bastion_system/data/models/events/chart_tier.dart';
import 'package:maura_bastion_system/data/models/events/dispatch.dart';
import 'package:maura_bastion_system/data/models/npcs/defender.dart';
import 'package:maura_bastion_system/features/bastions_page/presentation/widgets/bastion_attack_dialog.dart';

const _enemy = BastionEnemy(
  id: 'e',
  name: 'Bandit Cutthroats',
  description: 'Ragged knife-men.',
  tier: ChartTier.basic,
);

BastionCombatResult _winResult() => resolveBastionCombat(
      defenders: [
        Defender(
          id: 'd1',
          name: 'Aldric',
          type: DefenderType.knight,
          bastionId: 'b1',
        ),
      ],
      enemy: _enemy,
      enemyCount: 1,
      config: const BastionDefenseConfig(
        deathThreshold: 1,
        advantage: false,
        bastionDefenderDice: UnitDice(1, 6),
      ),
      rng: Random(1),
    );

Widget _harness(BastionCombatResult result, {String? destroyed}) => MaterialApp(
      home: Scaffold(
        body: BastionAttackDialog(
          enemy: _enemy,
          enemyCount: 1,
          result: result,
          destroyedFacilityName: destroyed,
        ),
      ),
    );

void main() {
  testWidgets('shows the enemy, roster rolls and the repelled verdict',
      (tester) async {
    await tester.pumpWidget(_harness(_winResult()));
    await tester.pumpAndSettle();

    expect(find.text('Bastion Attacked'), findsOneWidget);
    expect(find.textContaining('Bandit Cutthroats'), findsOneWidget);
    expect(find.textContaining('Aldric'), findsOneWidget);
    expect(find.text('ATTACK REPELLED'), findsOneWidget);
  });

  testWidgets('a loss shows the destroyed facility', (tester) async {
    final result = resolveBastionCombat(
      defenders: const [],
      enemy: _enemy,
      enemyCount: 2,
      config: const BastionDefenseConfig(
        deathThreshold: 4,
        advantage: false,
        bastionDefenderDice: UnitDice(1, 6),
      ),
      rng: Random(1),
    );
    await tester.pumpWidget(_harness(result, destroyed: 'Kitchen'));
    await tester.pumpAndSettle();

    expect(find.text('BASTION FALLEN'), findsOneWidget);
    expect(find.textContaining('Kitchen'), findsOneWidget);
  });

  testWidgets('Done pops the dialog', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () => BastionAttackDialog.show(
                context,
                enemy: _enemy,
                enemyCount: 1,
                result: _winResult(),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Bastion Attacked'), findsOneWidget);

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.text('Bastion Attacked'), findsNothing);
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/features/bastions_page/presentation/widgets/bastion_attack_dialog_test.dart`
Expected: FAIL — `bastion_attack_dialog.dart` not found.

- [ ] **Step 3: Write the minimal implementation**

Create `lib/features/bastions_page/presentation/widgets/bastion_attack_dialog.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:maura_bastion_system/core/juice/juice_sfx.dart';
import 'package:maura_bastion_system/core/juice/reveal_widgets.dart';
import 'package:maura_bastion_system/core/themes/theme_colors.dart';
import 'package:maura_bastion_system/data/models/events/bastion_attack.dart';
import 'package:maura_bastion_system/data/models/events/reward_spec.dart';
import 'package:maura_bastion_system/features/news_paper/presentation/widgets/parchment_border.dart';

class BastionAttackDialog extends StatelessWidget {
  final BastionEnemy enemy;
  final int enemyCount;
  final BastionCombatResult result;
  final TurnReward? loot;
  final String? destroyedFacilityName;

  const BastionAttackDialog({
    super.key,
    required this.enemy,
    required this.enemyCount,
    required this.result,
    this.loot,
    this.destroyedFacilityName,
  });

  static Future<void> show(
    BuildContext context, {
    required BastionEnemy enemy,
    required int enemyCount,
    required BastionCombatResult result,
    TurnReward? loot,
    String? destroyedFacilityName,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: BastionAttackDialog(
          enemy: enemy,
          enemyCount: enemyCount,
          result: result,
          loot: loot,
          destroyedFacilityName: destroyedFacilityName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: 480,
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        gradient: const RadialGradient(
          center: Alignment.center,
          radius: 0.9,
          colors: [MedievalColors.parchmentLight, MedievalColors.parchmentDark],
          stops: [0.6, 1.0],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(50),
            blurRadius: 6,
            offset: const Offset(2, 3),
          ),
        ],
      ),
      child: CustomPaint(
        painter: ParchmentBorderPainter(),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Bastion Attacked',
                textAlign: TextAlign.center,
                style: GoogleFonts.cinzel(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: MedievalColors.vermillion,
                ),
              ),
              const SizedBox(height: 8),
              Flexible(child: SingleChildScrollView(child: _buildBody())),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Done'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '$enemyCount \u00d7 ${enemy.name}',
          style: GoogleFonts.cinzel(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: MedievalColors.vermillion,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          enemy.description,
          style: GoogleFonts.imFellEnglish(
            fontSize: 15,
            height: 1.4,
            color: MedievalColors.sepiaInk,
          ),
        ),
        const SizedBox(height: 8),
        if (result.rounds.isEmpty)
          _line('No defenders stand ready. The gates are thrown open.')
        else
          for (var i = 0; i < result.rounds.length; i++) ...[
            FadeSlide(
              delay: Duration(milliseconds: 200 * i),
              child: Text(
                'Round ${i + 1}',
                style: GoogleFonts.imFellEnglish(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: MedievalColors.sepiaSecondary,
                ),
              ),
            ),
            for (final roll in result.rounds[i].rolls)
              _line(
                '${roll.defenderName}: ${roll.rolls.join(', ')}'
                '${roll.died ? ' \u2014 slain' : ''}',
              ),
            const SizedBox(height: 4),
          ],
        Center(
          child: StampIn(
            sfx: SfxClip.stamp,
            haptic: true,
            child: _AttackVerdict(won: result.won),
          ),
        ),
        if (result.won && loot != null) ...[
          const SizedBox(height: 8),
          for (final grant in loot!.materials)
            _line(
              '${grant.units} \u00d7 ${grant.reward.name} '
              '(Rank ${grant.effectiveRank.title})',
            ),
          if (loot!.note != null) _line(loot!.note!),
        ],
        if (!result.won && destroyedFacilityName != null) ...[
          const SizedBox(height: 8),
          _line(
            'The $destroyedFacilityName is destroyed. '
            'Rebuild it to restore its benefits.',
          ),
        ],
      ],
    );
  }

  Widget _line(String text) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          text,
          style: GoogleFonts.imFellEnglish(
            fontSize: 15,
            height: 1.4,
            color: MedievalColors.sepiaInk,
          ),
        ),
      );
}

class _AttackVerdict extends StatelessWidget {
  final bool won;

  const _AttackVerdict({required this.won});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.06,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: won
              ? MedievalColors.vermillionDark
              : MedievalColors.parchmentMuted,
          border: Border.all(
            color: won ? MedievalColors.goldLeaf : MedievalColors.sepiaMuted,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          won ? 'ATTACK REPELLED' : 'BASTION FALLEN',
          style: GoogleFonts.cinzel(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            color: won ? MedievalColors.goldPale : MedievalColors.sepiaInk,
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/features/bastions_page/presentation/widgets/bastion_attack_dialog_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/bastions_page/presentation/widgets/bastion_attack_dialog.dart test/features/bastions_page/presentation/widgets/bastion_attack_dialog_test.dart
git commit -m "feat: add bastion attack dialog"
```

---

### Task 5: Turn integration

**Files:**
- Modify: `lib/features/bastions_page/presentation/bastion_page.dart`
- Modify: `test/features/bastions_page/presentation/bastion_page_test.dart`

**Interfaces:**
- Consumes: `shouldRollBastionAttack`, `bastionDefenseConfig`, `randomEnemyForTier`, `rollEnemyCount`, `resolveBastionCombat`, `rollCombatLoot`, `BastionAttackDialog.show`, `DefendersCubit`, `DefenderApi`, `BastionCubit.removeFacility`, `BastionCubit.advanceBastionTurn`, `BastionTurnResult`, `BastionTurnEventResult`, `BastionTurnAdvancedFacility`, `rewardSummaryText`, `ChartTurnRoll`.
- Produces: `BastionPage.attackChance` (optional, defaults to `defaultAttackChance`), and a private `_takeAttackTurn`.

- [ ] **Step 1: Write the failing integration test**

In `test/features/bastions_page/presentation/bastion_page_test.dart`, add this import near the other `maura_bastion_system` imports:

```dart
import 'package:maura_bastion_system/data/models/events/bastion_attack.dart';
```

Change the `pumpBastionPage` helper to accept an optional chance and pass it through. Replace its signature and the `BastionPage(...)` construction:

```dart
  Future<void> pumpBastionPage(WidgetTester tester,
      {required bool isUserBastion,
      required MockClient mockClient,
      double? attackChance}) async {
```

```dart
          home: BastionPage(
            bastionId: 'bastion_1',
            isUserBastion: isUserBastion,
            attackChance: attackChance ?? defaultAttackChance,
          ),
```

Append this test before the final closing brace of `void main()`:

```dart
  testWidgets(
      'an eligible attack turn opens the attack dialog and destroys a facility on an auto-loss',
      (tester) async {
    final deletes = <http.Request>[];
    final facilities = List.generate(
      6,
      (i) => turnFacilityJson(id: 'f$i', name: 'Facility $i'),
    );
    final mockClient = _withEmptyBrowsePage((request) async {
      if (request.method == 'GET' &&
          request.url.path == '/maura/v1/bastions') {
        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'ok',
            'data': [
              {
                'id': 'bastion_1',
                'userId': 'user_1',
                'name': 'Test Bastion',
                'description': 'A test stronghold.',
                'facilities': facilities,
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      if (request.method == 'DELETE' &&
          request.url.path.startsWith('/maura/v1/facilities/')) {
        deletes.add(request);
        return http.Response(
          jsonEncode({'success': true, 'message': 'ok', 'data': {}}),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      if (request.method == 'POST' &&
          request.url.path.startsWith('/maura/v1/discord/')) {
        return http.Response(
          jsonEncode({'success': true, 'message': 'ok', 'data': {}}),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      return http.Response(
        jsonEncode({'success': false, 'message': 'not found'}),
        404,
        headers: {'content-type': 'application/json'},
      );
    });

    await pumpBastionPage(
      tester,
      isUserBastion: true,
      mockClient: mockClient,
      attackChance: 1.0,
    );

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'quest');
    await tester.pump();
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    expect(find.text('Bastion Attacked'), findsOneWidget);

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(deletes, hasLength(1));
  });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/bastions_page/presentation/bastion_page_test.dart`
Expected: FAIL — `BastionPage` has no `attackChance` parameter.

- [ ] **Step 3: Write the minimal implementation**

In `lib/features/bastions_page/presentation/bastion_page.dart`, add these imports:

```dart
import 'dart:math';

import 'package:maura_bastion_system/api/defender_api.dart';
import 'package:maura_bastion_system/data/default_data/events/enemy_catalog.dart';
import 'package:maura_bastion_system/data/models/events/bastion_attack.dart';
import 'package:maura_bastion_system/data/models/events/chart_event.dart';
import 'package:maura_bastion_system/data/models/events/reward_spec.dart';
import 'package:maura_bastion_system/features/bastions_page/logic/defenders_cubit.dart';
import 'package:maura_bastion_system/features/bastions_page/presentation/widgets/bastion_attack_dialog.dart';
```

Add the field and constructor parameter to `BastionPage`:

```dart
class BastionPage extends StatelessWidget {
  static const double _cardWidth = 200.0;

  final String bastionId;
  final bool isUserBastion;
  final double attackChance;

  const BastionPage({
    super.key,
    required this.bastionId,
    this.isUserBastion = false,
    this.attackChance = defaultAttackChance,
  });
```

In `_takeBastionTurn`, immediately after `final rolledRow = eventRoll?.row;` and before the `// The turn resolves BEFORE the advance` comment, insert the attack branch:

```dart
    final random = Random();
    if (shouldRollBastionAttack(
      bastion,
      rng: random,
      chance: attackChance,
    )) {
      await _takeAttackTurn(context, bastion, cubit, quest, roll, random);
      return;
    }
```

Add the `_takeAttackTurn` method immediately after `_takeBastionTurn` (before `_buildRankedFacilities`):

```dart
  Future<void> _takeAttackTurn(
    BuildContext context,
    Bastion bastion,
    BastionCubit cubit,
    String quest,
    ChartTurnRoll roll,
    Random random,
  ) async {
    final config = bastionDefenseConfig(bastion);
    final enemy = randomEnemyForTier(roll.tier, rng: random);
    final enemyCount = rollEnemyCount(roll.tier, random);
    final result = resolveBastionCombat(
      defenders: bastion.defenders,
      enemy: enemy,
      enemyCount: enemyCount,
      config: config,
      rng: random,
    );
    final loot = result.won ? rollCombatLoot(enemy, rng: random) : null;
    final destroyedFacility = !result.won && bastion.facilities.isNotEmpty
        ? bastion.facilities[random.nextInt(bastion.facilities.length)]
        : null;

    if (!context.mounted) return;
    await BastionAttackDialog.show(
      context,
      enemy: enemy,
      enemyCount: enemyCount,
      result: result,
      loot: loot,
      destroyedFacilityName: destroyedFacility?.name,
    );
    if (!context.mounted) return;

    if (result.dead.isNotEmpty) {
      final defendersCubit = DefendersCubit(
        bastionId: bastion.id,
        defenderApi: GetIt.I<DefenderApi>(),
        discordAnnouncer: GetIt.I.isRegistered<DiscordAnnouncer>()
            ? GetIt.I<DiscordAnnouncer>()
            : null,
        bastionName: bastion.name,
      );
      await defendersCubit.loadDefenders();
      for (final defender in result.dead) {
        await defendersCubit.removeDefender(defender.id);
      }
      await defendersCubit.close();
    }

    if (destroyedFacility != null) {
      await cubit.removeFacility(bastion.id, destroyedFacility);
    }

    final rewardSummary = result.won
        ? (loot == null ? 'The attack is repelled.' : rewardSummaryText(loot))
        : destroyedFacility == null
            ? 'The bastion is overrun.'
            : 'The ${destroyedFacility.name} is destroyed.';
    final eventResult = BastionTurnEventResult(
      name: enemy.name,
      description: '${enemy.description}\n\n'
          '$enemyCount attackers against ${bastion.defenders.length} defenders.',
      rewardSummary: rewardSummary,
    );

    final hadTarget = bastion.facilities.any(
      (f) => f.constructedTurns < f.constructionTurns,
    );
    BastionTurnResult? loggedResult;
    final advanced = await cubit.advanceBastionTurn(
      bastion.id,
      gate: (advancedFacility) async {
        final log = BastionTurnResult(
          bastionId: bastion.id,
          bastionName: bastion.name,
          quest: quest,
          advancedFacility: advancedFacility == null
              ? null
              : BastionTurnAdvancedFacility(
                  name: advancedFacility.name,
                  rankTitle: advancedFacility.rank.title,
                  constructedTurns: advancedFacility.constructedTurns,
                  constructionTurns: advancedFacility.constructionTurns,
                ),
          event: eventResult,
        );
        await GetIt.I<DiscordApi>().sendIndividualBastionTurn(log);
        loggedResult = log;
      },
    );
    if (!context.mounted) return;
    if (loggedResult == null || (advanced == null && hadTarget)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Turn could not be advanced')),
      );
      return;
    }
    await BastionTurnDialog.show(
      context,
      advancedFacility: hadTarget ? advanced : null,
      event: ChartEvent(
        id: enemy.id,
        name: enemy.name,
        chart: null,
        tier: roll.tier,
        description: enemy.description,
        reward: const RewardSpec(),
      ),
      result: loggedResult,
    );
  }
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/features/bastions_page/presentation/bastion_page_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/bastions_page/presentation/bastion_page.dart test/features/bastions_page/presentation/bastion_page_test.dart
git commit -m "feat: route eligible bastion turns into attacks"
```

---

### Task 6: Full verification

**Files:**
- No source changes.

- [ ] **Step 1: Run the analyzer**

Run: `flutter analyze`
Expected: no new warnings or errors.

- [ ] **Step 2: Run the full test suite**

Run: `flutter test`
Expected: PASS (all existing tests plus the new ones).

- [ ] **Step 3: Commit any analyzer-driven fixes**

If `flutter analyze` or the suite surfaced issues, fix them and commit:

```bash
git add -A
git commit -m "fix: address analyzer findings for bastion attacks"
```

If there were no issues, skip this commit.
