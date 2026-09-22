// test/data/models/events/chart_event_test.dart
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:maura_bastion_system/data/enums/rank.dart';
import 'package:maura_bastion_system/data/models/events/chart_event.dart';
import 'package:maura_bastion_system/data/models/events/dispatch.dart';
import 'package:maura_bastion_system/data/models/events/event_chart.dart';
import 'package:maura_bastion_system/data/models/events/chart_tier.dart';
import 'package:maura_bastion_system/data/models/events/reward_spec.dart';
import 'package:maura_bastion_system/data/models/rewards/reward.dart';

ChartEvent eventWith(RewardSpec reward) => ChartEvent(
      id: 'evt_test',
      name: 'Test Event',
      chart: EventChart.wilds,
      tier: ChartTier.basic,
      description: 'desc',
      reward: reward,
    );

void main() {
  test('isArchetype reflects relatedCharts', () {
    const plain = ChartEvent(
      id: 'a', name: 'A', chart: EventChart.wilds, tier: ChartTier.basic,
      description: 'd',
    );
    final archetype = ChartEvent(
      id: 'b', name: 'B', chart: EventChart.wilds, tier: ChartTier.basic,
      description: 'd',
      relatedCharts: {EventChart.wilds, EventChart.arcane},
      minPointsPerChart: 4,
    );
    expect(plain.isArchetype, isFalse);
    expect(archetype.isArchetype, isTrue);
    expect(plain.minPointsPerChart, 0);
  });

  group('rollTurnReward', () {
    test('failure yields only the note', () {
      final result = rollTurnReward(
        event: eventWith(const RewardSpec(
          kind: RewardKind.material,
          categories: [RewardCategory.herb],
          note: 'lost',
        )),
        success: false,
        rng: Random(1),
      );
      expect(result.materials, isEmpty);
      expect(result.recruit, RewardKind.none);
      expect(result.note, 'lost');
    });

    test('failure yields the failure note when present', () {
      final result = rollTurnReward(
        event: eventWith(const RewardSpec(
          note: 'success flavor',
          failureNote: 'failure flavor',
        )),
        success: false,
        rng: Random(1),
      );
      expect(result.note, 'failure flavor');
    });

    test('failure falls back to the plain note when no failure note', () {
      final result = rollTurnReward(
        event: eventWith(const RewardSpec(note: 'quiet')),
        success: false,
        rng: Random(1),
      );
      expect(result.note, 'quiet');
    });

    test('kind none yields nothing but the note', () {
      final result = rollTurnReward(
        event: eventWith(const RewardSpec(note: 'quiet')),
        success: true,
        rng: Random(1),
      );
      expect(result, isA<TurnReward>());
      expect(result.materials, isEmpty);
      expect(result.note, 'quiet');
    });

    test('material success grants within the tier cap', () {
      final result = rollTurnReward(
        event: eventWith(const RewardSpec(
          kind: RewardKind.material,
          categories: [RewardCategory.herb],
          unitDice: UnitDice(1, 2),
        )),
        success: true,
        rng: Random(2),
      );
      expect(result.materials.length, 1);
      expect(withinRewardCap(result.materials.single.reward.rank, Rank.D), isTrue);
    });

    test('flavor-only success yields just the note', () {
      final result = rollTurnReward(
        event: eventWith(const RewardSpec(
          note: 'Your hirelings split the bounty over drinks',
        )),
        success: true,
        rng: Random(7),
      );
      expect(result.materials, isEmpty);
      expect(result.recruit, RewardKind.none);
      expect(result.note, 'Your hirelings split the bounty over drinks');
    });

    test('recruit kind carries through', () {
      final result = rollTurnReward(
        event: eventWith(const RewardSpec(kind: RewardKind.recruitHireling)),
        success: true,
        rng: Random(1),
      );
      expect(result.recruit, RewardKind.recruitHireling);
      expect(result.materials, isEmpty);
    });

    test('material success carries the note', () {
      final result = rollTurnReward(
        event: eventWith(const RewardSpec(
          kind: RewardKind.material,
          categories: [RewardCategory.stone],
          note: 'the stockpile is yours',
        )),
        success: true,
        rng: Random(4),
      );
      expect(result.materials.length, 1);
      expect(result.note, 'the stockpile is yours');
    });
  });
}
