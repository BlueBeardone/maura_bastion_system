# Chart Web C — Persistence & Newspaper Integration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make chart allocations and bastion inventory survive app restarts (local persistence via `shared_preferences`, the app's established store pattern), and write notable turn results into the Maura newspaper.

**Architecture:** Two small store classes (JSON in `shared_preferences`, per bastion) hydrating the existing cubits without changing their public call sites (`load` stays synchronous; hydration re-emits asynchronously). A pure `notableResultArticle` helper plus a fire-and-forget `NewspaperApi.create` call in the flow dialog (try/catch-wrapped GetIt access, matching the Discord announcer pattern). Recruit fulfillment and server-side persistence need backend decisions — explicitly OUT of scope (see ledger).

**Tech Stack:** Flutter, `shared_preferences` (existing dep), `get_it` (existing), `flutter_bloc`.

**Spec:** `docs/superpowers/specs/2026-09-18-chart-web-reward-system-design.md` (Section 4 phase 5 newspaper hook, Section 5 persistence intent — adapted to local storage pending backend support)

## Global Constraints

- Store keys: `chart_points_<bastionId>` and `bastion_inventory_<bastionId>`.
- Chart points JSON: `{"points": {"wilds": 3, "hearth": 1}}` (EventChart enum names; unknown names ignored on read).
- Inventory JSON: `{"entries": [{"rewardId": "rew_x", "effectiveRank": "D", "units": 2}]}` — rebuild `Reward` by id from `getDefaultRewards()`; entries with unknown ids are dropped silently; invalid rank strings throw `ArgumentError` (matches `Rank.fromString`).
- Cubit public API unchanged: `load(bastion)` stays synchronous — it emits a fresh state then asynchronously re-emits with stored data if non-empty; `assign`/`addRewards` write through to the store fire-and-forget.
- Newspaper notable rule: article when ANY of — a material with `effectiveRank` index ≤ `Rank.B.index` (B or better), gold ≥ 500, a recruit reward, a Legend event, or a bonus archetype fired. Otherwise null.
- Newspaper author: 'Bastion Correspondent'. Title: `'<EVENT NAME> AT <BASTION NAME>'` uppercased.
- GetIt access for `NewspaperApi` in the dialog must be try/catch-wrapped and fire-and-forget (`unawaited(...catchError)`) so tests without DI registrations and offline runs both stay clean.
- House style: no comments unless non-obvious; stores follow `AuthSessionStore`'s shape.

---

### Task 1: ChartPointsStore + cubit write-through

**Files:**
- Create: `lib/features/bastions_page/data/chart_points_store.dart`
- Modify: `lib/features/bastions_page/logic/chart_points_cubit.dart`
- Test: `test/features/bastions_page/data/chart_points_store_test.dart` + extend `test/features/bastions_page/logic/chart_points_cubit_test.dart`

**Interfaces:**
- Produces: `class ChartPointsStore { Future<void> save(String bastionId, ChartPoints points); Future<Map<EventChart, int>> read(String bastionId); }` (constructor takes no args; uses `SharedPreferences.getInstance()`).
- Cubit: `ChartPointsCubit({ChartPointsStore? store})` — `load` emits fresh then `_restore(bastionId)` async-merges stored points (emit only if non-empty); `assign` calls `_store.save(...)` unawaited after emitting.

- [ ] **Step 1: Write the failing tests**

Store test:

```dart
// test/features/bastions_page/data/chart_points_store_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:maura_bastion_system/data/models/events/chart_points.dart';
import 'package:maura_bastion_system/data/models/events/event_chart.dart';
import 'package:maura_bastion_system/features/bastions_page/data/chart_points_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('save then read round-trips points', () async {
    SharedPreferences.setMockInitialValues({});
    final store = ChartPointsStore();
    await store.save('b1', const ChartPoints(
      earnedPoints: 4,
      points: {EventChart.wilds: 3, EventChart.hearth: 1},
    ));

    final read = await store.read('b1');
    expect(read, {EventChart.wilds: 3, EventChart.hearth: 1});
  });

  test('read of an unknown bastion is empty', () async {
    SharedPreferences.setMockInitialValues({});
    final store = ChartPointsStore();
    expect(await store.read('nope'), isEmpty);
  });

  test('read ignores unknown chart names', () async {
    SharedPreferences.setMockInitialValues({
      'chart_points_b2': '{"points": {"wilds": 2, "notAChart": 5}}',
    });
    final store = ChartPointsStore();
    final read = await store.read('b2');
    expect(read, {EventChart.wilds: 2});
  });
}
```

