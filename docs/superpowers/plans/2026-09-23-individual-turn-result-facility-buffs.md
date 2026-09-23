# Individual Turn Result Dialog — Event Outcome & Facility Buffs Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the Individual Bastion Turn result dialog show the full event outcome and an expandable list of every eligible facility with its buff and any per-turn table roll.

**Architecture:** All dice rolling stays in `bastion_page.dart:_takeBastionTurn`; a presentation view-model carries the resolved data into the stateless `BastionTurnDialog`. A new `FacilityBuffCard` statelessly renders each buff and expands on tap. `FacilityTable` gains a `rollable` flag so only genuinely random facility tables are rolled.

**Tech Stack:** Flutter, Dart SDK `^3.11.0`, `flutter_test`, `google_fonts`. No new dependencies.

## Global Constraints

- Dart SDK `^3.11.0` (from `pubspec.yaml`); no new packages.
- Test command: `flutter test`. Analyzer command: `flutter analyze`.
- Follow existing patterns: parchment/gold theming via `MedievalColors`, `GoogleFonts.cinzel` for headings and `GoogleFonts.imFellEnglish` for body, `ParchmentBorderPainter` for card borders, `FacilityTableView` for tables.
- `docs/` is gitignored; commit doc files with `git add -f`.
- Do not modify `BastionTurnFlowDialog`, the monthly turn, the Discord payload schema, or the bastion page facility cards.
- Discord model `BastionTurnFacilityResult` keeps its shape (`name`, `rolledRow`).

---

### Task 1: `rollTable` helper and `rollable` flag on `FacilityTable`

**Files:**
- Modify: `lib/data/models/bastion/table.dart`
- Test: `test/data/models/bastion/table_test.dart`

**Interfaces:**
- Consumes: nothing new.
- Produces:
  - `FacilityTable({required List<List<String>> table, bool rollable = false})` with `final bool rollable`, JSON `rollable` (default `false`).
  - `({int roll, String row})? rollTable(FacilityTable table, {Random? rng})`.
  - `String? rollTableResult(FacilityTable table, {Random? rng})` (unchanged behavior, now a wrapper).

- [ ] **Step 1: Write the failing tests**

Append these two groups inside `main()` in `test/data/models/bastion/table_test.dart`, after the existing `group('rollTableResult', ...)`:

```dart
group('rollTable', () {
  test('returns both the numeric roll and the matching row', () {
    final table = FacilityTable(table: [
      ['d4', 'Guest', 'Description'],
      ['1', 'Renowned Builder', 'Helps construction'],
      ['2', 'Seeking Sanctuary', 'Stays a turn'],
      ['3', 'Mercenary Guest', 'Extra defender'],
      ['4', 'Friendly Monster', 'Repels attack'],
    ]);
    final result = rollTable(table, rng: _FixedRandom(1));
    expect(result, isNotNull);
    expect(result!.roll, 2);
    expect(result.row, '2 | Seeking Sanctuary | Stays a turn');
  });

  test('returns null for empty or header-only table', () {
    expect(rollTable(FacilityTable(table: [])), isNull);
    expect(rollTable(FacilityTable(table: [['d6', 'Event']])), isNull);
  });
});

group('FacilityTable JSON', () {
  test('rollable defaults to false and round-trips', () {
    final plain = FacilityTable.fromJson({
      'table': [
        ['d6', 'X'],
        ['1', 'a'],
      ],
    });
    expect(plain.rollable, isFalse);

    final rollable = FacilityTable(
      table: [
        ['d6', 'X'],
        ['1', 'a'],
      ],
      rollable: true,
    );
    final back = FacilityTable.fromJson(rollable.toJson());
    expect(back.rollable, isTrue);
    expect(back.table, rollable.table);
  });
});
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/data/models/bastion/table_test.dart`
Expected: FAIL — `rollTable` is not defined; `FacilityTable` has no `rollable`.

- [ ] **Step 3: Implement the helper and flag**

Replace the top of `lib/data/models/bastion/table.dart` (the `FacilityTable` class and `rollTableResult`) so it reads:

