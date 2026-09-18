import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:maura_bastion_system/data/default_data/rewards/default_reward_data.dart';
import 'package:maura_bastion_system/data/enums/rank.dart';
import 'package:maura_bastion_system/data/models/events/reward_spec.dart';
import 'package:maura_bastion_system/data/models/rewards/bastion_inventory.dart';
import 'package:maura_bastion_system/features/bastions_page/data/bastion_inventory_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('save then read round-trips grants (real reward catalog)', () async {
    SharedPreferences.setMockInitialValues({});
    final store = BastionInventoryStore();
    final adamantine =
        getDefaultRewards().firstWhere((r) => r.id == 'rew_adamantine');
    final inventory = const BastionInventory().addGrants([
      RewardGrant(reward: adamantine, effectiveRank: Rank.D, units: 3),
    ]);

    await store.save('b1', inventory);
    final grants = await store.read('b1');

    expect(grants.single.reward.id, 'rew_adamantine');
    expect(grants.single.effectiveRank, Rank.D);
    expect(grants.single.units, 3);
  });

  test('read of an unknown bastion is empty', () async {
    SharedPreferences.setMockInitialValues({});
    final store = BastionInventoryStore();
    expect(await store.read('nope'), isEmpty);
  });

  test('read drops entries with unknown reward ids', () async {
    SharedPreferences.setMockInitialValues({
      'bastion_inventory_b1':
          '{"entries": [{"rewardId": "rew_ghost", "effectiveRank": "D", "units": 2}]}',
    });
    final store = BastionInventoryStore();
    expect(await store.read('b1'), isEmpty);
  });

  test('read of corrupt (non-JSON) data is empty, no throw', () async {
    SharedPreferences.setMockInitialValues({'bastion_inventory_b1': 'garbage'});
    final store = BastionInventoryStore();
    expect(await store.read('b1'), isEmpty);
  });

  test('read skips a bad entry but keeps the good one', () async {
    final adamantine =
        getDefaultRewards().firstWhere((r) => r.id == 'rew_adamantine');
    SharedPreferences.setMockInitialValues({
      'bastion_inventory_b1': jsonEncode({
        'entries': [
          {
            'rewardId': adamantine.id,
            'effectiveRank': 'D',
          },
          {
            'rewardId': adamantine.id,
            'effectiveRank': 'D',
            'units': 3,
          },
        ],
      }),
    });
    final store = BastionInventoryStore();
    final grants = await store.read('b1');
    expect(grants, hasLength(1));
    expect(grants.single.reward.id, 'rew_adamantine');
    expect(grants.single.units, 3);
  });
}
