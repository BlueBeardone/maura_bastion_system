import 'package:maura_bastion_system/data/enums/rank.dart';
import 'package:maura_bastion_system/data/models/events/dispatch.dart';
import 'package:maura_bastion_system/data/models/rewards/reward.dart';

enum RewardKind { material, gold, recruitDefender, recruitHireling, none }

class RewardSpec {
  final RewardKind kind;
  final List<RewardCategory> categories;
  final int picks;
  final UnitDice unitDice;
  final UnitDice? goldDice;
  final String? note;

  const RewardSpec({
    this.kind = RewardKind.none,
    this.categories = const [],
    this.picks = 1,
    this.unitDice = const UnitDice(1, 2),
    this.goldDice,
    this.note,
  });
}

/// Rank-null materials are harvested at the cap rank; higher-quality ranks
/// (lower index) are out of cap.
bool withinRewardCap(Rank? rewardRank, Rank cap) {
  final effective = rewardRank ?? cap;
  return effective.index >= cap.index;
}

class RewardGrant {
  final Reward reward;
  final Rank effectiveRank;
  final int units;

  const RewardGrant({
    required this.reward,
    required this.effectiveRank,
    required this.units,
  });
}

class TurnReward {
  final List<RewardGrant> materials;
  final int gold;
  final RewardKind recruit;
  final String? note;

  const TurnReward({
    required this.materials,
    required this.gold,
    required this.recruit,
    this.note,
  });

  static const TurnReward empty =
      TurnReward(materials: [], gold: 0, recruit: RewardKind.none);
}
