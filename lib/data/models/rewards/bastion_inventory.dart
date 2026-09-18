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
      0.0,
      (sum, e) => sum + e.reward.weightPerUnit * e.units,
    );
  }
}
