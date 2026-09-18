import 'dart:convert';

import 'package:maura_bastion_system/data/default_data/rewards/default_reward_data.dart';
import 'package:maura_bastion_system/data/enums/rank.dart';
import 'package:maura_bastion_system/data/models/events/reward_spec.dart';
import 'package:maura_bastion_system/data/models/rewards/bastion_inventory.dart';
import 'package:maura_bastion_system/data/models/rewards/reward.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BastionInventoryStore {
  static const _prefix = 'bastion_inventory_';

  Future<void> save(String bastionId, BastionInventory inventory) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode({
      'entries': [
        for (final entry in inventory.entries.values)
          {
            'rewardId': entry.reward.id,
            'effectiveRank': entry.effectiveRank.name,
            'units': entry.units,
          },
      ],
    });
    await prefs.setString('$_prefix$bastionId', json);
  }

  Future<List<RewardGrant>> read(String bastionId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_prefix$bastionId');
    if (raw == null) return const [];
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final entries = decoded['entries'] as List? ?? [];
    final catalog = getDefaultRewards();
    final grants = <RewardGrant>[];
    for (final e in entries) {
      final map = e as Map<String, dynamic>;
      final rewardId = map['rewardId'] as String;
      Reward? reward;
      for (final r in catalog) {
        if (r.id == rewardId) {
          reward = r;
          break;
        }
      }
      if (reward == null) continue;
      grants.add(RewardGrant(
        reward: reward,
        effectiveRank:
            Rank.fromString((map['effectiveRank'] as String).toLowerCase()),
        units: (map['units'] as num).toInt(),
      ));
    }
    return grants;
  }
}
