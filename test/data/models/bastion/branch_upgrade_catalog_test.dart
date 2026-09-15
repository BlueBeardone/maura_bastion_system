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

  group('displayName / displayDescription', () {
    test('base facility keeps its own name and description', () {
      final f = facility();
      expect(f.displayName, 'Test');
      expect(f.displayDescription, 'desc');
    });

    test('owned oneTime upgrade transforms kitchen', () {
      final base = getFacilityCatalog().firstWhere((f) => f.id == 'cat_kitchen');
      final f = base.copyWith(branchUpgradeId: 'bru_industrial_kitchen');
      expect(f.displayName, 'Industrial Kitchen');
      expect(f.displayDescription, contains('holds up to 3 hirelings'));
      expect(f.displayDescription, contains('1d6 extra treats'));
      expect(f.displayDescription, isNot(contains('Pay 500 GP')));
      expect(f.displayDescription, contains('advantage on crafting treats'));
    });

    test('active perTurn upgrade transforms pub, lapsed shows base', () {
      final base = getFacilityCatalog().firstWhere((f) => f.id == 'cat_pub');
      final active = base.copyWith(
        branchUpgradeId: 'bru_pub_of_legend',
        branchUpgradeActive: true,
      );
      expect(active.displayName, 'Pub of Legend');
      expect(active.displayDescription,
          contains('You pay 2,000 GP each Individual Bastion Turn'));
      expect(active.displayDescription, isNot(contains('Pay 2,000 GP')));

      final lapsed = base.copyWith(branchUpgradeId: 'bru_pub_of_legend');
      expect(lapsed.displayName, 'Pub');
      expect(lapsed.displayDescription, base.description);
    });

    test('description without the upgrade paragraph falls back to base',
        () {
      final f = facility(branchUpgradeId: 'bru_industrial_kitchen');
      expect(f.displayName, 'Industrial Kitchen');
      expect(f.displayDescription, 'desc');
    });

    test('every upgraded description splices out the payment paragraph', () {
      final catalog = getFacilityCatalog();
      for (final upgrade in branchUpgradesByFacilityId.values) {
        if (upgrade.upgradedDescription == null) continue;
        final base = catalog.firstWhere((f) => f.id == upgrade.facilityId);
        // perTurn upgrades only transform while active; passing true is a
        // no-op for oneTime upgrades.
        final f = base.copyWith(
          branchUpgradeId: upgrade.id,
          branchUpgradeActive: true,
        );
        expect(f.displayDescription, isNot(contains(upgrade.description)),
            reason: upgrade.id);
        expect(f.displayDescription, contains(upgrade.upgradedDescription!),
            reason: upgrade.id);
      }
    });
  });
}