Cubit test additions (append inside `main` of the existing cubit test file; add imports `dart:async` not needed, `shared_preferences`):

```dart
  test('load restores persisted points for the same bastion', () async {
    SharedPreferences.setMockInitialValues({
      'chart_points_b1': '{"points": {"wilds": 3}}',
    });
    final restoring = ChartPointsCubit();
    restoring.load(bastionWithFacilities(4));
    await Future<void>.delayed(Duration.zero);
    expect(restoring.state.points[EventChart.wilds], 3);
    expect(restoring.state.points.earnedPoints, 4);
    await restoring.close();
  });

  test('assign writes through to the store', () async {
    SharedPreferences.setMockInitialValues({});
    cubit.load(bastionWithFacilities(4));
    cubit.assign(EventChart.wilds, 2);
    await Future<void>.delayed(Duration.zero);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('chart_points_b1'), contains('wilds'));
  });
```

NOTE: `SharedPreferences.setMockInitialValues` is global mock state — the existing cubit tests (no persistence expectations) must keep passing; if they observe the mock, that's fine since an empty mock store reads back empty.

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/features/bastions_page/data/ test/features/bastions_page/logic/chart_points_cubit_test.dart`
Expected: FAIL — store does not exist.

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/features/bastions_page/data/chart_points_store.dart
import 'dart:convert';

import 'package:maura_bastion_system/data/models/events/chart_points.dart';
import 'package:maura_bastion_system/data/models/events/event_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChartPointsStore {
  static const _prefix = 'chart_points_';

  Future<void> save(String bastionId, ChartPoints points) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode({
      'points': {
        for (final entry in points.points.entries)
          if (entry.value > 0) entry.key.name: entry.value,
      },
    });
    await prefs.setString('$_prefix$bastionId', json);
  }

  Future<Map<EventChart, int>> read(String bastionId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_prefix$bastionId');
    if (raw == null) return {};
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final points = decoded['points'] as Map<String, dynamic>? ?? {};
    return {
      for (final entry in points.entries)
        if (EventChart.values.where((c) => c.name == entry.key).isNotEmpty)
          EventChart.values.firstWhere((c) => c.name == entry.key):
              (entry.value as num).toInt(),
    };
  }
}
```

Cubit changes (`chart_points_cubit.dart`): add a `_store` field + optional constructor param; `load` ends with `unawaited(_restore(bastion.id))`; `assign` ends with `unawaited(_store.save(state.bastionId!, state.points))` guarded by `state.bastionId != null`; add `import 'dart:async';` and the store import.

```dart
  Future<void> _restore(String bastionId) async {
    final stored = await _store.read(bastionId);
    if (stored.isEmpty || bastionId != state.bastionId) return;
    final restored = ChartPoints(
      earnedPoints: state.points.earnedPoints,
      points: stored,
    );
    emit(ChartPointsState(bastionId: state.bastionId, points: restored));
  }
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/features/bastions_page/data/ test/features/bastions_page/logic/chart_points_cubit_test.dart`
Expected: PASS (3 store + 6 cubit tests).

- [ ] **Step 5: Commit**

```bash
git add lib/features/bastions_page/data/chart_points_store.dart lib/features/bastions_page/logic/chart_points_cubit.dart test/features/bastions_page/data/chart_points_store_test.dart test/features/bastions_page/logic/chart_points_cubit_test.dart
git commit -m "feat: persist chart point allocations per bastion"
```

---

### Task 2: BastionInventoryStore + cubit hydration

**Files:**
- Create: `lib/features/bastions_page/data/bastion_inventory_store.dart`
- Modify: `lib/features/bastions_page/logic/bastion_inventory_cubit.dart`
- Test: `test/features/bastions_page/data/bastion_inventory_store_test.dart` + extend the cubit test

**Interfaces:**
- Produces: `class BastionInventoryStore { Future<void> save(String bastionId, BastionInventory inventory); Future<List<RewardGrant>> read(String bastionId); }` — `read` rebuilds grants (reward by id from `getDefaultRewards()`, `Rank.fromString(effectiveRank)`); unknown reward ids dropped.
- Cubit: `BastionInventoryCubit({BastionInventoryStore? store})` — `load` emits fresh then `_restore` re-emits `addGrants(stored)` if non-empty; `addRewards` saves the FINAL post-sale inventory unawaited.

