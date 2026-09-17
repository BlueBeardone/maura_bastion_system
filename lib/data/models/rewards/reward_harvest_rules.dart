import 'package:maura_bastion_system/data/enums/rank.dart';

/// "The Main Chart" — market value per unit of an exotic material by rank.
const Map<Rank, int> mainChartValueByRank = {
  Rank.E: 15,
  Rank.D: 150,
  Rank.C: 300,
  Rank.B: 850,
  Rank.A: 1500,
  Rank.S: 5600,
};

/// Market value per unit of meat/blood by rank.
const Map<Rank, int> mainChartMeatBloodValueByRank = {
  Rank.E: 3,
  Rank.D: 30,
  Rank.C: 60,
  Rank.B: 170,
  Rank.A: 300,
  Rank.S: 1120,
};

/// Whenever an 'X' appears in any other chart, substitute the value of 'X'
/// from The Main Chart for the material's rank.
const Map<Rank, int> unitBonusXByRank = {
  Rank.E: 0,
  Rank.D: 1,
  Rank.C: 2,
  Rank.B: 3,
  Rank.A: 4,
  Rank.S: 5,
};

enum CreatureSize { small, medium, large, huge, gargantuan }

/// Harvest stats for a creature of a given size: how many harvesting checks
/// it allows, how many units of parts each successful check awards, and how
/// many rations of meat and units of blood it yields.
class CreatureHarvestStats {
  final int maxChecks;
  final int? maxUnitsPerCheck;
  final int rationsOfMeat;
  final int unitsOfBlood;

  const CreatureHarvestStats({
    required this.maxChecks,
    this.maxUnitsPerCheck,
    required this.rationsOfMeat,
    required this.unitsOfBlood,
  });

  static const CreatureHarvestStats small = CreatureHarvestStats(
    maxChecks: 1,
    maxUnitsPerCheck: null,
    rationsOfMeat: 1,
    unitsOfBlood: 1,
  );
  static const CreatureHarvestStats medium = CreatureHarvestStats(
    maxChecks: 1,
    maxUnitsPerCheck: 1,
    rationsOfMeat: 2,
    unitsOfBlood: 2,
  );
  static const CreatureHarvestStats large = CreatureHarvestStats(
    maxChecks: 1,
    maxUnitsPerCheck: 2,
    rationsOfMeat: 3,
    unitsOfBlood: 3,
  );
  static const CreatureHarvestStats huge = CreatureHarvestStats(
    maxChecks: 2,
    maxUnitsPerCheck: 2,
    rationsOfMeat: 4,
    unitsOfBlood: 4,
  );
  static const CreatureHarvestStats gargantuan = CreatureHarvestStats(
    maxChecks: 2,
    maxUnitsPerCheck: 3,
    rationsOfMeat: 6,
    unitsOfBlood: 6,
  );

  static CreatureHarvestStats forSize(CreatureSize size) {
    switch (size) {
      case CreatureSize.small:
        return small;
      case CreatureSize.medium:
        return medium;
      case CreatureSize.large:
        return large;
      case CreatureSize.huge:
        return huge;
      case CreatureSize.gargantuan:
        return gargantuan;
    }
  }
}

/// The skill check used to harvest parts from a creature, by creature
/// category.
const Map<String, String> creaturePartSkillCheckByCategory = {
  'Aberration': 'Arcana',
  'Beast': 'Nature/Survival',
  'Celestial': 'Religion',
  'Construct': 'Arcana',
  'Dragon': 'Nature/Survival',
  'Elemental': 'Arcana',
  'Fey': 'Religion',
  'Fiend': 'Religion',
  'Giant': 'Nature/Survival',
  'Humanoid': 'Nature/Survival',
  'Monstrosity': 'Nature/Survival',
  'Ooze': 'Nature/Survival',
  'Plants': 'Nature/Survival',
  'Undead': 'Religion',
};

/// DC to harvest creature parts: 12 + 1/2 the creature's CR (rounded down).
int creaturePartHarvestDC(int cr) => 12 + cr ~/ 2;

/// DC to harvest a creature's venom glands: 12 + CR. On a failure the gland
/// is destroyed and the harvester is poisoned by it.
int venomGlandHarvestDC(int cr) => 12 + cr;

/// Blood from a fresh kill of a healthy Beast can be drunk immediately. After
/// 10 minutes, blood spoils and a character must make a DC 15 Constitution
/// save to avoid vomiting.
const String bloodSpoilageRule =
    'After 10 minutes, blood spoils and a character must make a DC 15 '
    'Constitution save to avoid vomiting.';
