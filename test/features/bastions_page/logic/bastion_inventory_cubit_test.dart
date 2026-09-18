import 'package:flutter_test/flutter_test.dart';
import 'package:maura_bastion_system/data/enums/rank.dart';
import 'package:maura_bastion_system/data/models/bastion/bastion.dart';
import 'package:maura_bastion_system/data/models/events/reward_spec.dart';
import 'package:maura_bastion_system/data/models/rewards/reward.dart';
import 'package:maura_bastion_system/features/bastions_page/logic/bastion_inventory_cubit.dart';

Reward _metal(String id) => Reward(
      id: id,
      name: id,
      category: RewardCategory.metal,
      weightPerUnit: 5,
      description: 'test',
    );

RewardGrant _grant(Reward reward, int units) => RewardGrant(
      reward: reward,
      effectiveRank: Rank.D,
      units: units,
    );

Bastion _bastion() => Bastion(id: 'b1', name: 'T', description: '', facilities: const []);

void main() {
  late BastionInventoryCubit cubit;

  setUp(() => cubit = BastionInventoryCubit());
  tearDown(() => cubit.close());

  test('initial state is empty', () {
    expect(cubit.state.bastionId, isNull);
    expect(cubit.state.inventory.entries, isEmpty);
    expect(cubit.state.goldEarned, 0);
  });

  test('load resets per bastion', () {
    cubit.load(_bastion());
    cubit.addRewards([_grant(_metal('rew_m'), 2)]);
    cubit.load(_bastion());
    expect(cubit.state.inventory.entries, isEmpty);
    expect(cubit.state.bastionId, 'b1');
  });

  test('addRewards stores grants without a sale under the cap', () {
    cubit.load(_bastion());
    cubit.addRewards([_grant(_metal('rew_m'), 2)]);
    expect(cubit.state.inventory.totalWeight(), 10.0);
    expect(cubit.state.goldEarned, 0);
    expect(cubit.state.lastSold, isEmpty);
  });

  test('overflow auto-sells cheapest first and credits gold', () {
    cubit.load(_bastion());
    // 101 metal units = 505 lbs > 500 lbs cap -> sell 1 unit (150 GP at D).
    cubit.addRewards([_grant(_metal('rew_m'), 101)]);
    expect(cubit.state.inventory.totalWeight(), lessThanOrEqualTo(500));
    expect(cubit.state.goldEarned, 150);
    expect(cubit.state.lastSold.single.reward.id, 'rew_m');
    expect(cubit.state.lastSold.single.units, 1);
  });

  test('gold accumulates across overflow sales', () {
    cubit.load(_bastion());
    cubit.addRewards([_grant(_metal('rew_m'), 101)]);
    cubit.addRewards([_grant(_metal('rew_m'), 1)]);
    expect(cubit.state.goldEarned, 300);
  });
}
