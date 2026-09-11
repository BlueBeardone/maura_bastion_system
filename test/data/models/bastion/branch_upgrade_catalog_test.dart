// test/data/models/bastion/branch_upgrade_catalog_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:maura_bastion_system/data/enums/rank.dart';
import 'package:maura_bastion_system/data/models/bastion/branch_upgrade.dart';
import 'package:maura_bastion_system/data/models/bastion/facility.dart';
import 'package:maura_bastion_system/data/models/bastion/facility_catalog.dart';

Facility facility({
  String id = 'cat_kitchen',
  Rank rank = Rank.D,
  String? branchUpgradeId,
  bool branchUpgradeActive = false,
  int minimumRequiredHirelings = 1,
}) =>
    Facility(
      id: id,
      name: 'Test',
      rank: rank,
      description: 'desc',
      minimumRequiredHirelings: minimumRequiredHirelings,
      branchUpgradeId: branchUpgradeId,
      branchUpgradeActive: branchUpgradeActive,
    );

void main() {
  group('branchUpgradesByFacilityId', () {
    test('contains exactly the 7 branch-upgrade facilities', () {
      expect(branchUpgradesByFacilityId.keys.toSet(), {
        'cat_kitchen',
        'cat_laboratory',
        'cat_library',
        'cat_trading_hub',
        'cat_workshop',
        'cat_pub',
        'cat_theatre',
      });
    });

    test('kitchen is oneTime with capacity 3 at 500 GP', () {
      final upgrade = branchUpgradeFor('cat_kitchen')!;
      expect(upgrade.id, 'bru_industrial_kitchen');
      expect(upgrade.kind, BranchUpgradeKind.oneTime);
      expect(upgrade.costFor(Rank.D), 500);
      expect(upgrade.hirelingCapacity, 3);
    });

    test('pub is perTurn with capacity 4 at 2,000 GP', () {
      final upgrade = branchUpgradeFor('cat_pub')!;
      expect(upgrade.kind, BranchUpgradeKind.perTurn);
      expect(upgrade.costFor(Rank.A), 2000);
      expect(upgrade.hirelingCapacity, 4);
    });

    test('theatre is perUse with rank-based cost', () {
      final upgrade = branchUpgradeFor('cat_theatre')!;
      expect(upgrade.kind, BranchUpgradeKind.perUse);
      expect(upgrade.costFor(Rank.B), 750);
      expect(upgrade.costFor(Rank.A), 1000);
      expect(upgrade.costFor(Rank.S), 1500);
    });

    test('returns null for facilities without a branch upgrade', () {
      expect(branchUpgradeFor('cat_barracks'), isNull);
    });
  });

  group('FacilityBranchUpgradeX', () {
    test('hirelingCapacity is base when no upgrade owned', () {
      final f = facility(minimumRequiredHirelings: 1);
      expect(f.hasActiveBranchUpgrade, isFalse);
      expect(f.hirelingCapacity, 1);
    });

    test('hirelingCapacity comes from owned oneTime upgrade', () {
      final f = facility(branchUpgradeId: 'bru_industrial_kitchen');
      expect(f.hasActiveBranchUpgrade, isTrue);
      expect(f.hirelingCapacity, 3);
    });

    test('perTurn upgrade only active when branchUpgradeActive is true', () {
      final lapsed = facility(
        branchUpgradeId: 'bru_pub_of_legend',
        minimumRequiredHirelings: 1,
      );
      expect(lapsed.hasActiveBranchUpgrade, isFalse);
      expect(lapsed.hirelingCapacity, 1);

      final paid = facility(
        branchUpgradeId: 'bru_pub_of_legend',
        branchUpgradeActive: true,
        minimumRequiredHirelings: 1,
      );
      expect(paid.hasActiveBranchUpgrade, isTrue);
      expect(paid.hirelingCapacity, 4);
    });

    test('owned upgrade without capacity keeps base capacity', () {
      final f = facility(
        id: 'cat_library',
        branchUpgradeId: 'bru_vault_of_knowledge',
        minimumRequiredHirelings: 1,
      );
      expect(f.hasActiveBranchUpgrade, isTrue);
      expect(f.hirelingCapacity, 1);
    });
  });
}
