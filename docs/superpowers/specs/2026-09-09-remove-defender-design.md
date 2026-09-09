# Remove Bastion Defender — Design

**Date:** 2026-09-09
**Status:** Approved
**Scope:** `lib/features/bastions_page/`

## Problem

Defenders can be enlisted on the Defenders page but never removed. `DefenderApi.delete()` already exists (`lib/api/defender_api.dart`), yet neither the cubit nor the UI exposes removal. A defender added by mistake is permanent.

## Goal

Tapping a defender card opens a parchment-styled detail sheet showing the defender's info, with a "Remove from Bastion" action that — after explicit confirmation — deletes the defender via the API and updates the UI.

## Non-Goals

- No editing of defenders (only viewing and removing).
- No changes to `addDefender` / `loadDefenders` error handling (existing silent `catch (_) {}` stays as-is; that is a separate concern).

## Design

### 1. `DefendersCubit.removeDefender(String id)`

```dart
Future<void> removeDefender(String id) async
```

- Calls `await _defenderApi.delete(id)`.
- On success, emits state with that defender filtered out of `state.defenders`.
- **Error handling (deliberate divergence from existing methods):** rethrows on failure instead of silently swallowing, so the UI can show an error snackbar. A silent failure here would look like a tap that does nothing.

### 2. Defender detail sheet

New widget: `lib/features/bastions_page/presentation/widgets/defender_detail_sheet.dart`, shown with `showModalBottomSheet` when a `_buildCompactDefenderCard` is tapped.

- **Styling:** matches existing parchment containers — radial parchment gradient, `ParchmentBorderPainter`, Cinzel headers, imFellEnglish body text.
- **Content:** type icon, defender name, type title, description, and acquisition story (when present). The circular icon style from `_DefendersViewState._buildTypeIcon` is extracted into a small shared widget so the page and the sheet render it identically.
- **Action:** red "Remove from Bastion" button at the bottom.

### 3. Confirmation dialog

Tapping "Remove from Bastion" opens a standard `AlertDialog`: "Remove {name}? This cannot be undone." with Cancel and Remove actions. On confirm:

1. `cubit.removeDefender(defender.id)`
2. Close the detail sheet.
3. "Defender removed" snackbar.

On failure (rethrown error): sheet stays open, "Failed to remove defender" error snackbar.

## Testing

- **Cubit** (`test/features/bastions_page/logic/defenders_cubit_test.dart`, matching existing test patterns):
  - Calls `DefenderApi.delete(id)` and removes the defender from state on success.
  - Rethrows when the API call fails; state unchanged.
- **Page** (`test/features/bastions_page/presentation/defenders_page_test.dart`):
  - Tapping a card opens the detail sheet with name/description/story.
  - Remove flow: confirm → API called → card gone → snackbar shown.
  - Cancel keeps the defender; API failure shows error snackbar and keeps the defender.
