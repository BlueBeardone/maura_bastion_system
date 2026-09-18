import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:maura_bastion_system/data/enums/rank.dart';
import 'package:maura_bastion_system/data/models/events/dispatch.dart';
import 'package:maura_bastion_system/data/models/events/reward_spec.dart';
import 'package:maura_bastion_system/data/models/rewards/reward.dart';

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

    test('throws when no categories are offered', () {
      expect(
        () => rollMaterialRewards(
          categories: [],
          picks: 1,
          cap: Rank.E,
          unitDice: const UnitDice(1, 2),
          rng: Random(1),
        ),
        throwsArgumentError,
      );
    });
  });
}
