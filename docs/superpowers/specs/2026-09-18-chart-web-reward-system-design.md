# Chart Web Reward System — Design

Date: 2026-09-18
Branch: `reward-system`
Status: Approved design (sections 1–3 approved in brainstorming session)

## Problem

The Individual Bastion Turn currently rolls 1d100 on a static 14-event catalog
(`individual_bastion_events_catalog.dart`). Events such as *Something Found*
instruct the player to "roll on the reward table (logging or herb)" — but those
tables do not exist in code, and the 67 rewards in
`default_data/rewards/default_reward_data.dart` are not wired to any mechanic.
The turn is also entirely passive: the dialog displays text, the player reads it.

## Goal

Replace the static event table with a **player-built event system** ("Chart
Web") where facilities grant points, points are assigned to themed event
charts, the distribution of points determines which events a player can
encounter and how good the rewards are, and resolving events is an interactive
dispatch mini-game that grants actual reward inventory.

## 1. Point Economy

- Each **built facility** grants **1 point**. Maximum **16 points** (matching
  the facility cap).
- Points are **freely assignable**: at any time between turns the player may
  move any point to any chart. No facility-type coupling.
- Points are **locked once a Bastion Turn begins**; reassignment resumes after
  the turn resolves.
- Points are **persistent** — demolishing a facility removes its point
  (charts rebalance on next reassignment; the player is never left with more
  assigned points than earned).
- Zero points assigned = the roll lands on the **Uneventful table** (a
  deliberately anemic mini-table of quiet/nothing outcomes). This teaches the
  system by absence.

## 2. The Chart Web

Six base charts replace the single d100 event table. Each chart owns a theme
and reward categories (categories reuse the existing `RewardCategory` enum):

| Chart | Themes | Reward categories |
|---|---|---|
| The Wilds | hunting, gathering, animal events | creaturePart, meat, blood, herb |
| The Deeps | mining, excavation, underground | metal, stone |
| The Trade Road | guests, caravans, sellswords, treasure | gold, weaves, market goods |
| The War March | attacks, duels, requests for aid | combat loot, defenders |
| The Hearth | accidents, vermin, festivals, hireling drama | buffs, hirelings |
| The Arcane | planar tears, visiting notables, strange finds | herb, weave, any (exotic) |

### 2.1 Points define the table

- The turn roll stays **1d100**. Each chart's **share of the d100 range is
  proportional to its assigned points**.   E.g. 8 Wilds / 5 Trade / 3 Hearth →
  Wilds owns 1–50, Trade 51–81, Hearth 82–100 (largest-remainder rounding so
  the slices always sum to 100). Charts with zero points never fire.
- **Tiers within a chart** (by points in that chart):

  | Points | Tier | Effect |
  |---|---|---|
  | 1–3 | Basic | Rank E–D reward tables, few dice |
  | 4–7 | Skilled | Richer event variants, Rank C–B tables, more dice |
  | 8–12 | Master | Chart-exclusive set-piece events, Rank A tables |
  | 13–16 | Legend | One signature event per chart, Rank S tables |

  Rewards roll on tier-gated tables built from the existing reward catalog
  (`default_reward_data.dart`), reusing `rank` and `marketValue` as-is.

### 2.2 Distribution archetypes

- **Convergence events** (6 total) — each involves 2–3 related charts and is
  eligible when **every related chart has ≥ 4 points** (per-event gating;
  the engine's archetype side-roll applies). Examples: *The Alchemist's
  Commission* (Wilds+Arcane: hunt planar-touched game for Rank B herbs), a
  Trade Road caravan delivering Deeps ore.
- **Rivalry events** (2 total) — each involves exactly 2 related charts at
  **≥ 8 points each** (both Master tier — the maximum 16 points allows at
  most one such pairing); a choice event favoring one chart or the other.
- Archetype eligibility is **per-event** (related-charts threshold), not a
  global unlock: a player with 4+ in Wilds and Arcane can roll *The
  Alchemist's Commission* regardless of their other charts. The
  `unlocksConvergence`/`unlocksRivalry` helper predicates remain for UI
  hinting ("new events available") only.

## 3. Event Catalog

~12 events per chart (3 per tier) × 6 charts ≈ **72 events**, plus ~8
archetype events, replacing the current 14-event catalog. Exemplar flavor per
chart (approved in brainstorming):

- **The Wilds** — Basic: *Foraging Party* (choose Gatherers→herbs or
  Hunters→meat/blood), *Wolf Cull*. Skilled: *The Migrating Herd* (per-defender
  rolls), *Rare Bloom Spotted* (harvest now at risk, or mark site for a future
  bonus — push-your-luck). Master: *The Great Stag Hunt* (multi-round, build
  Momentum, cash out anytime; longer = better part tier but the stag fights
  back). Legend: *The Beast of Maura* (two-turn bastion-wide event; Rank S
  reward + permanent title/buff).
- **The Deeps** — *Seam Strike* (Basic), *Collapsed Shaft* (Skilled: rescue or
  salvage), *The Glimmerdeep* (Master: push deeper each turn for better tiers;
  one step too far = collapse), *Heart of the Mountain* (Legend: Rank S
  metal/stone + permanent +1 to Deeps rolls).
- **The Trade Road** — *Peddlers' Cart* (Basic), *The Fair Comes to Maura*
  (Skilled: spend gold to attract better goods), *Diamond in the Rough*
  (Master: appraisal choice — buy low, sell high or keep), *The Merchant
  Prince* (Legend: exclusive contracts, passive gold per turn).
- **The War March** — absorbs *Surprise Attack*, *Duel*, *Ronin*, *Request for
  Aid*; higher tiers bring richer loot, named enemies, lieutenant recruits.
- **The Hearth** — absorbs *Vermin Infestation*, *Tragic Accident*, *Criminal
  Hireling*, *Wandering Professionals*; Skilled+ tiers flip negatives into
  problem-plus-opportunity (e.g. giant honeybees: exterminate *or* domesticate
  for a herb bonus).
- **The Arcane** — *Planar Whisper* (Basic), *Fey Bargain* (Skilled: trade
  something odd for a weave/herb), *The Star Fall* (Master: race to a fallen
  skyshard), *The Door in the Hill* (Legend: Rank S anything, but walking away
  costs a point).

## 4. Turn Flow (five phases)

Reuses the medieval parchment theme (`MedievalColors`, `ParchmentBorderPainter`,
Cinzel / imFell English typography).

1. **Allocation** — a "Chart Web" panel (hex/constellation diagram) on the
   facilities page. Drag points between charts; live preview shows each
   chart's d100 slice and tier ("Wilds: rolls 1–50, Master tier"). Charts with
   no points render dark.
2. **The Roll** — tap *Begin Bastion Turn*: d100 tumble animation, chart name
   flash, event card flip with the existing parchment callout styling from
   `BastionTurnDialog`.
3. **The Dispatch** — most events open a dispatch panel: assign
   defenders/hirelings from live cubit state, capped per event and bastion
   rank. Unit types matter: beasts roll 2d6 on Wilds (matching existing Vermin
   rules), knights excel on War March, hirelings on Hearth/Trade. Facility
   buffs apply here (e.g. Harvestarium = reroll one die).
4. **The Resolution** — per-unit dice with visible results ("Guard Aldric:
   4 ✓"), tallied against the event DC (tally style matching *Request for
   Aid*). Push-your-luck events loop phases 3–4 until the player banks or
   busts.
5. **The Reward Reveal** — roll on the tier's reward table; rarity reveal
   animation (parchment → gold-leaf shine for Rank A/S); quantities stored in
   a new bastion inventory (units tracked with `weightPerUnit`; weight limits
   apply). Rank B+ results, Legend events, and won battles auto-write a
   newspaper article (existing `news_paper` feature) and optionally announce
   via `discord_announcer`.

## 5. Architecture

- **New models**: `EventChart` (id, name, theme, reward categories), chart
  member events, per-event tier + DC + reward-table reference; `ChartPoints`
  (chart id → assigned points, derived from built-facility count with
  validation); `BastionInventory` (reward id → units, weight totals).
- **New catalog**: `chart_events_catalog.dart` replaces
  `individual_bastion_events_catalog.dart` (which is retired along with its
  roll ranges — the d100 slice is now computed from points, not hardcoded).
- **Turn engine**: a pure-Dart turn resolver (given bastion state, points,
  dispatch choices, RNG) producing a `ChartTurnResult` — separately testable
  from UI, following the existing `BastionTurnResult` pattern.
- **UI**: `ChartWebPanel` (allocation), `BastionTurnFlow` (phases 2–5 as a
  stepped dialog/page), reusing `FacilityTableView` for tables and the
  parchment widget family for chrome.
- **API**: turn results and inventory persist through the existing
  `bastion_api` layer; point assignment is part of bastion state.

## 6. Edge Cases

- Points locked during an in-flight turn; reassignment only between turns.
- Events that remove defenders/hirelings cannot reduce a category below 1.
- Storage full: event offers to sell overflow at `marketValue`.
- Demolished facility mid-cycle: excess assigned points are auto-unassigned
  (player chooses which chart(s) lose points at next allocation).
- A Legend event interrupted by bastion destruction resolves as a loss.

## 7. Testing

- Unit tests: d100 slice math (proportional allocation, boundary rolls),
  tier thresholds, archetype unlock conditions, turn resolver with seeded RNG,
  inventory weight math, overflow-sale behavior, catalog coverage (every
  chart/tier populated, archetype events gated correctly).
- Widget tests: allocation panel drag/reassign, turn flow phases, dispatch
  validation (caps, unit-type bonuses).
