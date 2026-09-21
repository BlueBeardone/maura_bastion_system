# Chart Web D1 — Display-Only Rewards Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rewards are shown once in the turn report and echoed in the Discord message — never stored. The inventory system (model, cubit, store, overflow sale) is deleted.

**Architecture:** The flow dialog now runs BEFORE `advanceBastionTurn`: the player resolves dispatch/rewards in the dialog, closes it (returning a reward summary string), and only then does the page advance the turn with the Discord gate — so the single `sendIndividualBastionTurn` payload includes the rewards. `BastionTurnEventResult` gains a nullable `rewardSummary`. Chart-points persistence (allocation, not rewards) is untouched.

**Tech Stack:** Flutter, existing bloc/DI setup.

**Spec note:** This plan supersedes the spec's storage/inventory clauses (Section 4 phase 5 inventory sentence, Section 6 storage-full rule) per human decision 2026-09-18: "the app does not care about money or items yet".

## Global Constraints

- No reward state exists anywhere after the dialog closes: no inventory model, cubit, store, or tests.
- Reward summary format (single source of truth): `String rewardSummaryText(TurnReward reward)` in `lib/data/models/events/turn_flow.dart` — parts joined ', ' — `'2 × Adamantine (Rank D)'`, `'320 GP'`, `'a new defender'`/`'a new hireling'` — or 'none' when empty.
- Discord payload: `BastionTurnEventResult` gains `final String? rewardSummary;` serialized in `toJson`/`fromJson`. The backend embed formatter may need updating to display it — flag in the report, don't touch the backend.
- Dialog flow: dispatch phase (if any) → reward reveal (uses `rewardSummaryText`) → Close pops with the summary string; closing early (dispatch phase) pops null. Page advances the turn AFTER the dialog returns, then shows the existing failure snackbar if advance fails.
- Newspaper integration (`notableResultArticle`) is unchanged and keeps working off the resolved `TurnReward`.
- Chart points cubit/store/persistence unchanged.
- House style: no comments unless non-obvious.

---

### Task 1: Model field + summary helper

**Files:**
- Modify: `lib/data/models/bastion/bastion_turn_result.dart` (`BastionTurnEventResult` gains `rewardSummary`)
- Modify: `lib/data/models/events/turn_flow.dart` (add `rewardSummaryText`)
- Test: `test/data/models/bastion/bastion_turn_result_test.dart` + `test/data/models/events/turn_flow_test.dart` (extend)

**Interfaces:**
- Produces: `BastionTurnEventResult({name, description, rolledRow, rewardSummary})` with null-tolerant JSON; `String rewardSummaryText(TurnReward reward)`.

- [ ] **Step 1: Write failing tests**

