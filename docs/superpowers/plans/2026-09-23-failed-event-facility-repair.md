# Failed-Event Facility Repair Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Failing a facility-affecting individual chart event knocks the associated facility offline for exactly one construction turn, and the player is told in the end-of-turn dialog and the Discord turn log.

**Architecture:** Reuse the existing construction fields. A facility is operational when `constructedTurns >= constructionTurns`; `BastionCubit.advanceBastionTurn` already advances the first facility with `constructedTurns < constructionTurns` and persists it. Marking the Kitchen at `constructedTurns = constructionTurns - 1` makes the next turn's construction slot repair it. `ChartEvent` gains an explicit `facilityId`; a pure helper `facilityKnockedOffline` computes the damaged state and is shared by the cubit and the page.

**Tech Stack:** Flutter, Dart, flutter_bloc (Cubit), get_it, http/testing MockClient, flutter_test.

## Global Constraints

- No new third-party dependencies.
- No backend/schema contract may be assumed beyond existing JSON fields; the Discord message is rendered by the external backend.
- Only dispatch events (`ChartEvent.dispatch != null`) can be failed and therefore trigger damage.
- Damage must never stack on an already-offline facility (`constructedTurns < constructionTurns`) and must never target a facility with `constructionTurns <= 0`.
- Damage is persisted only as part of a successfully logged turn; gate/advance failure means no damage.
- Existing `advanceBastionTurn` behavior (advance first under-construction facility, per-turn branch-upgrade lapse, gate ordering, return value) must remain intact.
- Run `flutter test` and `flutter analyze` before considering any task complete.

---

### Task 1: Event facility link, offline helper, and event data

**Files:**
- Modify: `lib/data/models/events/chart_event.dart`
- Modify: `lib/data/models/events/turn_flow.dart`
- Modify: `lib/data/default_data/events/hearth_events.dart`
- Test: `test/data/models/events/turn_flow_test.dart`
- Test: `test/data/default_data/events/chart_events_catalog_test.dart`

**Interfaces:**
- Consumes: existing `Bastion` (`lib/data/models/bastion/bastion.dart`), `Facility` (`lib/data/models/bastion/facility.dart`, has `id`, `name`, `construct` fields, `copyWith`).
- Produces:
  - `ChartEvent.facilityId` → `final String? facilityId;` (default `null`).
  - `Facility? facilityKnockedOffline(Bastion bastion, String? facilityId)` in `turn_flow.dart`.

- [ ] **Step 1: Write the failing helper tests**

Add the import and group to `test/data/models/events/turn_flow_test.dart`. Add this import near the other imports:

```dart
import 'package:maura_bastion_system/data/models/bastion/facility.dart';
```

Add this group at the end of `main()` (before the final closing brace):

```dart
  group('facilityKnockedOffline', () {
    Bastion bastionWith(Facility facility) => Bastion(
          id: 'b1',
          name: 'T',
          description: '',
          facilities: [facility],
        );

    Facility kitchen({required int constructed, required int total}) => Facility(
          id: 'cat_kitchen',
          name: 'Kitchen',
          rank: Rank.D,
          description: 'desc',
          constructedTurns: constructed,
          constructionTurns: total,
        );

    test('returns null when facilityId is null', () {
      expect(
        facilityKnockedOffline(
            bastionWith(kitchen(constructed: 2, total: 2)), null),
        isNull,
      );
    });

    test('returns null when the facility is absent', () {
      expect(
        facilityKnockedOffline(
            bastionWith(kitchen(constructed: 2, total: 2)), 'cat_pub'),
        isNull,
      );
    });

    test('returns null when the facility is already offline', () {
      expect(
        facilityKnockedOffline(
            bastionWith(kitchen(constructed: 1, total: 2)), 'cat_kitchen'),
        isNull,
      );
    });

    test('returns null when constructionTurns is zero', () {
      expect(
        facilityKnockedOffline(
            bastionWith(kitchen(constructed: 0, total: 0)), 'cat_kitchen'),
        isNull,
      );
    });

    test('marks an operational facility one turn short', () {
      final closed = facilityKnockedOffline(
          bastionWith(kitchen(constructed: 2, total: 2)), 'cat_kitchen');
      expect(closed, isNotNull);
      expect(closed!.id, 'cat_kitchen');
      expect(closed.name, 'Kitchen');
      expect(closed.constructedTurns, 1);
      expect(closed.constructionTurns, 2);
    });
  });
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/data/models/events/turn_flow_test.dart`
Expected: FAIL — `facilityKnockedOffline` is not defined / `ChartEvent.facilityId` does not yet matter.

