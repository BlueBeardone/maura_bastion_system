// lib/data/default_data/events/arcane_events.dart
import 'package:maura_bastion_system/data/models/events/chart_event.dart';
import 'package:maura_bastion_system/data/models/events/chart_tier.dart';
import 'package:maura_bastion_system/data/models/events/dispatch.dart';
import 'package:maura_bastion_system/data/models/events/event_chart.dart';
import 'package:maura_bastion_system/data/models/events/reward_spec.dart';
import 'package:maura_bastion_system/data/models/rewards/reward.dart';

List<ChartEvent> arcaneEvents() {
  return const [
    ChartEvent(
      id: 'arc_planar_whisper',
      name: 'Planar Whisper',
      chart: EventChart.arcane,
      tier: ChartTier.basic,
      description:
          'The stable cat stared at an empty corner all night, and in the morning you know the name of a herb that should not grow here — but does.',
      reward: RewardSpec(
        kind: RewardKind.material,
        categories: [RewardCategory.herb],
        unitDice: UnitDice(1, 1),
        note: 'The whisper names a herb worth finding',
      ),
    ),
    ChartEvent(
      id: 'arc_moth_lights',
      name: 'Moth Lights',
      chart: EventChart.arcane,
      tier: ChartTier.basic,
      description:
          'Pale lights the size of hands drift over the hedgerows at dusk. Where they land, strange flora blooms.',
      dispatch: DispatchSpec(prompt: 'Follow the moth lights', maxUnits: 2, dc: 10),
      reward: RewardSpec(
        kind: RewardKind.material,
        categories: [RewardCategory.herb],
        unitDice: UnitDice(1, 1),
      ),
    ),
    ChartEvent(
      id: 'arc_fey_trinket',
      name: 'Fey Trinket',
      chart: EventChart.arcane,
      tier: ChartTier.basic,
      description:
          'A child of the bastion traded lunch for a little brass thing to a stranger with too many fingers. It appraises well.',
      reward: RewardSpec(
        note: 'The child\'s brass trinket becomes the bastion\'s favorite curiosity',
      ),
    ),
    ChartEvent(
      id: 'arc_cold_spot',
      name: 'The Cold Spot',
      chart: EventChart.arcane,
      tier: ChartTier.basic,
      description:
          'One flagstone in the east hall is cold enough to frost breath. The chaplain sprinkles salt on it and says to leave it be. For now.',
      reward: RewardSpec(
        note: 'Nothing happens — yet',
      ),
    ),
    ChartEvent(
      id: 'arc_fey_bargain',
      name: 'Fey Bargain',
      chart: EventChart.arcane,
      tier: ChartTier.skilled,
      description:
          'A voice under the garden offers a deal: one oddity of yours, one oddity of theirs. Their oddities are better. Their prices are odd.',
      reward: RewardSpec(
        kind: RewardKind.material,
        categories: [RewardCategory.weave],
        unitDice: UnitDice(1, 1),
        note: 'The price: one random material from your stores',
      ),
    ),
    ChartEvent(
      id: 'arc_ley_bloom',
      name: 'Ley Bloom',
      chart: EventChart.arcane,
      tier: ChartTier.skilled,
      description:
          'Where two ley lines cross in the orchard, the trees have flowered out of season. The blooms hum faintly in a chord.',
      dispatch: DispatchSpec(prompt: 'Gather the ley blooms', maxUnits: 3, dc: 13),
      reward: RewardSpec(
        kind: RewardKind.material,
        categories: [RewardCategory.herb],
        unitDice: UnitDice(1, 1),
      ),
    ),
    ChartEvent(
      id: 'arc_blink_dog',
      name: 'The Blink Dog',
      chart: EventChart.arcane,
      tier: ChartTier.skilled,
      description:
          'A blink dog has adopted the bastion: here, then gone, then here with a rabbit. It seems to intend to stay.',
      reward: RewardSpec(
        kind: RewardKind.recruitDefender,
        note: 'A blink dog adoptee (beast defender)',
      ),
    ),
    ChartEvent(
      id: 'arc_star_chart',
      name: 'The Star Chart',
      chart: EventChart.arcane,
      tier: ChartTier.skilled,
      description:
          'A chart fell from nowhere onto the scriptorium desk, inked in no constellation you know. A collector in town pays handsomely for the impossible.',
      reward: RewardSpec(
        note: 'Your hirelings sell the chart to a collector and toast the sale',
      ),
    ),
    ChartEvent(
      id: 'arc_star_fall',
      name: 'The Star Fall',
      chart: EventChart.arcane,
      tier: ChartTier.master,
      description:
          'A star came down in the night, trailing glass, and now half of Maura is racing to the crater. The flora growing in its light is the real prize.',
      dispatch: DispatchSpec(prompt: 'Race to the crater', maxUnits: 4, dc: 16),
      reward: RewardSpec(
        kind: RewardKind.material,
        categories: [RewardCategory.weave],
        unitDice: UnitDice(1, 1),
        note: 'Race the other claim-jumpers to the crater',
      ),
    ),
    ChartEvent(
      id: 'arc_dreaming_grove',
      name: 'The Dreaming Grove',
      chart: EventChart.arcane,
      tier: ChartTier.master,
      description:
          'Sleepers all across the bastion dream of the same grove, and those who walk there wake with loam under their nails and pockets full.',
      reward: RewardSpec(
        kind: RewardKind.material,
        categories: [RewardCategory.herb, RewardCategory.weave],
        picks: 2,
        unitDice: UnitDice(1, 1),
      ),
    ),
    ChartEvent(
      id: 'arc_planar_wandering',
      name: 'Planar Wandering',
      chart: EventChart.arcane,
      tier: ChartTier.master,
      description:
          'A lost creature of elsewhere stands in the cattle field, homesick and enormous. Guide it home and it will pay in things from beyond.',
      dispatch: DispatchSpec(prompt: 'Guide the wanderer home', maxUnits: 3, dc: 14),
      reward: RewardSpec(
        kind: RewardKind.material,
        categories: [RewardCategory.weave],
        unitDice: UnitDice(1, 1),
        note: 'Guide the lost planar home for a fee',
      ),
    ),
    ChartEvent(
      id: 'arc_door_in_hill',
      name: 'The Door in the Hill',
      chart: EventChart.arcane,
      tier: ChartTier.legend,
      description:
          'A door stands open in the hillside that was solid earth last week. Beyond it: a hall of everything anyone has ever lost, and a price for everything taken.',
      dispatch: DispatchSpec(prompt: 'Enter the door in the hill', maxUnits: 4, dc: 18),
      reward: RewardSpec(
        kind: RewardKind.material,
        categories: [RewardCategory.herb, RewardCategory.weave],
        unitDice: UnitDice(1, 1),
        note: 'Walk away and the door takes a point from your chart',
      ),
    ),
  ];
}