In `bastion_turn_result_test.dart` (match the file's existing style):

```dart
    test('event result serializes rewardSummary', () {
      const result = BastionTurnEventResult(
        name: 'Wolf Cull',
        description: 'Wolves.',
        rewardSummary: '2 × Adamantine (Rank D)',
      );
      final json = result.toJson();
      expect(json['rewardSummary'], '2 × Adamantine (Rank D)');
      expect(
        BastionTurnEventResult.fromJson(json).rewardSummary,
        '2 × Adamantine (Rank D)',
      );
      const absent = BastionTurnEventResult(name: 'A', description: 'B');
      expect(absent.toJson()['rewardSummary'], isNull);
      expect(BastionTurnEventResult.fromJson(absent.toJson()).rewardSummary, isNull);
    });
```

In `turn_flow_test.dart` (append inside `main`; `RewardGrant`/`Reward`/`Rank`/`RewardCategory` imports as needed):

```dart
  group('rewardSummaryText', () {
    test('empty reward reads none', () {
      expect(
        rewardSummaryText(const TurnReward(materials: [], gold: 0, recruit: RewardKind.none)),
        'none',
      );
    });

    test('materials, gold and recruits are joined', () {
      final metal = Reward(
        id: 'rew_m',
        name: 'Adamantine',
        category: RewardCategory.metal,
        weightPerUnit: 5,
        description: 'test',
      );
      final summary = rewardSummaryText(TurnReward(
        materials: [RewardGrant(reward: metal, effectiveRank: Rank.D, units: 2)],
        gold: 320,
        recruit: RewardKind.recruitHireling,
      ));
      expect(summary, '2 × Adamantine (Rank D), 320 GP, a new hireling');
    });
  });
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/data/models/bastion/bastion_turn_result_test.dart test/data/models/events/turn_flow_test.dart`
Expected: FAIL — no `rewardSummary` field / no `rewardSummaryText`.

- [ ] **Step 3: Implement**

`BastionTurnEventResult`: add `final String? rewardSummary;` + constructor param + `fromJson` (`json['rewardSummary'] as String?`) + `toJson` (`'rewardSummary': rewardSummary`). Update any existing constructor call sites that would break (none expected — it's optional).

`turn_flow.dart`:

```dart
String rewardSummaryText(TurnReward reward) {
  final parts = <String>[
    for (final g in reward.materials)
      '${g.units} \u00d7 ${g.reward.name} (Rank ${g.effectiveRank.title})',
    if (reward.gold > 0) '${reward.gold} GP',
    if (reward.recruit == RewardKind.recruitDefender) 'a new defender',
    if (reward.recruit == RewardKind.recruitHireling) 'a new hireling',
  ];
  return parts.isEmpty ? 'none' : parts.join(', ');
}
```

Note: `chart_web_news.dart` builds its own summary parts — switch its content line to `rewardSummaryText(reward)` (keeping its 'Rewards: ' prefix and the bonus-archetype paragraph) so the format has one source of truth; the news test asserting `contains('Adamantine')` and `contains('500 GP')` must still pass.

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/data/models/bastion/bastion_turn_result_test.dart test/data/models/events/turn_flow_test.dart test/features/bastions_page/logic/chart_web_news_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/data/models/bastion/bastion_turn_result.dart lib/data/models/events/turn_flow.dart lib/features/bastions_page/logic/chart_web_news.dart test/data/models/bastion/bastion_turn_result_test.dart test/data/models/events/turn_flow_test.dart
git commit -m "feat: add reward summary to turn event result"
```

---

### Task 2: Remove the inventory system

**Files:**
- Delete: `lib/data/models/rewards/bastion_inventory.dart`
- Delete: `lib/features/bastions_page/logic/bastion_inventory_cubit.dart` + `bastion_inventory_state.dart`
- Delete: `lib/features/bastions_page/data/bastion_inventory_store.dart`
- Delete: `test/data/models/rewards/bastion_inventory_test.dart`, `test/features/bastions_page/logic/bastion_inventory_cubit_test.dart`, `test/features/bastions_page/data/bastion_inventory_store_test.dart`
- Modify: `lib/features/bastions_page/presentation/widgets/bastion_turn_flow_dialog.dart` (remove `BastionInventoryCubit` import/usage, `context.watch`, the overflow-sale line, and the `addRewards` call)
- Modify: `lib/features/bastions_page/presentation/bastion_page.dart` (remove the `BastionInventoryCubit` provider and its `load` calls)
- Test: `test/features/bastions_page/presentation/widgets/bastion_turn_flow_dialog_test.dart` (remove inventory cubit usage; harness drops that provider; the inventory assertion in the dispatch test is removed)

**Interfaces:**
- The dialog's reward reveal keeps showing gold/materials/recruit/note — now purely from the in-memory `TurnReward` (display only). The overflow-sale line is deleted entirely.

- [ ] **Step 1: Update tests first** (dialog test harness loses the inventory provider + the `inventoryCubit.state` assertion; remove the now-deleted files' tests from the suite)

- [ ] **Step 2: Run to verify the target state fails**

Run: `flutter test test/features/bastions_page/presentation/widgets/bastion_turn_flow_dialog_test.dart`
Expected: FAIL/compile errors until the dialog is updated (that's the point — the harness no longer provides the cubit the dialog consumes).

- [ ] **Step 3: Implement**

- Dialog: delete the `BastionInventoryCubit` import, the `addRewards` call in `_finalize`, and the `inventory.lastSold` overflow block in `_buildRewardSection`. The `context.watch<BastionInventoryCubit>()` goes away — `_buildRewardSection` reads `_reward!` only.
- Page: remove the `BastionInventoryCubit` `BlocProvider` and both `load` call sites.
- Delete the 4 production files + 3 test files listed above.
- Grep for any remaining `bastion_inventory` / `BastionInventoryCubit` references and remove them (`bastionStorageMaxWeight` in `bastion_inventory.dart` dies with the file).

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test`
Expected: PASS — full suite minus the deleted inventory tests, no compile errors.

- [ ] **Step 5: Commit**

```bash
git add -A lib/ test/
git commit -m "feat: remove inventory tracking; rewards are display-only"
```

---

### Task 3: Resolution before advance; rewards ride the Discord payload

**Files:**
- Modify: `lib/features/bastions_page/presentation/widgets/bastion_turn_flow_dialog.dart` (`_finalize` builds `rewardSummaryText(_reward!)`; Close pops `Navigator.of(context).pop(_reward == null ? null : rewardSummaryText(_reward!))`; rename Close label to 'Done')
- Modify: `lib/features/bastions_page/presentation/bastion_page.dart` (`_takeBastionTurn` restructured)
- Test: `test/features/bastions_page/presentation/bastion_page_test.dart` + dialog test (assert the popped summary)

**Interfaces:**
- Dialog: `Future<String?> BastionTurnFlowDialog.show(...)` — resolves with the summary string, or null on early close.
- Page `_takeBastionTurn` new order: quest input → ensure points loaded → engine roll → `final rewardSummary = await BastionTurnFlowDialog.show(context, bastion: bastion, roll: roll);` (null if unmounted → return) → build `BastionTurnEventResult(name, description, rolledRow, rewardSummary: rewardSummary)` → `advanceBastionTurn` with the UNCHANGED gate (Discord `sendIndividualBastionTurn(result)` then PUT) → failure snackbar unchanged.

- [ ] **Step 1: Write failing tests**

Dialog test addition:

```dart
  testWidgets('Done pops with the reward summary', (tester) async {
    const event = ChartEvent(
      id: 'evt_plain2',
      name: 'Berry Thicket',
      chart: EventChart.wilds,
      tier: ChartTier.basic,
      description: 'A quiet harvest.',
      reward: RewardSpec(note: 'quiet'),
    );
    String? popped;
    await tester.pumpWidget(MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: ChartPointsCubit()..load(_bastion())),
        ],
        child: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  popped = await BastionTurnFlowDialog.show(
                    context,
                    bastion: _bastion(),
                    roll: _roll(event),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(popped, isNull); // no materials/gold/recruit — 'none' collapses to null
  });
```

DESIGN NOTE (binding): `show` resolves with `rewardSummaryText(_reward!)` when the summary is `'none'`-only? Simplify the contract: the dialog pops `null` when there is nothing worth sending (materials empty AND gold 0 AND recruit none — i.e. `rewardSummaryText == 'none'`), else the summary string. Implement exactly that.

Page test: adapt the existing full-turn test — after the dialog's Done tap, the advance PUT still fires (the existing test already asserts the PUT; keep it green by completing the dialog flow in the test: if the rolled event has no dispatch, tap 'Done' before asserting the PUT).

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/features/bastions_page/presentation/`
Expected: FAIL — dialog pops without a value / page flow unchanged.

- [ ] **Step 3: Implement**

Dialog `_finalize` stores `_rewardSummary = rewardSummaryText(_reward!);` and Close (`Done`) pops `_rewardSummary == 'none' ? null : _rewardSummary`. Early-close during dispatch pops null. Page `_takeBastionTurn` restructured per the Interfaces block — the `gate` closure now builds the result WITH `rewardSummary` (the closure body is otherwise byte-identical: Discord send + `loggedResult` assignment).

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/features/bastions_page/presentation/`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/bastions_page/presentation/ test/features/bastions_page/presentation/
git commit -m "feat: resolve turn rewards before advance and echo them to discord"
```

---

### Task 4: Verification

- [ ] **Step 1:** `flutter test` — full suite pass.
- [ ] **Step 2:** `flutter analyze` — no new issues.
- [ ] **Step 3:** Confirm no references remain: `grep -rn "BastionInventory\|bastion_storage" lib/ test/` returns nothing.