```dart
import 'dart:math';

class FacilityTable {
  final List<List<String>> table;
  final bool rollable;

  FacilityTable({required this.table, this.rollable = false});

  factory FacilityTable.fromJson(Map<String, dynamic> json) {
    return FacilityTable(
      table: (json['table'] as List? ?? [])
          .map((tableItems) => List<String>.from(tableItems))
          .toList(),
      rollable: json['rollable'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'table': table,
      'rollable': rollable,
    };
  }
}

/// Rolls on [table]'s data rows (row 0 is the header) and returns the numeric
/// die result plus the matching row's cells joined with ' | ', or null if no
/// rows are parseable.
///
/// First-column formats: single number ('1', '8') or inclusive range
/// ('01 - 40', '99 - 00' — 0 as an upper bound means 100). The die size is
/// the highest upper bound; a roll matching no range (table gaps) clamps to
/// the first row whose upper bound is >= the roll.
({int roll, String row})? rollTable(FacilityTable table, {Random? rng}) {
  final rows = table.table.length <= 1
      ? const <List<String>>[]
      : table.table.sublist(1);

  final parsed = <({int min, int max, List<String> cells})>[];
  for (final row in rows) {
    if (row.isEmpty) continue;
    final match = RegExp(r'^\s*(\d+)\s*(?:-\s*(\d+))?\s*$').firstMatch(row.first);
    if (match == null) continue;
    var min = int.parse(match.group(1)!);
    var max = match.group(2) == null ? min : int.parse(match.group(2)!);
    if (min == 0) min = 100;
    if (max == 0) max = 100;
    if (max < min) continue;
    parsed.add((min: min, max: max, cells: row));
  }
  if (parsed.isEmpty) return null;

  final die = parsed.map((p) => p.max).reduce((a, b) => a > b ? a : b);
  final roll = (rng ?? Random()).nextInt(die) + 1;

  ({int min, int max, List<String> cells})? hit;
  for (final p in parsed) {
    if (roll >= p.min && roll <= p.max) {
      hit = p;
      break;
    }
  }
  hit ??= parsed.firstWhere((p) => p.max >= roll, orElse: () => parsed.last);
  return (roll: roll, row: hit.cells.join(' | '));
}

/// Rolls on [table] and returns the matching row joined with ' | ', or null.
String? rollTableResult(FacilityTable table, {Random? rng}) =>
    rollTable(table, rng: rng)?.row;
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/data/models/bastion/table_test.dart`
Expected: PASS (existing `rollTableResult` tests plus the new groups).

- [ ] **Step 5: Run the analyzer**

Run: `flutter analyze`
Expected: no new issues.

- [ ] **Step 6: Commit**

```bash
git add lib/data/models/bastion/table.dart test/data/models/bastion/table_test.dart
git commit -m "Add rollTable helper and rollable flag to FacilityTable"
```

---

### Task 2: Mark genuinely random facility tables as rollable

**Files:**
- Modify: `lib/data/models/bastion/facility_catalog.dart` (Gaming Hall ~line 441, Training Area ~line 558)
- Test: `test/data/test_data/facility_catalog_test.dart`

**Interfaces:**
- Consumes: `FacilityTable.rollable` from Task 1.
- Produces: catalog tables for `Training Area` and `Gaming Hall` with `rollable: true`; all other facility tables remain `rollable: false`.

- [ ] **Step 1: Write the failing test**

Append this group inside `main()` in `test/data/test_data/facility_catalog_test.dart`:

```dart
group('rollable facility tables', () {
  test('only genuinely random tables are rollable', () {
    final catalog = getFacilityCatalog();
    Facility byName(String name) =>
        catalog.firstWhere((f) => f.name == name);

    expect(byName('Training Area').table!.rollable, isTrue);
    expect(byName('Gaming Hall').table!.rollable, isTrue);

    expect(byName('Kitchen').table!.rollable, isFalse);
    expect(byName('Workshop').table!.rollable, isFalse);
    expect(byName('Trading Hub').table!.rollable, isFalse);
  });
});
```

Add this import at the top of the test file:

```dart
import 'package:maura_bastion_system/data/models/bastion/facility.dart';
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/data/test_data/facility_catalog_test.dart`
Expected: FAIL — `rollable` is `false` for Training Area and Gaming Hall.

- [ ] **Step 3: Set the flag in the catalog**

In `lib/data/models/bastion/facility_catalog.dart`, change the Gaming Hall table:

