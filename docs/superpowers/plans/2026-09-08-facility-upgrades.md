# Facility Upgrades Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let players upgrade owned facilities one rank at a time (D→C→B→A→S) for the cost difference in GP and 2 turns of construction, reusing the existing construction-progress mechanic.

**Architecture:** Add a `next` getter on `Rank`, catalog metadata (`baseCostByRank`, `upgradeableFacilityIds`, `facilityUpgradeCost`), a `BastionCubit.upgradeFacility` that persists an upgraded `Facility` via the existing `FacilityApi.update` and reloads bastions, and an "Upgrade" button on `FacilityPage` wired from `BastionPage`. Upgrading sets `constructionTurns = 2`, `constructedTurns = 0`, and bumps `rank`; the existing turn/construction UI handles the 2-turn progress for free.

**Tech Stack:** Flutter, dart (SDK ^3.11.0), flutter_bloc (Cubit), get_it, equatable.

## Global Constraints

- Rank chain and costs: D→C→B→A→S, one rank per upgrade step; upgrade construction time is exactly **2 turns**.
- Base costs (copy verbatim): D=600, C=1500, B=4500, A=9000, S=20000.
- Upgrade GP cost = next rank's base cost minus current rank's base cost: D→C=900, C→B=3000, B→A=4500, A→S=11000.
- Upgradeable facility ids (exactly 13): `cat_barracks`, `cat_battlements`, `cat_bedroom`, `cat_dining_room`, `cat_kitchen`, `cat_well_room`, `cat_siege_engine`, `cat_library`, `cat_sanctuary`, `cat_stables`, `cat_trading_hub`, `cat_training_area`, `cat_observatory`.
- **One at a time:** a user cannot upgrade a facility while ANY facility in that bastion is busy (`constructedTurns < constructionTurns`).
- S-rank facilities cannot upgrade (`Rank.next` is null).
- No backend changes, no `Facility` model / serialization changes, no third-party dependencies.
- No code comments unless they clarify an otherwise-opaque public behavior.

---
### Task 1: Rank `next` + catalog upgrade metadata

**Files:**
- Modify: `lib/data/enums/rank.dart`
- Modify: `lib/data/test_data/bastion/facility_catalog.dart`
- Create: `test/data/enums/rank_test.dart`
- Create: `test/data/test_data/facility_catalog_test.dart`

**Interfaces:**
- Produces: `Rank? get next` (extension on `Rank`, returns `null` for `Rank.S`); `const Map<Rank, int> baseCostByRank`; `const Set<String> upgradeableFacilityIds`; `int facilityUpgradeCost(Rank rank)`.

- [ ] **Step 1: Write the failing `Rank.next` test**

Create `test/data/enums/rank_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:maura_bastion_system/data/enums/rank.dart';

void main() {
  group('Rank.next', () {
    test('advances through the chain and stops at S', () {
      expect(Rank.D.next, Rank.C);
      expect(Rank.C.next, Rank.B);
      expect(Rank.B.next, Rank.A);
      expect(Rank.A.next, Rank.S);
      expect(Rank.S.next, isNull);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/data/enums/rank_test.dart`
Expected: FAIL — compile error: `The getter 'next' isn't defined for the type 'Rank'`.

- [ ] **Step 3: Add the `next` getter to `rank.dart`**

In `lib/data/enums/rank.dart`, inside the existing `extension MainNavigationExtension on Rank`, add:

```dart
  Rank? get next {
    switch (this) {
      case Rank.D: return Rank.C;
      case Rank.C: return Rank.B;
      case Rank.B: return Rank.A;
      case Rank.A: return Rank.S;
      case Rank.S: return null;
    }
  }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/data/enums/rank_test.dart`
Expected: PASS (1 test).

- [ ] **Step 5: Write the failing catalog metadata test**

