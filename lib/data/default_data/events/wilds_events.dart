// lib/data/default_data/events/wilds_events.dart
import 'package:maura_bastion_system/data/models/events/chart_event.dart';
import 'package:maura_bastion_system/data/models/events/chart_tier.dart';
import 'package:maura_bastion_system/data/models/events/dispatch.dart';
import 'package:maura_bastion_system/data/models/events/event_chart.dart';
import 'package:maura_bastion_system/data/models/events/reward_spec.dart';
import 'package:maura_bastion_system/data/models/rewards/reward.dart';

List<ChartEvent> wildsEvents() {
  return const [
    ChartEvent(
      id: 'wld_foraging_party',
      name: 'Foraging Party',
      chart: EventChart.wilds,
      tier: ChartTier.basic,
      description:
          'Your hirelings spent the turn combing the forest floors of Maura. Send them out again to see what the season has left behind.',
      dispatch: DispatchSpec(prompt: 'Send foragers into the forests of Maura', maxUnits: 4, dc: 12),
      reward: RewardSpec(
        kind: RewardKind.material,
        categories: [RewardCategory.herb],
        unitDice: UnitDice(1, 2),
      ),
    ),
    ChartEvent(
      id: 'wld_wolf_cull',
      name: 'Wolf Cull',
      chart: EventChart.wilds,
      tier: ChartTier.basic,
      description:
          'Wolves have grown bold near the pastures. Thin the pack and the hides are yours.',
      dispatch: DispatchSpec(prompt: 'Send defenders against the wolves', maxUnits: 2, dc: 10),
      reward: RewardSpec(
        kind: RewardKind.material,
        categories: [RewardCategory.creaturePart],
        unitDice: UnitDice(1, 1),
      ),
    ),
    ChartEvent(
      id: 'wld_berry_thicket',
      name: 'Berry Thicket',
      chart: EventChart.wilds,
      tier: ChartTier.basic,
      description:
          'A hireling found a thicket heavy with rare berries. No risk, no glory — just a basket to fill.',
      reward: RewardSpec(
        kind: RewardKind.material,
        categories: [RewardCategory.herb],
        unitDice: UnitDice(1, 2),
      ),
    ),
    ChartEvent(
      id: 'wld_tracker_signs',
      name: 'Tracker Signs',
      chart: EventChart.wilds,
      tier: ChartTier.basic,
      description:
          'Your hunters found fresh spoor and a half-eaten carcass. One clean kill was easy to claim.',
      reward: RewardSpec(
        kind: RewardKind.material,
        categories: [RewardCategory.meat],
        unitDice: UnitDice(1, 1),
      ),
    ),
    ChartEvent(
      id: 'wld_migrating_herd',
      name: 'The Migrating Herd',
      chart: EventChart.wilds,
      tier: ChartTier.skilled,
      description:
          'A great herd crosses the plains. Each hunter who lands a blow brings home meat and blood alike.',
      dispatch: DispatchSpec(prompt: 'Send hunters after the herd', maxUnits: 4, dc: 16),
      reward: RewardSpec(
        kind: RewardKind.material,
        categories: [RewardCategory.meat, RewardCategory.blood],
        picks: 2,
        unitDice: UnitDice(1, 2),
      ),
    ),
    ChartEvent(
      id: 'wld_rare_bloom',
      name: 'Rare Bloom Spotted',
      chart: EventChart.wilds,
      tier: ChartTier.skilled,
      description:
          'A ghost-pale flower blooms only in the dark. Harvest now and risk trampling it, or wait and risk losing it.',
      dispatch: DispatchSpec(prompt: 'Send gatherers to the bloom by night', maxUnits: 2, dc: 14),
      reward: RewardSpec(
        kind: RewardKind.material,
        categories: [RewardCategory.herb],
        unitDice: UnitDice(1, 2),
        note: 'Harvest at night or the bloom is lost',
      ),
    ),
    ChartEvent(
      id: 'wld_boar_hunt',
      name: 'Boar Hunt',
      chart: EventChart.wilds,
      tier: ChartTier.skilled,
      description:
          'A tusked boar has been goring livestock. Bring it down and the butchering is generous.',
      dispatch: DispatchSpec(prompt: 'Send hunters against the boar', maxUnits: 3, dc: 15),
      reward: RewardSpec(
        kind: RewardKind.material,
        categories: [RewardCategory.creaturePart, RewardCategory.meat],
        picks: 2,
        unitDice: UnitDice(1, 2),
      ),
    ),
    ChartEvent(
      id: 'wld_owlbear_den',
      name: 'Owlbear Den',
      chart: EventChart.wilds,
      tier: ChartTier.skilled,
      description:
          'An owlbear den has been found in the high crags. The mother is away — mostly.',
      dispatch: DispatchSpec(prompt: 'Raid the owlbear den', maxUnits: 3, dc: 15),
      reward: RewardSpec(
        kind: RewardKind.material,
        categories: [RewardCategory.creaturePart],
        unitDice: UnitDice(1, 2),
        note: 'Cubs may be tamed at DM discretion',
      ),
    ),
    ChartEvent(
      id: 'wld_great_stag',
      name: 'The Great Stag',
      chart: EventChart.wilds,
      tier: ChartTier.master,
      description:
          'The Great Stag of Maura haunts the deep woods. Each extra round of pursuit promises a finer trophy — and sharper antlers.',
      dispatch: DispatchSpec(prompt: 'Pursue the Great Stag', maxUnits: 3, dc: 18),
      reward: RewardSpec(
        kind: RewardKind.material,
        categories: [RewardCategory.creaturePart],
        unitDice: UnitDice(1, 2),
        note: 'Each additional pursuit round raises the reward rank',
      ),
    ),
    ChartEvent(
      id: 'wld_plains_fire',
      name: 'Plains Fire',
      chart: EventChart.wilds,
      tier: ChartTier.master,
      description:
          'Grassfire sweeps the plains and the beasts flee before it. Salvage what the smoke leaves behind.',
      dispatch: DispatchSpec(prompt: 'Salvage game from the fire line', maxUnits: 4, dc: 14),
      reward: RewardSpec(
        kind: RewardKind.material,
        categories: [RewardCategory.creaturePart, RewardCategory.meat],
        picks: 2,
        unitDice: UnitDice(1, 2),
      ),
    ),
    ChartEvent(
      id: 'wld_ancient_owl',
      name: 'The Ancient Owl',
      chart: EventChart.wilds,
      tier: ChartTier.master,
      description:
          'An owl the size of a horse has roosted in the old pines. Its feathers shed moonlight, and its nest hides herbs.',
      dispatch: DispatchSpec(prompt: 'Approach the Ancient Owl', maxUnits: 3, dc: 16),
      reward: RewardSpec(
        kind: RewardKind.material,
        categories: [RewardCategory.creaturePart, RewardCategory.herb],
        picks: 2,
        unitDice: UnitDice(1, 2),
      ),
    ),
    ChartEvent(
      id: 'wld_beast_of_maura',
      name: 'The Beast of Maura',
      chart: EventChart.wilds,
      tier: ChartTier.legend,
      description:
          'The Beast of Maura has woken. It is two turns of hunting, ruin, and terror — but a pelt of it is worth more than a small farm.',
      dispatch: DispatchSpec(prompt: 'Join the great hunt for the Beast', maxUnits: 4, dc: 20),
      reward: RewardSpec(
        kind: RewardKind.material,
        categories: [RewardCategory.creaturePart],
        unitDice: UnitDice(1, 1),
        note: 'Two-turn event: victory grants a permanent bastion title',
      ),
    ),
  ];
}