- [ ] **Step 1: Write the failing tests**

```dart
// test/features/bastions_page/data/bastion_inventory_store_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:maura_bastion_system/data/enums/rank.dart';
import 'package:maura_bastion_system/data/models/events/reward_spec.dart';
import 'package:maura_bastion_system/features/bastions_page/data/bastion_inventory_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('save then read round-trips grants (real reward catalog)', () async {
    SharedPreferences.setMockInitialValues({});
    final store = BastionInventoryStore();
    final herb = const BastionInventory()
        .addGrants([]); // build via real reward below
    expect(herb, isNotNull);

    final reward = defaultRewardsForTest();
    await store.save('b1', reward.inventory);
    final grants = await store.read('b1');
    expect(grants.single.reward.id, reward.rewardId);
    expect(grants.single.effectiveRank, Rank.D);
    expect(grants.single.units, reward.units);
  });
}
```

NOTE: the test sketch above is intentionally incomplete — write it concretely as follows: pick a REAL reward from `getDefaultRewards()` (e.g. `rew_adamantine`), build `BastionInventory().addGrants([RewardGrant(reward: adamantine, effectiveRank: Rank.D, units: 3)])`, save, read back, and assert `grants.single` has reward id `rew_adamantine`, `effectiveRank` D, units 3. Add a second test: a stored entry with an unknown reward id (`rew_ghost`) is dropped on read. Import `default_reward_data.dart` for the catalog.

Cubit test addition (append; uses real rewards):

```dart
  test('load restores a persisted inventory', () async {
    final adamantine = getDefaultRewards().firstWhere((r) => r.id == 'rew_adamantine');
    SharedPreferences.setMockInitialValues({
      'bastion_inventory_b1':
          '{"entries": [{"rewardId": "rew_adamantine", "effectiveRank": "D", "units": 3}]}',
    });
    final restoring = BastionInventoryCubit();
    restoring.load(_bastion());
    await Future<void>.delayed(Duration.zero);
    expect(restoring.state.inventory.entries['rew_adamantine|D']!.units, 3);
    await restoring.close();
  });
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/features/bastions_page/data/bastion_inventory_store_test.dart test/features/bastions_page/logic/bastion_inventory_cubit_test.dart`
Expected: FAIL — store does not exist.

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/features/bastions_page/data/bastion_inventory_store.dart
import 'dart:convert';

import 'package:maura_bastion_system/data/default_data/rewards/default_reward_data.dart';
import 'package:maura_bastion_system/data/enums/rank.dart';
import 'package:maura_bastion_system/data/models/events/reward_spec.dart';
import 'package:maura_bastion_system/data/models/rewards/bastion_inventory.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BastionInventoryStore {
  static const _prefix = 'bastion_inventory_';

  Future<void> save(String bastionId, BastionInventory inventory) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode({
      'entries': [
        for (final entry in inventory.entries.values)
          {
            'rewardId': entry.reward.id,
            'effectiveRank': entry.effectiveRank.name,
            'units': entry.units,
          },
      ],
    });
    await prefs.setString('$_prefix$bastionId', json);
  }

  Future<List<RewardGrant>> read(String bastionId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_prefix$bastionId');
    if (raw == null) return const [];
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final entries = decoded['entries'] as List? ?? [];
    final catalog = getDefaultRewards();
    final grants = <RewardGrant>[];
    for (final e in entries) {
      final map = e as Map<String, dynamic>;
      final reward = catalog.where((r) => r.id == map['rewardId']).firstOrNull;
      if (reward == null) continue;
      grants.add(RewardGrant(
        reward: reward,
        effectiveRank: Rank.fromString(map['effectiveRank'] as String),
        units: (map['units'] as num).toInt(),
      ));
    }
    return grants;
  }
}
```

(`firstOrNull` needs `import 'package:collection/collection.dart';` if not already available — the B1 task established it is NOT in pubspec; use a manual lookup instead.)

Cubit changes: `_store` field + optional ctor param; `load` ends with `unawaited(_restore(bastion.id))`; `addRewards` ends with `if (state.bastionId != null) { unawaited(_store.save(state.bastionId!, inventory)); }` (save the final post-sale inventory).

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/features/bastions_page/data/bastion_inventory_store_test.dart test/features/bastions_page/logic/bastion_inventory_cubit_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/bastions_page/data/bastion_inventory_store.dart lib/features/bastions_page/logic/bastion_inventory_cubit.dart test/features/bastions_page/data/bastion_inventory_store_test.dart test/features/bastions_page/logic/bastion_inventory_cubit_test.dart
git commit -m "feat: persist bastion inventory per bastion"
```

