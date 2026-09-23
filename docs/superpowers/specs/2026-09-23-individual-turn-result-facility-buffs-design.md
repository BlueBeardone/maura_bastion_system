# Individual Turn Result Dialog — Event Outcome & Facility Buffs

Date: 2026-09-23

## Problem

`BastionTurnDialog` is the post-turn summary shown only for an Individual
Bastion Turn (from `_takeBastionTurn` in `bastion_page.dart`). Today it:

1. Shows the individual event name, description, and rolled row, but none of
   the event's outcome — the reward summary and (for dispatch events) the unit
   rolls, total vs DC, and MISSION HELD/LOST result. Those exist only inside
   the earlier `BastionTurnFlowDialog`.
2. Lists facility results as a flat block that only includes eligible
   facilities **with a table**, and skips every eligible facility without one
   (e.g. Bedroom, Parlor). It never shows what a facility actually gives you,
   and the player cannot drill into a facility to read its benefit.
3. Rolls blindly on every eligible facility table, including reference and
   choice tables (Kitchen rank list, Trading Hub price list, Workshop tool
   list, ...) that are not random per-turn outcomes. The rolled row is shown
   without the numeric die result.

## Goal

In the Individual turn result dialog, and only there:

1. Display the full individual event result: name, description, table, the
   numeric roll and produced row, the reward summary, and the dispatch
   outcome when present.
2. Show a list of **every eligible facility** — fully constructed and staffed
   to its minimum hireling requirement (`Bastion.eligibleFacilities`).
3. Tapping a facility expands it to reveal its rules description (the buff it
   grants) and its table (if any).
4. Show the numeric die result and produced row for the **individual event's**
   table roll. Facility tables are reference/choice lists and are not rolled.

### Decision — no facility table rolling (2026-09-23)

