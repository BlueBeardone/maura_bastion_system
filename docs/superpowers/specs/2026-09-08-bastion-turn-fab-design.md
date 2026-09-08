# Bastion Turn FAB — Design

**Date:** 2026-09-08
**Status:** Approved
**Scope:** `lib/features/bastions_page/`, `lib/widgets/standard_scaffold/`

## Problem

The app tracks construction progress per facility (`Facility.constructedTurns` / `constructionTurns`) but nothing ever advances it. The D&D 2024 DMG "Bastion Turn" concept — facilities that are complete and staffed grant their described buffs/effects each turn — exists only as catalog text. There is no way for a player to take a bastion turn in the app.

## Goal

A Floating Action Button on the user's bastion page that:

1. Advances one construction turn for the **first** facility currently under construction (`constructedTurns < constructionTurns`, in `bastion.facilities` order), persisting via the Facility API.
2. Opens a parchment-styled dialog listing all facilities that can grant buffs this turn — i.e., **built** (`constructedTurns >= constructionTurns`) **and** staffed (`bastion.facilityHirelingCount(id) >= minimumRequiredHirelings`; facilities requiring 0 hirelings always qualify).
3. Each list item collapses to the facility name + rank; expanding reveals the full description and, when the facility has one, its table.

## Non-Goals

- No dice rolling / interactive tables — tables are display only.
- No buff state model or persistence of granted buffs.
- No turn history or turn counter for the bastion as a whole.
- FAB appears only on user bastions (`isUserBastion == true`); visitors cannot take turns.

## Design

### 1. `StandardScaffold` FAB support

Add an optional `floatingActionButton` parameter (`Widget?`) and pass it through to the inner `Scaffold`. Non-breaking; existing callers unchanged. FAB theming is already global (`theme_components.dart`: vermillion background, parchment foreground, circle shape).

### 2. `BastionCubit.advanceBastionTurn()`

```dart
Future<Facility?> advanceBastionTurn(String bastionId) async
```

- Requires `BastionLoadedState`; finds the bastion by id.
- Picks the first facility in `bastion.facilities` where `constructedTurns < constructionTurns`. If none, returns `null` without any API call.
- Reconstructs the `Facility` field-by-field (the model has no `copyWith`; follows the pattern in `createBastion`) with `constructedTurns: constructedTurns + 1`.
- Persists via `FacilityApi.update(id, updated)`, then `loadBastions()` to refetch.
- On error: emits `BastionErrorState` (existing pattern) and returns `null`.

### 3. Bastion Turn dialog

New widget: `lib/features/bastions_page/presentation/widgets/bastion_turn_dialog.dart`, shown with `showDialog`.

- **Header** reports the construction result:
  - Facility advanced: "Construction advanced: **{name}** ({n}/{total} turns)" with the timer icon styling used on facility cards.
  - Nothing under construction: "No facilities under construction."
- **Body:** scrollable list of eligible facilities (built + staffed, per definition above), rendered as theme-styled `ExpansionTile`s inside parchment-gradient containers with `ParchmentBorderPainter`:
  - Collapsed row: facility name (Cinzel, vermillion) + `Rank {rank.title}`.
  - Expanded: full description (imFellEnglish, sepiaInk) and — when `facility.table != null` — the table rendered like `FacilityPage._buildTableSection` (first row as vermillion/gold header row, gold borders, alternating parchment rows). The table rendering is extracted into a shared widget so `FacilityPage` and the dialog reuse one implementation.
- **Empty state:** "No facilities ready to grant buffs this turn."
- Single "Close" action; dismissing the dialog does nothing further — the turn was already advanced when the FAB was pressed.

### 4. Wiring in `BastionPage`

- When `isUserBastion`, pass a FAB (icon `Icons.auto_awesome`, tooltip "Bastion Turn") to `StandardScaffold`.
- `onPressed`: `final advanced = await cubit.advanceBastionTurn(bastionId);` then opens the dialog with the advanced facility (or null) and the eligible list computed from `bastion` (using `bastion.facilityHirelingCount`).

## Error Handling

- API failure advancing the turn: `BastionErrorState` emitted; dialog still opens but reports no construction advance (the cubit returns `null` on failure).
- Facility images/tables absent: dialog renders description only (table section omitted).

## Testing

- **Cubit** (`test/features/bastions_page/logic/bastion_cubit_test.dart`):
  - Increments the first under-construction facility and calls `FacilityApi.update`.
  - Caps at `constructionTurns` (facility completes).
  - Returns `null` and makes no API call when every facility is complete.
- **Page** (`test/features/bastions_page/presentation/bastion_page_test.dart`):
  - FAB absent when `isUserBastion == false`; present when true.
  - Tapping the FAB opens the dialog with the construction message; under-construction and understaffed facilities are excluded; eligible facilities show name + rank and expand to description/table.
