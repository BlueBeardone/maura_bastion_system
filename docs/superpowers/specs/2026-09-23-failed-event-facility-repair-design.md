# Failed Facility Events — One Construction Turn to Repair

Date: 2026-09-23

## Problem

Some individual chart events read as knocking a facility out of action when
the dispatch is failed — e.g. `hrt_cellar_rats` ("The rats keep the cellar for
now") and `hrt_kitchen_fire` ("the kitchen smells of smoke for days"). Today
that is pure flavor text in the failure note. Nothing in the game reacts: the
affected facility keeps working, and there is no repair.

`ChartEvent` has no link to a facility at all, and no facility in the catalog
is named "Cellar", so the event cannot currently identify a target.

## Goal

When a facility-affecting event's dispatch is failed, put the associated
facility into **exactly one construction turn**: it goes offline immediately
and the next turn's construction slot repairs it. The player is told what
happened in the end-of-turn dialog and in the Discord turn log.

### Scope

- Event to facility link: explicit, per event (`ChartEvent.facilityId`).
- Events in scope for this change:
  - `hrt_kitchen_fire` → `cat_kitchen`
  - `hrt_cellar_rats` → `cat_kitchen`

  The cellar is food storage, so the Kitchen is the closest facility; the
  human confirmed both events target the Kitchen.
- Only **dispatch** events can knock a facility offline. Events with no
  `dispatch` are never failed and so never trigger this.

### Non-goals / out of scope

- No change to the monthly turn, the `BastionTurnFlowDialog`, archetype events,
  or the individual bastion event catalog (`ibe_*`, display-only reference).
- No new backend/schema contract assumed. The Discord message is rendered by
  the external backend; a brand-new JSON field may not render (see Discord
  below).
- No change to `upgradeFacility`/`purchaseBranchUpgrade` rules. They already
  refuse while any facility is under construction, which is the intended
  "can't upgrade a broken facility" behavior.

## Approach

Selected: **reuse the existing construction fields** (Approach 1). A facility
is operational when `constructedTurns >= constructionTurns`, and
`advanceBastionTurn` already advances the first facility with
`constructedTurns < constructionTurns` by one and persists it. Marking the
Kitchen at `constructedTurns = constructionTurns - 1` therefore makes the next
turn's construction slot repair it, with no backend changes and with the
existing under-construction UI already reflecting the state.

Rejected:

- **New `repairTurns`/offline field on `Facility`** — the external backend
  would need to persist a new field (uncertain), plus extra UI plumbing.
- **Damage as a `RewardSpec` variant** — conflates rewards with event effects.

## Changes

### 1. Event model — `data/models/events/chart_event.dart`

- Add `final String? facilityId;` to `ChartEvent` (default `null`) and to the
  const constructor.

### 2. Event data — `data/default_data/events/hearth_events.dart`

- `hrt_kitchen_fire`: `facilityId: 'cat_kitchen'`.
- `hrt_cellar_rats`: `facilityId: 'cat_kitchen'`.

### 3. Pure helper — `data/models/events/turn_flow.dart`

Add:

```dart
Facility? facilityKnockedOffline(Bastion bastion, String? facilityId)
```

- Returns `null` when `facilityId` is null, the facility is absent from the
  bastion, the facility is already non-operational
  (`constructedTurns < constructionTurns`), or `constructionTurns <= 0`.
- Otherwise returns `facility.copyWith(constructedTurns: constructionTurns - 1)`.

This is pure and independently testable; it both computes the persisted state
and lets `_takeBastionTurn` build the Discord/log payload before advancing.

### 4. Cubit — `features/bastions_page/logic/bastion_cubit.dart`

- `advanceBastionTurn` gains an optional `String? closeFacilityId`.
- After the normal construction advance (and branch-upgrade lapses) and
  **before** `refreshUserBastion`, if `closeFacilityId` resolves via
  `facilityKnockedOffline` to a target, persist that target with
  `_facilityApi.update` as part of the same batch.
- If there is no under-construction target but there is a close target, still
  call `gate(null)` and persist the damaged facility; return `null` for the
  advanced facility (as "no construction this turn" already does).
- The close target is computed from the pre-advance bastion. An operational
  facility can never be the advance target (advance requires under
  construction), so the two never conflict; the guard in the helper prevents
  stacking on an already-offline facility.

### 5. Page wiring — `features/bastions_page/presentation/bastion_page.dart`

In `_takeBastionTurn`, after the flow dialog returns:

- `dispatchFailed = turnResult?.dispatch != null && !turnResult!.dispatch!.success`
- `closedFacility = dispatchFailed ? facilityKnockedOffline(bastion, event.facilityId) : null`
- Pass `closeFacilityId: closedFacility?.id` to `advanceBastionTurn`.
- Include `closedFacility?.name` in the `BastionTurnEventResult` built in the
  gate so the Discord payload and result dialog carry it.

### 6. Result model — `data/models/bastion/bastion_turn_result.dart`

- `BastionTurnEventResult` gains `final String? closedFacilityName;`, wired
  through the constructor, `fromJson`, and `toJson`.

### 7. Dialog — `features/bastions_page/presentation/widgets/bastion_turn_dialog.dart`

- In the event section, when `result?.event?.closedFacilityName != null`, show a
  callout titled "Out of action" with body
  `<name> is offline — 1 construction turn to repair.`

### 8. Discord note

The Discord message is built by the external backend from
`BastionTurnResult.toJson()`. To guarantee the note is rendered without a
backend change, also append a sentence to the logged
`BastionTurnEventResult.description`:

> `The <name> is out of action until it is repaired over one construction turn.`

The dedicated `closedFacilityName` field is still added for the in-app dialog
and future backend use. If the backend later renders the field directly, the
appended description sentence can be dropped.

## Error handling

- Missing/absent/offline facility: no-op, turn proceeds normally.
- If the turn advance or its Discord gate fails, no damage is persisted (the
  existing "Turn could not be advanced" path is unchanged); the facility is
  damaged only as part of a successfully logged turn.
- The damage update shares the advance's error handling: a failed update
  surfaces through the existing failure path rather than silently.

## Testing

- `test/data/models/events/turn_flow_test.dart`: `facilityKnockedOffline`
  returns `null` for null id, absent facility, and already-offline facility,
  and returns `constructedTurns == constructionTurns - 1` for an operational
  facility.
- `test/data/default_data/events/chart_events_catalog_test.dart`: the two
  hearth events carry `facilityId == 'cat_kitchen'`; other events have none.
- `test/features/bastions_page/logic/bastion_cubit_test.dart`:
  - `advanceBastionTurn(closeFacilityId: 'cat_kitchen')` persists the Kitchen at
    `constructedTurns = constructionTurns - 1` after advancing a different
    under-construction facility;
  - it persists the damage when nothing else is under construction and still
    runs the gate;
  - it is a no-op when the facility is absent or already offline.
- `test/features/bastions_page/presentation/widgets/bastion_turn_dialog_test.dart`:
  the "Out of action" callout renders when `closedFacilityName` is set and is
  absent otherwise.

## Verification

Run `flutter test` and `flutter analyze` before considering the work complete.