---

### Task 3: Newspaper integration

**Files:**
- Create: `lib/features/bastions_page/logic/chart_web_news.dart`
- Modify: `lib/features/bastions_page/presentation/widgets/bastion_turn_flow_dialog.dart` (fire-and-forget article in `_finalize`)
- Test: `test/features/bastions_page/logic/chart_web_news_test.dart`

**Interfaces:**
- Produces: `NewspaperArticle? notableResultArticle({required Bastion bastion, required ChartEvent event, required TurnReward reward, ChartEvent? bonusArchetype})` — null when nothing notable (see Global Constraints); else an article with the specified title/author and content combining event description + a rewards summary line (e.g. 'Rewards: 2 × Adamantine (Rank D), 320 GP.').
- Dialog: in `_finalize`, after inventory add — build the article; if non-null, try/catch-wrapped `unawaited(GetIt.I<NewspaperApi>().create(article).then((_) {}, onError: (_) {}))`.

- [ ] **Step 1: Write the failing test**

```dart
// test/features/bastions_page/logic/chart_web_news_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:maura_bastion_system/data/enums/rank.dart';
import 'package:maura_bastion_system/data/default_data/rewards/default_reward_data.dart';
import 'package:maura_bastion_system/data/models/bastion/bastion.dart';
import 'package:maura_bastion_system/data/models/events/chart_event.dart';
import 'package:maura_bastion_system/data/models/events/chart_tier.dart';
import 'package:maura_bastion_system/data/models/events/event_chart.dart';
import 'package:maura_bastion_system/data/models/events/reward_spec.dart';
import 'package:maura_bastion_system/data/models/events/turn_flow.dart';
import 'package:maura_bastion_system/data/models/news_paper/news_paper_article.dart';
import 'package:maura_bastion_system/data/models/rewards/reward.dart';
import 'package:maura_bastion_system/features/bastions_page/logic/chart_web_news.dart';

Bastion _bastion() => Bastion(id: 'b1', name: 'Highfell', description: '', facilities: const []);

TurnReward _rewardWith(RewardGrant grant) => TurnReward(
      materials: [grant],
      gold: 0,
      recruit: RewardKind.none,
    );

void main() {
  final adamantine = getDefaultRewards().firstWhere((r) => r.id == 'rew_adamantine');

  test('returns null for modest results', () {
    final herb = getDefaultRewards().firstWhere((r) => r.id == 'rew_blue_herb');
    final article = notableResultArticle(
      bastion: _bastion(),
      event: _basicEvent(),
      reward: _rewardWith(RewardGrant(reward: herb, effectiveRank: Rank.E, units: 2)),
    );
    expect(article, isNull);
  });

  test('rank B or better materials are notable', () {
    final article = notableResultArticle(
      bastion: _bastion(),
      event: _basicEvent(),
      reward: _rewardWith(RewardGrant(reward: adamantine, effectiveRank: Rank.B, units: 2)),
    );
    expect(article, isNotNull);
    expect(article!.title, 'WOLF CULL AT HIGHFELL');
    expect(article.author, 'Bastion Correspondent');
    expect(article.content, contains('Adamantine'));
  });

  test('gold of 500 or more is notable', () {
    final article = notableResultArticle(
      bastion: _bastion(),
      event: _basicEvent(),
      reward: const TurnReward(materials: [], gold: 500, recruit: RewardKind.none),
    );
    expect(article, isNotNull);
    expect(article!.content, contains('500 GP'));
  });

  test('recruit and legend and bonus archetype are notable', () {
    expect(
      notableResultArticle(
        bastion: _bastion(),
        event: _basicEvent(),
        reward: const TurnReward(materials: [], gold: 0, recruit: RewardKind.recruitDefender),
      ),
      isNotNull,
    );
    expect(
      notableResultArticle(
        bastion: _bastion(),
        event: _legendEvent(),
        reward: const TurnReward(materials: [], gold: 0, recruit: RewardKind.none),
      ),
      isNotNull,
    );
    expect(
      notableResultArticle(
        bastion: _bastion(),
        event: _basicEvent(),
        reward: const TurnReward(materials: [], gold: 0, recruit: RewardKind.none),
        bonusArchetype: _bonusEvent(),
      ),
      isNotNull,
    );
  });
}

ChartEvent _basicEvent() => const ChartEvent(
      id: 'evt_b',
      name: 'Wolf Cull',
      chart: EventChart.wilds,
      tier: ChartTier.basic,
      description: 'Wolves.',
    );

ChartEvent _legendEvent() => const ChartEvent(
      id: 'evt_l',
      name: 'The Beast of Maura',
      chart: EventChart.wilds,
      tier: ChartTier.legend,
      description: 'The Beast.',
    );

ChartEvent _bonusEvent() => const ChartEvent(
      id: 'evt_x',
      name: "The Alchemist's Commission",
      chart: EventChart.wilds,
      tier: ChartTier.skilled,
      description: 'A commission.',
      relatedCharts: {EventChart.wilds, EventChart.arcane},
      minPointsPerChart: 4,
    );
```

