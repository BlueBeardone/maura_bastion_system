// lib/data/default_data/events/deeps_events.dart
import 'package:maura_bastion_system/data/models/events/chart_event.dart';
import 'package:maura_bastion_system/data/models/events/chart_tier.dart';
import 'package:maura_bastion_system/data/models/events/dispatch.dart';
import 'package:maura_bastion_system/data/models/events/event_chart.dart';
import 'package:maura_bastion_system/data/models/events/reward_spec.dart';
import 'package:maura_bastion_system/data/models/rewards/reward.dart';

List<ChartEvent> deepsEvents() {
  return const [
    ChartEvent(
      id: 'dps_seam_strike',
      name: 'Seam Strike',
      chart: EventChart.deeps,
      tier: ChartTier.basic,
      description:
          'The picks have struck a promising seam. Work it before the shift ends.',
      dispatch: DispatchSpec(prompt: 'Work the new seam', maxUnits: 4, dc: 8),
      reward: RewardSpec(
        kind: RewardKind.material,
        categories: [RewardCategory.metal, RewardCategory.stone],
        unitDice: UnitDice(1, 1),
      ),
    ),
    ChartEvent(
      id: 'dps_quarry_flakes',
      name: 'Quarry Flakes',
      chart: EventChart.deeps,
      tier: ChartTier.basic,
      description:
          'The quarry waste piles still glint when the light is right. A slow afternoon of sorting yields a little something.',
      reward: RewardSpec(
        kind: RewardKind.material,
        categories: [RewardCategory.stone],
        unitDice: UnitDice(1, 1),
      ),
    ),
    ChartEvent(
      id: 'dps_prospector_rumors',
      name: 'Prospector Rumors',
      chart: EventChart.deeps,
      tier: ChartTier.basic,
      description:
          'A prospector at the tavern sold you a map for two coppers. Half of what he said was probably true.',
      reward: RewardSpec(
        kind: RewardKind.material,
        categories: [RewardCategory.stone],
        unitDice: UnitDice(1, 1),
        note: 'Half the tales are false',
      ),
    ),
    ChartEvent(
      id: 'dps_shoring_up',
      name: 'Shoring Up',
      chart: EventChart.deeps,
      tier: ChartTier.basic,
      description:
          'The lower galleries need new timbers. Good honest work, and the old beams can be reclaimed and sold.',
      dispatch: DispatchSpec(prompt: 'Send crews to shore the galleries', maxUnits: 3, dc: 8),
      reward: RewardSpec(
        kind: RewardKind.material,
        categories: [RewardCategory.metal],
        unitDice: UnitDice(1, 1),
        note: 'Support beams reclaimed',
      ),
    ),
    ChartEvent(
      id: 'dps_collapsed_shaft',
      name: 'Collapsed Shaft',
      chart: EventChart.deeps,
      tier: ChartTier.skilled,
      description:
          'The main shaft has caved. Dig for the trapped crew, or salvage the exposed seam while it lasts — either pays.',
      dispatch: DispatchSpec(prompt: 'Answer the collapse', maxUnits: 4, dc: 12),
      reward: RewardSpec(
        kind: RewardKind.material,
        categories: [RewardCategory.metal, RewardCategory.stone],
        picks: 2,
        unitDice: UnitDice(1, 1),
        note: 'Rescue the crew or salvage the seam',
      ),
    ),
    ChartEvent(
      id: 'dps_glowing_geode',
      name: 'Glowing Geode',
      chart: EventChart.deeps,
      tier: ChartTier.skilled,
      description:
          'A blast opened a hollow lined with softly glowing crystal. No work needed beyond a steady hand and a chisel.',
      reward: RewardSpec(
        kind: RewardKind.material,
        categories: [RewardCategory.stone],
        unitDice: UnitDice(1, 1),
      ),
    ),
    ChartEvent(
      id: 'dps_deep_vein',
      name: 'Deep Vein',
      chart: EventChart.deeps,
      tier: ChartTier.skilled,
      description:
          'The vein keeps going where the maps stop. Follow it down; the ore gets richer and the air gets worse.',
      dispatch: DispatchSpec(prompt: 'Follow the vein downward', maxUnits: 4, dc: 11),
      reward: RewardSpec(
        kind: RewardKind.material,
        categories: [RewardCategory.metal],
        unitDice: UnitDice(1, 1),
      ),
    ),
    ChartEvent(
      id: 'dps_abandoned_mine',
      name: 'The Abandoned Mine',
      chart: EventChart.deeps,
      tier: ChartTier.skilled,
      description:
          'The old mine was sealed a generation ago — for the collapse, they said. The equipment left behind was worth sealing it for.',
      dispatch: DispatchSpec(prompt: 'Explore the abandoned mine', maxUnits: 2, dc: 10),
      reward: RewardSpec(
        kind: RewardKind.material,
        categories: [RewardCategory.metal, RewardCategory.stone],
        unitDice: UnitDice(1, 1),
        note: 'The old works are not abandoned enough',
      ),
    ),
    ChartEvent(
      id: 'dps_glimmerdeep',
      name: 'The Glimmerdeep',
      chart: EventChart.deeps,
      tier: ChartTier.master,
      description:
          'Below the water table lies the Glimmerdeep, where the stone itself glitters. Every step deeper is richer — and one step too far is your last.',
      dispatch: DispatchSpec(prompt: 'Descend into the Glimmerdeep', maxUnits: 4, dc: 14),
      reward: RewardSpec(
        kind: RewardKind.material,
        categories: [RewardCategory.metal, RewardCategory.stone],
        picks: 2,
        unitDice: UnitDice(1, 1),
        note: 'Push one step deeper for a better rank — or the tunnel collapses',
      ),
    ),
    ChartEvent(
      id: 'dps_crystal_cavern',
      name: 'Crystal Cavern',
      chart: EventChart.deeps,
      tier: ChartTier.master,
      description:
          'A cavern of untouched crystal, found by a cave-in nobody survived. It will keep. Probably.',
      reward: RewardSpec(
        kind: RewardKind.material,
        categories: [RewardCategory.stone],
        unitDice: UnitDice(1, 1),
      ),
    ),
    ChartEvent(
      id: 'dps_waking_golem',
      name: 'The Waking Golem',
      chart: EventChart.deeps,
      tier: ChartTier.master,
      description:
          'The miners have uncovered a golem of living stone, dormant so far. Its body is a fortune in raw ore — if it stays asleep.',
      dispatch: DispatchSpec(prompt: 'Dismantle the sleeping golem', maxUnits: 3, dc: 13),
      reward: RewardSpec(
        kind: RewardKind.material,
        categories: [RewardCategory.metal],
        unitDice: UnitDice(1, 1),
        note: 'It wakes if you fail',
      ),
    ),
    ChartEvent(
      id: 'dps_heart_of_mountain',
      name: 'Heart of the Mountain',
      chart: EventChart.deeps,
      tier: ChartTier.legend,
      description:
          'Every miner dreams of it once: a single stone at the mountain\'s core, older than the world above. Bring it up and the deeps will remember your name.',
      dispatch: DispatchSpec(prompt: 'Descend to the mountain\'s heart', maxUnits: 4, dc: 16),
      reward: RewardSpec(
        kind: RewardKind.material,
        categories: [RewardCategory.stone],
        unitDice: UnitDice(1, 1),
        note: 'Permanent: +1 to all Deeps dispatch totals',
      ),
    ),
  ];
}
