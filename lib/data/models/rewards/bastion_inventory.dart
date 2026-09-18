import 'package:maura_bastion_system/data/enums/rank.dart';
import 'package:maura_bastion_system/data/models/events/reward_spec.dart';
import 'package:maura_bastion_system/data/models/rewards/reward.dart';
import 'package:maura_bastion_system/data/models/rewards/reward_harvest_rules.dart';

int valuePerUnit(Reward reward, Rank effectiveRank) {
  if (reward.marketValue != null) return reward.marketValue!;
  if (reward.category == RewardCategory.meat ||
      reward.category == RewardCategory.blood) {
    return mainChartMeatBloodValueByRank[effectiveRank]!;
  }
  return mainChartValueByRank[effectiveRank]!;
}

class SellOverflowResult {
  final BastionInventory inventory;
  final int goldGained;
  final List<RewardGrant> sold;

  const SellOverflowResult({
    required this.inventory,
    required this.goldGained,
    required this.sold,
  });
}

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

  SellOverflowResult sellDownTo({required double maxWeight}) {
    var inventory = this;
    var gold = 0;
    final sold = <RewardGrant>[];
    while (inventory.totalWeight() > maxWeight) {
      final sellable = inventory.entries.values
          .where((e) => e.units > 0)
          .toList()
        ..sort((a, b) => valuePerUnit(a.reward, a.effectiveRank)
            .compareTo(valuePerUnit(b.reward, b.effectiveRank)));
      if (sellable.isEmpty) break;
      final target = sellable.first;
      final overweight = inventory.totalWeight() - maxWeight;
      final weightPerUnit = target.reward.weightPerUnit;
      final unitsToSell = weightPerUnit <= 0
          ? target.units
          : (overweight / weightPerUnit).ceil().clamp(1, target.units);
      sold.add(RewardGrant(
        reward: target.reward,
        effectiveRank: target.effectiveRank,
        units: unitsToSell,
      ));
      gold += unitsToSell * valuePerUnit(target.reward, target.effectiveRank);
      final key = entryKey(target.reward.id, target.effectiveRank);
      final remainingUnits = target.units - unitsToSell;
      final merged = Map<String, BastionInventoryEntry>.from(inventory.entries);
      if (remainingUnits <= 0) {
        merged.remove(key);
      } else {
        merged[key] = BastionInventoryEntry(
          reward: target.reward,
          effectiveRank: target.effectiveRank,
          units: remainingUnits,
        );
      }
      inventory = BastionInventory(entries: merged);
    }
    return SellOverflowResult(inventory: inventory, goldGained: gold, sold: sold);
  }
}

const double bastionStorageMaxWeight = 500.0;