```dart
      table: FacilityTable(
        rollable: true,
        table: [
          ['Round', '1-2', '3-5', '6'],
          ['One (1d6)', 'Bust', 'A gemstone worth 100 GP', 'A gemstone worth 200 GP'],
          [
            'Two (1d6)',
            'Bust',
            'A gemstone worth 200 GP',
            "Roll once on the Reward Table equal to the rank of this facility"
          ],
          ['Three (1d6)', 'Bust', 'A gemstone worth 200 GP', "You gain a Gambler's Lucky Dice"],
        ],
      ),
```

And change the Training Area table:

```dart
      table: FacilityTable(
        rollable: true,
        table: [
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
        ],
      ),
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/data/test_data/facility_catalog_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/data/models/bastion/facility_catalog.dart test/data/test_data/facility_catalog_test.dart
git commit -m "Mark Training Area and Gaming Hall tables as rollable"
```

---

### Task 3: `BastionTurnFacilityBuff` view-model and `FacilityBuffCard`

**Files:**
- Create: `lib/data/models/bastion/bastion_turn_facility_buff.dart`
- Create: `lib/features/bastions_page/presentation/widgets/facility_buff_card.dart`
- Test: `test/features/bastions_page/presentation/widgets/facility_buff_card_test.dart`

**Interfaces:**
- Consumes: `Facility`, `FacilityTableView`, `MedievalColors`, `ParchmentBorderPainter`.
- Produces:
  - `BastionTurnFacilityBuff({required Facility facility, int hirelingCount = 0, int? rolledNumber, String? rolledRow})`.
  - `FacilityBuffCard({required BastionTurnFacilityBuff buff})`.

- [ ] **Step 1: Write the failing test**

Create `test/features/bastions_page/presentation/widgets/facility_buff_card_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:maura_bastion_system/data/enums/rank.dart';
import 'package:maura_bastion_system/data/models/bastion/bastion_turn_facility_buff.dart';
import 'package:maura_bastion_system/data/models/bastion/facility.dart';
import 'package:maura_bastion_system/data/models/bastion/table.dart';
import 'package:maura_bastion_system/features/bastions_page/presentation/widgets/facility_buff_card.dart';

Widget _harness(BastionTurnFacilityBuff buff) => MaterialApp(
      home: Scaffold(body: FacilityBuffCard(buff: buff)),
    );

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('starts collapsed: shows name and hirelings, not the benefit',
      (tester) async {
    await tester.pumpWidget(_harness(BastionTurnFacilityBuff(
      facility: Facility(
        id: 'f1',
        name: 'Training Area',
        rank: Rank.B,
        description: 'You gain one Trainer benefit.',
      ),
      hirelingCount: 4,
    )));
    await tester.pumpAndSettle();

    expect(find.text('Training Area'), findsOneWidget);
    expect(find.text('Rank B'), findsOneWidget);
    expect(find.text('4 Hirelings'), findsOneWidget);
    expect(find.text('You gain one Trainer benefit.'), findsNothing);
  });

  testWidgets('expands on tap to reveal description, table and roll',
      (tester) async {
    await tester.pumpWidget(_harness(BastionTurnFacilityBuff(
      facility: Facility(
        id: 'f1',
        name: 'Training Area',
        rank: Rank.B,
        description: 'You gain one Trainer benefit.',
        table: FacilityTable(table: [
          ['Trainer', 'Benefit'],
          ['Weapon Expert', 'You gain +1 to hit with melee weapons.'],
        ]),
      ),
      hirelingCount: 4,
      rolledNumber: 1,
      rolledRow: '1 | Weapon Expert | You gain +1 to hit with melee weapons.',
    )));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Training Area'));
    await tester.pumpAndSettle();

    expect(find.text('You gain one Trainer benefit.'), findsOneWidget);
    expect(find.text('Rolled 1'), findsOneWidget);
    expect(
      find.text('1 | Weapon Expert | You gain +1 to hit with melee weapons.'),
      findsOneWidget,
    );
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/bastions_page/presentation/widgets/facility_buff_card_test.dart`
Expected: FAIL — `bastion_turn_facility_buff.dart` and `facility_buff_card.dart` do not exist.

- [ ] **Step 3: Create the view-model**

Create `lib/data/models/bastion/bastion_turn_facility_buff.dart`:

```dart
import 'package:maura_bastion_system/data/models/bastion/facility.dart';

/// Presentation-only view of a facility granting a benefit this turn, with
/// the result of its table roll when one was made.
class BastionTurnFacilityBuff {
  final Facility facility;
  final int hirelingCount;
  final int? rolledNumber;
  final String? rolledRow;

  const BastionTurnFacilityBuff({
    required this.facility,
    this.hirelingCount = 0,
    this.rolledNumber,
    this.rolledRow,
  });
}
```

- [ ] **Step 4: Create the widget**

Create `lib/features/bastions_page/presentation/widgets/facility_buff_card.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:maura_bastion_system/core/themes/theme_colors.dart';
import 'package:maura_bastion_system/data/models/bastion/bastion_turn_facility_buff.dart';
import 'package:maura_bastion_system/features/bastions_page/presentation/widgets/facility_table_view.dart';
import 'package:maura_bastion_system/features/news_paper/presentation/widgets/parchment_border.dart';

class FacilityBuffCard extends StatefulWidget {
  final BastionTurnFacilityBuff buff;

  const FacilityBuffCard({super.key, required this.buff});

  @override
  State<FacilityBuffCard> createState() => _FacilityBuffCardState();
}

class _FacilityBuffCardState extends State<FacilityBuffCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final facility = widget.buff.facility;
    return Container(
      decoration: BoxDecoration(
        gradient: const RadialGradient(
          center: Alignment.center,
          radius: 0.9,
          colors: [
            MedievalColors.parchmentLight,
            MedievalColors.parchmentDark,
          ],
          stops: [0.6, 1.0],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(50),
            blurRadius: 6,
            offset: const Offset(2, 3),
          ),
        ],
      ),
      child: CustomPaint(
        painter: ParchmentBorderPainter(),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        facility.name,
                        style: GoogleFonts.cinzel(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: MedievalColors.vermillion,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: MedievalColors.vermillionDark,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Rank ${facility.rank.title}',
                        style: GoogleFonts.cinzel(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: MedievalColors.goldPale,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.group,
                      size: 14,
                      color: MedievalColors.sepiaSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.buff.hirelingCount} Hirelings',
                      style: GoogleFonts.imFellEnglish(
                        fontSize: 13,
                        color: MedievalColors.sepiaSecondary,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more,
                      size: 20,
                      color: MedievalColors.sepiaSecondary,
                    ),
                  ],
                ),
                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 200),
                  crossFadeState: _expanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  firstChild: const SizedBox(width: double.infinity),
                  secondChild: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_expanded) ...[
                        const SizedBox(height: 8),
                        Text(
                          facility.description,
                          style: GoogleFonts.imFellEnglish(
                            fontSize: 15,
                            height: 1.4,
                            color: MedievalColors.sepiaInk,
                          ),
                        ),
                        if (facility.table != null) ...[
                          const SizedBox(height: 8),
                          FacilityTableView(table: facility.table!),
                        ],
                        if (widget.buff.rolledRow != null) ...[
                          const SizedBox(height: 8),
                          _buildRollCallout(widget.buff),
                        ],
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRollCallout(BastionTurnFacilityBuff buff) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: MedievalColors.parchment,
        border: Border.all(color: MedievalColors.goldLeaf),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              buff.rolledNumber == null
                  ? 'Rolled'
                  : 'Rolled ${buff.rolledNumber}',
              style: GoogleFonts.cinzel(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: MedievalColors.vermillion,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              buff.rolledRow!,
              style: GoogleFonts.imFellEnglish(
                fontSize: 15,
                height: 1.4,
                color: MedievalColors.sepiaInk,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/features/bastions_page/presentation/widgets/facility_buff_card_test.dart`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/data/models/bastion/bastion_turn_facility_buff.dart \
  lib/features/bastions_page/presentation/widgets/facility_buff_card.dart \
  test/features/bastions_page/presentation/widgets/facility_buff_card_test.dart
