import 'package:maura_bastion_system/data/enums/rank.dart';
import 'package:maura_bastion_system/data/models/bastion/branch_upgrade.dart';
import 'package:maura_bastion_system/data/models/bastion/facility.dart';
import 'package:maura_bastion_system/data/models/bastion/table.dart';

const Map<Rank, int> baseCostByRank = {
  Rank.D: 600,
  Rank.C: 1500,
  Rank.B: 4500,
  Rank.A: 9000,
  Rank.S: 20000,
};

const Set<String> upgradeableFacilityIds = {
  'cat_barracks',
  'cat_battlements',
  'cat_bedroom',
  'cat_dining_room',
  'cat_kitchen',
  'cat_well_room',
  'cat_siege_engine',
  'cat_library',
  'cat_sanctuary',
  'cat_stables',
  'cat_trading_hub',
  'cat_training_area',
  'cat_observatory',
};

int facilityUpgradeCost(Rank rank) {
  final next = rank.next;
  if (next == null) return 0;
  return baseCostByRank[next]! - baseCostByRank[rank]!;
}

const Map<String, BranchUpgrade> branchUpgradesByFacilityId = {
  'cat_kitchen': BranchUpgrade(
    id: 'bru_industrial_kitchen',
    facilityId: 'cat_kitchen',
    name: 'Industrial Kitchen',
    cost: 500,
    description:
        'Pay 500 GP. The amount of hirelings your kitchen can hold increases to 3. While you have three hirelings in the kitchen, when you successfully pass a DC to craft a treat in the kitchen, you get 1d6 extra treats!',
    kind: BranchUpgradeKind.oneTime,
    hirelingCapacity: 3,
  ),
  'cat_laboratory': BranchUpgrade(
    id: 'bru_industrial_laboratory',
    facilityId: 'cat_laboratory',
    name: 'Industrial Laboratory',
    cost: 4000,
    description:
        'Pay 4,000 GP. The amount of hirelings your Laboratory can hold increases to 2. While you have two hirelings in the laboratory, when you successfully pass a DC to craft a potion, poison, or dilution, you have a 20% chance to gain a double. Increase this chance by 10% for each Laboratory rank above C.',
    kind: BranchUpgradeKind.oneTime,
    hirelingCapacity: 2,
  ),
  'cat_library': BranchUpgrade(
    id: 'bru_vault_of_knowledge',
    facilityId: 'cat_library',
    name: 'Vault of Knowledge',
    cost: 1000,
    description:
        'Pay 1,000 GP to gain new and accurate information, and your bonus to a skill increases to +3 until the end of the Bastion Turn.',
    kind: BranchUpgradeKind.oneTime,
  ),
  'cat_trading_hub': BranchUpgrade(
    id: 'bru_specialized_shelving',
    facilityId: 'cat_trading_hub',
    name: 'Specialized Shelving',
    cost: 2000,
    description:
        'Pay 2,000 GP to increase the total value of what you can procure by 500 GP per rank. You also unlock additional items to buy.',
    kind: BranchUpgradeKind.oneTime,
  ),
  'cat_workshop': BranchUpgrade(
    id: 'bru_mastercraft_workshop',
    facilityId: 'cat_workshop',
    name: 'Mastercraft Workshop',
    cost: 4000,
    description:
        'Pay 4,000 GP. The amount of hirelings your Workshop can hold increases to 2. While you have two hirelings in the Workshop, the Individual Bastion Turn Order also adds 1d4 to your crafting roll. This does not stack with Flash of Genius or Built for Success.',
    kind: BranchUpgradeKind.oneTime,
    hirelingCapacity: 2,
  ),
  'cat_pub': BranchUpgrade(
    id: 'bru_pub_of_legend',
    facilityId: 'cat_pub',
    name: 'Pub of Legend',
    cost: 2000,
    description:
        'Pay 2,000 GP each Individual Bastion Turn to increase your Hireling count to 4. While you have at least 4 hirelings working in the pub, you can have another pub special.',
    kind: BranchUpgradeKind.perTurn,
    hirelingCapacity: 4,
  ),
  'cat_theatre': BranchUpgrade(
    id: 'bru_stage_enhancements',
    facilityId: 'cat_theatre',
    name: 'Stage Enhancements',
    costByRank: {Rank.B: 750, Rank.A: 1000, Rank.S: 1500},
    description:
        'Pay the amount of gold listed in the table every time you make a play for players, to increase the Performance Token. You can pay up to your Facility Rank from the table.',
    kind: BranchUpgradeKind.perUse,
  ),
};

