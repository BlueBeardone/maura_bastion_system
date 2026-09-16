// test/data/models/bastion/branch_upgrade_catalog_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:maura_bastion_system/data/enums/rank.dart';
import 'package:maura_bastion_system/data/models/bastion/branch_upgrade.dart';
import 'package:maura_bastion_system/data/models/bastion/facility.dart';
import 'package:maura_bastion_system/data/models/bastion/facility_catalog.dart';

Facility facility({
  String id = 'cat_kitchen',
  Rank rank = Rank.D,
  String name = 'Test',
  int minimumRequiredHirelings = 1,
}) =>
    Facility(
      id: id,
      name: name,
      rank: rank,
      description: 'desc',
      minimumRequiredHirelings: minimumRequiredHirelings,
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

    test('hirelingCapacity comes from an applied oneTime upgrade', () {
      final base =
          getFacilityCatalog().firstWhere((f) => f.id == 'cat_kitchen');
      final f = base.applyBranchUpgrade(branchUpgradeFor('cat_kitchen')!);
      expect(f.name, 'Industrial Kitchen');
      expect(f.hasActiveBranchUpgrade, isTrue);
      expect(f.hirelingCapacity, 3);
    });

    test('reverting a perTurn upgrade restores the base facility', () {
      final base = getFacilityCatalog().firstWhere((f) => f.id == 'cat_pub');
      final paid = base.applyBranchUpgrade(branchUpgradeFor('cat_pub')!);
      expect(paid.name, 'Pub of Legend');
      expect(paid.hasActiveBranchUpgrade, isTrue);
      expect(paid.hirelingCapacity, 4);

      final lapsed = paid.revertBranchUpgrade();
      expect(lapsed.name, 'Pub');
      expect(lapsed.description, base.description);
      expect(lapsed.hasActiveBranchUpgrade, isFalse);
      expect(lapsed.hirelingCapacity, 1);
    });

    test('owned upgrade without capacity keeps base capacity', () {
      final base =
          getFacilityCatalog().firstWhere((f) => f.id == 'cat_library');
      final f = base.applyBranchUpgrade(branchUpgradeFor('cat_library')!);
      expect(f.hasActiveBranchUpgrade, isTrue);
      expect(f.hirelingCapacity, 1);
    });
  });

  group('upgraded name and description variants', () {
    test('all oneTime and perTurn upgrades define upgraded variants', () {
      for (final upgrade in branchUpgradesByFacilityId.values) {
        if (upgrade.kind == BranchUpgradeKind.perUse) continue;
        expect(upgrade.upgradedName, isNotNull,
            reason: '${upgrade.id} missing upgradedName');
        expect(upgrade.upgradedDescription, isNotNull,
            reason: '${upgrade.id} missing upgradedDescription');
      }
    });

    test('theatre perUse upgrade has no upgraded variant', () {
      final upgrade = branchUpgradeFor('cat_theatre')!;
      expect(upgrade.upgradedName, isNull);
      expect(upgrade.upgradedDescription, isNull);
    });

    test('kitchen upgraded variant renames to Industrial Kitchen', () {
      final upgrade = branchUpgradeFor('cat_kitchen')!;
      expect(upgrade.upgradedName, 'Industrial Kitchen');
      expect(upgrade.upgradedDescription,
          contains('holds up to 3 hirelings'));
      expect(upgrade.upgradedDescription, isNot(contains('Pay 500 GP')));
    });

    test('pub upgraded variant renames to Pub of Legend', () {
      final upgrade = branchUpgradeFor('cat_pub')!;
      expect(upgrade.upgradedName, 'Pub of Legend');
      expect(upgrade.upgradedDescription,
          contains('You pay 2,000 GP each Individual Bastion Turn'));
    });
  });

  group('applyBranchUpgrade', () {
    test('kitchen upgrade renames and swaps the description', () {
      final base =
          getFacilityCatalog().firstWhere((f) => f.id == 'cat_kitchen');
      final f = base.applyBranchUpgrade(branchUpgradeFor('cat_kitchen')!);
      expect(f.name, 'Industrial Kitchen');
      expect(f.description, contains('holds up to 3 hirelings'));
      expect(f.description, contains('1d6 extra treats'));
      expect(f.description, isNot(contains('Pay 500 GP')));
      expect(f.description, isNot(contains('advantage on crafting treats')));
    });

    test('every stateful upgrade replaces the payment paragraph', () {
      final catalog = getFacilityCatalog();
      for (final upgrade in branchUpgradesByFacilityId.values) {
        if (upgrade.kind == BranchUpgradeKind.perUse) continue;
        final base = catalog.firstWhere((f) => f.id == upgrade.facilityId);
        final f = base.applyBranchUpgrade(upgrade);
        expect(f.name, upgrade.upgradedName, reason: upgrade.id);
        expect(f.description, upgrade.upgradedDescription, reason: upgrade.id);
        expect(f.description, isNot(contains(upgrade.description)),
            reason: upgrade.id);
      }
    });

    test('revert is a no-op for a base facility', () {
      final f = facility();
      expect(f.revertBranchUpgrade(), same(f));
    });
  });
}
