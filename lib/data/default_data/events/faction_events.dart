// lib/data/default_data/events/faction_events.dart
import 'package:maura_bastion_system/data/models/events/chart_event.dart';
import 'package:maura_bastion_system/data/models/events/chart_tier.dart';
import 'package:maura_bastion_system/data/models/events/dispatch.dart';
import 'package:maura_bastion_system/data/models/events/event_chart.dart';
import 'package:maura_bastion_system/data/models/events/reward_spec.dart';
import 'package:maura_bastion_system/data/models/rewards/reward.dart';

/// Events for the four recurring factions: Skeletor's Crew, Nanoxy-chan,
/// The Twinsters, and The Whispers. Three per faction, two per chart, one
/// basic and one skilled each.
List<ChartEvent> factionEvents() {
  return const [
    // --- Skeletor's Crew ---
    ChartEvent(
      id: 'sc_well_wishes',
      name: "Skeletor's Well-Wishes",
      chart: EventChart.wilds,
      tier: ChartTier.basic,
      description:
          "Skeletor's Crew marched on a frontier hamlet to poison the well, as is traditional. They were waylaid by an argument about lunch, and by dawn the well ran clean and the hamlet's winter cough had cleared. Skeletor has logged the operation as a triumph.",
      reward: RewardSpec(
        kind: RewardKind.material,
        categories: [RewardCategory.herb],
        unitDice: UnitDice(1, 1),
        note: "The well's 'poison' cures what ails; the hamlet shares the harvest.",
      ),
    ),
    ChartEvent(
      id: 'sc_fair_contract',
      name: 'The Fair Contract',
      chart: EventChart.deeps,
      tier: ChartTier.skilled,
      description:
          "Skeletor's Crew has offered your deeps miners a written contract: fair wage, two meal breaks, and a pension of unspecified bones. The Guild calls it poaching. Your miners call it Tuesday, and read it twice.",
      reward: RewardSpec(
        kind: RewardKind.material,
        categories: [RewardCategory.metal],
        unitDice: UnitDice(1, 1),
        note: 'Well-paid miners dig deeper.',
      ),
    ),
    ChartEvent(
      id: 'sc_consideration',
      name: "The Crew's Consideration",
      chart: EventChart.hearth,
      tier: ChartTier.basic,
      description:
          "Skeletor's Crew arrived to besiege the bastion and, finding the hirelings overworked, laid down their arms and their grievance, insisted everyone sit down, and served a hot meal. Morale has not been this high since the siege that didn't happen.",
      reward: RewardSpec(
        note: 'The hirelings remember the Crew fondly; the Guild is furious.',
      ),
    ),

    // --- Nanoxy-chan ---
    ChartEvent(
      id: 'nan_roadside_set',
      name: 'The Roadside Set',
      chart: EventChart.tradeRoad,
      tier: ChartTier.basic,
      description:
          'Nanoxy-chan set down at the crossroads and played until the caravans forgot to move. When the music stopped, the drivers paid well above the toll and asked, all of them, whether they had been at the other crossing too.',
      reward: RewardSpec(
        kind: RewardKind.material,
        categories: [RewardCategory.weave],
        unitDice: UnitDice(1, 1),
        note: 'A full road and a generous purse.',
      ),
    ),
    ChartEvent(
      id: 'nan_almost_song',
      name: 'A Song You Almost Remember',
      chart: EventChart.arcane,
      tier: ChartTier.basic,
      description:
          'Nanoxy-chan played something that was not quite a song, and the listeners woke the next morning knowing the name of a herb that grows nowhere near here. None can hum the tune. All can find the plant.',
      reward: RewardSpec(
        kind: RewardKind.material,
        categories: [RewardCategory.herb],
        unitDice: UnitDice(1, 1),
        note: 'The tune is gone; the herb-name stays.',
      ),
    ),
    ChartEvent(
      id: 'nan_residency',
      name: 'The Residency',
      chart: EventChart.hearth,
      tier: ChartTier.skilled,
      description:
          'Nanoxy-chan has agreed to one night in your common room. The town has heard, and the town is coming. By midnight the rafters are full, the takings are excellent, and no one can quite recall watching them leave.',
      reward: RewardSpec(
        note: 'One night, a full house, and a legend nobody can pin down.',
      ),
    ),

    // --- The Twinsters ---
    ChartEvent(
      id: 'twn_walk',
      name: 'The Twinsters Walk',
      chart: EventChart.warMarch,
      tier: ChartTier.basic,
      description:
          'The Twinsters were seen walking the north road in step, which is all they ever do before something happens. The road emptied ahead of them and stayed empty behind. Count your people twice.',
      dispatch: DispatchSpec(
        prompt: "Shadow the Twinsters' walk",
        maxUnits: 2,
        dc: 9,
      ),
      reward: RewardSpec(
        note: 'You keep your people off the road and your walls manned',
        failureNote: 'A patrol is missing a member, and the Twinsters gained one.',
      ),
    ),
    ChartEvent(
      id: 'twn_treeline',
      name: 'Twinsters in the Treeline',
      chart: EventChart.wilds,
      tier: ChartTier.skilled,
      description:
          "A hunting party came back without a hunting party's worth of people. The Twinsters do not hunt for food. They hunt for the walk back, and they take their time.",
      dispatch: DispatchSpec(
        prompt: 'Recover the hunting party',
        maxUnits: 3,
        dc: 12,
      ),
      reward: RewardSpec(
        kind: RewardKind.material,
        categories: [RewardCategory.creaturePart],
        unitDice: UnitDice(1, 1),
        note: 'What the Twinsters left is still worth carrying home',
        failureNote: 'The treeline keeps what it took.',
      ),
    ),
    ChartEvent(
      id: 'twn_toll',
      name: "The Twinsters' Toll",
      chart: EventChart.tradeRoad,
      tier: ChartTier.skilled,
      description:
          'The Twinsters have set a toll on the road: everything, paid once, by everyone. The caravans are queuing to comply. Nobody has thought to ask what happens after.',
      dispatch: DispatchSpec(
        prompt: "Break the Twinsters' toll",
        maxUnits: 4,
        dc: 13,
      ),
      reward: RewardSpec(
        kind: RewardKind.material,
        categories: [RewardCategory.weave],
        unitDice: UnitDice(1, 1),
        note: 'The road reopens and the toll-box comes home with you',
        failureNote: 'The toll is paid, and the Twinsters remember who refused.',
      ),
    ),

    // --- The Whispers ---
    ChartEvent(
      id: 'wsp_deeps_ward',
      name: 'Something Below',
      chart: EventChart.deeps,
      tier: ChartTier.basic,
      description:
          "The Whispers descended into the deeps without asking permission and came back up without explaining. The knocking has stopped. They will not say what they warded, only that it was 'before your line, and after it.'",
      reward: RewardSpec(
        note: 'The deeps are quiet, and the Whispers leave no bill.',
      ),
    ),
    ChartEvent(
      id: 'wsp_unblinking',
      name: 'The Unblinking',
      chart: EventChart.warMarch,
      tier: ChartTier.skilled,
      description:
          'Something with too many eyes pressed against the edge of the world this week. The Whispers stood in front of it and did not blink. Your defenders held the line that the Whispers could not be everywhere at once.',
      dispatch: DispatchSpec(
        prompt: 'Hold the line with the Whispers',
        maxUnits: 4,
        dc: 13,
      ),
      reward: RewardSpec(
        kind: RewardKind.material,
        categories: [RewardCategory.creaturePart],
        unitDice: UnitDice(1, 1),
        note: 'The incursion is turned; what it left behind is stranger than it is useful',
        failureNote:
            'A door stays open a moment too long, and the Whispers pay for it.',
      ),
    ),
    ChartEvent(
      id: 'wsp_rift',
      name: 'The Rift and the Watchers',
      chart: EventChart.arcane,
      tier: ChartTier.skilled,
      description:
          'A seam opened in the air above the orchard, and things that should not be on this side began to lean through it. The Whispers arrived before your hirelings could decide what to call it, and shut it like a book.',
      dispatch: DispatchSpec(
        prompt: 'Assist the Whispers at the rift',
        maxUnits: 3,
        dc: 12,
      ),
      reward: RewardSpec(
        kind: RewardKind.material,
        categories: [RewardCategory.weave],
        unitDice: UnitDice(1, 1),
        note: 'The seam closes; the Whispers nod once, which is their whole vocabulary',
        failureNote: 'The seam closes early, and not all of it closes.',
      ),
    ),
  ];
}
