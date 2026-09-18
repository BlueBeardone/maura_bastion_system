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

  group('sellDownTo', () {
    test('inventory under the limit sells nothing', () {
      final inventory = const BastionInventory().addGrants([
        grant(herb('rew_a', Rank.E, 15), Rank.E, 4),
        grant(metal('rew_m'), Rank.D, 2),
      ]);
      final result = inventory.sellDownTo(maxWeight: 100);
      expect(result.goldGained, 0);
      expect(result.sold, isEmpty);
      expect(result.inventory.totalWeight(), inventory.totalWeight());
    });

    test('sells cheapest first until the weight fits', () {
      final cheap = herb('rew_cheap', Rank.E, 15);
      final pricey = herb('rew_pricey', Rank.D, 150);
      final inventory = const BastionInventory().addGrants([
        grant(cheap, Rank.E, 10), // 5 lbs, value 150
        grant(pricey, Rank.D, 10), // 5 lbs, value 1500
      ]);
      final result = inventory.sellDownTo(maxWeight: 8);
      expect(result.sold.single.reward.id, 'rew_cheap');
      expect(result.sold.single.units, 4);
      expect(result.goldGained, 4 * 15);
      expect(result.inventory.totalWeight(), closeTo(8, 0.001));
      expect(result.inventory.entries['rew_cheap|E']!.units, 6);
      expect(result.inventory.entries['rew_pricey|D']!.units, 10);
    });

    test('partial sale shrinks the cheapest entry', () {
      final cheap = herb('rew_cheap', Rank.E, 15);
      final inventory = const BastionInventory().addGrants([
        grant(cheap, Rank.E, 10), // 5 lbs
        grant(metal('rew_m'), Rank.D, 3), // 15 lbs
      ]);
      final result = inventory.sellDownTo(maxWeight: 17);
      expect(result.inventory.entries['rew_cheap|E']!.units, 4);
      expect(result.sold.single.units, 6);
      expect(result.goldGained, 6 * 15);
    });

    test('rank-null meat values come from the meat/blood chart', () {
      final meat = Reward(
        id: 'rew_meat',
        name: 'Meat',
        category: RewardCategory.meat,
        weightPerUnit: 2,
        description: 'test',
      );
      final inventory = const BastionInventory().addGrants([
        grant(herb('rew_pricey', Rank.D, 150), Rank.D, 10), // 5 lbs, 1500
        grant(meat, Rank.E, 10), // 20 lbs, 3/unit
      ]);
      final result = inventory.sellDownTo(maxWeight: 10);
      expect(result.sold.single.reward.id, 'rew_meat');
      expect(result.sold.single.units, 8);
      expect(result.goldGained, 8 * 3);
      expect(result.inventory.entries['rew_meat|E']!.units, 2);
    });
  });
}
