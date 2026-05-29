import 'package:maura_bastion_system/data/enums/rank.dart';
import 'package:maura_bastion_system/data/models/bastion/bastion.dart';
import 'package:maura_bastion_system/data/models/bastion/facility.dart';
import 'package:maura_bastion_system/data/models/bastion/table.dart';

const String userBastionId = 'bastion_1';

List<Bastion> getFakeBastions() {
  final bastions = [
    Bastion(
      id: userBastionId,
      name: 'Aurelian Keep',
      description: 'The user bastion sits at the heart of the realm, centered on defense, morale, and disciplined growth.',
      imgUrl: 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?auto=format&fit=crop&w=1200&q=80',
      facilities: [
        Facility(
          id: 'facility_1',
          name: 'Grand Armory',
          rank: Rank.A,
          hirelingAmount: 14,
          description: 'A reinforced workshop holding siege kits, patrol gear, and fortified supplies for the castle guard.',
          table: FacilityTable(table: [
            ['Item', 'Level', 'Stock'],
            ['Longsword', 'A', '18'],
            ['Plate Armor', 'B', '11'],
          ]),
        ),
        Facility(
          id: 'facility_2',
          name: 'Scholar Hall',
          rank: Rank.B,
          hirelingAmount: 7,
          description: 'A quiet study chamber where strategists refine training, reports, and battle plans.',
          table: null,
        ),
      ],
    ),
    Bastion(
      id: 'bastion_2',
      name: 'Briarwatch Garrison',
      description: 'A rugged outpost built to monitor the wilds and protect trade routes against northern incursions.',
      imgUrl: 'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?auto=format&fit=crop&w=1200&q=80',
      facilities: [
        Facility(
          id: 'facility_3',
          name: 'Scout Tower',
          rank: Rank.B,
          hirelingAmount: 9,
          description: 'A raised tower with signal fires and scout cots to track movement across the frontier.',
          table: FacilityTable(table: [
            ['Signal', 'Range', 'Crew'],
            ['Flare', '1 day', '4'],
            ['Courier', '2 days', '6'],
          ]),
        ),
        Facility(
          id: 'facility_4',
          name: 'Ranger Stables',
          rank: Rank.C,
          hirelingAmount: 5,
          description: 'Provides trained mounts and field riders for quick response through dense woods.',
          table: null,
        ),
      ],
    ),
    Bastion(
      id: 'bastion_3',
      name: 'Crimson Harbor',
      description: 'A coastal bastion designed for fleet coordination, port security, and harbor expansions.',
      imgUrl: 'https://images.unsplash.com/photo-1454789476662-53eb23ba5907?auto=format&fit=crop&w=1200&q=80',
      facilities: [
        Facility(
          id: 'facility_5',
          name: 'Shipwright Yard',
          rank: Rank.B,
          hirelingAmount: 10,
          description: 'Crafts and repairs vessels for patrols, trade, and coastal defense.',
          table: FacilityTable(table: [
            ['Ship Type', 'Build Time', 'Crew'],
            ['Sloop', '3 days', '6'],
            ['Brigantine', '7 days', '18'],
          ]),
        ),
        Facility(
          id: 'facility_6',
          name: 'Lookout Bell',
          rank: Rank.C,
          hirelingAmount: 4,
          description: 'Stores signal bells and harbor watchers for incoming ships and nighttime patrols.',
          table: null,
        ),
      ],
    ),
    Bastion(
      id: 'bastion_4',
      name: 'Moonshadow Watch',
      description: 'A quiet mountain stronghold with magical outlooks, scout patrols, and training grounds for elite rangers.',
      imgUrl: null,
      facilities: [
        Facility(
          id: 'facility_7',
          name: 'Starward Observatory',
          rank: Rank.A,
          hirelingAmount: 6,
          description: 'Tracks celestial patterns, weather changes, and long-range scouting reports.',
          table: null,
        ),
        Facility(
          id: 'facility_8',
          name: 'Herbal Conservatory',
          rank: Rank.A,
          hirelingAmount: 8,
          description: 'Grows rare herbs and prepares magical salves for field medics and scouts.',
          table: FacilityTable(table: [
            ['Herb', 'Effect', 'Yield'],
            ['Silverleaf', 'Healing', '12'],
            ['Nightbloom', 'Stealth', '7'],
          ]),
        ),
      ],
    ),
    Bastion(
      id: 'bastion_5',
      name: 'Stonegate Bastion',
      description: 'An old stone fortress restored for merchants, engineers, and field medics who keep the roads secure.',
      imgUrl: 'https://images.unsplash.com/photo-1517816743773-6e0fd518b4a6?auto=format&fit=crop&w=1200&q=80',
      facilities: [
        Facility(
          id: 'facility_9',
          name: 'Foundry Hall',
          rank: Rank.B,
          hirelingAmount: 11,
          description: 'Turns ore into tools, armor, and construction materials for rapid repairs and expansion.',
          table: null,
        ),
        Facility(
          id: 'facility_10',
          name: 'Mercantile Market',
          rank: Rank.C,
          hirelingAmount: 6,
          description: 'Trades supplies, provisions, and rare goods with the surrounding villages and caravans.',
          table: null,
        ),
      ],
    ),
  ];

  bastions.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  return bastions;
}
