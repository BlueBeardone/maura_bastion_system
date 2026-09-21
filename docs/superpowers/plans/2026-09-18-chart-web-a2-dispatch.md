# Chart Web A2 — Dispatch Model & Dice Resolver Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Model event dispatch (who you send, how they roll) and implement the tally resolver used by every dispatchable Chart Web event.

**Architecture:** One model file `lib/data/models/events/dispatch.dart` containing the dispatch value types and the pure resolver function. Pure Dart, no UI. Later plans (A3 reward rolling, A4–A7 catalogs, A8 turn engine) consume `DispatchSpec`/`DispatchResult`.

**Tech Stack:** Dart / Flutter (no new dependencies). Tests with `flutter test`.

**Spec:** `docs/superpowers/specs/2026-09-18-chart-web-reward-system-design.md` (Section 4, phases 3–4)

## Global Constraints

- Unit-type default dice: **beast 2d6, knight 1d8, bastionDefender 1d6, hireling 1d6** (events may override per type).
- Dispatch cap: **units.length must never exceed `spec.maxUnits`** (resolver throws `ArgumentError`).
- Success: **total tally (sum of all unit rolls + flat bonus) >= DC** (meets it, beats it — matching the existing Request-for-Aid convention).
- House style: plain classes with `const` constructors; no comments unless explaining a non-obvious rule.

---

### Task 1: DispatchUnitType + UnitDice + defaultDiceFor

**Files:**
- Create: `lib/data/models/events/dispatch.dart`
- Test: `test/data/models/events/dispatch_test.dart`

**Interfaces:**
- Produces:
  - `enum DispatchUnitType { knight, bastionDefender, beast, hireling }`
  - `class UnitDice { final int count; final int faces; const UnitDice(this.count, this.faces); int roll(Random rng); }` — `roll` returns the sum of `count` dice of `faces` sides.
  - `UnitDice defaultDiceFor(DispatchUnitType type)` — beast `UnitDice(2, 6)`, knight `UnitDice(1, 8)`, bastionDefender `UnitDice(1, 6)`, hireling `UnitDice(1, 6)`.

- [ ] **Step 1: Write the failing test**

```dart
// test/data/models/events/dispatch_test.dart
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:maura_bastion_system/data/models/events/dispatch.dart';

void main() {
  group('UnitDice', () {
    test('roll stays within count*faces bounds', () {
      final dice = const UnitDice(2, 6);
      for (var i = 0; i < 500; i++) {
        final value = dice.roll(Random(42 + i));
        expect(value, inInclusiveRange(2, 12));
      }
    });

    test('single die covers every face', () {
      final seen = <int>{};
      for (var i = 0; i < 200; i++) {
        seen.add(const UnitDice(1, 6).roll(Random(1000 + i)));
      }
      expect(seen, containsAll([1, 2, 3, 4, 5, 6]));
    });
  });

  test('default dice per unit type', () {
    expect(defaultDiceFor(DispatchUnitType.beast), const UnitDice(2, 6));
    expect(defaultDiceFor(DispatchUnitType.knight), const UnitDice(1, 8));
    expect(defaultDiceFor(DispatchUnitType.bastionDefender), const UnitDice(1, 6));
    expect(defaultDiceFor(DispatchUnitType.hireling), const UnitDice(1, 6));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/data/models/events/dispatch_test.dart`
Expected: FAIL — cannot find `dispatch.dart`.

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/data/models/events/dispatch.dart
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
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/data/models/events/dispatch_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/data/models/events/dispatch.dart test/data/models/events/dispatch_test.dart
git commit -m "feat: add dispatch unit types and unit dice"
```

---

### Task 2: DispatchUnit + DispatchSpec

**Files:**
- Modify: `lib/data/models/events/dispatch.dart`
- Test: `test/data/models/events/dispatch_test.dart` (append inside existing `main`)

**Interfaces:**
- Consumes: `DispatchUnitType`, `UnitDice`, `defaultDiceFor` (Task 1).
- Produces:
  - `class DispatchUnit { final String id; final String name; final DispatchUnitType type; const DispatchUnit({...}); }`
  - `class DispatchSpec { final String prompt; final int maxUnits; final int dc; final Map<DispatchUnitType, UnitDice>? diceOverride; const DispatchSpec({...}); UnitDice diceFor(DispatchUnitType type); }` — `diceFor` returns the override for the type when present, else `defaultDiceFor(type)`.

- [ ] **Step 1: Write the failing test** (append a new group inside `main`, before its closing brace)

```dart
  group('DispatchSpec', () {
    test('diceFor prefers the override', () {
      const spec = DispatchSpec(
        prompt: 'Send hunters',
        maxUnits: 3,
        dc: 12,
        diceOverride: {DispatchUnitType.knight: UnitDice(2, 6)},
      );
      expect(spec.diceFor(DispatchUnitType.knight), const UnitDice(2, 6));
      expect(spec.diceFor(DispatchUnitType.beast), const UnitDice(2, 6));
      expect(spec.diceFor(DispatchUnitType.hireling), const UnitDice(1, 6));
    });

    test('diceFor falls back to defaults without override', () {
      const spec = DispatchSpec(prompt: 'Send anyone', maxUnits: 4, dc: 10);
      expect(spec.diceFor(DispatchUnitType.bastionDefender), const UnitDice(1, 6));
    });
  });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/data/models/events/dispatch_test.dart`
Expected: FAIL — `DispatchSpec` is not defined.

- [ ] **Step 3: Write minimal implementation** (append to `lib/data/models/events/dispatch.dart`)

```dart
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
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/data/models/events/dispatch_test.dart`
Expected: PASS (5 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/data/models/events/dispatch.dart test/data/models/events/dispatch_test.dart
git commit -m "feat: add DispatchUnit and DispatchSpec"
```

