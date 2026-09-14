# Nav Menu Pop-or-Push + Newspaper Button — Design

Date: 2026-09-14

## Problem

Every press of an app-bar navigation item (`My Bastion`, `Facilities`, `Hirelings`, `About`) calls `Navigator.push`, stacking a duplicate page each time. Pressing `My Bastion` repeatedly piles up identical `BastionMainScreen` instances. There is also no way to get back to the newspaper (the root page) from the menu — only the system back button, one page at a time.

## Goal

- Pressing a nav item for a page already in the navigation stack returns to the existing instance instead of pushing a duplicate. Pressing the item for the page you are currently on is a no-op.
- Add a `Newspaper` nav item that returns to the root newspaper page; it is a no-op when already there.

## UX Behavior

- The menu gains a **Newspaper** item, shown first. Both the desktop inline row and the mobile popup render from the `MainNavigation` enum, so both get it automatically.
- Pressing `My Bastion` / `Facilities` / `Hirelings` / `About`: if a route for that page exists anywhere in the navigation stack, pop back to it; otherwise push a fresh one.
- Pressing `Newspaper`: pop back to the first route (the newspaper root, `MainPage`). No-op if already there (`popUntil` with `isFirst` pops nothing on the root route).
- Facilities keeps its existing rule: hidden until the user has a bastion; tapping does nothing if `userBastion` is null.
- Existing behaviors preserved: the `_navigationInProgress` re-entrancy lock and the `loadBastions()` refresh after navigation completes.

## Implementation

Two files changed, no new files.

### `lib/data/enums/main_navigation_enum.dart`

- Add `newspaper` as the first enum value with title `"Newspaper"`.

### `lib/widgets/standard_scaffold/app_bar_navigation_menu.dart`

- The four content pages are pushed with `RouteSettings(name: MainNavigation.x.name)` so each has a stable, unique route name.
- A small static route registry (`Set<String>`) on the menu's state tracks which named pages are currently on the stack:
  - Name is added when the push starts.
  - Name is removed when the pushed future completes — this fires no matter how the page left the stack (system back, logout `popUntil`, or our own `popUntil`), so the registry cannot go stale.
- Press handler per item:
  - If the target name is in the registry → `Navigator.popUntil` to the route with that name (no push).
  - Otherwise → push as today (with the route name attached).
- `Newspaper` case → `Navigator.popUntil((route) => route.isFirst)`.

Why a registry: Flutter does not expose the navigator's route stack publicly, and `popUntil` is destructive — it cannot be used to inspect. Tracking names around the push futures is the smallest reliable mechanism.

## Testing

- Widget test in `test/` covering the guard logic, using fake GetIt registrations the way existing tests do:
  - Press `My Bastion` twice → exactly one `BastionMainScreen` route in the stack.
  - From a buried stack, press `Newspaper` → back at the root newspaper route.
  - Press `Newspaper` while already at root → no-op.
- Manual check on the running app: desktop menu and mobile popup, pressing `My Bastion` repeatedly, `Newspaper` from a buried stack, logout with a deep stack.

## Out of Scope

- No central `NavigationService` refactor (rejected as overkill for now).
- No changes to other push sites in the app; the registry only tracks the four nav pages.
