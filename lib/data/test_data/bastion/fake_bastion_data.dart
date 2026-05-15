import 'package:maura_bastion_system/data/enums/rank.dart';
import 'package:maura_bastion_system/data/models/bastion/bastion.dart';
import 'package:maura_bastion_system/data/models/bastion/facility.dart';
import 'package:maura_bastion_system/data/models/bastion/table.dart';

List<Bastion> getFakeBastions() {
  return [
    Bastion(
      id: 'bastion_1',
      name: 'Castle Bastion',
      description: 'A sturdy bastion built to defend the surrounding lands and house skilled adventurers.',
      imgUrl: 'https://example.com/images/castle_bastion.jpg',
      facilities: [
        Facility(
          id: 'facility_1',
          name: 'Armory',
          rank: Rank.A,
          hirelingAmount: 12,
          description: 'A place to store weapons, armor, and supplies for the castle guards.',
          table: FacilityTable(table: [
            ['Item', 'Level', 'Stock'],
            ['Longsword', 'A', '15'],
            ['Heavy Armor', 'B', '8'],
          ]),
        ),
        Facility(
          id: 'facility_2',
          name: 'Tactical Library',
          rank: Rank.B,
          hirelingAmount: 5,
          description: 'A quiet space where strategists study enemy movements and train new officers.',
          table: null,
        ),
      ],
    ),
    Bastion(
      id: 'bastion_2',
      name: 'Harbor Bastion',
      description: 'A maritime bastion that protects the harbor and supports shipwrights and naval scouts.',
      imgUrl: 'https://example.com/images/harbor_bastion.jpg',
      facilities: [
        Facility(
          id: 'facility_3',
          name: 'Shipwright Yard',
          rank: Rank.B,
          hirelingAmount: 9,
          description: 'Crafts and repairs vessels for patrols, trade, and coastal defense.',
          table: FacilityTable(table: [
            ['Ship Type', 'Build Time', 'Crew'],
            ['Sloop', '3 days', '6'],
            ['Brigantine', '7 days', '18'],
          ]),
        ),
        Facility(
          id: 'facility_4',
          name: 'Lookout Tower',
          rank: Rank.C,
          hirelingAmount: 4,
          description: 'A tall tower with a wide view over the bay and incoming vessels.',
          table: null,
        ),
      ],
    ),
    Bastion(
      id: 'bastion_3',
      name: 'Forest Bastion',
      description: 'Hidden in the woods, this bastion supports ranger patrols and magical scouts.',
      imgUrl: null,
      facilities: [
        Facility(
          id: 'facility_5',
          name: 'Ranger Stables',
          rank: Rank.C,
          hirelingAmount: 6,
          description: 'Keeps mounts and hunting beasts ready for rapid forest response.',
          table: null,
        ),
        Facility(
          id: 'facility_6',
          name: 'Herbal Conservatory',
          rank: Rank.A,
          hirelingAmount: 8,
          description: 'Grows rare herbs and prepares magical salves for field medics.',
          table: FacilityTable(table: [
            ['Herb', 'Effect', 'Yield'],
            ['Silverleaf', 'Healing', '12'],
            ['Nightbloom', 'Stealth', '7'],
          ]),
        ),
      ],
    ),
  ];
}