---

### Task 3: DispatchResult + resolveDispatch

**Files:**
- Modify: `lib/data/models/events/dispatch.dart`
- Test: `test/data/models/events/dispatch_test.dart` (append inside `main`)

**Interfaces:**
- Consumes: `DispatchSpec`, `DispatchUnit`, `UnitDice` (Tasks 1–2).
- Produces:
  - `class UnitRoll { final DispatchUnit unit; final List<int> rolls; int get subtotal; const UnitRoll({...}); }`
  - `class DispatchResult { final List<UnitRoll> unitRolls; final int bonus; int get total; bool get success; final int dc; const DispatchResult({...}); }` — `total` = sum of subtotals + bonus; `success` = `total >= dc`.
  - `DispatchResult resolveDispatch({required DispatchSpec spec, required List<DispatchUnit> units, Random? rng, int bonus = 0})` — throws `ArgumentError` when `units.length > spec.maxUnits`; rolls each unit's dice via `spec.diceFor(unit.type)`.

- [ ] **Step 1: Write the failing test** (append inside `main`)

```dart
  group('resolveDispatch', () {
    const spec = DispatchSpec(prompt: 'Send a party', maxUnits: 2, dc: 10);

    test('throws when more units than maxUnits', () {
      const units = [
        DispatchUnit(id: 'a', name: 'A', type: DispatchUnitType.bastionDefender),
        DispatchUnit(id: 'b', name: 'B', type: DispatchUnitType.bastionDefender),
        DispatchUnit(id: 'c', name: 'C', type: DispatchUnitType.bastionDefender),
      ];
      expect(
        () => resolveDispatch(spec: spec, units: units, rng: Random(1)),
        throwsArgumentError,
      );
    });

    test('rolls per-unit dice and tallies with bonus', () {
      final result = resolveDispatch(
        spec: spec,
        units: const [
          DispatchUnit(id: 'a', name: 'Aldric', type: DispatchUnitType.knight),
          DispatchUnit(id: 'b', name: 'Rex', type: DispatchUnitType.beast),
        ],
        rng: Random(7),
        bonus: 2,
      );
      expect(result.unitRolls.length, 2);
      expect(result.unitRolls[0].rolls.length, 1); // knight 1d8
      expect(result.unitRolls[0].unit.name, 'Aldric');
      expect(result.unitRolls[1].rolls.length, 2); // beast 2d6
      final expectedTotal = result.unitRolls.fold<int>(0, (s, r) => s + r.subtotal) + 2;
      expect(result.total, expectedTotal);
      expect(result.success, expectedTotal >= 10);
    });

    test('deterministic rng gives deterministic rolls', () {
      final a = resolveDispatch(
        spec: spec,
        units: const [DispatchUnit(id: 'a', name: 'A', type: DispatchUnitType.bastionDefender)],
        rng: Random(99),
      );
      final b = resolveDispatch(
        spec: spec,
        units: const [DispatchUnit(id: 'a', name: 'A', type: DispatchUnitType.bastionDefender)],
        rng: Random(99),
      );
      expect(a.unitRolls.single.subtotal, b.unitRolls.single.subtotal);
    });

    test('success boundary is meets-it-beats-it', () {
      final result = DispatchResult(
        unitRolls: const [],
        bonus: 10,
        dc: 10,
      );
      expect(result.total, 10);
      expect(result.success, isTrue);
    });
  });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/data/models/events/dispatch_test.dart`
Expected: FAIL — `resolveDispatch` is not defined.

- [ ] **Step 3: Write minimal implementation** (append to `lib/data/models/events/dispatch.dart`)

```dart
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
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/data/models/events/dispatch_test.dart`
Expected: PASS (9 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/data/models/events/dispatch.dart test/data/models/events/dispatch_test.dart
git commit -m "feat: add dispatch resolver with per-unit dice and tally"
```

---

### Task 4: Verification

- [ ] **Step 1:** Run `flutter test test/data/models/events/` — expect all pass.
- [ ] **Step 2:** Run `flutter test` — expect full suite pass.
- [ ] **Step 3:** Run `flutter analyze lib/data/models/events` — expect no issues.