Note: `TurnReward`/`RewardKind` are re-exported from `turn_flow.dart` (B2a) — import from there as the test does.

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/bastions_page/logic/chart_web_news_test.dart`
Expected: FAIL — cannot find `chart_web_news.dart`.

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/features/bastions_page/logic/chart_web_news.dart
import 'package:maura_bastion_system/data/enums/rank.dart';
import 'package:maura_bastion_system/data/models/bastion/bastion.dart';
import 'package:maura_bastion_system/data/models/events/chart_event.dart';
import 'package:maura_bastion_system/data/models/events/reward_spec.dart';
import 'package:maura_bastion_system/data/models/events/turn_flow.dart';
import 'package:maura_bastion_system/data/models/news_paper/news_paper_article.dart';

NewspaperArticle? notableResultArticle({
  required Bastion bastion,
  required ChartEvent event,
  required TurnReward reward,
  ChartEvent? bonusArchetype,
}) {
  final notableMaterial = reward.materials.any(
    (g) => g.effectiveRank.index <= Rank.B.index,
  );
  final notable = notableMaterial ||
      reward.gold >= 500 ||
      reward.recruit != RewardKind.none ||
      event.tier == ChartTier.legend ||
      bonusArchetype != null;
  if (!notable) return null;

  final summaryParts = <String>[
    for (final g in reward.materials)
      '${g.units} \u00d7 ${g.reward.name} (Rank ${g.effectiveRank.title})',
    if (reward.gold > 0) '${reward.gold} GP',
    if (reward.recruit == RewardKind.recruitDefender) 'a new defender',
    if (reward.recruit == RewardKind.recruitHireling) 'a new hireling',
  ];
  final content =
      '${event.description}\n\nRewards: ${summaryParts.isEmpty ? 'none recorded' : summaryParts.join(', ')}.'
      '${bonusArchetype != null ? '\n\nElsewhere in Maura: ${bonusArchetype.description}' : ''}';

  return NewspaperArticle(
    title: '${event.name.toUpperCase()} AT ${bastion.name.toUpperCase()}',
    content: content,
    imageUrl: null,
    author: 'Bastion Correspondent',
  );
}
```

Dialog change (`_finalize`, after `addRewards`): 

```dart
    final article = notableResultArticle(
      bastion: widget.bastion,
      event: widget.roll.event,
      reward: _reward!,
      bonusArchetype: _bonusArchetype,
    );
    if (article != null) {
      try {
        unawaited(
          GetIt.I<NewspaperApi>().create(article).then((_) {}, onError: (_) {}),
        );
      } catch (_) {}
    }
```

(`import 'dart:async';`, `import 'package:get_it/get_it.dart';`, `import 'package:maura_bastion_system/api/newspaper_api.dart';`, `import '.../logic/chart_web_news.dart';`)

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/features/bastions_page/logic/chart_web_news_test.dart test/features/bastions_page/presentation/widgets/bastion_turn_flow_dialog_test.dart`
Expected: PASS — the news tests (4) and the existing dialog tests (4) all pass; the dialog's GetIt access must be caught when unregistered.

- [ ] **Step 5: Commit**

```bash
git add lib/features/bastions_page/logic/chart_web_news.dart lib/features/bastions_page/presentation/widgets/bastion_turn_flow_dialog.dart test/features/bastions_page/logic/chart_web_news_test.dart
git commit -m "feat: write notable chart web results to the Maura newspaper"
```

---

### Task 4: Verification

- [ ] **Step 1:** Run `flutter test` — expect full suite pass.
- [ ] **Step 2:** Run `flutter analyze` — expect no new issues.
