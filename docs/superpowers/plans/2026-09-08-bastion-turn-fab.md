# Bastion Turn FAB Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a "Bastion Turn" FAB to the user's bastion page that advances one construction turn and opens a dialog listing buff-granting facilities with expandable descriptions/tables.

**Architecture:** Extend `StandardScaffold` with an optional FAB slot; add `advanceBastionTurn()` to `BastionCubit` (first under-construction facility, persisted via `FacilityApi.update`); new parchment-styled `BastionTurnDialog` widget with `ExpansionTile` list; extract `FacilityPage`'s table rendering into a shared `FacilityTableView` widget.

**Tech Stack:** Flutter, flutter_bloc (per-page Cubits), get_it DI, MockClient-based tests.

**Spec:** `docs/superpowers/specs/2026-09-08-bastion-turn-fab-design.md`

## Global Constraints

- No new package dependencies (zero-dependency app; `flutter_bloc`, `get_it`, `google_fonts`, `http` already present).
- `Facility` has NO `copyWith` — reconstruct field-by-field (pattern: `lib/features/bastions_page/logic/bastion_cubit.dart:43-54`).
- Theming: `GoogleFonts.cinzel` for headers, `GoogleFonts.imFellEnglish` for body, `MedievalColors` from `lib/core/themes/theme_colors.dart`, parchment cards = RadialGradient + `ParchmentBorderPainter`.
- FAB theming is global (`theme_components.dart` vermillion circle) — do not restyle per-page.
- Work in `/Users/barendblom/Personal_Projects/maura_bastion_system`. `docs/` is gitignored; use `git add -f` for docs.
- Run tests with `flutter test` from the repo root; analyze with `flutter analyze`.

---

### Task 1: `StandardScaffold` FAB support

**Files:**
- Modify: `lib/widgets/standard_scaffold/standard_scaffold.dart`

**Interfaces:**
- Produces: `StandardScaffold({required Widget body, Widget? floatingActionButton})` — used by Task 5.

- [ ] **Step 1: Add the optional parameter**

In `lib/widgets/standard_scaffold/standard_scaffold.dart`, add the field and constructor param, then pass it to the inner `Scaffold`:

```dart
class StandardScaffold extends StatelessWidget {
  final Widget body;
  final Widget? floatingActionButton;

  const StandardScaffold({
    super.key,
    required this.body,
    this.floatingActionButton,
  });
```

and inside `build`, on the returned `Scaffold` (after `body:`):

```dart
      floatingActionButton: floatingActionButton,
```

- [ ] **Step 2: Verify existing tests still pass**

Run: `flutter test`
Expected: ALL PASS (no behavioral change for existing callers).

- [ ] **Step 3: Commit**

```bash
git add lib/widgets/standard_scaffold/standard_scaffold.dart
git commit -m "Add optional FAB slot to StandardScaffold"
```

---

### Task 2: `BastionCubit.advanceBastionTurn()`

**Files:**
- Modify: `lib/features/bastions_page/logic/bastion_cubit.dart`
- Test: `test/features/bastions_page/logic/bastion_cubit_test.dart`

**Interfaces:**
- Consumes: `FacilityApi.update(String id, Facility facility)` (`lib/api/facility_api.dart:39`), `loadBastions()`.
- Produces: `Future<Facility?> advanceBastionTurn(String bastionId)` — returns the facility that advanced (with incremented `constructedTurns`), or `null` when nothing is under construction or the state is not loaded or the API call fails. Used by Task 5.

- [ ] **Step 1: Write the failing tests**

Append inside the existing `void main() { ... }` of `test/features/bastions_page/logic/bastion_cubit_test.dart` (after the `BastionCubit.addFacility` group), adding a `BastionApi.getAll` + `FacilityApi.update` mock harness:

