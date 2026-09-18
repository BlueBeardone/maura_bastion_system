import 'package:flutter_test/flutter_test.dart';
import 'package:maura_bastion_system/data/models/events/event_chart.dart';
import 'package:maura_bastion_system/data/models/rewards/reward.dart';

void main() {
  test('has six charts with display names', () {
    expect(EventChart.values.length, 6);
    expect(EventChart.wilds.displayName, 'The Wilds');
    expect(EventChart.deeps.displayName, 'The Deeps');
    expect(EventChart.tradeRoad.displayName, 'The Trade Road');
    expect(EventChart.warMarch.displayName, 'The War March');
    expect(EventChart.hearth.displayName, 'The Hearth');
    expect(EventChart.arcane.displayName, 'The Arcane');
  });

  test('reward categories match the spec', () {
    expect(EventChart.wilds.rewardCategories,
        [RewardCategory.creaturePart, RewardCategory.meat, RewardCategory.blood, RewardCategory.herb]);
    expect(EventChart.deeps.rewardCategories, [RewardCategory.metal, RewardCategory.stone]);
    expect(EventChart.tradeRoad.rewardCategories, [RewardCategory.weave]);
    expect(EventChart.warMarch.rewardCategories, [RewardCategory.creaturePart]);
    expect(EventChart.hearth.rewardCategories, isEmpty);
    expect(EventChart.arcane.rewardCategories, [RewardCategory.herb, RewardCategory.weave]);
  });
}
