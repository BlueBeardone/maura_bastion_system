import 'dart:math';

import 'package:maura_bastion_system/data/models/bastion/individual_bastion_event.dart';
import 'package:maura_bastion_system/data/models/bastion/table.dart';

/// Roll on the following table (1d100) for your bastion, fleshing out the details.
List<IndividualBastionEvent> getIndividualBastionEventsCatalog() {
  return [
    IndividualBastionEvent(
      id: 'ibe_quiet_week',
      name: 'Quiet Week',
      rollMin: 1,
      rollMax: 30,
      description: 'Nothing happens this turn.',
    ),
    IndividualBastionEvent(
      id: 'ibe_something_found',
      name: 'Something Found',
      rollMin: 31,
      rollMax: 60,
      description:
          '''Here you can choose between these two options:

Gatherers: Some of your Hirelings spent the Bastion Turn going through the forests of Maura looking for materials. Roll on the reward table (logging or herb).

Hunters: Some of your Defenders spent the Bastion Turn going through the forests of Maura removing bandits and wolves. Roll on the reward table for the reward they got (hunting or mining).''',
    ),
    IndividualBastionEvent(
      id: 'ibe_animal_rescue',
      name: 'Animal Rescue',
      rollMin: 61,
      rollMax: 62,
      description:
          'One of your hirelings finds a wild animal. If you can cast a healing spell or succeed on a DC 15 Medicine Check, you save the animal. If saved, the wild animal joins as an extra beast Defender until the end of the next Attack against you. If you pass a DC 18 Animal Handling Check, you convince the animal to remain until it dies.',
    ),
    IndividualBastionEvent(
      id: 'ibe_criminal_hireling',
      name: 'Criminal Hireling',
      rollMin: 63,
      rollMax: 65,
      description:
          '''One of your hirelings is discovered to have a criminal past. You have three options:

Pay the Fine: You can keep the hireling by paying a fine of 1d6 x 10 GP per rank.

Allow the Arrest: The hireling is removed from the Bastion.

Persuade: You may attempt a DC 15 Persuasion check to keep your hireling. If you fail, pay the fine.''',
    ),
    IndividualBastionEvent(
      id: 'ibe_duel',
      name: 'Duel',
      rollMin: 66,
      rollMax: 68,
      description:
          'A wandering knight arrives at your Bastion. He challenges a Regular Bastion Defender! Roll as if the knight were an attacker. If your defender "survives" three rolls without "dying", you win. If you defeat the champion, he joins your Bastion as a knight. He takes care of his own accommodations.',
    ),
    IndividualBastionEvent(
      id: 'ibe_guest',
      name: 'Guest',
      rollMin: 69,
      rollMax: 71,
      description:
          'A Notable guest arrives at your Bastion. Roll on the table below to determine who they are:',
      table: FacilityTable(table: [
        ['d4', 'Guest', 'Description'],
        [
          '1',
          'Renowned Builder',
          'Helps out on your next Bastion construction turn. The next time you would advance the timer, advance it by 1 additional turn.'
        ],
        [
          '2',
          'Seeking Sanctuary',
          'They may stay for a turn and upon leaving they will attempt to give you a Reward from the Reward Table as gratitude.'
        ],
        [
          '3',
          'Mercenary Guest',
          'This guest stays until you send them away or they are killed. They provide you with one additional Bastion Defender and do not require housing.'
        ],
        [
          '4',
          'Friendly Monster',
          'The monster stays until it has defended your Bastion once or until you send it away. If your Bastion is attacked or sieged while the monster is staying, it will Repel the attack, preventing all Bastion Defenders from being lost.'
        ],
      ]),
    ),
    IndividualBastionEvent(
      id: 'ibe_request_for_aid',
      name: 'Request for Aid',
      rollMin: 72,
      rollMax: 74,
      description:
          'Your Bastion is called upon to aid a local Notable. If you choose to help, you can send up to 4 Bastion Defenders and/or Hirelings per rank above D. Roll 1d6 for each defender/hireling sent. If the total of all rolls is 12 or more per Rank above D (meets it, beats it), the problem is solved and you can roll on the Reward table.',
    ),
    IndividualBastionEvent(
      id: 'ibe_ronin',
      name: 'Ronin',
      rollMin: 75,
      rollMax: 77,
      description:
          'A warrior arrives at your Bastion. He offers you his service as a Knight for 250 GP, or if you best him in a game he will join you for free. Roll 3d6 six times. If you roll three 6s you win. If you roll three 1s you lose. If you lose, you can still hire the Knight for 250 GP.',
    ),
    IndividualBastionEvent(
      id: 'ibe_sellswords',
      name: 'Sellswords',
      rollMin: 78,
      rollMax: 82,
      description:
          'Eight defenders arrive at your gates. You can take as many as you can. Alternatively, two of them have the skills to be hired as hirelings for free.',
    ),
    IndividualBastionEvent(
      id: 'ibe_surprise_attack',
      name: 'Surprise Attack!',
      rollMin: 83,
      rollMax: 85,
      description:
          '''Your Bastion is under attack by an amount of Maura's enemies. The maximum number of attackers for D-Rank and C-Rank is 6 and 18 respectively. You can use siege weapons. If you successfully defend against an attacking force, roll once on the Reward table. Repelling the attack by destroying your Battlements or other similar defenses yields no rewards.

Roll a d8 on the table below for the number of attackers per Rank above D.''',
      table: FacilityTable(table: [
        ['d8', '# of Attackers per Rank above D'],
        ['1', '2'],
        ['2', '4'],
        ['3', '6'],
        ['4', '8'],
        ['5', '10'],
        ['6', '12'],
        ['7', '14'],
        ['8', '16'],
      ]),
    ),
    IndividualBastionEvent(
      id: 'ibe_vermin_infestation',
      name: 'Vermin Infestation',
      rollMin: 86,
      rollMax: 89,
      description:
          'All cooking and laboratories are shut down until vermin are exterminated — either pay 1d4 x 10 GP per Rank or send up to 4 Bastion Defenders. Roll 1d6 for defenders/knights and 2d6 for beasts, and tally the results together. If you roll 10 or more, you succeed. If you fail, you must pay the price stated.',
    ),
    IndividualBastionEvent(
      id: 'ibe_wandering_professionals',
      name: 'Wandering Professionals',
      rollMin: 90,
      rollMax: 93,
      description:
          'Visitors arrive at your Bastion. They see your Bastion and one of them asks to become one of your hirelings for free!',
    ),
    IndividualBastionEvent(
      id: 'ibe_tragic_accident',
      name: 'Tragic Accident',
      rollMin: 94,
      rollMax: 98,
      description:
          "There's a tragic accident in one of your facilities, chosen at random. The facility remains closed until the beginning of your next Bastion turn.",
    ),
    IndividualBastionEvent(
      id: 'ibe_treasure',
      name: 'Treasure',
      rollMin: 99,
      rollMax: 100,
      description:
          'One of your hirelings gifts you a treasure. Roll on the table below. This is not the Reward table for other events. Value in Diamonds.',
      table: FacilityTable(table: [
        ['1d100', 'Treasure'],
        ['01 - 40', '25 GP'],
        ['41 - 63', '125 GP'],
        ['64 - 73', '150 GP'],
        ['76 - 90', '150 GP per rank'],
        ['91 - 98', '200 GP per rank'],
        ['99 - 00', '250 GP per rank'],
      ]),
    ),
  ];
}

/// Rolls 1d100 and returns the matching individual Bastion event.
IndividualBastionEvent rollIndividualBastionEvent({Random? rng}) {
  final events = getIndividualBastionEventsCatalog();
  assert(
    events.first.rollMin == 1 && events.last.rollMax == 100,
    'Individual event catalog must cover rolls 1-100',
  );
  final roll = (rng ?? Random()).nextInt(100) + 1;
  return events.firstWhere((e) => e.matchesRoll(roll));
}
