# Bastion Attacks Design

**Date:** 2026-09-23

## Problem

Bastion turns currently always resolve an individual event from the chart catalog. There is no way for enemies — bandits, cultists, or wild monsters — to assault the bastion itself. Defenders exist and are used in event dispatches, but they never actually defend the bastion in a fight.

This feature adds a chance that a Bastion turn is interrupted by an attack, replaced by a round-based combat between the bastion's defenders and a tier-scaled enemy force. Winning preserves the bastion; losing destroys a random facility, which the player must rebuild from scratch.

## Scope

- New attack model and combat engine (`lib/data/models/events/bastion_attack.dart`)
- New tiered enemy catalog (`lib/data/default_data/events/enemy_catalog.dart`)
- New combat dialog (`lib/features/bastions_page/presentation/widgets/bastion_attack_dialog.dart`)
- Turn entry point branch (`lib/features/bastions_page/presentation/bastion_page.dart`)
- Tests for the engine, catalog, dialog, and turn integration

Out of scope: modeling Lieutenants, siege weapons, wall destruction state, and persistent material storage. Loot is display-only, consistent with existing event rewards.

## Eligibility

An attack can only happen on a turn where **all** of the following hold:

1. The bastion has earned **at least 6 points** (`ChartPoints.earnedPointsFor(bastion) >= 6`).
2. The bastion has **no operational Humble Exterior** (`cat_humble_exterior` with `constructedTurns >= constructionTurns`). Humble Exterior already converts Surprise Attack to a quiet week; it blocks attacks entirely.
3. A random roll succeeds: `Random().nextDouble() < attackChance`, where `attackChance` is a named constant defaulting to `0.25`.

If eligible and triggered, the attack **replaces the individual event** for that turn. Construction advance and eligible facility buffs still run exactly as they do today.

## Enemy Force

The engine calls `ChartTurnEngine.rollTurn` as usual to obtain the tier the turn would have rolled, then discards the event and uses `ChartTurnRoll.tier` for the attack.

- **Count** = `1d4` × tier multiplier:
  - `basic` ×1, `skilled` ×2, `master` ×3, `legend` ×4 (range 1–16).
- **Type** is rolled flavor from a tiered catalog. Each catalog entry has `id`, `name`, `description`, and `tier`. Type does not change combat math.

## Combat Engine

Pure functions in `bastion_attack.dart`. Combat is deterministic given a seeded `Random`, so it is fully unit-testable.

### Defender dice

Each defender rolls one die by type, reusing `defaultDiceFor`:

- Knight `1d12`
- Beast `1d10`
- Bastion Defender `1d6`

### Facility-based configuration

Derived from `Bastion.facilities` (operational = `constructedTurns >= constructionTurns`):

- **Death threshold** defaults to **4**. A defender dies when its roll is strictly less than the threshold.
- **Armory** operational: threshold −1; at rank A or above, −2.
- **Battlements** operational: threshold −1 per two ranks above D (D=0, C=0, B=1, A=1, S=2).
- Thresholds **floor at 1** (a roll of 1 never dies).
- **Armory + Battlements** both operational: bastion defenders roll `d8` instead of `d6`.
- **War Room** operational: defenders roll at **advantage** (roll twice, keep the higher). *Assumption: Lieutenants are not modeled, so an operational War Room grants advantage.*

All reductions stack, floored at 1.

### Round loop

```
remaining = enemyCount
for each round:
  fighting = min(aliveDefenders, remaining)
  each fighting defender rolls (twice if advantage)
  each fighting defender kills exactly one enemy — even if it dies
  each fighting defender dies if its roll < threshold
  remaining -= kills
  remove dead defenders
  if remaining <= 0: win
  if aliveDefenders == 0: loss
```

A defender kills its enemy regardless of whether it survives, so the last enemy and the last defender can die in the same round.

- **Win** if the last enemy is killed, even when every defender also died (a pyrrhic win).
- **Loss** if all defenders are dead while enemies remain.
- **Auto-loss** if the bastion has no defenders when attacked; no combat rounds occur.

