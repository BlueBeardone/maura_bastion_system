// lib/data/models/events/turn_flow.dart
import 'dart:math';

import 'package:maura_bastion_system/data/enums/defender_type.dart';
import 'package:maura_bastion_system/data/enums/rank.dart';
import 'package:maura_bastion_system/data/models/bastion/bastion.dart';
import 'package:maura_bastion_system/data/models/events/chart_event.dart';
import 'package:maura_bastion_system/data/models/events/dispatch.dart';
import 'package:maura_bastion_system/data/models/events/reward_spec.dart';

export 'package:maura_bastion_system/data/models/events/reward_spec.dart'
    show RewardKind, TurnReward;

DispatchUnitType dispatchTypeForDefender(DefenderType type) {
  switch (type) {
    case DefenderType.knight:
      return DispatchUnitType.knight;
    case DefenderType.bastionDefender:
      return DispatchUnitType.bastionDefender;
    case DefenderType.beast:
      return DispatchUnitType.beast;
  }
}

List<DispatchUnit> dispatchUnitsFromBastion(Bastion bastion) {
  return [
    for (final d in bastion.defenders)
      DispatchUnit(
        id: d.id,
        name: d.name ?? 'Defender',
        type: dispatchTypeForDefender(d.type),
      ),
    for (final h in bastion.hirelings)
      DispatchUnit(
        id: h.id,
        name: h.name,
        type: DispatchUnitType.hireling,
      ),
  ];
}

DispatchResult? resolveEventDispatch({
  required ChartEvent event,
  required List<DispatchUnit> selected,
  Random? rng,
}) {
  final spec = event.dispatch;
  if (spec == null) return null;
  return resolveDispatch(spec: spec, units: selected, rng: rng);
}

TurnReward resolveEventRewards({
  required ChartEvent event,
  DispatchResult? dispatch,
  Random? rng,
}) {
  return rollTurnReward(
    event: event,
    success: dispatch == null ? true : dispatch.success,
    rng: rng,
  );
}

String rewardSummaryText(TurnReward reward) {
  final parts = <String>[
    for (final g in reward.materials)
      '${g.units} \u00d7 ${g.reward.name} (Rank ${g.effectiveRank.title})',
    if (reward.recruit == RewardKind.recruitDefender) 'a new defender',
    if (reward.recruit == RewardKind.recruitHireling) 'a new hireling',
  ];
  return parts.isEmpty ? 'none' : parts.join(', ');
}