```dart
  group('BastionCubit.advanceBastionTurn', () {
    Map<String, dynamic> facilityJson({
      required String id,
      required String name,
      int constructed = 0,
      int total = 0,
      int requiredHirelings = 0,
    }) =>
        {
          'id': id,
          'name': name,
          'rank': 'd',
          'description': 'desc',
          'constructionTurns': total,
          'constructedTurns': constructed,
          'minimumRequiredHirelings': requiredHirelings,
          'cost': 0,
        };

    Map<String, dynamic> bastionJson(List<Map<String, dynamic>> facilities) =>
        {
          'id': 'bastion-1',
          'userId': 'user_1',
          'name': 'Test Bastion',
          'description': 'desc',
          'facilities': facilities,
        };

    test('increments the FIRST under-construction facility and persists it',
        () async {
      final puts = <http.Request>[];
      var bastionGets = 0;
      final mock = MockClient((request) async {
        if (request.method == 'GET' &&
            request.url.path == '/maura/v1/bastions') {
          bastionGets++;
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'ok',
              'data': [
                bastionJson([
                  facilityJson(id: 'keep', name: 'Keep'),
                  facilityJson(
                      id: 'barracks', name: 'Barracks', constructed: 0, total: 2),
                  facilityJson(
                      id: 'garden', name: 'Garden', constructed: 1, total: 3),
                ]),
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.method == 'PUT' &&
            request.url.path == '/maura/v1/facilities/barracks') {
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

      final advanced = await cubit.advanceBastionTurn('bastion-1');

      expect(advanced, isNotNull);
      expect(advanced!.name, 'Barracks');
      expect(advanced.constructedTurns, 1);
      expect(puts.length, 1);
      expect(
        jsonDecode(puts.first.body)['constructedTurns'],
        1,
      );
      expect(bastionGets, greaterThanOrEqualTo(2)); // refetched after update

      await cubit.close();
    });

    test('returns null and calls no API when all facilities are complete',
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
                  facilityJson(id: 'keep', name: 'Keep'),
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

      final advanced = await cubit.advanceBastionTurn('bastion-1');

      expect(advanced, isNull);
      expect(puts, isEmpty);

      await cubit.close();
    });
  });
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/features/bastions_page/logic/bastion_cubit_test.dart`
Expected: FAIL — `advanceBastionTurn` isn't defined on `BastionCubit`.

- [ ] **Step 3: Implement `advanceBastionTurn`**

In `lib/features/bastions_page/logic/bastion_cubit.dart`, add this method to `BastionCubit` (after `addFacility`):

```dart
  Future<Facility?> advanceBastionTurn(String bastionId) async {
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
    if (target == null) return null;

    final advanced = Facility(
      id: target.id,
      name: target.name,
      rank: target.rank,
      description: target.description,
      imgUrl: target.imgUrl,
      table: target.table,
      minimumRequiredHirelings: target.minimumRequiredHirelings,
      constructionTurns: target.constructionTurns,
      cost: target.cost,
      constructedTurns: target.constructedTurns + 1,
    );

    try {
      await _facilityApi.update(advanced.id, advanced);
      await loadBastions();
      return advanced;
    } catch (e, stackTrace) {
      emit(BastionErrorState(
        error: e as Exception,
        stackTrace: stackTrace,
        message: 'Failed to advance bastion turn',
      ));
      return null;
    }
  }
```