BranchUpgrade? branchUpgradeFor(String facilityId) =>
    branchUpgradesByFacilityId[facilityId];

extension FacilityBranchUpgradeX on Facility {
  BranchUpgrade? get branchUpgrade {
    if (branchUpgradeId == null) return null;
    for (final upgrade in branchUpgradesByFacilityId.values) {
      if (upgrade.id == branchUpgradeId) return upgrade;
    }
    return null;
  }

  bool get hasActiveBranchUpgrade {
    final upgrade = branchUpgrade;
    if (upgrade == null) return false;
    if (upgrade.kind == BranchUpgradeKind.perTurn && !branchUpgradeActive) {
      return false;
    }
    return true;
  }

  int get hirelingCapacity {
    final upgrade = branchUpgrade;
    if (!hasActiveBranchUpgrade || upgrade!.hirelingCapacity == null) {
      return minimumRequiredHirelings;
    }
    return upgrade.hirelingCapacity!;
  }
}

List<Facility> getFacilityCatalog() {
  return [
    // ===================== Rank D =====================
    Facility(
      id: 'cat_barracks',
      name: 'Barracks',
      rank: Rank.D,
      description: '''A Barracks is required to house Bastion Defenders.
A Barracks houses up to 4 Bastion Defenders per rank above E Rank.

Individual Bastion Turn Order: Each Individual Bastion Turn you issue the Recruit order to this facility, up to four Bastion Defenders are recruited.''',
      constructionTurns: 2,
      cost: 600,
    ),
    Facility(
      id: 'cat_battlements',
      name: 'Battlements',
      rank: Rank.D,
      description: '''Repel Attackers: You can sacrifice your Battlements to win a Bastion combat. You will need to Rebuild your walls.

Reduce Defender Death: For every 2 ranks above D-Rank you reduce the death threshold by 1 for Bastion Defender Dice (Minimum 1) while defending your Bastion.

Individual Bastion Turn Order: It costs 300 GP per rank above C (D-Rank is free) to rebuild the Battlements. Takes no time.''',
      constructionTurns: 2,
      cost: 600,
    ),
    Facility(
      id: 'cat_bedroom',
      name: 'Bedroom',
      rank: Rank.D,
      description:
          'If you long rest in your Bastion, gain 1d4 + Constitution Modifier as Max HP. For each rank the room is above D, increase the Max HP you gain by 1d4.',
      constructionTurns: 2,
      cost: 600,
    ),
    Facility(
      id: 'cat_dining_room',
      name: 'Dining Room',
      rank: Rank.D,
      description:
          'If you long rest in your Bastion, gain 1d4 + Constitution Modifier as Temporary HP. For each rank the room is above D, increase the Temporary HP you gain by 1d4.',
      constructionTurns: 2,
      cost: 600,
    ),
    Facility(
      id: 'cat_humble_exterior',
      name: 'Humble Exterior',
      rank: Rank.D,
      description:
          '''Prerequisite: must not have Armory, Battlements, Siege Workshop, or War Room facilities constructed.

The Humble Exterior only protects Facilities of its rank and below. You treat the Individual Bastion Event "Surprise Attack!" and the Monthly Bastion Event "Siege" as "Quiet week" instead.''',
      constructionTurns: 2,
      cost: 600,
    ),
    Facility(
      id: 'cat_kitchen',
      name: 'Kitchen',
      rank: Rank.D,
      description: '''Individual Bastion Turn Order: If you have at least 1 Hireling assisting you in the kitchen, you get advantage on crafting treats if they are the same rank or lower than the kitchen.

Industrial Kitchen: Pay 500 GP. The amount of hirelings your kitchen can hold increases to 3. While you have three hirelings in the kitchen, when you successfully pass a DC to craft a treat in the kitchen, you get 1d6 extra treats!''',
      minimumRequiredHirelings: 1,
      constructionTurns: 2,
      cost: 600,
      table: FacilityTable(table: [
        ['Rank', 'Recipe Advantage'],
        ['D', 'Common/Uncommon Treats'],
        ['C', 'Rare Treats'],
        ['B', 'Rare+ Treats'],
        ['A', 'Very Rare Treats'],
        ['S', 'Legendary Treats'],
      ]),
    ),
    Facility(
      id: 'cat_well_room',
      name: 'Well Room',
      rank: Rank.D,
      description:
          '''The Well Room is a vital part of your Bastion, ensuring a constant, reliable source of drinking water for your defenders, hirelings, and crafters.

Individual Bastion Turn Order: Each size of your well room increases the amount of facilities that remain in operation during a drought and siege (up to 3 per rank).''',
      constructionTurns: 2,
      cost: 600,
    ),
    Facility(
      id: 'cat_parlor',
      name: 'Parlor',
      rank: Rank.D,
      description:
          'Individual Bastion Turn Order: As long as you are the same rank or below, a short rest in the Parlor grants you a Heroic Inspiration.',
      minimumRequiredHirelings: 1,
      constructionTurns: 2,
      cost: 600,
    ),
    Facility(
      id: 'cat_siege_engine',
      name: 'Siege Engine',
      rank: Rank.D,
      description: '''Hirelings: 3 per siege weapon.

Siege weapons can be deployed both against attackers and besiegers. Siege weapons are consumable; once used they must be replaced. You begin with 1 siege weapon slot and gain 1 additional siege slot every rank up (up to 5 slots at S-Rank). A siege weapon must have the maximum number of hirelings in order to operate.

Ballistas automatically kill 6 attackers during an attack, OR deal 3d10 damage during an invasion. Catapults automatically kill 8 attackers during an attack, OR deal 10d6 damage during an invasion. Cannons automatically kill 16 attackers during an attack, OR deal 8d10 damage during an invasion.

At A Rank you gain: Individual Bastion Turn Order — Once per Bastion Turn you can order your siege weapons to fire a second time.''',
      minimumRequiredHirelings: 3,
      constructionTurns: 2,
      cost: 600,
      table: FacilityTable(table: [
        ['Weapon', 'Cost', 'Rank'],
        ['Ballista', '300 GP', 'D'],
        ['Catapult', '500 GP', 'B'],
        ['Cannon', '700 GP', 'S'],
      ]),
    ),

    // ===================== Rank C =====================
    Facility(
      id: 'cat_armory',
      name: 'Armory',
      rank: Rank.C,
      description: '''Individual Bastion Turn Order: Until the beginning of your next Bastion Turn, you reduce the death threshold by 1 (Minimum 1).

Individual Bastion Turn Order: If you have both Battlements constructed, and your Walls are not currently destroyed, all your Bastion Defenders now defend with a d8 instead of a d6.

Equipment Improvements: At C-Rank and then A-Rank you reduce the death threshold by 1 for Bastion Defender Dice (Minimum 1).''',
      minimumRequiredHirelings: 2,
      constructionTurns: 4,
      cost: 1500,
    ),
    Facility(
      id: 'cat_harvestarium',
      name: 'Harvestarium',
      rank: Rank.C,
      description: '''When building this facility, choose a particular resource to specialize in. When you gain a Reward from any event, you may issue Order: Harvest to acquire extra materials.

Individual Bastion Turn Order: Roll once on your specialization material for 1d4 materials, at two ranks lower than the Facility's.

Individual Bastion Turn Order: Pay 500 GP and issue this order for 2 Construction turns to change the specialization. Once started, you must finish or cancel.

Specializations: Fertile Soil (random Herbs), Quarries (random Stones or Bones, your choice), Mines (random Metals), Hunter's Lodge (random Leathers or Bones, your choice), Pasturelands (random Meats or Bloods, your choice), Black Forest (random Woods or Silks, your choice). You gain a dice amount equivalent to the amount of materials of that Rank.''',
      minimumRequiredHirelings: 1,
      constructionTurns: 4,
      cost: 1500,
    ),
    Facility(
      id: 'cat_laboratory',
      name: 'Laboratory',
      rank: Rank.C,
      description: '''Prerequisite: Alchemist, Poisoner, Herbalist, or Brewer Tools.

When building this facility, choose one of the prerequisite tools or kits for which you have proficiency. That becomes the specialization for this Laboratory. Only those in your combined bastion may use this facility.

You gain Advantage on any crafting rolls with the tool or kit specialized by the Laboratory. Your hireling gives you Expertise in the tool or kit specialized by the Laboratory.

Industrial Laboratory: Pay 4,000 GP. The amount of hirelings your Laboratory can hold increases to 2. While you have two hirelings in the laboratory, when you successfully pass a DC to craft a potion, poison, or dilution, you have a 20% chance to gain a double. Increase this chance by 10% for each Laboratory rank above C.''',
      minimumRequiredHirelings: 1,
      constructionTurns: 4,
      cost: 1500,
    ),
    Facility(
      id: 'cat_library',
      name: 'Library',
      rank: Rank.C,
      description: '''Individual Bastion Turn Order: You task the Library's Hireling with researching a topic of your choice. The info you gain is under DM discretion.

Individual Bastion Turn Order: You research a specific skill. Until the end of your next quest you gain a +1 to that skill.

Arcane Insight: Reduce the cost of magic item crafting by 10% per Rank to a maximum of 30% at S-rank. This facility needs to be of an equal rank or higher to the item to take effect. Does not stack with other sources.

Vault of Knowledge: Pay 1,000 GP to gain new and accurate information, and your bonus to a skill increases to +3 until the end of the Bastion Turn.''',
      minimumRequiredHirelings: 1,
      constructionTurns: 4,
      cost: 1500,
    ),
    Facility(
      id: 'cat_sanctuary',
      name: 'Sanctuary',
      rank: Rank.C,
      description: '''Individual Bastion Turn Order: You gain a magical amulet that lasts until the beginning of your next Individual Bastion Turn or until you use it. At the time of crafting, choose either Healing Word or Cure Wounds; they are cast at Level one and increase with each rank up. At A-Rank you can choose Greater Restoration.

Individual Bastion Turn Order: You may cast the 1st level spell Ceremony at will while inside your Sanctuary. You don't pay the material costs unless for rings for a marriage.

Divine/Natural Insight: Reduce the cost of magic item crafting by 10% per Rank to a maximum of 30% at S-rank. This facility needs to be of an equal rank or higher to the item to take effect. Does not stack with other sources.''',
      minimumRequiredHirelings: 1,
      constructionTurns: 4,
      cost: 1500,
    ),
    Facility(
      id: 'cat_stables',
      name: 'Stables',
      rank: Rank.C,
      description: '''A Stable is required to house Beasts of medium or larger size. A Stable houses up to 3 Beasts of medium size or larger per Rank above C.

Individual Bastion Turn: Your steed gains 1d4 + Steed Con maximum HP per rank of the stable above C. This can only be used on one steed. This lasts until the steed is dead or unsummoned.

Individual Bastion Turn: Your steed gains 1d4 temporary Max HP per rank of the stable above C. If you have a Kitchen equal to this Facility's rank, your steed also gains 1d4 Temporary HP per rank of the stable above C. This can only be used on one steed. This lasts until the steed is dead or unsummoned.

Individual Bastion Turn: As long as you have two large mounts available, you can dispatch your hirelings to retrieve one dead or unconscious creature with a size category of huge or smaller. To haul a gargantuan creature, you must have four large mounts available. DM discretion still applies if the creature can be hauled back.''',
      minimumRequiredHirelings: 3,
      constructionTurns: 4,
      cost: 1500,
    ),
    Facility(
      id: 'cat_trading_hub',
      name: 'Trading Hub',
      rank: Rank.C,
      description: '''Individual Bastion Turn Order: When given this order you may purchase one item from the Price List at double the market value, with a total value of up to 1,000 GP (after adjustment) per rank of the Storehouse above C. Furthermore, the Storehouse can only procure items equal to or lower than its rank.

Price List: Poisons (any poison in the DMG Poisons Section), Alchemy Potions (Maura Alchemy Crafting Guide — add together the market values of the materials, then double), Healing Potions (Maura Herbalism Crafting Guide — double the market value), Art Pieces and Gemstones (DMG Treasure Section), and Scrolls — all at double their market value.

Specialized Shelving: Pay 2,000 GP to increase the total value of what you can procure by 500 GP per rank. You also unlock additional items to buy.''',
      minimumRequiredHirelings: 1,
      constructionTurns: 4,
      cost: 1500,
      table: FacilityTable(table: [
        ['Rank', 'Rarity', 'Total Value'],
        ['C', 'Common', '1,000 GP'],
        ['B', 'Uncommon', '2,000 GP'],
        ['A', 'Rare', '4,000 GP'],
        ['S', 'Very Rare', '6,000 GP'],
      ]),
    ),
    Facility(
      id: 'cat_workshop',
      name: 'Workshop',
      rank: Rank.C,
      description: '''When building the Workshop, choose one tool or kit which you are proficient with for this Facility to specialize in. Only those in your combined bastion may use this facility.

You gain Advantage on any crafting rolls with the tool or kit specialized by the Workshop. Your hireling gives you Expertise in the tool or kit specialized by the Workshop.

Pay 500 GP per Rank above C to change this workshop's specialization. Once started, you must finish or cancel. It takes 2 Bastion Turns, during which your workshop cannot be used.

Mastercraft Workshop: Pay 4,000 GP. The amount of hirelings your Workshop can hold increases to 2. While you have two hirelings in the Workshop, the Individual Bastion Turn Order also adds 1d4 to your crafting roll. This does not stack with Flash of Genius or Built for Success.''',
      minimumRequiredHirelings: 1,
      constructionTurns: 4,
      cost: 1500,
      table: FacilityTable(table: [
        ['Type', 'Type'],
        ['Calligraphy Supplies', "Carpenter's Tools"],
        ["Cobbler's Tools", 'Glassblower\'s Tools'],
        ["Jeweller's Tools", "Leatherworker's Tools"],
        ["Mason's Tools", "Painter's Tools"],
        ["Potter's Tools", "Smith's Tools"],
        ["Tinker's Tools", "Weaver's Tools"],
        ['Woodcarver\'s Tools', 'Disguise Kit'],
        ['Forgery Kit', ''],
      ]),
    ),

    // ===================== Rank B =====================
    Facility(
      id: 'cat_gaming_hall',
      name: 'Gaming Hall',
      rank: Rank.B,
      description: '''You gain access to Fortune's Folly, an exclusive high-stakes gambling circuit. Play up to three escalating rounds of increasingly risky gambling. You may choose to stop and cash out after any successful round. If you Bust, you lose all winnings.

Individual Bastion Turn Order: Play Fortune's Folly — B Rank: once, A Rank: twice, S Rank: thrice.

Gambler's Lucky Dice: When you make a D20 test, you may expend one Gambler's Lucky Dice to reroll the die after seeing the result, but before knowing the outcome. You must use the new roll. You may not hold multiple Gambler's Lucky Dice at a time.''',
      minimumRequiredHirelings: 3,
      constructionTurns: 6,
      cost: 4500,
      table: FacilityTable(table: [
        ['Round', '1-2', '3-5', '6'],
        ['One (1d6)', 'Bust', 'A gemstone worth 100 GP', 'A gemstone worth 200 GP'],
        [
          'Two (1d6)',
          'Bust',
          'A gemstone worth 200 GP',
          "Roll once on the Reward Table equal to the rank of this facility"
        ],
        ['Three (1d6)', 'Bust', 'A gemstone worth 200 GP', "You gain a Gambler's Lucky Dice"],
      ]),
    ),
    Facility(
      id: 'cat_guildhall',
      name: 'Guildhall',
      rank: Rank.B,
      description: '''A Guildhall comes with a guild, for which you are the guild master. Choose the type of guild from the Guild List. The facility is a meeting room where members of your guild can discuss important matters in your presence. Your guild has roughly fifty members made up of skilled folk who live and work outside your Bastion, usually in nearby settlements.

Alchemists' Guild: As long as you have a Laboratory devoted to the same specialization as your guild, you add 1 per Rank of the guild above C to your crafting roll. Does not stack with Flash of Genius or Built for Success.

Artisans' Guild: As long as you have a Workshop devoted to the same specialization as your guild, when you successfully pass a DC to craft in your workshop you have a 20% chance to gain a double. Increase this chance by 10% for each Guild rank above B.

Builders' Guild: Individual Bastion Turn Order — You may reduce the cost to build a facility by 5% per Rank of the Guild above C; if you pay the cost you may do it for others. You may also reduce the time to build a facility by 1 Bastion Turn per Rank of the Guild above C, if you pay the cost you may do it for others.

Cooks' Guild: When you successfully pass a DC to craft a treat in the kitchen, you get 2 extra treats per Rank of the guild past C!''',
      minimumRequiredHirelings: 1,
      constructionTurns: 6,
      cost: 4500,
    ),
    Facility(
      id: 'cat_museum',
      name: 'Museum',
      rank: Rank.B,
      description: '''This room houses a collection of mementos, such as weapons from old battles, the mounted heads of slain creatures, trinkets plucked from dungeons and ruins, and trophies passed down from ancestors. The following benefits apply only to you.

After spending a Long Rest in your Bastion, you gain a trinket that lasts for 1 Bastion Turn or until you use it. The trinket allows you to cast Borrowed Knowledge once without expending a spell slot, after which it disappears. You can't gain this trinket again while you still have it.

Individual Bastion Turn Order: You commission the facility's hireling to research a topic of your choice. The topic can be a legend, any kind of creature, or a famous object. The work takes one Bastion Turn. When the research concludes, you obtain up to three accurate pieces of information about the topic that were previously unknown to you.''',
      minimumRequiredHirelings: 1,
      constructionTurns: 6,
      cost: 4500,
    ),
    Facility(
      id: 'cat_sacristy',
      name: 'Sacristy',
      rank: Rank.B,
      description: '''A Sacristy serves as a preparation and storage room for sacred items and vestments.

Individual Bastion Turn Order: Allows you to cast one spell of level 4 or lower without spending a spell slot after spending an entire Short Rest in your Bastion. You can't gain this benefit again until you finish a Bastion Turn.

Individual Bastion Turn Order: You commission one flask of Holy Water for the cost listed in the table, which you can pick up at the beginning of your next Bastion Turn. When using it, you can expend an extra flask to increase the 2d8 Radiant damage if the target is a Fiend or Undead.''',
      minimumRequiredHirelings: 1,
      constructionTurns: 6,
      cost: 4500,
      table: FacilityTable(table: [
        ['Rank', 'Damage', 'Cost'],
        ['C', '2d8', '25 GP'],
        ['B', '3d8', '50 GP'],
        ['A', '4d8', '100 GP'],
        ['S', '5d8', '250 GP'],
      ]),
    ),
    Facility(
      id: 'cat_teleportation_circle',
      name: 'Teleportation Circle',
      rank: Rank.B,
      description:
          '''Costs 18,250 GP (50 GP per cast). Construction Turns: 53 (divided by the amount of casters).

This Facility keeps your Teleportation Circle safe from enemies' spying eyes.

Individual Bastion Turn Order: Once your Teleportation Circle is complete, you can activate or deactivate the circle.''',
      minimumRequiredHirelings: 5,
      constructionTurns: 53,
      cost: 18250,
    ),
    Facility(
      id: 'cat_theatre',
      name: 'Theatre',
      rank: Rank.B,
      description: '''Individual Bastion Turn Order: Show Time! You must be present in your Bastion, along with any attendees. You may host up to four other players as audience members. Make a Performance check (a natural 1 always fails). The DC depends on the rank of the Theatre: B Rank DC 13, A Rank DC 15, S Rank DC 17. On a success, you and each attending player gain one Performance Token.

Performance Tokens: A Performance Token is a die. Only creatures who attended the show (including you) can gain a token. A creature can only hold one Performance Token at a time. Tokens last until used, and give an Initiative Bonus until used. Using a Performance Token: when you make a D20 test, you may expend your token to gain a bonus. You can choose to do so after seeing the roll, but before knowing the outcome.

Stage Enhancements: Pay the amount of gold listed in the table every time you make a play for players, to increase the Performance Token. You can pay up to your Facility Rank from the table.''',
      minimumRequiredHirelings: 20,
      constructionTurns: 6,
      cost: 4500,
      table: FacilityTable(table: [
        ['Rank', 'Cost', 'Token Die', 'Initiative Bonus'],
        ['B', '750 GP', 'd8', '+1'],
        ['A', '1,000 GP', 'd10', '+1'],
        ['S', '1,500 GP', 'd12', '+2'],
      ]),
    ),
    Facility(
      id: 'cat_war_room',
      name: 'War Room',
      rank: Rank.B,
      description: '''The War Room is where you house Lieutenants. Lieutenants housed in your Bastion make Bastion Defenders roll at Advantage on their Defender Die. You can only gain Lieutenants from events or on quests under DM discretion.

Individual Bastion Turn Order: You commission one or more of your Lieutenants to assemble a small army. Each soldier can be paid 2 GP (pay an extra 4 GP to mount them) immediately, and you can pay up to 100 per Lieutenant sent. You also have to pay each soldier each Bastion Turn to keep them — soldiers will leave if you don't pay them. Otherwise, the army remains until it is destroyed or you command it to disband. During an event each guard can contribute 1d6 to the event, 1d12 if they are mounted on horses. The Lieutenants themselves do not fight, they lead.''',
      minimumRequiredHirelings: 1,
      constructionTurns: 6,
      cost: 4500,
    ),
    Facility(
      id: 'cat_training_area',
      name: 'Training Area',
      rank: Rank.B,
      description:
          '''You gain 1 Trainer per Rank from B rank. Max 3 Trainers.

Individual Bastion Turn Order: You get one Trainer's benefit.''',
      minimumRequiredHirelings: 4,
      constructionTurns: 6,
      cost: 4500,
      table: FacilityTable(table: [
        ['Trainer', 'Benefit per Bastion Turn'],
        [
          'Battle Expert',
          'Once per turn, you can reduce physical damage taken from any sources by 2, provided you don\'t have the Incapacitated condition.'
        ],
        [
          'Unarmed Combat Expert',
          'When you use an Unarmed Strike to damage a target, the attack is a +1 to hit.'
        ],
        ['Weapon Expert', 'You gain +1 to hit with melee weapons.'],
        ['Marksman', 'You gain +1 to hit with ranged weapons.'],
      ]),
    ),

    // ===================== Rank A =====================
    Facility(
      id: 'cat_archive',
      name: 'Archive',
      rank: Rank.A,
      description: '''An Archive is a repository of valuable books, scrolls, and maps.

Individual Bastion Turn: You gain knowledge as if you had cast the Legend Lore spell.

Reference Book: Your Archive contains one copy of a rare and valuable reference book, which gives you a benefit while the book is in your Bastion. Upgrade the Archive to S rank and you can select two additional titles from the Reference Book table. You have Advantage on any Intelligence check you make when you take the Study action to recall lore about what is covered by the book.''',
      minimumRequiredHirelings: 1,
      constructionTurns: 8,
      cost: 9000,
      table: FacilityTable(table: [
        ['Reference Book', 'Skill'],
        ["Bigby's Handy Arcana Codex", 'Arcana'],
        ['The Chronepsis Chronicles', 'History'],
        ['Investigations of the Inquisitive', 'Investigation'],
        ['Material Musings on the Nature of the World', 'Nature'],
        ['The Old Faith and Other Religions', 'Religion'],
      ]),
    ),
    Facility(
      id: 'cat_meditation_chamber',
      name: 'Meditation Chamber',
      rank: Rank.A,
      description: '''Individual Bastion Turn Order: You become immune to the Frightened condition and gain Advantage against the Charmed condition until the next Individual Bastion Turn.

Individual Bastion Turn Order: Cure any phobia, madness, or insanity.

Upgrading this Facility to S-Rank gives you the following Order — Individual Bastion Turn Order: You gain a +2 to Wisdom saves.''',
      constructionTurns: 8,
      cost: 9000,
    ),
    Facility(
      id: 'cat_observatory',
      name: 'Observatory',
      rank: Rank.A,
      description: '''Individual Bastion Turn Order: You gain a magical Charm that lasts for 1 Bastion Turn or until you use it. The Charm allows you to cast Divination without expending a spell slot. You can't gain this Charm again while you still have it.

Individual Bastion Turn Order: Augury. You can cast Augury once per day as a magic action.

Upgrading this Facility to S-Rank gives you the following Order — Individual Bastion Turn Order: You gain a magical Charm that lasts for 1 Bastion Turn or until you use it. The Charm can be the Charm of Darkvision, Charm of Heroism, or Charm of Vitality (from the DMG, supernatural gifts). You can't gain this Charm again while you still have it.''',
      minimumRequiredHirelings: 1,
      constructionTurns: 8,
      cost: 9000,
    ),
    Facility(
      id: 'cat_pub',
      name: 'Pub',
      rank: Rank.A,
      description: '''Your Pub has one Pub Special that you can choose from the table below, and they are treated as very rare potions.

Individual Bastion Turn Order: When you give this order, your staff change one of your pub specials and stock it.

Individual Bastion Turn Order: Your staff restock all of your current pub specials.

Individual Bastion Turn Order: Until the end of your Bastion Turn, you gain Poison Resistance.

If you upgrade your Pub to S-Rank, you can stock a second pub special.

Pub of Legend: Pay 2,000 GP each Individual Bastion Turn to increase your Hireling count to 4. While you have at least 4 hirelings working in the pub, you can have another pub special.''',
      minimumRequiredHirelings: 1,
      constructionTurns: 8,
      cost: 9000,
      table: FacilityTable(table: [
        ['Beverage', 'Effect'],
        [
          "Bigby's Burden",
          'Grants the enlarge effect of an Enlarge/Reduce spell with a duration of 24 hours, for which you get no saving throw.'
        ],
        [
          'Kiss of the Spider Queen',
          'Grants the effect of a Spider Climb spell that has a duration of 24 hours.'
        ],
        [
          'Moonlight Serenade',
          'Gives Darkvision within 60 feet for the next 24 hours. If you already have Darkvision, its range is extended by 60 feet for the same duration.'
        ],
        [
          "Scurvy's Surprise",
          'Gives you a random effect from the wild magic table.'
        ],
        [
          'Positive Reinforcement',
          'Gives Resistance to Necrotic damage for the next 24 hours.'
        ],
        [
          'Negative Reinforcement',
          'Gives Resistance to Radiant damage for the next 24 hours.'
        ],
        [
          'Sterner Stuff',
          'Makes you immune to the Frightened condition for the next 24 hours.'
        ],
      ]),
    ),

    // ===================== Rank S =====================
    // Note: A bastion can only have one S rank facility.
    Facility(
      id: 'cat_colosseum',
      name: 'Colosseum',
      rank: Rank.S,
      description: '''The following benefits apply only to you.

After spending a Long Rest in your Bastion, you gain the ability of Steel Wind Strike as if it had been cast on you; it can be used at any time as an action. For this use of the spell, you use the to-hit bonus of your weapon or unarmed strike for the attacks, and each hit counts as a hit with the chosen weapon, but the weapon's damage dice are replaced by the spell's 6d10 force damage. This ability can only be gained once per long rest in your Bastion.

Individual Bastion Turn Order: You can enter a state of heightened martial focus. Until the end of the Bastion Turn, when you miss with an attack roll, you can reroll it. You can use this feature up to three times per Bastion Turn and must use the new roll.''',
      minimumRequiredHirelings: 4,
      constructionTurns: 10,
      cost: 20000,
    ),
    Facility(
      id: 'cat_crucible_baths',
      name: 'Crucible Baths',
      rank: Rank.S,
      description: '''The following benefits apply only to you.

Once per turn, when you take damage, you can reduce that damage by 5. At the start of combat, your Max and current HP get increased by 20. You lose this Max HP at the end of combat.

Individual Bastion Turn Order: Your body becomes extraordinarily resilient. While you have levels of Exhaustion, treat your Exhaustion level as 1 lower for the purpose of determining its effects. You still die if your Exhaustion reaches 6. As a Bonus Action, you can end one Poisonous effect on yourself and gain 10 Temporary Hit Points.''',
      minimumRequiredHirelings: 4,
      constructionTurns: 10,
      cost: 20000,
    ),
    Facility(
      id: 'cat_gymnasium',
      name: 'Gymnasium',
      rank: Rank.S,
      description:
          '''When you take the Attack, Dodge, or Disengage action, your movement speed increases by 10 feet until the end of your turn.

Once per round when you take damage, you gain resistance to one type of the damage in the attack and move away half your movement without provoking attacks of opportunity.''',
      minimumRequiredHirelings: 4,
      constructionTurns: 10,
      cost: 20000,
    ),
    Facility(
      id: 'cat_ivory_tower',
      name: 'Ivory Tower',
      rank: Rank.S,
      description: '''The following benefits apply only to you. You can cast Identify and Detect Magic without expending spell slots or material components. Once per combat, the first spell you cast at 3rd level or lower does not consume a spell slot.

Individual Bastion Turn Order: You create rituals to increase your arcane potency. Choose one damage type: Acid, Cold, Fire, Force, Lightning, Necrotic, Poison, Psychic, Radiant, or Thunder. Once per turn when you deal the chosen damage type, add your Intelligence modifier to one damage roll. You gain a bonus to Initiative equal to your Intelligence modifier.''',
      minimumRequiredHirelings: 4,
      constructionTurns: 10,
      cost: 20000,
    ),
    Facility(
      id: 'cat_shrine_of_power',
      name: 'Shrine of Power',
      rank: Rank.S,
      description: '''The following benefits apply only to you.

Individual Bastion Turn Order: Shifting Font — You may swap one spell you know or have prepared with another spell of the same level from your class spell list.

Individual Bastion Turn Order: Blessed Warrior (or a fighting style of your choice if you already have this feature) — You learn two Cleric cantrips of your choice. The chosen cantrips count as class-specific spells for you (Paladin Spells, Cleric Spells), and Charisma is your spellcasting ability for them. These cantrips remain until your next Bastion Turn.

Once per Bastion Turn you may cast one spell up to 5th level from your class spell list at its base level without expending a spell slot. The spell must be of a level you can cast from a class with Charisma as a primary ability.''',
      minimumRequiredHirelings: 4,
      constructionTurns: 10,
      cost: 20000,
    ),
    Facility(
      id: 'cat_tranquil_sanctum',
      name: 'Tranquil Sanctum',
      rank: Rank.S,
      description: '''The following benefits apply only to you.

You may cast Lesser Restoration without expending a spell slot once per Bastion Turn.

Individual Bastion Turn Order: After spending a Long Rest in your Bastion, you gain a magical Charm that lasts for 1 Bastion Turn or until you use it. The Charm allows you to cast Heal once without expending a spell slot. You can't gain this Charm again while you still have it and lose it after you cast the spell.

Sanctum Recall: While the Sanctum exists, you always have the Word of Recall spell prepared, and you can make your Sanctum the destination of the spell. In addition, one creature of your choice that arrives in the Sanctum via this spell gains the benefit of a Heal spell.''',
      minimumRequiredHirelings: 4,
      constructionTurns: 10,
      cost: 20000,
    ),
  ];
}
