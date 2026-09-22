import 'dart:math';

import 'package:maura_bastion_system/data/default_data/rewards/default_reward_data.dart';
import 'package:maura_bastion_system/data/enums/rank.dart';
import 'package:maura_bastion_system/data/models/events/dispatch.dart';
import 'package:maura_bastion_system/data/models/rewards/reward.dart';

enum RewardKind { material, recruitDefender, recruitHireling, none }

class RewardSpec {
  final RewardKind kind;
  final List<RewardCategory> categories;
  final int picks;
  final UnitDice unitDice;
  final String? note;

  /// Shown on failed dispatch; falls back to [note].
  final String? failureNote;

  const RewardSpec({
    this.kind = RewardKind.none,
    this.categories = const [],
    this.picks = 1,
    this.unitDice = const UnitDice(1, 2),
    this.note,
    this.failureNote,
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
  final RewardKind recruit;
  final String? note;

  const TurnReward({
    required this.materials,
    required this.recruit,
    this.note,
  });

  static const TurnReward empty =
      TurnReward(materials: [], recruit: RewardKind.none);
}

List<RewardGrant> rollMaterialRewards({
  required List<RewardCategory> categories,
  required int picks,
  required Rank cap,
  required UnitDice unitDice,
  Random? rng,
}) {
  final random = rng ?? Random();
  final pool = categories.toSet().toList()..shuffle(random);
  final chosen = pool.take(picks.clamp(0, pool.length)).toList();
  if (chosen.isEmpty) {
    throw ArgumentError('No categories offered for material rewards');
  }
  final grants = <RewardGrant>[];
  for (final category in chosen) {
    final candidates = getDefaultRewards()
        .where((r) => r.category == category && withinRewardCap(r.rank, cap))
        .toList();
    if (candidates.isEmpty) {
      throw ArgumentError('No rewards within cap for $category');
    }
    final reward = candidates[random.nextInt(candidates.length)];
    grants.add(RewardGrant(
      reward: reward,
      effectiveRank: reward.rank ?? cap,
      units: unitDice.roll(random),
    ));
  }
  return grants;
}
