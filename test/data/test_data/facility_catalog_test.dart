import 'package:flutter_test/flutter_test.dart';
import 'package:maura_bastion_system/data/enums/rank.dart';
import 'package:maura_bastion_system/data/models/bastion/facility_catalog.dart';

void main() {
  group('baseCostByRank', () {
    test('matches the catalog build costs', () {
      expect(baseCostByRank[Rank.D], 600);
      expect(baseCostByRank[Rank.C], 1500);
      expect(baseCostByRank[Rank.B], 4500);
      expect(baseCostByRank[Rank.A], 9000);
      expect(baseCostByRank[Rank.S], 20000);
    });
  });

  group('upgradeableFacilityIds', () {
    test('contains exactly the 13 expected catalog facilities, all below S',
        () {
      final catalog = getFacilityCatalog();
      final upgradeable =
          catalog.where((f) => upgradeableFacilityIds.contains(f.id)).toList();
      expect(upgradeable.length, 13);
      for (final facility in upgradeable) {
        expect(facility.rank, isNot(Rank.S));
      }
    });
  });

  group('facilityUpgradeCost', () {
    test('is the difference to the next rank base cost', () {
      expect(facilityUpgradeCost(Rank.D), 900);
      expect(facilityUpgradeCost(Rank.C), 3000);
      expect(facilityUpgradeCost(Rank.B), 4500);
      expect(facilityUpgradeCost(Rank.A), 11000);
      expect(facilityUpgradeCost(Rank.S), 0);
    });
  });
}