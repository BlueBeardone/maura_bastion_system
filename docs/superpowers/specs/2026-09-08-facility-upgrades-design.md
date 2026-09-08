# Facility Upgrades — Design

Date: 2026-09-08

## Problem

Several facilities in the catalog describe rank-based scaling (e.g. Barracks "Houses up to 4 Bastion Defenders per rank above E", Bedroom "Increases by 1d4 per rank above D"). Currently a facility is built once at a fixed `Rank` and can never increase. The descriptions promise benefits that the app cannot deliver because there is no upgrade path. Players should be able to upgrade an owned facility to the next rank, gaining the promised dice/bonuses.

## Scope

Add a repeatable, rank-by-rank upgrade mechanic for a fixed set of 13 catalog facilities. Upgrades reuse the existing construction-progress mechanism so the only new surface is a helper on `Rank`, a method on `BastionCubit`, and an "Upgrade" button on the facility detail page.

No backend changes. No `Facility` model / serialization changes.

## Rules

1. **Upgradeable set** — exactly these catalog ids (identified by `facility.id`):
   - Barracks, Battlements, Bedroom, Dining Room, Kitchen, Well Room, Siege Engine (all `Rank.D`)
   - Library, Sanctuary, Stables, Trading Hub (all `Rank.C`)
   - Training Area (`Rank.B`)
   - Observatory (`Rank.A`)
   - S-rank facilities have no upgrade (nothing above S).
2. **Chain** — an upgradeable facility can be upgraded repeatedly up the chain: D→C→B→A→S. Each step is one rank.
3. **Construction time** — each upgrade step takes **2 turns**.
4. **Cost** — each upgrade step costs the **difference** between the next rank's base build cost and the current rank's base build cost:
   - D→C: 1500 − 600 = **900**
   - C→B: 4500 − 1500 = **3000**
   - B→A: 9000 − 4500 = **4500**
   - A→S: 20000 − 9000 = **11000**
   - Base costs: D=600, C=1500, B=4500, A=9000, S=20000 (from the current catalog).
5. **One at a time** — a user cannot upgrade a facility while **any** facility in that bastion is busy (constructing or upgrading), i.e. while any facility has `constructedTurns < constructionTurns`.

## Design

### 1. `rank.dart` — next-rank helper

Add to the existing `MainNavigationExtension`-style extension on `Rank` (or a new helper on the enum):

```dart
Rank? get next {
  switch (this) {
    case Rank.D: return Rank.C;
    case Rank.C: return Rank.B;
    case Rank.B: return Rank.A;
    case Rank.A: return Rank.S;
    case Rank.S: return null;
  }
}
```

### 2. `facility_catalog.dart` — upgradeability metadata

Add:

- `const Map<Rank, int> baseCostByRank` — base build costs: D=600, C=1500, B=4500, A=9000, S=20000.
- `const Set<String> upgradeableFacilityIds` — the 13 ids above.

Upgrade cost for a facility at `rank` = `baseCostByRank[rank.next!] - baseCostByRank[rank]`. The upgraded facility's `cost` field is set to `baseCostByRank[rank.next!]` (it is now worth the next rank's base build).

`Facility` model is untouched; upgradeability is a catalog lookup on the facility's `id`, so upgraded facilities remain identified by their catalog id.

### 3. `BastionCubit.upgradeFacility(bastionId, facility)`

New method mirroring `addFacility` / `advanceBastionTurn`:

- **Guards** (return `null` on any):
  - No bastion loaded for `bastionId`.
  - `facility.rank == S`.
  - `facility.id` not in `upgradeableFacilityIds`.
  - Bastion has **any** facility with `constructedTurns < constructionTurns` (one-at-a-time rule).
- Build the upgraded `Facility`:
  - `rank = facility.rank.next`
  - `cost = baseCostByRank[facility.rank.next!]`
  - `constructionTurns = 2`
  - `constructedTurns = 0`
  - everything else (id, name, description, imgUrl, table, minimumRequiredHirelings) unchanged.