git commit -m "Add BastionTurnFacilityBuff view-model and FacilityBuffCard"
```

---

### Task 4: Result dialog shows event outcome and facility buffs; wire the turn

**Files:**
- Modify: `lib/features/bastions_page/presentation/widgets/bastion_turn_dialog.dart`
- Modify: `lib/features/bastions_page/presentation/bastion_page.dart` (`_takeBastionTurn`, lines ~203-285)
- Test: `test/features/bastions_page/presentation/widgets/bastion_turn_dialog_test.dart`
- Test: `test/features/bastions_page/presentation/bastion_page_test.dart`

**Interfaces:**
- Consumes: `BastionTurnFacilityBuff`, `FacilityBuffCard` (Task 3); `rollTable` (Task 1); `BastionTurnEventResult.rewardSummary`/`.dispatch` and `BastionTurnDispatchResult` (existing).
- Produces: `BastionTurnDialog({required Facility? advancedFacility, ChartEvent? event, BastionTurnResult? result, int? eventRollNumber, List<BastionTurnFacilityBuff> facilityBuffs})` and matching `show(...)`.

- [ ] **Step 1: Write the failing dialog tests**

Replace the entire contents of `test/features/bastions_page/presentation/widgets/bastion_turn_dialog_test.dart` with:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maura_bastion_system/data/enums/rank.dart';
import 'package:maura_bastion_system/data/models/bastion/bastion_turn_facility_buff.dart';
import 'package:maura_bastion_system/data/models/bastion/bastion_turn_result.dart';
import 'package:maura_bastion_system/data/models/bastion/facility.dart';
import 'package:maura_bastion_system/data/models/bastion/table.dart';
import 'package:maura_bastion_system/data/models/events/chart_event.dart';
import 'package:maura_bastion_system/data/models/events/chart_tier.dart';
import 'package:maura_bastion_system/data/models/events/event_chart.dart';
import 'package:maura_bastion_system/data/models/events/reward_spec.dart';
import 'package:maura_bastion_system/features/bastions_page/presentation/widgets/bastion_turn_dialog.dart';
import 'package:maura_bastion_system/features/bastions_page/presentation/widgets/facility_buff_card.dart';

const _event = ChartEvent(
  id: 'evt_berry',
  name: 'Berry Thicket',
  chart: EventChart.wilds,
  tier: ChartTier.basic,
  description: 'A quiet harvest.',
  reward: RewardSpec(note: 'A quiet harvest indeed'),
);

Facility _facility({
  required int constructedTurns,
  required int constructionTurns,
  String name = 'Kitchen',
  String description = '',
}) =>
    Facility(
      id: 'f1',
      name: name,
      rank: Rank.D,
      description: description,
      constructedTurns: constructedTurns,
      constructionTurns: constructionTurns,
    );

Widget _harness({
  Facility? advancedFacility,
  ChartEvent? event,
  BastionTurnResult? result,
  int? eventRollNumber,
  List<BastionTurnFacilityBuff> facilityBuffs = const [],
}) =>
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: BastionTurnDialog(
            advancedFacility: advancedFacility,
            event: event,
            result: result,
            eventRollNumber: eventRollNumber,
            facilityBuffs: facilityBuffs,
          ),
        ),
      ),
    );

void main() {
  testWidgets('in-progress construction shows the progress line',
      (tester) async {
    await tester.pumpWidget(_harness(
      advancedFacility:
          _facility(constructedTurns: 1, constructionTurns: 2),
    ));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Construction advanced: Kitchen (1/2 turns)'),
      findsOneWidget,
    );
  });

  testWidgets('completed construction shows the Completed! callout',
      (tester) async {
    await tester.pumpWidget(_harness(
      advancedFacility:
          _facility(constructedTurns: 2, constructionTurns: 2),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Completed!'), findsOneWidget);
    expect(find.text('Kitchen'), findsOneWidget);
  });

  testWidgets('no construction shows the empty state', (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    expect(find.text('No facilities under construction.'), findsOneWidget);
  });

  testWidgets('event section shows name, description, rolled number and row',
      (tester) async {
    await tester.pumpWidget(_harness(
      event: _event,
      eventRollNumber: 2,
      result: const BastionTurnResult(
        bastionId: 'b',
        bastionName: 'n',
        quest: 'q',
        event: BastionTurnEventResult(
          name: 'Berry Thicket',
          description: 'A quiet harvest.',
          rolledRow: '2 | Sweet berries',
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Berry Thicket'), findsOneWidget);
    expect(find.text('A quiet harvest.'), findsOneWidget);
    expect(find.text('Rolled 2'), findsOneWidget);
    expect(find.text('2 | Sweet berries'), findsOneWidget);
  });

  testWidgets('event section shows reward summary and dispatch outcome',
      (tester) async {
    await tester.pumpWidget(_harness(
      event: _event,
      result: const BastionTurnResult(
        bastionId: 'b',
        bastionName: 'n',
        quest: 'q',
        event: BastionTurnEventResult(
          name: 'Berry Thicket',
          description: 'A quiet harvest.',
          rewardSummary: '3 \u00d7 Herbs',
          dispatch: BastionTurnDispatchResult(
            units: [
              BastionTurnDispatchUnitResult(
                name: 'Sgt. Bram',
                rolls: [4, 5],
                subtotal: 9,
              ),
            ],
            bonus: 1,
            total: 10,
            dc: 12,
            success: false,
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Reward'), findsOneWidget);
    expect(find.text('3 \u00d7 Herbs'), findsOneWidget);
    expect(find.text('Dispatch'), findsOneWidget);
    expect(find.text('Sgt. Bram: 9 (4, 5)'), findsOneWidget);
    expect(find.textContaining('Total 10 vs DC 12'), findsOneWidget);
  });

  testWidgets('facility buffs render one card per facility', (tester) async {
    await tester.pumpWidget(_harness(
      facilityBuffs: [
        BastionTurnFacilityBuff(
          facility: _facility(constructedTurns: 2, constructionTurns: 2),
          hirelingCount: 1,
        ),
      ],
    ));
    await tester.pumpAndSettle();

    expect(find.text('Facilities granting benefits'), findsOneWidget);
    expect(find.byType(FacilityBuffCard), findsOneWidget);
    expect(find.text('Kitchen'), findsOneWidget);
  });

  testWidgets('tapping a facility buff card reveals its rolled result',
      (tester) async {
    await tester.pumpWidget(_harness(
      facilityBuffs: [
        BastionTurnFacilityBuff(
          facility: Facility(
            id: 'f1',
            name: 'Training Area',
            rank: Rank.B,
            description: 'You gain one Trainer benefit.',
            table: FacilityTable(table: [
              ['Trainer', 'Benefit'],
              ['Weapon Expert', '+1 to hit with melee weapons'],
            ]),
          ),
          hirelingCount: 4,
          rolledNumber: 1,
          rolledRow: '1 | Weapon Expert | +1 to hit with melee weapons',
        ),
      ],
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Training Area'));
    await tester.pumpAndSettle();

    expect(find.text('You gain one Trainer benefit.'), findsOneWidget);
    expect(find.text('Rolled 1'), findsOneWidget);
    expect(
      find.text('1 | Weapon Expert | +1 to hit with melee weapons'),
      findsOneWidget,
    );
  });

  testWidgets('empty facility buffs shows the empty state', (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    expect(
      find.text('No facilities are granting benefits this turn.'),
      findsOneWidget,
    );
  });
}
```

