import 'package:flutter_test/flutter_test.dart';
import 'package:maura_bastion_system/data/enums/rank.dart';
import 'package:maura_bastion_system/data/models/events/dispatch.dart';
import 'package:maura_bastion_system/data/models/events/reward_spec.dart';

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
}
