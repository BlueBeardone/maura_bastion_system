import 'dart:math';

import 'package:maura_bastion_system/data/enums/defender_type.dart';
import 'package:maura_bastion_system/data/enums/rank.dart';
import 'package:maura_bastion_system/data/models/bastion/bastion.dart';
import 'package:maura_bastion_system/data/models/bastion/facility.dart';
import 'package:maura_bastion_system/data/models/events/chart_points.dart';
import 'package:maura_bastion_system/data/models/events/chart_tier.dart';
import 'package:maura_bastion_system/data/models/events/dispatch.dart';
import 'package:maura_bastion_system/data/models/events/reward_spec.dart';
import 'package:maura_bastion_system/data/models/npcs/defender.dart';
import 'package:maura_bastion_system/data/models/rewards/reward.dart';

const double defaultAttackChance = 0.10;
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

typedef DefenderLoadout = ({String name, UnitDice dice});

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
  final List<DefenderLoadout> roster;

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
    this.roster = const [],
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
  final roster = [
    for (final defender in defenders)
      (
        name: defender.name ?? 'Defender',
        dice: defenderDiceFor(defender.type, config),
      ),
  ];

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
    roster: roster,
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