(Incrementing only facilities where `constructedTurns < constructionTurns` means the result can never exceed `constructionTurns` — completion caps automatically.)

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/features/bastions_page/logic/bastion_cubit_test.dart`
Expected: ALL PASS (3 tests: 1 existing addFacility + 2 new).

- [ ] **Step 5: Commit**

```bash
git add lib/features/bastions_page/logic/bastion_cubit.dart test/features/bastions_page/logic/bastion_cubit_test.dart
git commit -m "Add advanceBastionTurn to BastionCubit"
```

---

### Task 3: Shared `FacilityTableView` widget

**Files:**
- Create: `lib/features/bastions_page/presentation/widgets/facility_table_view.dart`
- Modify: `lib/features/bastions_page/presentation/facility_page.dart:402-500` (`_buildTableSection`)

**Interfaces:**
- Produces: `FacilityTableView({Key? key, required FacilityTable table})` — renders the 'Facility Table' header + bordered table. Used by Task 4 (dialog) and by `FacilityPage`.

- [ ] **Step 1: Create the widget**

Create `lib/features/bastions_page/presentation/widgets/facility_table_view.dart` with the exact rendering currently in `FacilityPage._buildTableSection`:

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:maura_bastion_system/core/themes/theme_colors.dart';
import 'package:maura_bastion_system/data/models/bastion/table.dart';

class FacilityTableView extends StatelessWidget {
  final FacilityTable table;

  const FacilityTableView({super.key, required this.table});

  @override
  Widget build(BuildContext context) {
    final rows = table.table;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: MedievalColors.parchment,
            border: Border.all(color: MedievalColors.goldLeaf),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(10),
              topRight: Radius.circular(10),
            ),
          ),
          child: Text(
            'Facility Table',
            style: GoogleFonts.cinzel(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: MedievalColors.vermillion,
            ),
          ),
        ),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: MedievalColors.goldLeaf),
              right: BorderSide(color: MedievalColors.goldLeaf),
              bottom: BorderSide(color: MedievalColors.goldLeaf),
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(10),
              bottomRight: Radius.circular(10),
            ),
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(10),
              bottomRight: Radius.circular(10),
            ),
            child: Table(
              border: TableBorder(
                horizontalInside: BorderSide(color: MedievalColors.goldPale),
                verticalInside: BorderSide(color: MedievalColors.goldPale),
              ),
              columnWidths: rows.isNotEmpty
                  ? Map.fromEntries(
                      List.generate(
                        rows.first.length,
                        (i) => MapEntry(i, const FlexColumnWidth()),
                      ),
                    )
                  : const {},
              children: rows.asMap().entries.map((entry) {
                final rowIndex = entry.key;
                final row = entry.value;

                return TableRow(
                  decoration: rowIndex == 0
                      ? BoxDecoration(color: MedievalColors.vermillionDark)
                      : BoxDecoration(
                          color: rowIndex.isOdd
                              ? MedievalColors.parchment
                              : MedievalColors.parchmentLight,
                        ),
                  children: row.map((cell) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 12,
                      ),
                      child: Text(
                        cell,
                        textAlign:
                            rowIndex == 0 ? TextAlign.center : TextAlign.start,
                        style: rowIndex == 0
                            ? GoogleFonts.cinzel(
                                fontSize: 13,
                                color: MedievalColors.goldPale,
                                fontWeight: FontWeight.bold,
                              )
                            : GoogleFonts.imFellEnglish(
                                fontSize: 14,
                                color: MedievalColors.sepiaInk,
                              ),
                      ),
                    );
                  }).toList(),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: Refactor `FacilityPage` to use it**

In `lib/features/bastions_page/presentation/facility_page.dart`:

1. Add import:
   ```dart
   import 'package:maura_bastion_system/features/bastions_page/presentation/widgets/facility_table_view.dart';
   ```
2. Replace the whole `_buildTableSection()` method body (lines 402–500) with:
   ```dart
   Widget _buildTableSection() {
     return FacilityTableView(table: facility.table!);
   }
   ```
3. Run `flutter analyze` — if it flags now-unused imports in `facility_page.dart`, remove exactly those flagged imports.

- [ ] **Step 3: Verify the full suite passes**

Run: `flutter test`
Expected: ALL PASS (FacilityPage renders identically through the shared widget).

- [ ] **Step 4: Commit**

```bash
git add lib/features/bastions_page/presentation/widgets/facility_table_view.dart lib/features/bastions_page/presentation/facility_page.dart
git commit -m "Extract FacilityTableView widget from FacilityPage"
```

---

### Task 4: `BastionTurnDialog` widget

**Files:**
- Create: `lib/features/bastions_page/presentation/widgets/bastion_turn_dialog.dart`

**Interfaces:**
- Consumes: `FacilityTableView` (Task 3), `ParchmentBorderPainter`, `MedievalColors`, `Bastion.facilityHirelingCount`.
- Produces: `BastionTurnDialog.show(BuildContext context, {required Facility? advancedFacility, required Bastion bastion})` — static helper wrapping `showDialog`. Widget is also directly constructible for tests (`const BastionTurnDialog({required this.advancedFacility, required this.bastion})`). Used by Task 5.

Eligibility rule (implemented here): facility is listed when `constructedTurns >= constructionTurns` AND `bastion.facilityHirelingCount(f.id) >= minimumRequiredHirelings`.

- [ ] **Step 1: Create the dialog widget**

Create `lib/features/bastions_page/presentation/widgets/bastion_turn_dialog.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:maura_bastion_system/core/themes/theme_colors.dart';
import 'package:maura_bastion_system/data/models/bastion/bastion.dart';
import 'package:maura_bastion_system/data/models/bastion/facility.dart';
import 'package:maura_bastion_system/features/bastions_page/presentation/widgets/facility_table_view.dart';
import 'package:maura_bastion_system/features/news_paper/presentation/widgets/parchment_border.dart';

