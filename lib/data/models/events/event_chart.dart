import 'package:maura_bastion_system/data/models/rewards/reward.dart';

enum EventChart {
  wilds('The Wilds', [
    RewardCategory.creaturePart,
    RewardCategory.meat,
    RewardCategory.blood,
    RewardCategory.herb,
  ]),
  deeps('The Deeps', [RewardCategory.metal, RewardCategory.stone]),
  tradeRoad('The Trade Road', [RewardCategory.weave]),
  warMarch('The War March', [RewardCategory.creaturePart]),
  hearth('The Hearth', []),
  arcane('The Arcane', [RewardCategory.herb, RewardCategory.weave]);

  final String displayName;
  final List<RewardCategory> rewardCategories;

  const EventChart(this.displayName, this.rewardCategories);
}
