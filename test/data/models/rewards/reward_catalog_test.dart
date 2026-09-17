import 'package:flutter_test/flutter_test.dart';
import 'package:maura_bastion_system/data/default_data/rewards/default_reward_data.dart';
import 'package:maura_bastion_system/data/enums/rank.dart';
import 'package:maura_bastion_system/data/models/rewards/reward.dart';
import 'package:maura_bastion_system/data/models/rewards/reward_harvest_rules.dart';

void main() {
  group('Rank E', () {
    test('exists below D', () {
      expect(Rank.values.length, 6);
      expect(Rank.D.next, Rank.C);
      expect(Rank.E.next, Rank.D);
      expect(Rank.E.title, 'E');
      expect(Rank.fromString('e'), Rank.E);
    });
  });

  group('getDefaultRewards', () {
    final rewards = getDefaultRewards();

    test('has the full resource list', () {
      expect(rewards.length, 70);
      int count(RewardCategory category) =>
          rewards.where((r) => r.category == category).length;
      expect(count(RewardCategory.creaturePart), 10);
      expect(count(RewardCategory.metal), 9);
      expect(count(RewardCategory.stone), 5);
      expect(count(RewardCategory.wood), 4);
      expect(count(RewardCategory.weave), 4);
      expect(count(RewardCategory.herb), 36);
      expect(count(RewardCategory.meat), 1);
      expect(count(RewardCategory.blood), 1);
    });

    test('has unique ids', () {
      final ids = rewards.map((r) => r.id).toSet();
      expect(ids.length, rewards.length);
    });

    test('herbs carry their fixed rank and market value', () {
      Reward herb(String name) =>
          rewards.firstWhere((r) => r.name == name && r.category == RewardCategory.herb);

      expect(herb('Blue Herb').rank, Rank.E);
      expect(herb('Blue Herb').marketValue, 15);
      expect(herb('Ash Chives').rank, Rank.D);
      expect(herb('Ash Chives').marketValue, 150);
      expect(herb('Ghost Blossom').rank, Rank.C);
      expect(herb('Ghost Blossom').marketValue, 300);
      expect(herb('Spirit Petals').rank, Rank.B);
      expect(herb('Spirit Petals').marketValue, 850);
      expect(herb('Thunder Leaf').rank, Rank.A);
      expect(herb('Thunder Leaf').marketValue, 1500);
      expect(herb('Black Lotus').rank, Rank.S);
      expect(herb('Black Lotus').marketValue, 5600);
    });

    test('Kreen Paste overrides the common herb value', () {
      final kreen =
          rewards.firstWhere((r) => r.name == 'Kreen Paste');
      expect(kreen.rank, Rank.E);
      expect(kreen.marketValue, 25);
    });

    test('gatherable materials leave rank and value to harvest time', () {
      final chitin =
          rewards.firstWhere((r) => r.name == 'Chitin');
      expect(chitin.category, RewardCategory.creaturePart);
      expect(chitin.rank, isNull);
      expect(chitin.marketValue, isNull);

      final ignum = rewards.firstWhere((r) => r.name == 'Ignum');
      expect(ignum.category, RewardCategory.stone);
      expect(ignum.rank, isNull);
      expect(ignum.marketValue, isNull);
    });

    test('ironwood is heavy', () {
      final ironwood = rewards.firstWhere((r) => r.name == 'Ironwood');
      expect(ironwood.weightPerUnit, 25.0);
    });

    test('herbs weigh half a pound, weaves and meat two', () {
      final blueHerb = rewards.firstWhere((r) => r.name == 'Blue Herb');
      final leafweave = rewards.firstWhere((r) => r.name == 'Leafweave');
      final meat = rewards.firstWhere((r) => r.category == RewardCategory.meat);
      expect(blueHerb.weightPerUnit, 0.5);
      expect(leafweave.weightPerUnit, 2.0);
      expect(meat.weightPerUnit, 2.0);
    });
  });

  group('Main Chart', () {
    test('material values by rank', () {
      expect(mainChartValueByRank[Rank.E], 15);
      expect(mainChartValueByRank[Rank.D], 150);
      expect(mainChartValueByRank[Rank.C], 300);
      expect(mainChartValueByRank[Rank.B], 850);
      expect(mainChartValueByRank[Rank.A], 1500);
      expect(mainChartValueByRank[Rank.S], 5600);
    });

    test('meat/blood values by rank', () {
      expect(mainChartMeatBloodValueByRank[Rank.E], 3);
      expect(mainChartMeatBloodValueByRank[Rank.D], 30);
      expect(mainChartMeatBloodValueByRank[Rank.C], 60);
      expect(mainChartMeatBloodValueByRank[Rank.B], 170);
      expect(mainChartMeatBloodValueByRank[Rank.A], 300);
      expect(mainChartMeatBloodValueByRank[Rank.S], 1120);
    });

    test('unit bonus X by rank', () {
      expect(unitBonusXByRank[Rank.E], 0);
      expect(unitBonusXByRank[Rank.D], 1);
      expect(unitBonusXByRank[Rank.C], 2);
      expect(unitBonusXByRank[Rank.B], 3);
      expect(unitBonusXByRank[Rank.A], 4);
      expect(unitBonusXByRank[Rank.S], 5);
    });
  });

  group('Harvest rules', () {
    test('DC formulas', () {
      expect(creaturePartHarvestDC(15), 19);
      expect(venomGlandHarvestDC(15), 27);
    });

    test('creature category skill checks', () {
      expect(creaturePartSkillCheckByCategory.length, 14);
      expect(creaturePartSkillCheckByCategory['Beast'], 'Nature/Survival');
      expect(creaturePartSkillCheckByCategory['Undead'], 'Religion');
      expect(creaturePartSkillCheckByCategory['Aberration'], 'Arcana');
    });

    test('creature size harvest stats', () {
      expect(CreatureHarvestStats.small.maxChecks, 1);
      expect(CreatureHarvestStats.small.maxUnitsPerCheck, isNull);
      expect(CreatureHarvestStats.medium.maxUnitsPerCheck, 1);
      expect(CreatureHarvestStats.large.maxUnitsPerCheck, 2);
      expect(CreatureHarvestStats.huge.maxChecks, 2);
      expect(CreatureHarvestStats.huge.maxUnitsPerCheck, 2);
      expect(CreatureHarvestStats.gargantuan.maxChecks, 2);
      expect(CreatureHarvestStats.gargantuan.maxUnitsPerCheck, 3);
      expect(CreatureHarvestStats.small.rationsOfMeat, 1);
      expect(CreatureHarvestStats.gargantuan.rationsOfMeat, 6);
      expect(CreatureHarvestStats.gargantuan.unitsOfBlood, 6);
    });
  });
}
