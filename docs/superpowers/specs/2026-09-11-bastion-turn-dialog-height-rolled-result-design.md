# Bastion Turn Dialog: Content-Driven Height & Rolled Result Display

Date: 2026-09-11

## Problem

The Bastion turn dialog (`lib/features/bastions_page/presentation/widgets/bastion_turn_dialog.dart`) has two problems:

1. **Fixed height.** The dialog is capped at a hard `maxHeight: 480`, so it always renders at that height (stretched) even when its content is short, and crams long content into two small scroll sections.
2. **Rolled result is invisible.** When a turn rolls on an event's table, the rolled row (`BastionTurnResult.event.rolledRow`, computed in `bastion_page.dart:131` via `rollTableResult`) is sent to Discord but never shown to the player in the dialog. The dialog shows the event's name, description, and full table, but not which row was rolled.

## Design

### 1. Content-driven dialog height

In `BastionTurnDialog.build`, replace the fixed constraint:

```dart
constraints: const BoxConstraints(maxHeight: 480),
```

with:

```dart
constraints: BoxConstraints(
  maxWidth: 480,
  maxHeight: MediaQuery.of(context).size.height * 0.85,
),
```

The dialog then sizes itself to its content, up to 85% of screen height. The existing `Flexible` + `SingleChildScrollView` sections stay unchanged, so oversized content still scrolls instead of overflowing.

### 2. Rolled result callout (Approach A)

In `_buildEventSection()`, after the event description (and before the table view), render a callout when a rolled row exists:

- **Data source:** `result?.event?.rolledRow` — already passed into the dialog, no new plumbing needed.
- **Presentation:** a parchment-framed callout box styled to match `FacilityTableView` (gold border, parchment background, cinzel header), containing:
  - Header label: `Rolled` (cinzel, vermillion, like the table header)
  - Body: the `rolledRow` string (imFellEnglish, sepiaInk), rendered as plain text exactly as it is sent to Discord.
- **Null handling:** if `rolledRow` is null (no table, or unparseable rows), the callout is omitted entirely.

### Not in scope

- No highlight of the rolled row inside `FacilityTableView` (Approach B rejected — the view is shared with facility tiles where no roll exists).
- No changes to the Discord payload or `BastionTurnResult` model.
- No changes to facility tiles in the dialog.

## Files touched

- `lib/features/bastions_page/presentation/widgets/bastion_turn_dialog.dart` — both changes.

## Testing

- Manual: run the app, take a Bastion turn with a short event and with a table event; verify the dialog shrinks with short content and the callout appears with the rolled row text.
- Existing widget tests for the turn dialog (if any) must still pass: `flutter analyze` and `flutter test`.