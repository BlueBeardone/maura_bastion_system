import 'dart:math';

enum DispatchUnitType { knight, bastionDefender, beast, hireling }

class UnitDice {
  final int count;
  final int faces;

  const UnitDice(this.count, this.faces);

  int roll(Random rng) => List.generate(count, (_) => rng.nextInt(faces) + 1)
      .reduce((a, b) => a + b);
}

UnitDice defaultDiceFor(DispatchUnitType type) {
  switch (type) {
    case DispatchUnitType.beast:
      return const UnitDice(1, 10);
    case DispatchUnitType.knight:
      return const UnitDice(1, 12);
    case DispatchUnitType.bastionDefender:
    case DispatchUnitType.hireling:
      return const UnitDice(1, 6);
  }
}

class DispatchUnit {
  final String id;
  final String name;
  final DispatchUnitType type;

  const DispatchUnit({required this.id, required this.name, required this.type});
}

class DispatchSpec {
  final String prompt;
  final int maxUnits;
  final int dc;
  final Map<DispatchUnitType, UnitDice>? diceOverride;

  const DispatchSpec({
    required this.prompt,
    required this.maxUnits,
    required this.dc,
    this.diceOverride,
  });

  UnitDice diceFor(DispatchUnitType type) =>
      diceOverride?[type] ?? defaultDiceFor(type);
}

class UnitRoll {
  final DispatchUnit unit;
  final List<int> rolls;

  const UnitRoll({required this.unit, required this.rolls});

  int get subtotal => rolls.fold(0, (a, b) => a + b);
}

class DispatchResult {
  final List<UnitRoll> unitRolls;
  final int bonus;
  final int dc;

  const DispatchResult({required this.unitRolls, required this.bonus, required this.dc});

  int get total =>
      unitRolls.fold(0, (sum, r) => sum + r.subtotal) + bonus;

  bool get success => total >= dc;
}

DispatchResult resolveDispatch({
  required DispatchSpec spec,
  required List<DispatchUnit> units,
  Random? rng,
  int bonus = 0,
}) {
  if (units.length > spec.maxUnits) {
    throw ArgumentError(
      'Dispatch allows at most ${spec.maxUnits} units, got ${units.length}',
    );
  }
  final random = rng ?? Random();
  final rolls = units
      .map((unit) => UnitRoll(
            unit: unit,
            rolls: List.generate(
              spec.diceFor(unit.type).count,
              (_) => random.nextInt(spec.diceFor(unit.type).faces) + 1,
            ),
          ))
      .toList();
  return DispatchResult(unitRolls: rolls, bonus: bonus, dc: spec.dc);
}