- [ ] **Step 3: Add `facilityId` to `ChartEvent`**

In `lib/data/models/events/chart_event.dart`, add the field after `description`:

```dart
  final String description;
  final DispatchSpec? dispatch;
  final RewardSpec reward;

  /// The catalog facility this event knocks offline when its dispatch fails.
  /// Null for events that do not affect a facility.
  final String? facilityId;
```

Add the constructor parameter (after `this.reward = const RewardSpec(),`):

```dart
    this.dispatch,
    this.reward = const RewardSpec(),
    this.facilityId,
    this.relatedCharts = const {},
```

- [ ] **Step 4: Add the helper to `turn_flow.dart`**

Add the import near the top of `lib/data/models/events/turn_flow.dart`:

```dart
import 'package:maura_bastion_system/data/models/bastion/facility.dart';
```

Add this function at the end of the file (after `rewardSummaryText`):

```dart
/// Returns the facility in [bastion] that [facilityId] identifies, marked one
/// construction turn short so the next turn repairs it. Returns null when
/// there is no id, the facility is absent, the facility is already offline
/// (`constructedTurns < constructionTurns`), or it has no construction turns
/// to spend.
Facility? facilityKnockedOffline(Bastion bastion, String? facilityId) {
  if (facilityId == null) return null;
  for (final facility in bastion.facilities) {
    if (facility.id != facilityId) continue;
    if (facility.constructionTurns <= 0) return null;
    if (facility.constructedTurns < facility.constructionTurns) return null;
    return facility.copyWith(
      constructedTurns: facility.constructionTurns - 1,
    );
  }
  return null;
}
```

- [ ] **Step 5: Run the helper tests to verify they pass**

Run: `flutter test test/data/models/events/turn_flow_test.dart`
Expected: PASS.

- [ ] **Step 6: Write the failing catalog tests**

Add these tests inside `main()` of `test/data/default_data/events/chart_events_catalog_test.dart`:

```dart
  test('facility-affecting events name the kitchen', () {
    final byId = {for (final e in events) e.id: e};
    expect(byId['hrt_kitchen_fire']?.facilityId, 'cat_kitchen');
    expect(byId['hrt_cellar_rats']?.facilityId, 'cat_kitchen');
  });

  test('only the two hearth events carry a facility link', () {
    final linked =
        events.where((e) => e.facilityId != null).map((e) => e.id).toSet();
    expect(linked, {'hrt_kitchen_fire', 'hrt_cellar_rats'});
  });
```

- [ ] **Step 7: Run the catalog tests to verify they fail**

Run: `flutter test test/data/default_data/events/chart_events_catalog_test.dart`
Expected: FAIL — `facilityId` is null for both events.

- [ ] **Step 8: Add the facility links in `hearth_events.dart`**

In `hrt_kitchen_fire`, add `facilityId: 'cat_kitchen',` after the `chart` line:

```dart
    ChartEvent(
      id: 'hrt_kitchen_fire',
      name: 'Kitchen Fire',
      chart: EventChart.hearth,
      facilityId: 'cat_kitchen',
      tier: ChartTier.basic,
```

In `hrt_cellar_rats`, add `facilityId: 'cat_kitchen',` after the `chart` line:

```dart
    ChartEvent(
      id: 'hrt_cellar_rats',
      name: 'Cellar Rats',
      chart: EventChart.hearth,
      facilityId: 'cat_kitchen',
      tier: ChartTier.basic,
```

- [ ] **Step 9: Run both test files to verify they pass**

Run: `flutter test test/data/models/events/turn_flow_test.dart test/data/default_data/events/chart_events_catalog_test.dart`
Expected: PASS.

- [ ] **Step 10: Commit**

```bash
git add lib/data/models/events/chart_event.dart lib/data/models/events/turn_flow.dart lib/data/default_data/events/hearth_events.dart test/data/models/events/turn_flow_test.dart test/data/default_data/events/chart_events_catalog_test.dart
git commit -m "Add facility link to events and offline-repair helper"
```

---

