import 'package:flutter_test/flutter_test.dart';
import 'package:maura_bastion_system/data/enums/rank.dart';
import 'package:maura_bastion_system/data/models/bastion/branch_upgrade.dart';

void main() {
  group('BranchUpgrade', () {
    test('costFor returns flat cost', () {
      const upgrade = BranchUpgrade(
        id: 'bru_test',
        facilityId: 'cat_test',
        name: 'Test Upgrade',
        cost: 500,
        description: 'desc',
        kind: BranchUpgradeKind.oneTime,
      );

      expect(upgrade.costFor(Rank.D), 500);
      expect(upgrade.costFor(Rank.S), 500);
    });

    test('costFor falls back to flat cost when rank missing from table', () {
      const upgrade = BranchUpgrade(
        id: 'bru_test',
        facilityId: 'cat_test',
        name: 'Test Upgrade',
        cost: 500,
        costByRank: {Rank.B: 750},
        description: 'desc',
        kind: BranchUpgradeKind.perUse,
      );

      expect(upgrade.costFor(Rank.B), 750);
      expect(upgrade.costFor(Rank.A), 500);
    });

    test('costFor returns 0 when no cost defined at all', () {
      const upgrade = BranchUpgrade(
        id: 'bru_test',
        facilityId: 'cat_test',
        name: 'Test Upgrade',
        description: 'desc',
        kind: BranchUpgradeKind.oneTime,
      );

      expect(upgrade.costFor(Rank.C), 0);
    });
  });
}