Create `test/data/test_data/facility_catalog_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:maura_bastion_system/data/enums/rank.dart';
import 'package:maura_bastion_system/data/test_data/bastion/facility_catalog.dart';

void main() {
  group('baseCostByRank', () {
    test('matches the catalog build costs', () {
      expect(baseCostByRank[Rank.D], 600);
      expect(baseCostByRank[Rank.C], 1500);
      expect(baseCostByRank[Rank.B], 4500);
      expect(baseCostByRank[Rank.A], 9000);
      expect(baseCostByRank[Rank.S], 20000);
    });
  });

  group('upgradeableFacilityIds', () {
    test('contains exactly the 13 expected catalog facilities, all below S',
        () {
      final catalog = getFacilityCatalog();
      final upgradeable =
          catalog.where((f) => upgradeableFacilityIds.contains(f.id)).toList();
      expect(upgradeable.length, 13);
      for (final facility in upgradeable) {
        expect(facility.rank, isNot(Rank.S));
      }
    });
  });

  group('facilityUpgradeCost', () {
    test('is the difference to the next rank base cost', () {
      expect(facilityUpgradeCost(Rank.D), 900);
      expect(facilityUpgradeCost(Rank.C), 3000);
      expect(facilityUpgradeCost(Rank.B), 4500);
      expect(facilityUpgradeCost(Rank.A), 11000);
      expect(facilityUpgradeCost(Rank.S), 0);
    });
  });
}
```

- [ ] **Step 6: Run test to verify it fails**

Run: `flutter test test/data/test_data/facility_catalog_test.dart`
Expected: FAIL — compile errors: `baseCostByRank`, `upgradeableFacilityIds`, `facilityUpgradeCost` are not defined.

- [ ] **Step 7: Add catalog metadata to `facility_catalog.dart`**

In `lib/data/test_data/bastion/facility_catalog.dart`, above the `getFacilityCatalog()` function, add:

```dart
const Map<Rank, int> baseCostByRank = {
  Rank.D: 600,
  Rank.C: 1500,
  Rank.B: 4500,
  Rank.A: 9000,
  Rank.S: 20000,
};

const Set<String> upgradeableFacilityIds = {
  'cat_barracks',
  'cat_battlements',
  'cat_bedroom',
  'cat_dining_room',
  'cat_kitchen',
  'cat_well_room',
  'cat_siege_engine',
  'cat_library',
  'cat_sanctuary',
  'cat_stables',
  'cat_trading_hub',
  'cat_training_area',
  'cat_observatory',
};

int facilityUpgradeCost(Rank rank) {
  final next = rank.next;
  if (next == null) return 0;
  return baseCostByRank[next]! - baseCostByRank[rank]!;
}
```

`rank.dart` is already imported in this file.

- [ ] **Step 8: Run tests to verify they pass**

Run: `flutter test test/data/enums/rank_test.dart test/data/test_data/facility_catalog_test.dart`
Expected: PASS — all Rank.next + catalog metadata assertions pass (7 tests total).

- [ ] **Step 9: Commit**

```bash
git add lib/data/enums/rank.dart lib/data/test_data/bastion/facility_catalog.dart test/data/enums/rank_test.dart test/data/test_data/facility_catalog_test.dart
git commit -m "feat: add rank progression and facility upgrade metadata"
```

---
### Task 2: `BastionCubit.upgradeFacility`

**Files:**
- Modify: `lib/features/bastions_page/logic/bastion_cubit.dart`
- Modify: `test/features/bastions_page/logic/bastion_cubit_test.dart`

**Interfaces:**
- Consumes: `Rank.next`, `baseCostByRank`, `upgradeableFacilityIds` (from Task 1); `FacilityApi.update`; existing `BastionCubit._advancingTurn` guard pattern.
- Produces: `Future<Facility?> upgradeFacility(String bastionId, Facility facility)` — returns the upgraded `Facility` on success, `null` on any guard failure or API error. The persisted `Facility` has: `rank = next`, `cost = baseCostByRank[next]`, `constructionTurns = 2`, `constructedTurns = 0`, all other fields preserved.

- [ ] **Step 1: Write the failing cubit tests**

Append to `test/features/bastions_page/logic/bastion_cubit_test.dart`, inside `void main()` (after the existing `advanceBastionTurn` group), the following group. The `advanceBastionTurn` group's `facilityJson`/`bastionJson` helpers are scoped inside that group's closure, so the new top-level group defines its own local helpers (with an extended `rank`/`table` signature) rather than reusing them:

```dart
  group('BastionCubit.upgradeFacility', () {
    Map<String, dynamic> facilityJson({
      required String id,
      required String name,
      String rank = 'd',
      int constructed = 0,
      int total = 0,
      int requiredHirelings = 0,
      Map<String, dynamic>? table,
    }) =>
        {
          'id': id,
          'name': name,
          'rank': rank,
          'description': 'desc',
          'constructionTurns': total,
          'constructedTurns': constructed,
          'minimumRequiredHirelings': requiredHirelings,
          'cost': 0,
          'table': table,
        };

    Map<String, dynamic> bastionJson(List<Map<String, dynamic>> facilities) =>
        {
          'id': 'bastion-1',
          'userId': 'user_1',
          'name': 'Test Bastion',
          'description': 'desc',
          'facilities': facilities,
        };

    test('upgrades a built D facility to C, persisting rank, cost, and turns',
        () async {
      final puts = <http.Request>[];
      final mock = MockClient((request) async {
        if (request.method == 'GET' &&
            request.url.path == '/maura/v1/bastions') {
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'ok',
              'data': [
                bastionJson([
                  facilityJson(
                    id: 'cat_barracks',
                    name: 'Barracks',
                    constructed: 2,
                    total: 2,
                    table: {
                      'table': [
                        ['Rank', 'Capacity'],
                        ['D', '4'],
                      ],
                    },
                  ),
                ]),
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.method == 'PUT' &&
            request.url.path == '/maura/v1/facilities/cat_barracks') {
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

      final barracks =
          (cubit.state as BastionLoadedState).bastions.first.facilities.first;
      final upgraded = await cubit.upgradeFacility('bastion-1', barracks);

      expect(upgraded, isNotNull);
      expect(upgraded!.rank, Rank.C);
      expect(upgraded.cost, 1500);
      expect(upgraded.constructionTurns, 2);
      expect(upgraded.constructedTurns, 0);
      expect(upgraded.id, 'cat_barracks');
      expect(upgraded.table, isNotNull);
      expect(puts.length, 1);
      final body = jsonDecode(puts.first.body) as Map<String, dynamic>;
      expect(body['rank'], 'c');
      expect(body['cost'], 1500);
      expect(body['constructionTurns'], 2);
      expect(body['constructedTurns'], 0);

      await cubit.close();
    });

    test('returns null without PUT when another facility is under construction',
        () async {
      final puts = <http.Request>[];
      final mock = MockClient((request) async {
        if (request.method == 'GET' &&
            request.url.path == '/maura/v1/bastions') {
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'ok',
              'data': [
                bastionJson([
                  facilityJson(
                      id: 'cat_barracks',
                      name: 'Barracks',
                      constructed: 2,
                      total: 2),
                  facilityJson(
                      id: 'cat_kitchen',
                      name: 'Kitchen',
                      constructed: 0,
                      total: 2),
                ]),
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.method == 'PUT') {
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

      final barracks = (cubit.state as BastionLoadedState)
          .bastions
          .first
          .facilities
          .firstWhere((f) => f.id == 'cat_barracks');
      final result = await cubit.upgradeFacility('bastion-1', barracks);

      expect(result, isNull);
      expect(puts, isEmpty);

      await cubit.close();
    });

    test('returns null without PUT when the facility is already Rank S',
        () async {
      final puts = <http.Request>[];
      final mock = MockClient((request) async {
        if (request.method == 'GET' &&
            request.url.path == '/maura/v1/bastions') {
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'ok',
              'data': [
                bastionJson([
                  facilityJson(
                      id: 'cat_barracks',
                      name: 'Barracks',
                      rank: 's',
                      constructed: 2,
                      total: 2),
                ]),
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.method == 'PUT') {
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

      final barracks = (cubit.state as BastionLoadedState)
          .bastions
          .first
          .facilities
          .firstWhere((f) => f.id == 'cat_barracks');
      final result = await cubit.upgradeFacility('bastion-1', barracks);

      expect(result, isNull);
      expect(puts, isEmpty);

      await cubit.close();
    });

    test('returns null without PUT for a non-upgradeable facility id',
        () async {
      final puts = <http.Request>[];
      final mock = MockClient((request) async {
        if (request.method == 'GET' &&
            request.url.path == '/maura/v1/bastions') {
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'ok',
              'data': [
                bastionJson([
                  facilityJson(
                      id: 'keep', name: 'Keep', constructed: 2, total: 2),
                ]),
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.method == 'PUT') {
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

      final keep = (cubit.state as BastionLoadedState)
          .bastions
          .first
          .facilities
          .firstWhere((f) => f.id == 'keep');
      final result = await cubit.upgradeFacility('bastion-1', keep);

      expect(result, isNull);
      expect(puts, isEmpty);

      await cubit.close();
    });
  });
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/features/bastions_page/logic/bastion_cubit_test.dart`
Expected: FAIL — compile error: `The method 'upgradeFacility' isn't defined for the type 'BastionCubit'`.