- `_facilityApi.update(...)` then `loadBastions()`.
- Reuse the `_advancingTurn` guard pattern to prevent double-submits.
- On error, emit `BastionErrorState` like the other methods.

### 4. `FacilityPage` — Upgrade button

Add an `onUpgrade` callback param (same pattern as `onConstruct`). The currently-construction-only `BastionPage` already wires an `onConstruct`; `BastionPage` will pass an `onUpgrade` that calls `cubit.upgradeFacility` then reloads.

Render a full-width elevated button below the description/table, styled identically to the existing "Construct Facility" button (vermillion background, gold-pale text, `GoogleFonts.cinzel`):

```
Upgrade to Rank C — 900 GP
```

Show it only when **all** hold:
- `isUserBastion && !isSelectionMode`
- `facility.constructedTurns >= facility.constructionTurns` (this facility is not itself busy)
- `facility.rank != S` and `upgradeableFacilityIds.contains(facility.id)`
- `!bastion.facilities.any((f) => f.constructedTurns < f.constructionTurns)` (no other facility is busy)

The one-at-a-time rule is enforced both in the UI (button hidden) and in the cubit (guard).

### 5. Behavior while upgrading

The upgrade reuses the construction mechanic, so existing behavior applies for free:

- Card renders at 50% opacity with progress (`1/2t`), because `constructedTurns < constructionTurns`.
- Bastion Turn dialog reports "Construction advanced: … (1/2 turns)".
- After 2 turns the facility is fully active at the new rank; its rank badge, cards, tables, and all rank-derived dice/bonus text reflect the new rank automatically.

Acceptable cosmetic limitation: during the 2 upgrade turns the facility labels read as "under construction" and the turn dialog says "Construction advanced" rather than "Upgrade advanced". No `isUpgrading` flag is added (explicitly rejected — Approach B).

## Error handling

- `upgradeFacility` refuses (returns `null`) when the one-at-a-time guard fails, `rank == S`, or the id is not upgradeable. UI hides the button in those cases, so this is a defensive backstop (e.g. same facility shown in a race).
- Double-submit prevented via a reuse of the `_advancingTurn`-style guard.
- API failure emits `BastionErrorState`, consistent with `addFacility` / `advanceBastionTurn`.

## Files touched

- `lib/data/enums/rank.dart` — `next` getter.
- `lib/data/test_data/bastion/facility_catalog.dart` — `nextRankBaseCost` map + `upgradeableFacilityIds` set.
- `lib/features/bastions_page/logic/bastion_cubit.dart` — `upgradeFacility`.
- `lib/features/bastions_page/presentation/facility_page.dart` — `onUpgrade` param + upgrade button.
- `lib/features/bastions_page/presentation/bastion_page.dart` — pass `onUpgrade` to `FacilityPage`.

## Testing

- Unit tests for `Rank.next` (D→C→B→A→S→null).
- Unit tests for `upgradeFacility`:
  - upgrades D→C with cost 900, turns 2, `constructedTurns 0`, rank defers to `next`.
  - refuses when another facility is busy.
  - refuses at `Rank.S`.
  - refuses for a non-upgradeable id.
  - preserves id/name/description/table/minimumRequiredHirelings/imgUrl.
- Widget test for the `FacilityPage` button:
  - visible for an owned, built, upgradeable, non-busy-bastion facility.
  - hidden when another facility is constructing.
  - hidden when the facility is itself mid-construction.
  - hidden for non-user bastions, non-upgradeable ids, and `Rank.S`.

## Out of scope

- Backend changes (keys, endpoints).
- `Facility` model / serialization changes.
- Distinguishing "under construction" vs "under upgrading" in UI copy.
- Facilities whose description has no rank-scaling mechanic (e.g. Armory, Pub, Workshop — they stay at base rank; their "Upgradeable to…" flavor text is not modeled).