- [ ] **Step 2: Run the dialog tests to verify they fail**

Run: `flutter test test/features/bastions_page/presentation/widgets/bastion_turn_dialog_test.dart`
Expected: FAIL — `BastionTurnDialog` has no `facilityBuffs` / `eventRollNumber`; `facilityResults` is gone.

- [ ] **Step 3: Update `BastionTurnDialog`**

In `lib/features/bastions_page/presentation/widgets/bastion_turn_dialog.dart`:

Add these imports after the existing imports:

```dart
import 'package:maura_bastion_system/data/models/bastion/bastion_turn_facility_buff.dart';
import 'package:maura_bastion_system/features/bastions_page/presentation/widgets/facility_buff_card.dart';
```

Replace the class fields, constructor, and `show` factory (lines 10-40) with:

```dart
class BastionTurnDialog extends StatelessWidget {
  final Facility? advancedFacility;
  final ChartEvent? event;
  final BastionTurnResult? result;
  final int? eventRollNumber;
  final List<BastionTurnFacilityBuff> facilityBuffs;

  const BastionTurnDialog({
    super.key,
    required this.advancedFacility,
    this.event,
    this.result,
    this.eventRollNumber,
    this.facilityBuffs = const [],
  });

  static Future<void> show(
    BuildContext context, {
    required Facility? advancedFacility,
    ChartEvent? event,
    BastionTurnResult? result,
    int? eventRollNumber,
    List<BastionTurnFacilityBuff> facilityBuffs = const [],
  }) {
    return showDialog(
      context: context,
      builder: (_) => BastionTurnDialog(
        advancedFacility: advancedFacility,
        event: event,
        result: result,
        eventRollNumber: eventRollNumber,
        facilityBuffs: facilityBuffs,
      ),
    );
  }
```

