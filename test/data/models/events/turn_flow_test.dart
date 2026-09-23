// test/data/models/events/turn_flow_test.dart
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:maura_bastion_system/data/enums/defender_type.dart';
import 'package:maura_bastion_system/data/models/bastion/bastion.dart';
import 'package:maura_bastion_system/data/models/bastion/facility.dart';
import 'package:maura_bastion_system/data/models/events/chart_event.dart';
import 'package:maura_bastion_system/data/models/events/chart_tier.dart';
import 'package:maura_bastion_system/data/models/events/dispatch.dart';
import 'package:maura_bastion_system/data/models/events/event_chart.dart';
import 'package:maura_bastion_system/data/enums/rank.dart';
import 'package:maura_bastion_system/data/models/events/reward_spec.dart';
import 'package:maura_bastion_system/data/models/events/turn_flow.dart';
import 'package:maura_bastion_system/data/models/npcs/defender.dart';
import 'package:maura_bastion_system/data/models/npcs/hireling.dart';
import 'package:maura_bastion_system/data/models/rewards/reward.dart';

ChartEvent _dispatchable() => const ChartEvent(
      id: 'evt_d',
      name: 'Dispatchable',
      chart: EventChart.wilds,
      tier: ChartTier.basic,
      description: 'd',
      dispatch: DispatchSpec(prompt: 'p', maxUnits: 2, dc: 1),
    );

ChartEvent _plain() => const ChartEvent(
      id: 'evt_p',
      name: 'Plain',
      chart: EventChart.wilds,
      tier: ChartTier.basic,
      description: 'd',
    );

void main() {
  test('dispatchTypeForDefender maps all defender types', () {
    expect(dispatchTypeForDefender(DefenderType.knight), DispatchUnitType.knight);
    expect(
        dispatchTypeForDefender(DefenderType.bastionDefender),
        DispatchUnitType.bastionDefender);
    expect(dispatchTypeForDefender(DefenderType.beast), DispatchUnitType.beast);
  });

  test('dispatchUnitsFromBastion maps defenders then hirelings', () {
    final bastion = Bastion(
      id: 'b1',
      name: 'T',
      description: '',
      facilities: const [],
      defenders: [
        Defender(id: 'd1', name: 'Aldric', type: DefenderType.knight, bastionId: 'b1'),
        Defender(id: 'd2', type: DefenderType.beast, bastionId: 'b1'),
      ],
      hirelings: [
        Hireling(id: 'h1', name: 'Mira', bastionId: 'b1'),
      ],
    );
    final units = dispatchUnitsFromBastion(bastion);
    expect(units.length, 3);
    expect(units[0].type, DispatchUnitType.knight);
    expect(units[0].name, 'Aldric');
    expect(units[1].type, DispatchUnitType.beast);
    expect(units[1].name, 'Defender');
    expect(units[2].type, DispatchUnitType.hireling);
    expect(units[2].name, 'Mira');
  });

  test('resolveEventDispatch returns null for plain events', () {
    expect(
      resolveEventDispatch(event: _plain(), selected: const [], rng: Random(1)),
      isNull,
    );
  });

  test('resolveEventDispatch resolves with dice for dispatchable events', () {
    final result = resolveEventDispatch(
      event: _dispatchable(),
      selected: const [
        DispatchUnit(id: 'a', name: 'A', type: DispatchUnitType.knight),
      ],
      rng: Random(3),
    );
    expect(result, isNotNull);
    expect(result!.unitRolls.single.rolls, isNotEmpty);
  });

  test('resolveEventRewards auto-succeeds plain events', () {
    final reward = resolveEventRewards(event: _plain());
    expect(reward.recruit, RewardKind.none);
  });

  group('rewardSummaryText', () {
    test('empty reward reads none', () {
      expect(
        rewardSummaryText(const TurnReward(materials: [], recruit: RewardKind.none)),
        'none',
      );
    });

    test('materials and recruits are joined', () {
      final metal = Reward(
        id: 'rew_m',
        name: 'Adamantine',
        category: RewardCategory.metal,
        weightPerUnit: 5,
        description: 'test',
      );
      final summary = rewardSummaryText(TurnReward(
        materials: [RewardGrant(reward: metal, effectiveRank: Rank.D, units: 2)],
        recruit: RewardKind.recruitHireling,
      ));
      expect(summary, '2 × Adamantine (Rank D), a new hireling');
    });
  });

  group('facilityKnockedOffline', () {
    Bastion bastionWith(Facility facility) => Bastion(
          id: 'b1',
          name: 'T',
          description: '',
          facilities: [facility],
        );

    Facility kitchen({required int constructed, required int total}) => Facility(
          id: 'cat_kitchen',
          name: 'Kitchen',
          rank: Rank.D,
          description: 'desc',
          constructedTurns: constructed,
          constructionTurns: total,
        );

    test('returns null when facilityId is null', () {
      expect(
        facilityKnockedOffline(
            bastionWith(kitchen(constructed: 2, total: 2)), null),
        isNull,
      );
    });

    test('returns null when the facility is absent', () {
      expect(
        facilityKnockedOffline(
            bastionWith(kitchen(constructed: 2, total: 2)), 'cat_pub'),
        isNull,
      );
    });

    test('returns null when the facility is already offline', () {
      expect(
        facilityKnockedOffline(
            bastionWith(kitchen(constructed: 1, total: 2)), 'cat_kitchen'),
        isNull,
      );
    });

    test('returns null when constructionTurns is zero', () {
      expect(
        facilityKnockedOffline(
            bastionWith(kitchen(constructed: 0, total: 0)), 'cat_kitchen'),
        isNull,
      );
    });

    test('marks an operational facility one turn short', () {
      final closed = facilityKnockedOffline(
          bastionWith(kitchen(constructed: 2, total: 2)), 'cat_kitchen');
      expect(closed, isNotNull);
      expect(closed!.id, 'cat_kitchen');
      expect(closed.name, 'Kitchen');
      expect(closed.constructedTurns, 1);
      expect(closed.constructionTurns, 2);
    });
  });
}
