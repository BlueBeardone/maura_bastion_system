// test/data/models/events/bastion_attack_test.dart
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:maura_bastion_system/data/enums/defender_type.dart';
import 'package:maura_bastion_system/data/enums/rank.dart';
import 'package:maura_bastion_system/data/models/bastion/bastion.dart';
import 'package:maura_bastion_system/data/models/bastion/facility.dart';
import 'package:maura_bastion_system/data/models/events/bastion_attack.dart';
import 'package:maura_bastion_system/data/models/events/chart_tier.dart';
import 'package:maura_bastion_system/data/models/events/dispatch.dart';
import 'package:maura_bastion_system/data/models/events/reward_spec.dart';
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

class _ScriptedRandom implements Random {
  final List<int> _values;
  int _index = 0;

  _ScriptedRandom(this._values);

  @override
  int nextInt(int max) {
    final value = _values[_index % _values.length];
    _index++;
    return value;
  }

  @override
  double nextDouble() => (nextInt(1000000)) / 1000000;

  @override
  bool nextBool() => nextInt(2) == 0;
}

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

    test('Battlements at A reduces threshold by 1', () {
      final config = bastionDefenseConfig(
        _bastion(facilities: [_facility('cat_battlements', rank: Rank.A)]),
      );
      expect(config.deathThreshold, 3);
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
    test('enemyMultiplier scales by tier', () {
      expect(enemyMultiplier(ChartTier.basic), 1);
      expect(enemyMultiplier(ChartTier.skilled), 2);
      expect(enemyMultiplier(ChartTier.master), 3);
      expect(enemyMultiplier(ChartTier.legend), 4);
    });

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

    test('without advantage a defender rolls a single die', () {
      const config = BastionDefenseConfig(
        deathThreshold: 1,
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
      expect(result.rounds.single.rolls.single.rolls, hasLength(1));
    });

    test('advantage keeps the higher of two rolls', () {
      const config = BastionDefenseConfig(
        deathThreshold: 4,
        advantage: true,
        bastionDefenderDice: UnitDice(1, 6),
      );
      final result = resolveBastionCombat(
        defenders: [defender('d1')],
        enemy: enemy,
        enemyCount: 1,
        config: config,
        rng: _ScriptedRandom([2, 4]),
      );
      expect(result.rounds.single.rolls.single.rolls, [3, 5]);
      expect(result.dead, isEmpty);
      expect(result.won, isTrue);
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
}