In `build`, replace the facility section child (the `Flexible` that currently calls `_buildFacilityResultsSection`) with:

```dart
                Flexible(
                  child: SingleChildScrollView(
                    child: _buildFacilityBuffsSection(),
                  ),
                ),
```

Replace `_buildEventSection` (lines 156-210) with:

```dart
  Widget _buildEventSection() {
    final e = event;
    if (e == null) {
      return Text(
        'No individual event this turn.',
        textAlign: TextAlign.center,
        style: GoogleFonts.imFellEnglish(
          fontSize: 15,
          fontStyle: FontStyle.italic,
          color: MedievalColors.sepiaMuted,
        ),
      );
    }
    final rolledRow = result?.event?.rolledRow;
    final rewardSummary = result?.event?.rewardSummary;
    final dispatch = result?.event?.dispatch;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Individual Event',
          style: GoogleFonts.imFellEnglish(
            fontSize: 14,
            color: MedievalColors.sepiaSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          e.name,
          style: GoogleFonts.cinzel(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: MedievalColors.vermillion,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          e.description,
          style: GoogleFonts.imFellEnglish(
            fontSize: 15,
            height: 1.4,
            color: MedievalColors.sepiaInk,
          ),
        ),
        if (rolledRow != null) ...[
          const SizedBox(height: 8),
          _buildCallout(
            title: eventRollNumber == null ? 'Rolled' : 'Rolled $eventRollNumber',
            body: rolledRow,
          ),
        ],
        if (e.table != null) ...[
          const SizedBox(height: 8),
          FacilityTableView(table: e.table!),
        ],
        if (rewardSummary != null) ...[
          const SizedBox(height: 8),
          _buildCallout(title: 'Reward', body: rewardSummary),
        ],
        if (dispatch != null) ...[
          const SizedBox(height: 8),
          _buildCallout(title: 'Dispatch', body: _dispatchBody(dispatch)),
        ],
      ],
    );
  }

  String _dispatchBody(BastionTurnDispatchResult dispatch) {
    final lines = <String>[
      for (final unit in dispatch.units)
        '${unit.name}: ${unit.subtotal} (${unit.rolls.join(', ')})',
      'Total ${dispatch.total} vs DC ${dispatch.dc} \u2014 '
          '${dispatch.success ? 'success!' : 'failure.'}',
    ];
    return lines.join('\n');
  }
```

Replace `_buildFacilityResultsSection` (lines 212-243) with:

```dart
  Widget _buildFacilityBuffsSection() {
    if (facilityBuffs.isEmpty) {
      return Text(
        'No facilities are granting benefits this turn.',
        textAlign: TextAlign.center,
        style: GoogleFonts.imFellEnglish(
          fontSize: 15,
          fontStyle: FontStyle.italic,
          color: MedievalColors.sepiaMuted,
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Facilities granting benefits',
          style: GoogleFonts.imFellEnglish(
            fontSize: 14,
            color: MedievalColors.sepiaSecondary,
          ),
        ),
        const SizedBox(height: 4),
        for (final buff in facilityBuffs) ...[
          FacilityBuffCard(buff: buff),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
```

- [ ] **Step 4: Run the dialog tests to verify they pass**

Run: `flutter test test/features/bastions_page/presentation/widgets/bastion_turn_dialog_test.dart`
Expected: PASS.

- [ ] **Step 5: Wire `_takeBastionTurn`**

In `lib/features/bastions_page/presentation/bastion_page.dart`, add this import after line 16 (`bastion_turn_result.dart`):

```dart
import 'package:maura_bastion_system/data/models/bastion/bastion_turn_facility_buff.dart';
```

Replace lines 203-205:

```dart
    final rolledRow = roll.event.table == null
        ? null
        : rollTableResult(roll.event.table!);
```

with:

```dart
    final eventRoll =
        roll.event.table == null ? null : rollTable(roll.event.table!);
    final rolledRow = eventRoll?.row;
```

Replace lines 216-222:

```dart
    final facilityResults = bastion.eligibleFacilities
        .where((f) => f.table != null)
        .map((f) => BastionTurnFacilityResult(
              name: f.name,
              rolledRow: rollTableResult(f.table!),
            ))
        .toList();
```