### Result shape

The engine returns a result containing: the enemy entry, the tier, the starting enemy count, an ordered list of rounds (each with per-defender roll(s), killed/casualty flags), surviving defenders, dead defenders, and `won`.

## Consequences

- **Win:** roll loot scaled to enemy tier via `rollMaterialRewards` with `cap = tier.rewardRankCap`, offered categories `creaturePart` and `metal`. Displayed as a reward note; not persisted, matching existing event rewards.
- **Loss:** destroy one **random facility** — any facility in the bastion, including one still under construction. Destruction removes the facility entirely (unassigning its hirelings and announcing removal) via the existing `BastionCubit.removeFacility`, so the player must pay its cost again to rebuild.
- **Defender deaths:** defenders that die are permanently removed from the bastion via the existing `DefendersCubit.removeDefender`.

## UI

New `BastionAttackDialog` (parchment styling, `StampIn`/`FadeSlide` juice, max-width 480, like `BastionTurnFlowDialog`). It presents:

1. The enemy group name, description, and count.
2. The defending roster and their dice.
3. Round-by-round resolution: each round's rolls and casualties.
4. The outcome stamp (`ATTACK REPELLED` / `BASTION FALLEN`), loot on victory, or the destroyed facility name on defeat.

The dialog returns the combat result to the caller. The caller then picks one random facility (when the attack was lost) and applies defender removals and facility destruction.

## Logging and Announcements

Logging reuses `BastionTurnEventResult` so the existing `DiscordApi.sendIndividualBastionTurn` path works unchanged:

- `name` = enemy group name
- `description` = enemy description plus the assault framing
- `rewardSummary` = loot line on victory, or the destroyed facility line on defeat
- `dispatch` = null

No new Discord payload fields or serialization changes are required.

## Turn Integration (`bastion_page._takeBastionTurn`)

After the quest is entered and chart points are loaded:

1. Evaluate eligibility. If eligible, roll `attackChance`.
2. If no attack: current behavior is unchanged.
3. If attack:
   - Roll the turn engine for the tier, build the enemy force, run the combat engine.
   - Show `BastionAttackDialog`.
   - Apply consequences: remove dead defenders, destroy a random facility on a loss.
   - Advance the turn (construction + branch-upgrade lapse) via the existing `advanceBastionTurn`.
   - Emit the `BastionTurnResult` with the attack recorded in the event slot and send the Discord announcement.
   - Show `BastionTurnDialog` as usual.

## Files

- **New:** `lib/data/models/events/bastion_attack.dart`, `lib/data/default_data/events/enemy_catalog.dart`, `lib/features/bastions_page/presentation/widgets/bastion_attack_dialog.dart`
- **Changed:** `lib/features/bastions_page/presentation/bastion_page.dart`
- **Tests:** `test/data/models/events/bastion_attack_test.dart`, `test/data/default_data/events/enemy_catalog_test.dart`, `test/features/bastions_page/presentation/widgets/bastion_attack_dialog_test.dart`, and a turn-integration test for the gate.

## Error handling

- The attack gate and engine are pure and return values; no throws are expected. `Random` seeds keep tests deterministic.
- The dialog never blocks the turn: if the player dismisses it, the result defaults to a resolved combat (already computed).
- Defender removal and facility destruction reuse existing cubit methods that already swallow and surface errors via snackbars; failures show the existing "something went wrong" message and leave the turn advanced.

## Testing

- Combat engine: thresholds, stacking facility reductions, floor at 1, advantage, d8 upgrade, pyrrhic win, auto-loss, round accounting, seeded determinism.
- Gate: earned points below 6 blocks, Humble Exterior blocks, successful roll triggers, failed roll does not.
- Enemy catalog: every tier has at least one entry; counts/multipliers match the spec.
- Dialog: renders enemy/roster, shows outcome, returns result.
- Integration: an eligible attack turn routes to the attack dialog and applies a loss penalty.
- Run `flutter test` for the affected files and the full suite.
