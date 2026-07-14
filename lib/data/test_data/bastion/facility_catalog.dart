import 'package:maura_bastion_system/data/enums/rank.dart';
import 'package:maura_bastion_system/data/models/bastion/facility.dart';
import 'package:maura_bastion_system/data/models/bastion/table.dart';

List<Facility> getFacilityCatalog() {
  return [
    // Rank D facilities
    Facility(
      id: 'cat_armory_basic',
      name: 'Basic Armory',
      rank: Rank.D,
      description: 'A modest workshop capable of maintaining basic arms and armor for a small garrison.',
      constructionTurns: 1,
      cost: 300,
    ),
    Facility(
      id: 'cat_storage_shed',
      name: 'Storage Shed',
      rank: Rank.D,
      description: 'A simple timber shed for storing provisions, tools, and spare equipment.',
      constructionTurns: 1,
      cost: 200,
    ),

    // Rank C facilities
    Facility(
      id: 'cat_barracks',
      name: 'Barracks',
      rank: Rank.C,
      description: 'Sleeping quarters for guards and soldiers, with a small mess hall attached.',
      constructionTurns: 2,
      cost: 800,
      minimumRequiredHirelings: 2,
    ),
    Facility(
      id: 'cat_stable',
      name: 'Stables',
      rank: Rank.C,
      description: 'Houses mounts and pack animals, with a small forge for shoeing.',
      constructionTurns: 2,
      cost: 700,
      minimumRequiredHirelings: 1,
    ),

    // Rank B facilities
    Facility(
      id: 'cat_alchemy_lab',
      name: 'Alchemy Laboratory',
      rank: Rank.B,
      description: 'A well-ventilated workspace for brewing potions, salves, and alchemical reagents.',
      constructionTurns: 4,
      cost: 2200,
      minimumRequiredHirelings: 2,
      table: FacilityTable(table: [
        ['Potion', 'Effect', 'Stock'],
        ['Healing Draught', 'Restore 2d4 HP', '8'],
        ['Vitality Tonic', 'Advantage on CON saves', '3'],
      ]),
    ),
    Facility(
      id: 'cat_war_room',
      name: 'War Room',
      rank: Rank.B,
      description: 'A secure chamber with maps, markers, and a strategy table for planning campaigns.',
      constructionTurns: 3,
      cost: 1800,
      minimumRequiredHirelings: 1,
    ),

    // Rank A facilities
    Facility(
      id: 'cat_grand_library',
      name: 'Grand Library',
      rank: Rank.A,
      description: 'A towering archive of ancient tomes, scrolls, and forbidden knowledge from across the realm.',
      constructionTurns: 6,
      cost: 4000,
      minimumRequiredHirelings: 3,
      table: FacilityTable(table: [
        ['Section', 'Volumes', 'Access'],
        ['Arcane Lore', '340', 'Restricted'],
        ['History', '520', 'Open'],
        ['Tactics', '210', 'Open'],
      ]),
    ),
    Facility(
      id: 'cat_grand_temple',
      name: 'Grand Temple',
      rank: Rank.A,
      description: 'A sanctified hall with towering altars, capable of hosting major ceremonies and divine rituals.',
      constructionTurns: 5,
      cost: 3500,
      minimumRequiredHirelings: 3,
    ),

    // Rank S facilities
    Facility(
      id: 'cat_arcane_sanctum',
      name: 'Arcane Sanctum',
      rank: Rank.S,
      description: 'A nexus of magical energy woven into the bastion itself. Teleportation circles, scrying pools, and warded vaults for artifacts of immense power.',
      constructionTurns: 10,
      cost: 10000,
      minimumRequiredHirelings: 5,
    ),
  ];
}
