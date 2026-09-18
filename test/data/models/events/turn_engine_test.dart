// test/data/models/events/turn_engine_test.dart
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:maura_bastion_system/data/models/events/event_chart.dart';
import 'package:maura_bastion_system/data/models/events/reward_spec.dart';
import 'package:maura_bastion_system/data/models/events/turn_engine.dart';

void main() {
  final engine = const ChartTurnEngine();

  group('rollTurn with no points', () {
    test('lands on the uneventful table', () {
      for (var i = 0; i < 10; i++) {
        final roll = engine.rollTurn(points: {}, rng: Random(i));
        expect(roll.slice, isNull);
        expect(roll.event.chart, isNull);
        expect(roll.event.id, startsWith('unt_'));
        expect(roll.event.reward.kind, RewardKind.none);
        expect(roll.event.dispatch, isNull);
      }
    });

    test('all-zero points are also uneventful', () {
      final roll = engine.rollTurn(
        points: {EventChart.wilds: 0, EventChart.deeps: 0},
        rng: Random(1),
      );
      expect(roll.event.id, startsWith('unt_'));
    });
  });

  group('rollTurn with points', () {
    test('single-chart distribution only rolls that chart at the right tier', () {
      for (var i = 0; i < 30; i++) {
        final roll = engine.rollTurn(
          points: {EventChart.wilds: 8},
          rng: Random(i),
        );
        expect(roll.event.chart, EventChart.wilds);
        expect(roll.tier.minPoints, 8);
        expect(roll.event.isArchetype, isFalse);
        expect(roll.slice!.points, 8);
      }
    });

    test('events never come from zero-point charts', () {
      for (var i = 0; i < 100; i++) {
        final roll = engine.rollTurn(
          points: {EventChart.wilds: 6, EventChart.deeps: 6, EventChart.arcane: 0},
          rng: Random(100 + i),
        );
        expect(roll.event.chart, isNot(EventChart.arcane));
        expect({EventChart.wilds, EventChart.deeps}.contains(roll.event.chart), isTrue);
      }
    });

    test('is deterministic for a fixed seed', () {
      final a = engine.rollTurn(points: {EventChart.wilds: 8}, rng: Random(42));
      final b = engine.rollTurn(points: {EventChart.wilds: 8}, rng: Random(42));
      expect(a.event.id, b.event.id);
      expect(a.slice!.rollMin, b.slice!.rollMin);
    });

    test('mixed distribution rolls only the funded charts', () {
      for (var i = 0; i < 100; i++) {
        final roll = engine.rollTurn(
          points: {
            EventChart.wilds: 8,
            EventChart.tradeRoad: 5,
            EventChart.hearth: 3,
          },
          rng: Random(200 + i),
        );
        expect(
          {EventChart.wilds, EventChart.tradeRoad, EventChart.hearth}
              .contains(roll.event.chart),
          isTrue,
          reason: 'roll ${roll.slice} produced ${roll.event.id}',
        );
      }
    });
  });
}