### Task 2: `closedFacilityName` on the turn result

**Files:**
- Modify: `lib/data/models/bastion/bastion_turn_result.dart`
- Test: `test/data/models/bastion/bastion_turn_result_test.dart`

**Interfaces:**
- Consumes: nothing from Task 1.
- Produces: `BastionTurnEventResult.closedFacilityName` → `final String? closedFacilityName;`, serialized as JSON key `closedFacilityName`.

- [ ] **Step 1: Write the failing test**

Add to the `BastionTurnResult JSON round-trip` group in `test/data/models/bastion/bastion_turn_result_test.dart`:

```dart
    test('event result serializes closedFacilityName', () {
      const event = BastionTurnEventResult(
        name: 'Cellar Rats',
        description: 'Rats.',
        closedFacilityName: 'Kitchen',
      );
      final json = event.toJson();
      expect(json['closedFacilityName'], 'Kitchen');
      expect(BastionTurnEventResult.fromJson(json).closedFacilityName,
          'Kitchen');
      const absent = BastionTurnEventResult(name: 'A', description: 'B');
      expect(absent.toJson()['closedFacilityName'], isNull);
      expect(
        BastionTurnEventResult.fromJson(absent.toJson()).closedFacilityName,
        isNull,
      );
    });
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/data/models/bastion/bastion_turn_result_test.dart`
Expected: FAIL — no named parameter `closedFacilityName`.

- [ ] **Step 3: Add the field to `BastionTurnEventResult`**

In `lib/data/models/bastion/bastion_turn_result.dart`, add the field after `rewardSummary`:

```dart
  final String? rolledRow;
  final String? rewardSummary;

  /// Name of a facility knocked offline for one construction turn by a failed
  /// dispatch, if any.
  final String? closedFacilityName;
  final BastionTurnDispatchResult? dispatch;
```

Add the constructor parameter after `this.rewardSummary,`:

```dart
    this.rolledRow,
    this.rewardSummary,
    this.closedFacilityName,
    this.dispatch,
```

In `fromJson`, add after the `rewardSummary` line:

```dart
      rewardSummary: json['rewardSummary'] as String?,
      closedFacilityName: json['closedFacilityName'] as String?,
      dispatch: json['dispatch'] == null
```

In `toJson`, add after the `rewardSummary` entry:

```dart
      'rewardSummary': rewardSummary,
      'closedFacilityName': closedFacilityName,
      'dispatch': dispatch?.toJson(),
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `flutter test test/data/models/bastion/bastion_turn_result_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/data/models/bastion/bastion_turn_result.dart test/data/models/bastion/bastion_turn_result_test.dart
git commit -m "Add closedFacilityName to BastionTurnEventResult"
```

---

### Task 3: Cubit persists the offline facility

**Files:**
- Modify: `lib/features/bastions_page/logic/bastion_cubit.dart`
- Test: `test/features/bastions_page/logic/bastion_cubit_test.dart`

**Interfaces:**
- Consumes: `facilityKnockedOffline(Bastion, String?)` from Task 1.
- Produces: `advanceBastionTurn(String bastionId, {String? closeFacilityId, Future<void> Function(Facility? advanced)? gate})` — same name and return type as before, plus the optional `closeFacilityId`.

- [ ] **Step 1: Write the failing tests**

Add to the `BastionCubit.advanceBastionTurn` group in `test/features/bastions_page/logic/bastion_cubit_test.dart` (after the existing tests, using the group's local `facilityJson`/`bastionJson` helpers):

```dart
    test('closeFacilityId marks an operational facility one turn short',
        () async {
      final puts = <http.Request>[];
      final mock = _withEmptyBrowsePage((request) async {
        if (request.method == 'GET' &&
            request.url.path == '/maura/v1/bastions') {
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'ok',
              'data': [
                bastionJson([
                  facilityJson(
                      id: 'barracks', name: 'Barracks', constructed: 0, total: 2),
                  facilityJson(
                      id: 'cat_kitchen', name: 'Kitchen', constructed: 2, total: 2),
                ]),
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.method == 'PUT' &&
            request.url.path.startsWith('/maura/v1/facilities/')) {
          puts.add(request);
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'ok',
              'data': jsonDecode(request.body),
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response(
          jsonEncode({'success': false, 'message': 'unexpected'}),
          404,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(baseUrl: 'http://example.test', client: mock);
      final cubit = BastionCubit(
        bastionApi: BastionApi(client: apiClient),
        facilityApi: FacilityApi(client: apiClient),
      );
      await cubit.loadBastions();

      final advanced = await cubit.advanceBastionTurn(
        'bastion-1',
        closeFacilityId: 'cat_kitchen',
      );

      expect(advanced, isNotNull);
      expect(advanced!.name, 'Barracks');
      expect(puts, hasLength(2));
      final kitchenPut = puts
          .firstWhere((r) => r.url.path == '/maura/v1/facilities/cat_kitchen');
      final body = jsonDecode(kitchenPut.body) as Map<String, dynamic>;
      expect(body['constructedTurns'], 1);
      expect(body['constructionTurns'], 2);

      await cubit.close();
    });

    test('closeFacilityId persists when nothing else is under construction',
        () async {
      final puts = <http.Request>[];
      final gateArgs = <Facility?>[];
      final mock = _withEmptyBrowsePage((request) async {
        if (request.method == 'GET' &&
            request.url.path == '/maura/v1/bastions') {
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'ok',
              'data': [
                bastionJson([
                  facilityJson(
                      id: 'cat_kitchen', name: 'Kitchen', constructed: 2, total: 2),
                ]),
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.method == 'PUT' &&
            request.url.path.startsWith('/maura/v1/facilities/')) {
          puts.add(request);
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'ok',
              'data': jsonDecode(request.body),
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response(
          jsonEncode({'success': false, 'message': 'unexpected'}),
          404,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(baseUrl: 'http://example.test', client: mock);
      final cubit = BastionCubit(
        bastionApi: BastionApi(client: apiClient),
        facilityApi: FacilityApi(client: apiClient),
      );
      await cubit.loadBastions();

      final advanced = await cubit.advanceBastionTurn(
        'bastion-1',
        closeFacilityId: 'cat_kitchen',
        gate: (f) async => gateArgs.add(f),
      );

      expect(advanced, isNull);
      expect(gateArgs, [null]);
      expect(puts, hasLength(1));
      expect(jsonDecode(puts.single.body)['constructedTurns'], 1);
      expect(puts.single.url.path, '/maura/v1/facilities/cat_kitchen');

      await cubit.close();
    });

    test('closeFacilityId is a no-op for an absent facility', () async {
      final puts = <http.Request>[];
      final mock = _withEmptyBrowsePage((request) async {
        if (request.method == 'GET' &&
            request.url.path == '/maura/v1/bastions') {
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'ok',
              'data': [
                bastionJson([
                  facilityJson(
                      id: 'barracks', name: 'Barracks', constructed: 0, total: 2),
                ]),
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.method == 'PUT' &&
            request.url.path.startsWith('/maura/v1/facilities/')) {
          puts.add(request);
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'ok',
              'data': jsonDecode(request.body),
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response(
          jsonEncode({'success': false, 'message': 'unexpected'}),
          404,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(baseUrl: 'http://example.test', client: mock);
      final cubit = BastionCubit(
        bastionApi: BastionApi(client: apiClient),
        facilityApi: FacilityApi(client: apiClient),
      );
      await cubit.loadBastions();

      await cubit.advanceBastionTurn(
        'bastion-1',
        closeFacilityId: 'cat_kitchen',
      );

      expect(
        puts.where((r) => r.url.path == '/maura/v1/facilities/cat_kitchen'),
        isEmpty,
      );

      await cubit.close();
    });
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/features/bastions_page/logic/bastion_cubit_test.dart`
Expected: FAIL — no named parameter `closeFacilityId`.

- [ ] **Step 3: Replace `advanceBastionTurn`**

Add this import to `lib/features/bastions_page/logic/bastion_cubit.dart`:

```dart
import 'package:maura_bastion_system/data/models/events/turn_flow.dart';
```

Replace the entire existing `advanceBastionTurn` method (currently from `Future<Facility?> advanceBastionTurn(` through its closing `}` before `upgradeFacility`) with:

```dart
  Future<Facility?> advanceBastionTurn(
    String bastionId, {
    String? closeFacilityId,
    Future<void> Function(Facility? advanced)? gate,
  }) async {
    if (_advancingTurn) return null;
    if (state is! BastionLoadedState) return null;

    final loaded = state as BastionLoadedState;
    final bastion = loaded.bastions.firstWhere(
      (b) => b.id == bastionId,
      orElse: () => loaded.bastions.first,
    );

    Facility? target;
    for (final facility in bastion.facilities) {
      if (facility.constructedTurns < facility.constructionTurns) {
        target = facility;
        break;
      }
    }
    final closeTarget = facilityKnockedOffline(bastion, closeFacilityId);

    try {
      _advancingTurn = true;
      _setMutating(true);
      if (target == null && closeTarget == null) {
        if (gate != null) {
          try {
            await gate(null);
          } catch (e) {
            return null;
          }
        }
        return null;
      }

      Facility? advanced;
      final updates = <Facility>[];

      if (target != null) {
        advanced = target.copyWith(
          constructedTurns: target.constructedTurns + 1,
        );

        // Lapse per-turn branch upgrades (e.g. Pub of Legend) at turn advance
        // by reverting them to the base name/description.
        final targetPerTurnUpgrade =
            target.branchUpgrade?.kind == BranchUpgradeKind.perTurn;
        if (targetPerTurnUpgrade) {
          advanced = advanced.revertBranchUpgrade();
        }
        for (final facility in bastion.facilities) {
          if (facility.id == target.id) continue;
          final isPerTurn =
              facility.branchUpgrade?.kind == BranchUpgradeKind.perTurn;
          if (isPerTurn) {
            updates.add(facility.revertBranchUpgrade());
          }
        }
        updates.insert(0, advanced);
      }

      if (closeTarget != null) {
        updates.add(closeTarget);
      }

      if (gate != null) {
        try {
          await gate(advanced);
        } catch (e) {
          return null;
        }
      }
      for (final facility in updates) {
        await _facilityApi.update(facility.id, facility, bastionId: bastion.id);
      }
      await refreshUserBastion();
      return advanced;
    } catch (e) {
      return null;
    } finally {
      _advancingTurn = false;
      _setMutating(false);
    }
  }
```

Note: `updates.insert(0, advanced)` keeps the advanced facility first so the existing "gate runs before the facility PUT" test still sees `/maura/v1/facilities/barracks` as the first facility PUT after the Discord POST.

- [ ] **Step 4: Run the cubit tests to verify they pass**

Run: `flutter test test/features/bastions_page/logic/bastion_cubit_test.dart`
Expected: PASS, including the pre-existing branch-upgrade lapse and gate-ordering tests.

- [ ] **Step 5: Commit**

```bash
git add lib/features/bastions_page/logic/bastion_cubit.dart test/features/bastions_page/logic/bastion_cubit_test.dart
git commit -m "Persist failed-event facility repair in advanceBastionTurn"
```

---

### Task 4: Wire the page and show the dialog note

**Files:**
- Modify: `lib/features/bastions_page/presentation/bastion_page.dart`
- Modify: `lib/features/bastions_page/presentation/widgets/bastion_turn_dialog.dart`
- Test: `test/features/bastions_page/presentation/widgets/bastion_turn_dialog_test.dart`

**Interfaces:**
- Consumes: `facilityKnockedOffline` (Task 1), `advanceBastionTurn(closeFacilityId:)` (Task 3), `BastionTurnEventResult.closedFacilityName` (Task 2).
- Produces: no new public API; `_takeBastionTurn` passes `closeFacilityId` and populates `closedFacilityName`, and the dialog renders the "Out of action" callout.

- [ ] **Step 1: Write the failing dialog test**

Add to `test/features/bastions_page/presentation/widgets/bastion_turn_dialog_test.dart` (before the final closing brace of `main()`):

```dart
  testWidgets('closed facility shows the out-of-action callout',
      (tester) async {
    await tester.pumpWidget(_harness(
      event: _event,
      result: const BastionTurnResult(
        bastionId: 'b',
        bastionName: 'n',
        quest: 'q',
        event: BastionTurnEventResult(
          name: 'Berry Thicket',
          description: 'A quiet harvest.',
          closedFacilityName: 'Kitchen',
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Out of action'), findsOneWidget);
    expect(find.textContaining('Kitchen is offline'), findsOneWidget);
  });

  testWidgets('no closed facility means no out-of-action callout',
      (tester) async {
    await tester.pumpWidget(_harness(
      event: _event,
      result: const BastionTurnResult(
        bastionId: 'b',
        bastionName: 'n',
        quest: 'q',
        event: BastionTurnEventResult(
          name: 'Berry Thicket',
          description: 'A quiet harvest.',
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Out of action'), findsNothing);
  });
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/features/bastions_page/presentation/widgets/bastion_turn_dialog_test.dart`
Expected: FAIL — `Out of action` not found.

- [ ] **Step 3: Render the callout in `BastionTurnDialog`**

In `lib/features/bastions_page/presentation/widgets/bastion_turn_dialog.dart`, inside `_buildEventSection`, add a local before `return Column(`:

```dart
    final closedFacilityName = result?.event?.closedFacilityName;
```

Then add this block in the returned `Column`'s children, immediately after the `if (dispatch != null) ...` block and before the closing `],` of the children list:

```dart
        if (closedFacilityName != null) ...[
          const SizedBox(height: 8),
          _buildCallout(
            title: 'Out of action',
            body: '$closedFacilityName is offline \u2014 '
                '1 construction turn to repair.',
          ),
        ],
```

- [ ] **Step 4: Run the dialog test to verify it passes**

Run: `flutter test test/features/bastions_page/presentation/widgets/bastion_turn_dialog_test.dart`
Expected: PASS.

- [ ] **Step 5: Wire `_takeBastionTurn`**

In `lib/features/bastions_page/presentation/bastion_page.dart`, add the import:

```dart
import 'package:maura_bastion_system/data/models/events/turn_flow.dart';
```

In `_takeBastionTurn`, immediately after the `if (!context.mounted) return;` that follows the `BastionTurnFlowDialog.show` call, insert:

```dart
    final eventDispatch = turnResult?.dispatch;
    final dispatchFailed = eventDispatch != null && !eventDispatch.success;
    final closedFacility = dispatchFailed
        ? facilityKnockedOffline(bastion, roll.event.facilityId)
        : null;
```

In the `BastionTurnEventResult(...)` construction, replace the `description:` argument and add the new field:

```dart
    final eventResult = BastionTurnEventResult(
      name: roll.event.name,
      description: closedFacility == null
          ? roll.event.description
          : '${roll.event.description}\n\nThe ${closedFacility.name} is out '
              'of action until it is repaired over one construction turn.',
      closedFacilityName: closedFacility?.name,
      rolledRow: rolledRow,
      rewardSummary: rewardSummary,
```

In the `cubit.advanceBastionTurn(...)` call, add the parameter before `gate:`:

```dart
    final advanced = await cubit.advanceBastionTurn(
      bastion.id,
      closeFacilityId: closedFacility?.id,
      gate: (advancedFacility) async {
```

- [ ] **Step 6: Run analyzer and the affected widget test**

Run: `flutter analyze lib/features/bastions_page/presentation/bastion_page.dart lib/features/bastions_page/presentation/widgets/bastion_turn_dialog.dart`
Expected: no issues.

Run: `flutter test test/features/bastions_page/presentation/bastion_page_test.dart test/features/bastions_page/presentation/widgets/bastion_turn_dialog_test.dart`
Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add lib/features/bastions_page/presentation/bastion_page.dart lib/features/bastions_page/presentation/widgets/bastion_turn_dialog.dart test/features/bastions_page/presentation/widgets/bastion_turn_dialog_test.dart
git commit -m "Knock facilities offline on failed events and show the repair note"
```

---

### Task 5: Full verification

**Files:** none.

- [ ] **Step 1: Run the full test suite**

Run: `flutter test`
Expected: all tests pass.

- [ ] **Step 2: Run the analyzer**

Run: `flutter analyze`
Expected: no issues introduced by this change.

- [ ] **Step 3: Report**

Summarize the test and analyzer output. Do not claim success without the actual command output.

---

## Self-Review Notes

- Spec coverage: event link + helper (Task 1), result field (Task 2), cubit persistence + guard (Task 3), page wiring + dialog callout + Discord description append (Task 4), verification (Task 5).
- The Discord note is carried both by the dedicated `closedFacilityName` field and by the appended sentence in `BastionTurnEventResult.description`, per the spec, because the external backend renders the payload.
- No page-level widget test is added for damage because the individual event is rolled randomly by `ChartTurnEngine`; behavior is covered at the pure-helper, cubit, catalog, and dialog layers.
