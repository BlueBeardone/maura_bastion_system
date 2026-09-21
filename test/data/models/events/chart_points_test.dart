import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:maura_bastion_system/data/enums/rank.dart';
import 'package:maura_bastion_system/data/models/bastion/bastion.dart';
import 'package:maura_bastion_system/data/models/bastion/facility.dart';
import 'package:maura_bastion_system/data/models/events/chart_points.dart';
import 'package:maura_bastion_system/data/models/events/event_chart.dart';

void main() {
  test('starts empty with unassigned equal to earned', () {
    final points = const ChartPoints(earnedPoints: 5);
    expect(points.assignedTotal, 0);
    expect(points.unassigned, 5);
    expect(points[EventChart.wilds], 0);
  });

  test('assign moves unassigned points into a chart', () {
    final points = const ChartPoints(earnedPoints: 4).assign(EventChart.wilds, 4);
    expect(points[EventChart.wilds], 4);
    expect(points.unassigned, 0);
  });

  test('cannot assign more than earned', () {
    final points = const ChartPoints(earnedPoints: 2);
    final rejected = points.assign(EventChart.deeps, 3);
    expect(identical(rejected, points), isTrue);
    final accepted = points.assign(EventChart.deeps, 2);
    expect(accepted[EventChart.deeps], 2);
  });

  test('assigning across charts respects the shared budget', () {
    final points = const ChartPoints(earnedPoints: 3).assign(EventChart.wilds, 2);
    final rejected = points.assign(EventChart.hearth, 2);
    expect(identical(rejected, points), isTrue);
    final accepted = points.assign(EventChart.hearth, 1);
    expect(accepted.assignedTotal, 3);
    expect(accepted.unassigned, 0);
  });

  test('cannot go below zero per chart', () {
    final points = const ChartPoints(earnedPoints: 4).assign(EventChart.arcane, 1);
    final rejected = points.assign(EventChart.arcane, -2);
    expect(identical(rejected, points), isTrue);
    final accepted = points.assign(EventChart.arcane, -1);
    expect(accepted[EventChart.arcane], 0);
  });

  test('reassignment between charts works', () {
    final points = const ChartPoints(earnedPoints: 4)
        .assign(EventChart.wilds, 4)
        .assign(EventChart.wilds, -2)
        .assign(EventChart.deeps, 2);
    expect(points[EventChart.wilds], 2);
    expect(points[EventChart.deeps], 2);
  });

  test('canAssign mirrors assign legality', () {
    final points = const ChartPoints(earnedPoints: 2).assign(EventChart.wilds, 1);
    expect(points.canAssign(EventChart.wilds, 1), isTrue);
    expect(points.canAssign(EventChart.wilds, 2), isFalse);
    expect(points.canAssign(EventChart.wilds, -2), isFalse);
    expect(points.canAssign(EventChart.wilds, -1), isTrue);
  });

  test('earnedPoints is expected to be pre-clamped to 16 by callers', () {
    final points = const ChartPoints(earnedPoints: 16);
    final full = points.assign(EventChart.hearth, 16);
    expect(full.assignedTotal, 16);
    expect(full.canAssign(EventChart.hearth, 1), isFalse);
  });

  group('randomizedAllocation', () {
    test('fully assigned allocation is returned unchanged', () {
      final points = const ChartPoints(earnedPoints: 4).assign(EventChart.wilds, 4);
      final effective = points.randomizedAllocation(rng: Random(1));
      expect(effective, {EventChart.wilds: 4});
    });

    test('explicit assignments are preserved and totals fill to earned', () {
      final points = const ChartPoints(earnedPoints: 6)
          .assign(EventChart.wilds, 2)
          .assign(EventChart.deeps, 1);
      for (var i = 0; i < 20; i++) {
        final effective = points.randomizedAllocation(rng: Random(i));
        expect(effective[EventChart.wilds], greaterThanOrEqualTo(2));
        expect(effective[EventChart.deeps], greaterThanOrEqualTo(1));
        final total = EventChart.values.fold<int>(0, (s, c) => s + (effective[c] ?? 0));
        expect(total, 6);
      }
    });

    test('source allocation is not mutated', () {
      final points = const ChartPoints(earnedPoints: 3);
      points.randomizedAllocation(rng: Random(1));
      expect(points.assignedTotal, 0);
      expect(points.unassigned, 3);
    });

    test('zero earned points yields an empty map', () {
      const points = ChartPoints(earnedPoints: 0);
      expect(points.randomizedAllocation(rng: Random(1)), isEmpty);
    });
  });

  group('earnedPointsFor', () {
    Facility facility(int constructed, int construction) => Facility(
          id: 'f',
          name: 'F',
          rank: Rank.D,
          description: '',
          constructedTurns: constructed,
          constructionTurns: construction,
        );

    test('under-construction facilities earn nothing', () {
      final bastion = Bastion(
        id: 'b',
        name: 'B',
        description: '',
        facilities: [facility(0, 3), facility(1, 2)],
      );
      expect(ChartPoints.earnedPointsFor(bastion), 4); // floor applies
    });

    test('completed facilities count', () {
      final bastion = Bastion(
        id: 'b',
        name: 'B',
        description: '',
        facilities: [facility(3, 3), facility(2, 2), facility(0, 1)],
      );
      expect(ChartPoints.earnedPointsFor(bastion), 4); // 2 completed < floor
    });

    test('floor of four', () {
      final bastion = Bastion(
        id: 'b',
        name: 'B',
        description: '',
        facilities: [facility(1, 1)],
      );
      expect(ChartPoints.earnedPointsFor(bastion), 4);
    });

    test('scales past the floor and caps at 16', () {
      final bastion = Bastion(
        id: 'b',
        name: 'B',
        description: '',
        facilities: List.generate(9, (i) => facility(1, 1)),
      );
      expect(ChartPoints.earnedPointsFor(bastion), 9);

      final huge = Bastion(
        id: 'b',
        name: 'B',
        description: '',
        facilities: List.generate(30, (i) => facility(1, 1)),
      );
      expect(ChartPoints.earnedPointsFor(huge), ChartPoints.maxPoints);
    });
  });
}