with:

```dart
    final facilityBuffs = bastion.eligibleFacilities.map((f) {
      final shouldRoll = f.table != null && f.table!.rollable;
      final facilityRoll = shouldRoll ? rollTable(f.table!) : null;
      return BastionTurnFacilityBuff(
        facility: f,
        hirelingCount: bastion.facilityHirelingCount(f.id),
        rolledNumber: facilityRoll?.roll,
        rolledRow: facilityRoll?.row,
      );
    }).toList();
    final facilityResults = facilityBuffs
        .where((b) => b.rolledRow != null)
        .map((b) => BastionTurnFacilityResult(
              name: b.facility.name,
              rolledRow: b.rolledRow,
            ))
        .toList();
```

Replace the final `BastionTurnDialog.show` call (lines 279-285):

```dart
    await BastionTurnDialog.show(
      context,
      advancedFacility: advanced,
      event: roll.event,
      result: loggedResult,
      facilityResults: facilityResults,
    );
```

with:

```dart
    await BastionTurnDialog.show(
      context,
      advancedFacility: advanced,
      event: roll.event,
      result: loggedResult,
      eventRollNumber: eventRoll?.roll,
      facilityBuffs: facilityBuffs,
    );
```

- [ ] **Step 6: Update the bastion page turn test**

In `test/features/bastions_page/presentation/bastion_page_test.dart`, add this import near the other widget imports:

```dart
import 'package:maura_bastion_system/features/bastions_page/presentation/widgets/facility_buff_card.dart';
```

In the `turnFacilityJson` table for the 'Keep' facility (inside the test `'FAB takes a turn: advances construction and opens the flow dialog'`, around line 280), add `'rollable': true`:

```dart
            table: {
              'rollable': true,
              'table': [
                ['d4', 'Effect'],
                ['1', 'Bonus flavor'],
              ],
            },
```

Replace the post-turn assertions (around lines 336-342):

```dart
    // The turn summary dialog now appears: construction progress plus the
    // rolled result from the eligible facility (keep).
    expect(find.text('Construction advanced: Barracks (1/2 turns)'),
        findsOneWidget);
    expect(find.text('Facility Results'), findsOneWidget);
    expect(find.text('Keep'), findsWidgets);
    expect(find.text('1 | Bonus flavor'), findsOneWidget);
```

with:

```dart
    // The turn summary dialog now appears: construction progress plus an
    // expandable facility buff card for the eligible facility (keep).
    expect(find.text('Construction advanced: Barracks (1/2 turns)'),
        findsOneWidget);
    expect(find.text('Facilities granting benefits'), findsOneWidget);
    expect(find.text('Keep'), findsWidgets);
    await tester.tap(find.byType(FacilityBuffCard).first);
    await tester.pumpAndSettle();
    expect(find.text('1 | Bonus flavor'), findsOneWidget);
```

- [ ] **Step 7: Run both test files**

Run: `flutter test test/features/bastions_page/presentation/widgets/bastion_turn_dialog_test.dart test/features/bastions_page/presentation/bastion_page_test.dart`
Expected: PASS.

- [ ] **Step 8: Run the full suite and analyzer**

Run: `flutter test`
Expected: all tests PASS.

Run: `flutter analyze`
Expected: no new issues.

- [ ] **Step 9: Commit**

```bash
git add lib/features/bastions_page/presentation/widgets/bastion_turn_dialog.dart \
  lib/features/bastions_page/presentation/bastion_page.dart \
  test/features/bastions_page/presentation/widgets/bastion_turn_dialog_test.dart \
  test/features/bastions_page/presentation/bastion_page_test.dart
git commit -m "Show event outcome and facility buffs in the individual turn result dialog"
```

---

## Notes for the implementer

- The flow dialog was already passing `rewardSummary` and `dispatch` into `BastionTurnEventResult`; Task 4 only surfaces them in the result dialog.
- `rollTableResult` remains in `table.dart` for any other callers and for backward compatibility; `bastion_page.dart` no longer uses it after Task 4.
- `BastionTurnFacilityResult` (Discord payload) now carries only facilities whose rollable table was actually rolled.
- Do not add a "Open facility" button or navigation anywhere — these cards are informational.