An earlier draft marked the Training Area and Gaming Hall tables
`rollable: true` and rolled them per turn. The final review found those tables
cannot be parsed by `rollTable` (its parser requires a numeric first column;
the catalog facilities' tables are rank/tool/beverage/trainer lists). In
practice no catalog facility table has a numeric first column, so facility
rolling never fired and the Discord `facilityResults` list was always empty.
The human decided: **do not roll facility tables at all.** The
`FacilityTable.rollable` field and the `rollTable` helper remain as
infrastructure for future use, and no catalog table is marked rollable. The
individual event table continues to roll and now shows its numeric result.

## Non-goals / out of scope

- No changes to `BastionTurnFlowDialog`, the monthly turn, or the bastion page
  facility cards.
- These enhancements are specific to the Individual turn result dialog.
  `BastionTurnDialog` is only used from `_takeBastionTurn`, so nothing else is
  affected.
- No change to the Discord payload *schema*; only the set of facilities that
  ride in `facilityResults` changes (see below).
- This is separate from the 2026-09-22 expandable facility cards on the
  bastion page, which were reverted. This work is in the turn result dialog
  and is not a revival of those changes.

## Approach

Selected: **resolve in `_takeBastionTurn`, pass a presentation view-model to a
stateless dialog** (Approach A). All dice rolling happens in
`bastion_page.dart`; `BastionTurnDialog` remains display-only and
deterministic, so it is straightforward to test.

Rejected:

- **Dialog owns the rolls** — buries turn logic in the UI, makes widget tests
  nondeterministic, and lets the displayed result drift from what was recorded
  and sent to Discord.
- **Roll inside the cubit** — mixes dice rolling into a persistence method.

## Changes

### 1. Table helper — `data/models/bastion/table.dart`

- Add `({int roll, String row})? rollTable(FacilityTable table, {Random? rng})`
  returning both the numeric die result and the matched row (cells joined with
  `' | '`). Same parsing/clamping rules as today; returns `null` when no rows
  are parseable.
- Reimplement `rollTableResult` as a thin wrapper: `rollTable(table, rng: rng)?.row`.
  Its signature and behavior stay identical, so event and other call sites are
  unaffected.

### 2. Rollable flag — `data/models/bastion/table.dart` + catalog

- `FacilityTable` gains `final bool rollable` (default `false`), wired through
  the constructor, `fromJson` (`json['rollable'] as bool? ?? false`), and
  `toJson`.
- No catalog facility table is marked `rollable: true`. The flag is kept as
  infrastructure so a future genuinely-random, parseable facility table can opt
  in. (See "Decision" above.)
- Individual event tables are always rolled regardless of the flag; no event
  tables need the flag.

### 3. Presentation view-model — `bastion_turn_dialog.dart`

Add a small immutable class used only for rendering:

```dart
class BastionTurnFacilityBuff {
  final Facility facility;
  final int hirelingCount;
  final int? rolledNumber;
  final String? rolledRow;
}
```

The full `Facility` is carried so the card can render name, rank, description,
and table without extra lookups. The existing Discord model
`BastionTurnFacilityResult` is untouched.

### 4. Turn resolution — `bastion_page.dart` (`_takeBastionTurn`)

- Event roll: replace `rollTableResult(roll.event.table!)` with
  `rollTable(roll.event.table!)`, keeping both the number and the row. The
  event row still goes into `BastionTurnEventResult.rolledRow`; the numeric
  roll is passed to the dialog for display.
- Build `facilityBuffs` from `bastion.eligibleFacilities`:
  - Every eligible facility is included (including those with no table).
  - If the facility has a table with `rollable == true`, roll once and set
    `rolledNumber` and `rolledRow`; otherwise leave both `null`. In practice no
    facility table is rollable, so both stay `null` and the card shows no roll.
- Discord payload: `facilityResults` is the subset of eligible facilities that
  were actually rolled. With no rollable facility tables it is empty. The
  payload shape is unchanged; backend formatting is unaffected.
- Pass `facilityBuffs` to `BastionTurnDialog`. `result` continues to be passed
  so the dialog can render the event reward summary and dispatch outcome.

### 5. Result dialog — `bastion_turn_dialog.dart`

- Replace the `facilityResults` parameter with `facilityBuffs`
  (`List<BastionTurnFacilityBuff>`, default `const []`).
- Event section:
  - name, description, and table as today;
  - `Rolled <n>` callout followed by the produced row (uses the numeric roll);
  - reward summary when `result?.event?.rewardSummary != null`;
  - dispatch outcome when `result?.event?.dispatch != null`: one line per unit
    (`<unit>: <subtotal> (<rolls>)`) and a line
    `Total <total> vs DC <dc> — success!/failure.`, matching the flow dialog's
    wording.
- Facility section:
  - heading, e.g. "Facilities granting benefits";
  - one `FacilityBuffCard` per buff;
  - empty state "No facilities are granting benefits this turn." when the list
    is empty.
- Construction section unchanged.

### 6. New widget — `widgets/facility_buff_card.dart`

`FacilityBuffCard` (`StatefulWidget`):

- Collapsed: facility name, `Rank <X>` badge, hireling count, expand chevron,
  in the existing parchment/gold card style.
- Tapping anywhere toggles expansion with `AnimatedCrossFade`.
- Expanded: the facility's full `description`, its table via
  `FacilityTableView` when present, and — when `rolledRow != null` — a
  "Rolled <n>" + row callout.
- No "Open facility" navigation button; the card is informational only.

## Error handling

- No new failure modes: rolling is pure, and the dialog is display-only.
- If `rollTable` returns `null` for a table (unparseable), `rolledNumber` and
  `rolledRow` stay null; the facility still appears and expands to show its
  description and table.
- Existing turn-advance failure handling (the "Turn could not be advanced"
  snackbar and skipping the summary) is unchanged.

## Testing

- `test/data/models/bastion/table_test.dart`: `rollTable` returns the numeric
  roll and matching row; `rollTableResult` still returns the row only;
  `rollable` round-trips through JSON (present and absent).
- `test/data/test_data/facility_catalog_test.dart`: asserts no catalog facility
  table is `rollable` (guards against accidental per-turn facility rolling);
  `rollable` round-trips through `FacilityTable` JSON.
- `test/features/bastions_page/presentation/widgets/bastion_turn_dialog_test.dart`:
  - event section renders reward summary and dispatch outcome when present,
    and numeric roll + row;
  - one card per eligible buff, including a facility with no table;
  - tapping a card reveals description, table (when present), and roll result;
  - empty state when `facilityBuffs` is empty;
  - replace the old "Facility Results" assertions.
- `test/.../widgets/facility_buff_card_test.dart`: collapsed by default;
  expands on tap; shows description/table/roll only when expanded.
- `test/features/bastions_page/presentation/bastion_page_test.dart`: a turn
  includes all eligible facilities (including no-table and non-rollable ones);
  no facility table is rolled; the Discord payload's `facilityResults` is empty
  (captured POST body is parsed and asserted).

## Verification

Run the project's test suite (`flutter test`) and the analyzer
(`flutter analyze`) before considering the work complete.