class BastionTurnDialog extends StatelessWidget {
  final Facility? advancedFacility;
  final Bastion bastion;

  const BastionTurnDialog({
    super.key,
    required this.advancedFacility,
    required this.bastion,
  });

  static Future<void> show(
    BuildContext context, {
    required Facility? advancedFacility,
    required Bastion bastion,
  }) {
    return showDialog(
      context: context,
      builder: (_) => BastionTurnDialog(
        advancedFacility: advancedFacility,
        bastion: bastion,
      ),
    );
  }

  List<Facility> _eligibleFacilities() {
    return bastion.facilities
        .where((f) =>
            f.constructedTurns >= f.constructionTurns &&
            bastion.facilityHirelingCount(f.id) >= f.minimumRequiredHirelings)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final eligible = _eligibleFacilities();
    final String header = advancedFacility != null
        ? 'Construction advanced: ${advancedFacility!.name} '
            '(${advancedFacility!.constructedTurns}/${advancedFacility!.constructionTurns} turns)'
        : 'No facilities under construction.';

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 480),
        decoration: BoxDecoration(
          gradient: const RadialGradient(
            center: Alignment.center,
            radius: 0.9,
            colors: [
              MedievalColors.parchmentLight,
              MedievalColors.parchmentDark,
            ],
            stops: [0.6, 1.0],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(50),
              blurRadius: 6,
              offset: const Offset(2, 3),
            ),
          ],
        ),
        child: CustomPaint(
          painter: ParchmentBorderPainter(),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Bastion Turn',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cinzel(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: MedievalColors.vermillion,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  header,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.imFellEnglish(
                    fontSize: 14,
                    height: 1.4,
                    color: MedievalColors.sepiaInk,
                  ),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: eligible.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            'No facilities ready to grant buffs this turn.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.imFellEnglish(
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                              color: MedievalColors.sepiaMuted,
                            ),
                          ),
                        )
                      : SingleChildScrollView(
                          child: Column(
                            children: eligible
                                .map((f) => _buildFacilityTile(context, f))
                                .toList(),
                          ),
                        ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFacilityTile(BuildContext context, Facility facility) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        gradient: const RadialGradient(
          center: Alignment.center,
          radius: 0.9,
          colors: [
            MedievalColors.parchmentLight,
            MedievalColors.parchmentDark,
          ],
          stops: [0.6, 1.0],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(50),
            blurRadius: 6,
            offset: const Offset(2, 3),
          ),
        ],
      ),
      child: CustomPaint(
        painter: ParchmentBorderPainter(),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 12),
            childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            iconColor: MedievalColors.sepiaSecondary,
            collapsedIconColor: MedievalColors.sepiaSecondary,
            title: Text(
              facility.name,
              style: GoogleFonts.cinzel(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: MedievalColors.vermillion,
              ),
            ),
            subtitle: Text(
              'Rank ${facility.rank.title}',
              style: GoogleFonts.imFellEnglish(
                fontSize: 12,
                color: MedievalColors.sepiaSecondary,
              ),
            ),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  facility.description,
                  style: GoogleFonts.imFellEnglish(
                    fontSize: 13,
                    height: 1.4,
                    color: MedievalColors.sepiaInk,
                  ),
                ),
              ),
              if (facility.table != null) ...[
                const SizedBox(height: 8),
                FacilityTableView(table: facility.table!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Analyze**

Run: `flutter analyze`
Expected: No issues in the new file.

- [ ] **Step 3: Commit**

```bash
git add lib/features/bastions_page/presentation/widgets/bastion_turn_dialog.dart
git commit -m "Add BastionTurnDialog widget"
```

---

### Task 5: Wire the FAB into `BastionPage`

**Files:**
- Modify: `lib/features/bastions_page/presentation/bastion_page.dart`
- Test: `test/features/bastions_page/presentation/bastion_page_test.dart`

**Interfaces:**
- Consumes: `StandardScaffold(floatingActionButton: ...)` (Task 1), `BastionCubit.advanceBastionTurn` (Task 2), `BastionTurnDialog.show` (Task 4).

- [ ] **Step 1: Write the failing tests**

Append inside `void main() { ... }` of `test/features/bastions_page/presentation/bastion_page_test.dart`, plus add the two new imports at the top of the file:

```dart
import 'package:maura_bastion_system/features/bastions_page/presentation/widgets/bastion_turn_dialog.dart';
```

(`find.byType(FloatingActionButton)` needs nothing extra; `flutter/material.dart` is already imported.)

Test helpers + tests:

```dart
  Map<String, dynamic> turnFacilityJson({
    required String id,
    required String name,
    String rank = 'd',
    String description = 'desc',
    int constructed = 0,
    int total = 0,
    int requiredHirelings = 0,
    Map<String, dynamic>? table,
  }) =>
      {
        'id': id,
        'name': name,
        'rank': rank,
        'description': description,
        'constructionTurns': total,
        'constructedTurns': constructed,
        'minimumRequiredHirelings': requiredHirelings,
        'cost': 0,
        if (table != null) 'table': table,
      };

  MockClient bastionTurnMockClient(List<Map<String, dynamic>> facilities,
      {List<Map<String, dynamic>> hirelings = const []}) {
    return MockClient((request) async {
      if (request.method == 'GET' &&
          request.url.path == '/maura/v1/bastions') {
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
                'facilities': facilities,
                'hirelings': hirelings,
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      if (request.method == 'PUT' &&
          request.url.path.startsWith('/maura/v1/facilities/')) {
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
  }

  Future<void> pumpBastionPage(WidgetTester tester,
      {required bool isUserBastion, required MockClient mockClient}) async {
    final apiClient = ApiClient(baseUrl: 'http://example.test', client: mockClient);
    GetIt.I.registerSingleton<BastionApi>(BastionApi(client: apiClient));
    GetIt.I.registerSingleton<FacilityApi>(FacilityApi(client: apiClient));
    final authCubit = AuthCubit(identityApi: IdentityApi(client: apiClient));
    GetIt.I.registerSingleton<AuthCubit>(authCubit);

    await tester.pumpWidget(
      BlocProvider<AuthCubit>(
        create: (_) => authCubit,
        child: MaterialApp(
          home: BastionPage(bastionId: 'bastion_1', isUserBastion: isUserBastion),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('FAB is hidden for non-user bastions', (tester) async {
    await pumpBastionPage(
      tester,
      isUserBastion: false,
      mockClient: bastionTurnMockClient([
        turnFacilityJson(id: 'keep', name: 'Keep'),
      ]),
    );

    expect(find.byType(FloatingActionButton), findsNothing);
  });

  testWidgets('FAB takes a turn: advances construction and shows eligible facilities',
      (tester) async {
    await pumpBastionPage(
      tester,
      isUserBastion: true,
      mockClient: bastionTurnMockClient(
        [
          turnFacilityJson(
            id: 'keep',
            name: 'Keep',
            description: 'A sturdy keep.',
            table: {
              'table': [
                ['d4', 'Effect'],
                ['1', 'Bonus gold'],
              ],
            },
          ),
          turnFacilityJson(
              id: 'barracks', name: 'Barracks', constructed: 0, total: 2),
          turnFacilityJson(
              id: 'kitchen',
              name: 'Kitchen',
              rank: 'c',
              requiredHirelings: 2),
        ],
        hirelings: [
          {
            'id': 'h1',
            'name': 'Anna',
            'bastionId': 'bastion_1',
            'facilityId': 'kitchen',
          },
        ],
      ),
    );

    expect(find.byType(FloatingActionButton), findsOneWidget);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    // Dialog is open, construction advanced for the first under-construction facility.
    expect(find.text('Bastion Turn'), findsOneWidget);
    expect(
      find.textContaining('Construction advanced: Barracks (1/2 turns)'),
      findsOneWidget,
    );

    // Only eligible (built + staffed) facilities are listed in the dialog.
    final dialogFinder = find.byType(BastionTurnDialog);
    expect(find.descendant(of: dialogFinder, matching: find.text('Keep')),
        findsOneWidget);
    expect(find.descendant(of: dialogFinder, matching: find.text('Barracks')),
        findsNothing);
    expect(find.descendant(of: dialogFinder, matching: find.text('Kitchen')),
        findsNothing);

    // Expanding reveals the description and the table.
    await tester.tap(find.descendant(of: dialogFinder, matching: find.text('Keep')));
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: dialogFinder, matching: find.text('A sturdy keep.')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: dialogFinder, matching: find.text('Facility Table')),
      findsOneWidget,
    );
  });
```

Note: `GetIt.I.reset()` in the existing `setUp` keeps these tests isolated — no change needed there.

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/features/bastions_page/presentation/bastion_page_test.dart`
Expected: FAIL — no FAB is rendered yet (`FAB is hidden...` passes trivially, the take-a-turn test fails on `findsOneWidget` for the FAB).

- [ ] **Step 3: Wire the FAB into `BastionPage`**

In `lib/features/bastions_page/presentation/bastion_page.dart`:

1. Add import:
   ```dart
   import 'package:maura_bastion_system/features/bastions_page/presentation/widgets/bastion_turn_dialog.dart';
   ```
2. In `build`, attach the FAB to `StandardScaffold` (only for user bastions):
   ```dart
   return StandardScaffold(
     floatingActionButton: isUserBastion
         ? FloatingActionButton(
             onPressed: () => _takeBastionTurn(context, bastion),
             tooltip: 'Bastion Turn',
             child: const Icon(Icons.auto_awesome),
           )
         : null,
     body: Padding(
   ```
   (the rest of the existing `body:` argument stays unchanged)
3. Add the handler method to the `BastionPage` class (after `build`):
   ```dart
   Future<void> _takeBastionTurn(BuildContext context, Bastion bastion) async {
     final cubit = context.read<BastionCubit>();
     final advanced = await cubit.advanceBastionTurn(bastion.id);
     if (!context.mounted) return;
     await BastionTurnDialog.show(
       context,
       advancedFacility: advanced,
       bastion: bastion,
     );
   }
   ```

Note: the `bastion` passed to the dialog is the pre-advance snapshot from the current build; `advanceBastionTurn` already triggered `loadBastions()`, so the page itself rebuilds with fresh data underneath the dialog. The dialog header uses `advancedFacility` (the freshly advanced copy), which is why it shows the new `{n}/{total}` counts.

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/features/bastions_page/presentation/bastion_page_test.dart`
Expected: ALL PASS (3 tests: 1 existing + 2 new).

- [ ] **Step 5: Commit**

```bash
git add lib/features/bastions_page/presentation/bastion_page.dart test/features/bastions_page/presentation/bastion_page_test.dart
git commit -m "Add Bastion Turn FAB to bastion page"
```

---

### Task 6: Full verification

- [ ] **Step 1: Analyze the whole project**

Run: `flutter analyze`
Expected: No issues.

- [ ] **Step 2: Run the full test suite**

Run: `flutter test`
Expected: ALL PASS.

- [ ] **Step 3: Commit any remaining changes**

```bash
git status --short
```
If anything is dirty (e.g., analyzer-driven import cleanup), commit it with an appropriate message; otherwise nothing to do.
