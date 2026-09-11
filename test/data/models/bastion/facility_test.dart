import 'package:flutter_test/flutter_test.dart';
import 'package:maura_bastion_system/data/enums/rank.dart';
import 'package:maura_bastion_system/data/models/bastion/facility.dart';

void main() {
  group('Facility branch upgrade fields', () {
    test('fromJson defaults branchUpgradeActive to false and id to null', () {
      final facility = Facility.fromJson({
        'id': 'cat_kitchen',
        'name': 'Kitchen',
        'rank': 'd',
        'description': 'desc',
      });

      expect(facility.branchUpgradeId, isNull);
      expect(facility.branchUpgradeActive, isFalse);
    });

    test('fromJson parses branch upgrade fields when present', () {
      final facility = Facility.fromJson({
        'id': 'cat_pub',
        'name': 'Pub',
        'rank': 'a',
        'description': 'desc',
        'branchUpgradeId': 'bru_pub_of_legend',
        'branchUpgradeActive': true,
      });

      expect(facility.branchUpgradeId, 'bru_pub_of_legend');
      expect(facility.branchUpgradeActive, isTrue);
    });

    test('toJson round-trips branch upgrade fields', () {
      const facility = Facility(
        id: 'cat_pub',
        name: 'Pub',
        rank: Rank.A,
        description: 'desc',
        branchUpgradeId: 'bru_pub_of_legend',
        branchUpgradeActive: true,
      );

      final json = facility.toJson();
      expect(json['branchUpgradeId'], 'bru_pub_of_legend');
      expect(json['branchUpgradeActive'], true);

      final parsed = Facility.fromJson(json);
      expect(parsed.branchUpgradeId, 'bru_pub_of_legend');
      expect(parsed.branchUpgradeActive, isTrue);
    });
  });

  group('Facility.copyWith', () {
    final base = Facility(
      id: 'cat_kitchen',
      name: 'Kitchen',
      rank: Rank.D,
      description: 'desc',
      minimumRequiredHirelings: 1,
      constructionTurns: 2,
      constructedTurns: 2,
      cost: 600,
      branchUpgradeId: 'bru_industrial_kitchen',
      branchUpgradeActive: true,
    );

    test('overrides provided fields', () {
      final upgraded = base.copyWith(rank: Rank.C, constructedTurns: 0);

      expect(upgraded.rank, Rank.C);
      expect(upgraded.constructedTurns, 0);
    });

    test('carries branch upgrade fields through unchanged', () {
      final upgraded = base.copyWith(rank: Rank.C, constructedTurns: 0);

      expect(upgraded.id, 'cat_kitchen');
      expect(upgraded.branchUpgradeId, 'bru_industrial_kitchen');
      expect(upgraded.branchUpgradeActive, isTrue);
      expect(upgraded.minimumRequiredHirelings, 1);
    });

    test('can set branchUpgradeId back to null via sentinel', () {
      final cleared = base.copyWith(branchUpgradeId: '');
      expect(cleared.branchUpgradeId, '');
    });
  });
}
