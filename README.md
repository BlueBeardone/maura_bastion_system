# Maura Bastion System

A Flutter companion app for running and tracking D&D bastions — the shared
front-end for a tabletop campaign's bastion management.

Players build and upgrade facilities, recruit defenders and hirelings, and
allocate points across six event charts (The Wilds, The Deeps, The Trade Road,
The War March, The Hearth, The Arcane). Each turn, an event engine rolls
against the funded charts, resolves dispatch missions with the bastion's
units, and pays out rewards. Notable results are published to a shared
newspaper; quiet turns generate small local filler articles in the same dry
Guild-of-Heralds voice, stored per device and used to pad thin editions —
never displacing the DM's shared content.

Out of scope on purpose: gold/accounts are tracked by a Discord bot, and
character sheets live in D&D Beyond. This app knows nothing about either.

## Features

- **Bastions** — create and edit bastions; build, upgrade, and remove
  facilities; purchase branch upgrades.
- **Defenders & hirelings** — recruit (singly or in bulk), assign hirelings
  to facilities, and track acquisition stories.
- **The Individual Bastion Turns** — allocate earned points across the six event charts;
  the turn engine rolls events weighted by your allocations, with tier
  scaling (basic → legend) and archetype events for converged charts.
- **Dispatch** — send defenders and hirelings on event missions against
  skill-check DCs; rewards scale with the event's tier.
- **Newspaper** — a shared, DM-authored edition plus auto-published notable
  events and per-device quiet-week fillers.
- **Discord announcements** — construction, hires, recruits, and upgrades are
  announced to the campaign's Discord (fire-and-forget).

## Running

### Locally

```bash
flutter pub get
flutter run -d chrome   # or any device
```

### Docker (web build)

```bash
docker compose up -d
# app at http://localhost:8080
```

The app talks to a REST backend (see `lib/api/` for endpoints); the backend
service lives in a separate repository. Point builds at the right API host
before deploying.

## Tests

```bash
flutter test       # full suite
flutter analyze    # lints
```

## Project structure

```
lib/
  api/            REST client layer (bastions, defenders, hirelings, newspaper, Discord)
  core/           DI, themes, Discord announcer, shared utils
  data/           Models, enums, and the default event/reward/newspaper catalogs
  features/       Feature pages (bastions, newspaper, login, …) in cubit/presentation/data split
  widgets/        Shared scaffolding
```

Design docs and implementation plans live under `docs/superpowers/`
(gitignored, local only).
