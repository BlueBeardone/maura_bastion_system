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
      return const UnitDice(2, 6);
    case DispatchUnitType.knight:
      return const UnitDice(1, 8);
    case DispatchUnitType.bastionDefender:
    case DispatchUnitType.hireling:
      return const UnitDice(1, 6);
  }
}