- [ ] **Step 3: Add imports to `bastion_cubit.dart`**

In `lib/features/bastions_page/logic/bastion_cubit.dart`, add after the existing imports:

```dart
import 'package:maura_bastion_system/data/enums/rank.dart';
import 'package:maura_bastion_system/data/test_data/bastion/facility_catalog.dart';
```

- [ ] **Step 4: Add the `upgradeFacility` method**

In `lib/features/bastions_page/logic/bastion_cubit.dart`, add a `bool _upgrading = false;` field next to `_advancingTurn`, and add this method after `advanceBastionTurn`:

```dart
  Future<Facility?> upgradeFacility(String bastionId, Facility facility) async {
    if (_upgrading) return null;
    if (state is! BastionLoadedState) return null;

    final loaded = state as BastionLoadedState;
    final bastion = loaded.bastions.firstWhere(
      (b) => b.id == bastionId,
      orElse: () => loaded.bastions.first,
    );

    if (facility.rank == Rank.S) return null;
    if (!upgradeableFacilityIds.contains(facility.id)) return null;
    final nextRank = facility.rank.next;
    if (nextRank == null) return null;
    final anyBusy = bastion.facilities
        .any((f) => f.constructedTurns < f.constructionTurns);
    if (anyBusy) return null;

    final upgraded = Facility(
      id: facility.id,
      name: facility.name,
      rank: nextRank,
      description: facility.description,
      imgUrl: facility.imgUrl,
      table: facility.table,
      minimumRequiredHirelings: facility.minimumRequiredHirelings,
      constructionTurns: 2,
      cost: baseCostByRank[nextRank]!,
      constructedTurns: 0,
    );

    try {
      _upgrading = true;
      await _facilityApi.update(upgraded.id, upgraded, bastionId: bastion.id);
      await loadBastions();
      return upgraded;
    } catch (e, stackTrace) {
      emit(BastionErrorState(
        error: e as Exception,
        stackTrace: stackTrace,
        message: 'Failed to upgrade facility',
      ));
      return null;
    } finally {
      _upgrading = false;
    }
  }
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `flutter test test/features/bastions_page/logic/bastion_cubit_test.dart`
Expected: PASS — all existing `advanceBastionTurn` tests plus the new `upgradeFacility` tests.

- [ ] **Step 6: Commit**

```bash
git add lib/features/bastions_page/logic/bastion_cubit.dart test/features/bastions_page/logic/bastion_cubit_test.dart
git commit -m "feat: add BastionCubit.upgradeFacility"
```

---
### Task 3: Upgrade button on `FacilityPage`

**Files:**
- Modify: `lib/features/bastions_page/presentation/facility_page.dart`
- Create: `test/features/bastions_page/presentation/facility_page_test.dart`

**Interfaces:**
- Consumes: `upgradeableFacilityIds`, `facilityUpgradeCost`, `Rank.next` (from Task 1).
- Produces: `FacilityPage.onUpgrade` (new optional `VoidCallback?` constructor param, passed through to `_FacilityView`). The upgrade button is rendered when: `isUserBastion && !isSelectionMode && facility.constructedTurns >= facility.constructionTurns && facility.rank != Rank.S && upgradeableFacilityIds.contains(facility.id) && !bastion.facilities.any((f) => f.constructedTurns < f.constructionTurns)`.

- [ ] **Step 1: Write the failing widget tests**

Create `test/features/bastions_page/presentation/facility_page_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:maura_bastion_system/api/api_client.dart';
import 'package:maura_bastion_system/api/hireling_api.dart';
import 'package:maura_bastion_system/api/identity_api.dart';
import 'package:maura_bastion_system/data/enums/rank.dart';
import 'package:maura_bastion_system/data/models/bastion/bastion.dart';
import 'package:maura_bastion_system/data/models/bastion/facility.dart';
import 'package:maura_bastion_system/features/bastions_page/presentation/facility_page.dart';
import 'package:maura_bastion_system/features/login/logic/auth_cubit.dart';

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    GetIt.I.reset();
  });

  Facility barracks({int constructed = 2, int total = 2, Rank rank = Rank.D}) =>
      Facility(
        id: 'cat_barracks',
        name: 'Barracks',
        rank: rank,
        description: 'Houses the guard.',
        constructionTurns: total,
        constructedTurns: constructed,
        cost: 600,
      );

  MockClient hirelingMock() {
    return MockClient((request) async {
      if (request.method == 'GET' &&
          request.url.path == '/maura/v1/hirelings') {
        return http.Response(
          jsonEncode({'success': true, 'message': 'ok', 'data': <Object>[]}),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      return http.Response(
        jsonEncode({'success': false, 'message': 'not found'}),
        404,
        headers: {'content-type': 'application/json'},
      );
    });
  }

  Future<void> pumpFacilityPage(
    WidgetTester tester, {
    required Facility facility,
    required List<Facility> bastionFacilities,
    required bool isUserBastion,
    VoidCallback? onUpgrade,
  }) async {
    final apiClient =
        ApiClient(baseUrl: 'http://example.test', client: hirelingMock());
    GetIt.I.registerSingleton<HirelingApi>(HirelingApi(client: apiClient));
    final authCubit = AuthCubit(identityApi: IdentityApi(client: apiClient));
    GetIt.I.registerSingleton<AuthCubit>(authCubit);

    final bastion = Bastion(
      id: 'bastion_1',
      name: 'Test Bastion',
      description: 'desc',
      facilities: bastionFacilities,
    );

    await tester.pumpWidget(
      BlocProvider<AuthCubit>(
        create: (_) => authCubit,
        child: MaterialApp(
          home: FacilityPage(
            facility: facility,
            bastion: bastion,
            isUserBastion: isUserBastion,
            onUpgrade: onUpgrade,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
      'shows Upgrade button for an owned, built, upgradeable facility with no busy facilities',
      (tester) async {
    await pumpFacilityPage(
      tester,
      facility: barracks(),
      bastionFacilities: [barracks()],
      isUserBastion: true,
      onUpgrade: () {},
    );

    expect(find.text('Upgrade to Rank C — 900 GP'), findsOneWidget);
  });

  testWidgets('hides Upgrade button while another facility is under construction',
      (tester) async {
    final kitchen = Facility(
      id: 'cat_kitchen',
      name: 'Kitchen',
      rank: Rank.D,
      description: 'Flavor.',
      constructionTurns: 2,
      constructedTurns: 0,
    );

    await pumpFacilityPage(
      tester,
      facility: barracks(),
      bastionFacilities: [barracks(), kitchen],
      isUserBastion: true,
      onUpgrade: () {},
    );

    expect(find.text('Upgrade to Rank C — 900 GP'), findsNothing);
  });

  testWidgets('hides Upgrade button while the facility itself is under construction',
      (tester) async {
    await pumpFacilityPage(
      tester,
      facility: barracks(constructed: 0, total: 2),
      bastionFacilities: [barracks(constructed: 0, total: 2)],
      isUserBastion: true,
      onUpgrade: () {},
    );

    expect(find.text('Upgrade to Rank C — 900 GP'), findsNothing);
  });

  testWidgets('hides Upgrade button for a non-user bastion', (tester) async {
    await pumpFacilityPage(
      tester,
      facility: barracks(),
      bastionFacilities: [barracks()],
      isUserBastion: false,
    );

    expect(find.text('Upgrade to Rank C — 900 GP'), findsNothing);
  });

  testWidgets('hides Upgrade button for a non-upgradeable facility id',
      (tester) async {
    final armory = Facility(
      id: 'cat_armory',
      name: 'Armory',
      rank: Rank.C,
      description: 'An armory.',
      constructionTurns: 4,
      constructedTurns: 4,
    );

    await pumpFacilityPage(
      tester,
      facility: armory,
      bastionFacilities: [armory],
      isUserBastion: true,
      onUpgrade: () {},
    );

    expect(find.text('Upgrade to Rank C — 900 GP'), findsNothing);
  });

  testWidgets('hides Upgrade button for an S-rank facility', (tester) async {
    await pumpFacilityPage(
      tester,
      facility: barracks(rank: Rank.S),
      bastionFacilities: [barracks(rank: Rank.S)],
      isUserBastion: true,
      onUpgrade: () {},
    );

    expect(find.textContaining('Upgrade to Rank'), findsNothing);
  });

  testWidgets('tapping Upgrade invokes the onUpgrade callback', (tester) async {
    var called = false;
    await pumpFacilityPage(
      tester,
      facility: barracks(),
      bastionFacilities: [barracks()],
      isUserBastion: true,
      onUpgrade: () {
        called = true;
      },
    );

    await tester.tap(find.text('Upgrade to Rank C — 900 GP'));
    expect(called, isTrue);
  });
}
```

Note: `jsonEncode` requires `import 'dart:convert';` — add it to the top of the test file:

```dart
import 'dart:convert';
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/features/bastions_page/presentation/facility_page_test.dart`
Expected: FAIL — compile error: `The named parameter 'onUpgrade' isn't defined` in `FacilityPage`.

- [ ] **Step 3: Add imports to `facility_page.dart`**

In `lib/features/bastions_page/presentation/facility_page.dart`, add after the existing imports:

```dart
import 'package:maura_bastion_system/data/test_data/bastion/facility_catalog.dart';
```

- [ ] **Step 4: Add the `onUpgrade` param to `FacilityPage`**

In `facility_page.dart`, in `class FacilityPage`, add:

```dart
  final VoidCallback? onUpgrade;
```

and add `this.onUpgrade,` to the constructor. Pass it through to every `_FacilityView` constructor call in the three branches.

- [ ] **Step 5: Add the `onUpgrade` param to `_FacilityView`**

In `class _FacilityView`, add:

```dart
  final VoidCallback? onUpgrade;
```

and `this.onUpgrade,` to the constructor.

- [ ] **Step 6: Render the upgrade button**

In `_FacilityView.build`, compute the visibility and render the button after the existing construction (selection-mode) button block. Insert this right before the closing `],` of the main `Column`'s children (after the `if (isSelectionMode && onConstruct != null) ...[ ... ]` block):

```dart
                  if (_shouldShowUpgradeButton()) ...[
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: onUpgrade,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: MedievalColors.vermillion,
                          foregroundColor: MedievalColors.goldPale,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'Upgrade to Rank ${facility.rank.next!.title} — ${facilityUpgradeCost(facility.rank)} GP',
                          style: GoogleFonts.cinzel(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
```

Add the private helper method to `_FacilityView`:

```dart
  bool _shouldShowUpgradeButton() {
    if (onUpgrade == null) return false;
    if (!isUserBastion || isSelectionMode) return false;
    if (facility.constructedTurns < facility.constructionTurns) return false;
    if (facility.rank == Rank.S) return false;
    if (!upgradeableFacilityIds.contains(facility.id)) return false;
    final anyBusy = bastion.facilities
        .any((f) => f.constructedTurns < f.constructionTurns);
    return !anyBusy;
  }
```

- [ ] **Step 7: Run tests to verify they pass**

Run: `flutter test test/features/bastions_page/presentation/facility_page_test.dart`
Expected: PASS — all 7 widget tests pass.

- [ ] **Step 8: Commit**

```bash
git add lib/features/bastions_page/presentation/facility_page.dart test/features/bastions_page/presentation/facility_page_test.dart
git commit -m "feat: add facility upgrade button to detail page"
```

---
### Task 4: Wire `onUpgrade` from `BastionPage` (end-to-end)

**Files:**
- Modify: `lib/features/bastions_page/presentation/bastion_page.dart`
- Modify: `test/features/bastions_page/presentation/bastion_page_test.dart`
- Verify: `test/features/bastions_page/presentation/facility_page_test.dart`, `test/features/bastions_page/logic/bastion_cubit_test.dart`

**Interfaces:**
- Consumes: `FacilityPage.onUpgrade` (from Task 3), `BastionCubit.upgradeFacility` (from Task 2).
- Produces: both `FacilityPage` push sites in `bastion_page.dart` pass an `onUpgrade` callback that awaits `cubit.upgradeFacility(bastion.id, facility)` and pops back on success.

- [ ] **Step 1: Write the failing end-to-end widget test**

Append to `test/features/bastions_page/presentation/bastion_page_test.dart`, inside `void main()`, a new test. It needs `HirelingApi` registered (the pushed `FacilityPage` creates a `HirelingsCubit` from `GetIt.I<HirelingApi>()`), and a `PUT` handler for the upgrade. Add the import at the top:

```dart
import 'package:maura_bastion_system/api/hireling_api.dart';
```

The test (append after the existing "FAB" tests):

```dart
  testWidgets(
      'upgrading a facility from its page POPTS it back at the next rank',
      (tester) async {
    var puts = 0;
    var firstBastionGet = true;
    final mockClient = MockClient((request) async {
      if (request.method == 'GET' &&
          request.url.path == '/maura/v1/bastions') {
        final rankField = firstBastionGet ? 'd' : 'c';
        firstBastionGet = false;
        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'ok',
            'data': [
              {
                'id': 'bastion_1',
                'userId': 'user_1',
                'name': 'Test Bastion',
                'description': 'A test stronghold.',
                'facilities': [
                  turnFacilityJson(
                    id: 'cat_barracks',
                    name: 'Barracks',
                    rank: rankField,
                    constructed: rankField == 'd' ? 2 : 0,
                    total: rankField == 'd' ? 2 : 2,
                  ),
                ],
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      if (request.method == 'GET' &&
          request.url.path == '/maura/v1/hirelings') {
        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'ok',
            'data': <Object>[],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      if (request.method == 'PUT' &&
          request.url.path == '/maura/v1/facilities/cat_barracks') {
        puts++;
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
        jsonEncode({'success': false, 'message': 'not found'}),
        404,
        headers: {'content-type': 'application/json'},
      );
    });

    final apiClient =
        ApiClient(baseUrl: 'http://example.test', client: mockClient);
    GetIt.I.registerSingleton<BastionApi>(BastionApi(client: apiClient));
    GetIt.I.registerSingleton<FacilityApi>(FacilityApi(client: apiClient));
    GetIt.I.registerSingleton<HirelingApi>(HirelingApi(client: apiClient));
    final authCubit = AuthCubit(identityApi: IdentityApi(client: apiClient));
    GetIt.I.registerSingleton<AuthCubit>(authCubit);

    await tester.pumpWidget(
      BlocProvider<AuthCubit>(
        create: (_) => authCubit,
        child: const MaterialApp(
          home: BastionPage(bastionId: 'bastion_1', isUserBastion: true),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Barracks'));
    await tester.pumpAndSettle();

    expect(find.text('Upgrade to Rank C — 900 GP'), findsOneWidget);

    await tester.tap(find.text('Upgrade to Rank C — 900 GP'));
    await tester.pumpAndSettle();

    expect(puts, 1);
    expect(find.text('Upgrade to Rank C — 900 GP'), findsNothing);
    expect(find.text('Barracks'), findsWidgets);
  });
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/features/bastions_page/presentation/bastion_page_test.dart`
Expected: FAIL — the `Upgrade to Rank C — 900 GP` button is not shown because `BastionPage` does not pass `onUpgrade` yet (and until Task 3's button is present in the page, the finder finds nothing).

- [ ] **Step 3: Wire `onUpgrade` in `bastion_page.dart`**

There are two `FacilityPage(...)` push sites in `lib/features/bastions_page/presentation/bastion_page.dart`: in `_buildFacilityCard` and in `_buildBastionHirelingChip`. In each, the push currently looks like:

```dart
                  MaterialPageRoute(builder: (_) => FacilityPage(
                    facility: facility,
                    bastion: bastion,
                    isUserBastion: isUserBastion,
                  )),
```

Add `onUpgrade` to each `FacilityPage(...)` call:

```dart
                  MaterialPageRoute(builder: (_) => FacilityPage(
                    facility: facility,
                    bastion: bastion,
                    isUserBastion: isUserBastion,
                    onUpgrade: isUserBastion
                        ? () async {
                            await cubit.upgradeFacility(bastion.id, facility);
                            if (context.mounted) {
                              Navigator.of(context).pop();
                            }
                          }
                        : null,
                  )),
```

In `_buildBastionHirelingChip`, `cubit` is already defined in the enclosing `onTap`; in `_buildFacilityCard`, `cubit` is defined just before the `Navigator.of(context).push(...)` call. The `context.mounted` guard refers to the page context — this is safe because the context is below the opened route in the navigator and remains mounted while `FacilityPage` is displayed.

- [ ] **Step 4: Run the full suite to verify**

Run: `flutter test`
Expected: PASS — all existing tests, plus the new end-to-end upgrade test (`puts == 1`, button disappears after tapping, page popped).

- [ ] **Step 5: Run the analyzer**

Run: `flutter analyze`
Expected: No issues. Fix any that appear (e.g., unused imports) before committing.

- [ ] **Step 6: Commit**

```bash
git add lib/features/bastions_page/presentation/bastion_page.dart test/features/bastions_page/presentation/bastion_page_test.dart
git commit -m "feat: wire facility upgrades from bastion page"
```

---
## Verification Summary

After all tasks complete, run:

```bash
flutter test
flutter analyze
```

Both must pass with no failures and no analyzer issues.