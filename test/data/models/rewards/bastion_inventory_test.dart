import 'package:flutter_test/flutter_test.dart';
import 'package:maura_bastion_system/data/enums/rank.dart';
import 'package:maura_bastion_system/data/models/events/reward_spec.dart';
import 'package:maura_bastion_system/data/models/rewards/bastion_inventory.dart';
import 'package:maura_bastion_system/data/models/rewards/reward.dart';

Reward herb(String id, Rank rank, int value) => Reward(
      id: id,
      name: id,
      category: RewardCategory.herb,
      rank: rank,
      marketValue: value,
      weightPerUnit: 0.5,
      description: 'test',
    );

Reward metal(String id) => Reward(
      id: id,
      name: id,
      category: RewardCategory.metal,
      weightPerUnit: 5,
      description: 'test',
    );

RewardGrant grant(Reward reward, Rank effective, int units) =>
    RewardGrant(reward: reward, effectiveRank: effective, units: units);

void main() {
  test('addGrants merges by reward and rank', () {
    final a = herb('rew_a', Rank.D, 150);
    final inventory = const BastionInventory()
        .addGrants([grant(a, Rank.D, 2)])
        .addGrants([grant(a, Rank.D, 3)]);
    expect(inventory.entries.length, 1);
    expect(inventory.entries.values.single.units, 5);
  });

  test('same reward at different ranks stays separate', () {
    final m = metal('rew_m');
    final inventory = const BastionInventory()
        .addGrants([grant(m, Rank.D, 2), grant(m, Rank.B, 1)]);
    expect(inventory.entries.length, 2);
    expect(inventory.totalWeight(), 15.0);
  });

  test('totalWeight sums weightPerUnit times units', () {
    final inventory = const BastionInventory().addGrants([
      grant(herb('rew_a', Rank.E, 15), Rank.E, 4),
      grant(metal('rew_m'), Rank.D, 3),
    ]);
    expect(inventory.totalWeight(), 4 * 0.5 + 3 * 5);
  });

  test('grants with zero or negative units are ignored', () {
    final inventory = const BastionInventory()
        .addGrants([grant(herb('rew_a', Rank.E, 15), Rank.E, 0)]);
    expect(inventory.entries, isEmpty);
  });

  test('addGrants does not mutate the source inventory', () {
    final a = herb('rew_a', Rank.E, 15);
    final original = const BastionInventory().addGrants([grant(a, Rank.E, 1)]);
    final updated = original.addGrants([grant(a, Rank.E, 1)]);
    expect(original.entries.values.single.units, 1);
    expect(updated.entries.values.single.units, 2);
  });
}
