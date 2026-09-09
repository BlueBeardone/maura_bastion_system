# Remove Bastion Defender Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let users remove a bastion defender via a detail sheet opened by tapping the defender card, with confirmation and API persistence.

**Architecture:** Add `DefendersCubit.removeDefender(id)` (calls existing `DefenderApi.delete`, filters state on success, rethrows on failure). Add a parchment-styled `DefenderDetailSheet` modal bottom sheet showing defender info with a "Remove from Bastion" button that opens a confirmation `AlertDialog`. Wire card taps to the sheet.

**Tech Stack:** Flutter, flutter_bloc (Cubit), get_it, MockClient (package:http/testing) for tests.

**Spec:** `docs/superpowers/specs/2026-09-09-remove-defender-design.md`

## Global Constraints

- No new dependencies (pubspec.yaml unchanged).
- Reuse existing theme constants from `MedievalColors` (`vermillion`, `sepiaInk`, `sepiaMuted`, `parchmentLight`, `parchmentDark`, `goldPale`); fonts via `GoogleFonts.cinzel` / `GoogleFonts.imFellEnglish`.
- Existing silent `catch (_) {}` in `addDefender`/`loadDefenders` must NOT be changed.
- `removeDefender` must rethrow API errors (deliberate divergence, per spec).
- Test style: `MockClient` + `ApiClient(baseUrl: 'http://example.test', client: mock)`; widget tests set `GoogleFonts.config.allowRuntimeFetching = false;` and register APIs in `GetIt.I` in `setUp`.
- API envelope: `{"success": bool, "message": String, "data": ...}`; non-2xx or `success: false` → `ApiException`.
- Commit style: `feat:`, `refactor:`, `test:` prefixes.

---

### Task 1: `DefendersCubit.removeDefender`

**Files:**
- Modify: `lib/features/bastions_page/logic/defenders_cubit.dart`
- Test: `test/features/bastions_page/logic/defenders_cubit_test.dart` (create)

**Interfaces:**
- Consumes: `DefenderApi.delete(String id) → Future<void>` (exists at `lib/api/defender_api.dart:45`), `DefendersState.copyWith(defenders:)`.
- Produces: `Future<void> removeDefender(String id)` on `DefendersCubit` — throws (`ApiException`) on API failure; on success emits state with the defender removed. Task 4 calls this.

- [ ] **Step 1: Write the failing test**

Create `test/features/bastions_page/logic/defenders_cubit_test.dart`:

```dart
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:maura_bastion_system/api/api_client.dart';
import 'package:maura_bastion_system/api/api_exception.dart';
import 'package:maura_bastion_system/api/defender_api.dart';
import 'package:maura_bastion_system/features/bastions_page/logic/defenders_cubit.dart';

void main() {
  Map<String, dynamic> defenderJson({
    required String id,
    String type = 'knight',
  }) =>
      {
        'id': id,
        'name': 'Defender $id',
        'type': type,
        'description': 'desc',
        'bastionId': 'bastion-1',
        'acquisitionStory': 'story',
      };

  MockClient defendersMockClient({
    void Function(http.Request)? onDelete,
    bool deleteSucceeds = true,
  }) {
    return MockClient((request) async {
      if (request.method == 'GET' &&
          request.url.path == '/maura/v1/defenders') {
        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'ok',
            'data': [
              defenderJson(id: 'd1'),
              defenderJson(id: 'd2', type: 'beast'),
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      if (request.method == 'DELETE' &&
          request.url.path == '/maura/v1/defenders/d1') {
        onDelete?.call(request);
        if (!deleteSucceeds) {
          return http.Response(
            jsonEncode({'success': false, 'message': 'boom'}),
            500,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response(
          jsonEncode({'success': true, 'message': 'ok', 'data': null}),
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
  }

  group('DefendersCubit.removeDefender', () {
    test('DELETEs the defender and removes it from state', () async {
      http.Request? captured;
      final mock = defendersMockClient(onDelete: (request) => captured = request);

      final apiClient = ApiClient(baseUrl: 'http://example.test', client: mock);
      final cubit = DefendersCubit(
        bastionId: 'bastion-1',
        defenderApi: DefenderApi(client: apiClient),
      );
      await cubit.loadDefenders();
      expect(cubit.state.defenders.length, 2);

      await cubit.removeDefender('d1');

      expect(captured, isNotNull);
      expect(captured!.method, 'DELETE');
      expect(captured!.url.path, '/maura/v1/defenders/d1');
      expect(cubit.state.defenders.length, 1);
      expect(cubit.state.defenders.first.id, 'd2');

      await cubit.close();
    });

    test('rethrows on API failure and leaves state unchanged', () async {
      final mock = defendersMockClient(deleteSucceeds: false);

      final apiClient = ApiClient(baseUrl: 'http://example.test', client: mock);
      final cubit = DefendersCubit(
        bastionId: 'bastion-1',
        defenderApi: DefenderApi(client: apiClient),
      );
      await cubit.loadDefenders();

      await expectLater(
        cubit.removeDefender('d1'),
        throwsA(isA<ApiException>()),
      );
      expect(cubit.state.defenders.length, 2);

      await cubit.close();
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/bastions_page/logic/defenders_cubit_test.dart`
Expected: FAIL — compile error, `removeDefender` isn't defined on `DefendersCubit`.

- [ ] **Step 3: Write minimal implementation**

In `lib/features/bastions_page/logic/defenders_cubit.dart`, add after `addDefender` (line 43):

```dart
  Future<void> removeDefender(String id) async {
    await _defenderApi.delete(id);
    emit(state.copyWith(
      defenders: state.defenders.where((d) => d.id != id).toList(),
    ));
  }
```

Note: no try/catch — a failed `_defenderApi.delete` throws before `emit`, leaving state unchanged and propagating the error (this is deliberate; do not match the silent `catch (_) {}` of the other methods).

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/bastions_page/logic/defenders_cubit_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/features/bastions_page/logic/defenders_cubit.dart test/features/bastions_page/logic/defenders_cubit_test.dart
git commit -m "feat: add DefendersCubit.removeDefender"
```

---

### Task 2: Extract shared `DefenderTypeIcon` widget

**Files:**
- Create: `lib/features/bastions_page/presentation/widgets/defender_type_icon.dart`
- Modify: `lib/features/bastions_page/presentation/defenders_page.dart` (use the new widget in `_buildCompactDefenderCard`, delete `_buildTypeIcon`)
- Test: `test/features/bastions_page/presentation/widgets/defender_type_icon_test.dart` (create)

**Interfaces:**
- Consumes: `DefenderType` (`lib/data/enums/defender_type.dart`), `MedievalColors`.
- Produces: `DefenderTypeIcon({super.key, required DefenderType type})` — 40x40 circular parchment icon. Used by the page (Task 2) and the detail sheet (Task 3).

- [ ] **Step 1: Write the failing test**

Create `test/features/bastions_page/presentation/widgets/defender_type_icon_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maura_bastion_system/data/enums/defender_type.dart';
import 'package:maura_bastion_system/features/bastions_page/presentation/widgets/defender_type_icon.dart';

void main() {
  testWidgets('renders the icon matching each defender type', (tester) async {
    final cases = {
      DefenderType.knight: Icons.shield,
      DefenderType.bastionDefender: Icons.castle,
      DefenderType.beast: Icons.pets,
    };
    for (final entry in cases.entries) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: DefenderTypeIcon(type: entry.key)),
        ),
      );
      expect(find.byIcon(entry.value), findsOneWidget);
    }
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/bastions_page/presentation/widgets/defender_type_icon_test.dart`
Expected: FAIL — `defender_type_icon.dart` doesn't exist.

- [ ] **Step 3: Write minimal implementation**

Create `lib/features/bastions_page/presentation/widgets/defender_type_icon.dart` (visuals copied verbatim from `_DefendersViewState._buildTypeIcon`, `defenders_page.dart:391-412`):

```dart
import 'package:flutter/material.dart';
import 'package:maura_bastion_system/core/themes/theme_colors.dart';
import 'package:maura_bastion_system/data/enums/defender_type.dart';

class DefenderTypeIcon extends StatelessWidget {
  final DefenderType type;

  const DefenderTypeIcon({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    IconData iconData;
    switch (type) {
      case DefenderType.knight:
        iconData = Icons.shield;
      case DefenderType.bastionDefender:
        iconData = Icons.castle;
      case DefenderType.beast:
        iconData = Icons.pets;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: MedievalColors.goldPale.withAlpha(100)),
        color: MedievalColors.parchmentDark,
      ),
      child: Icon(iconData, size: 20, color: MedievalColors.sepiaMuted),
    );
  }
}
```

Then in `defenders_page.dart`:
- Add import: `import 'package:maura_bastion_system/features/bastions_page/presentation/widgets/defender_type_icon.dart';`
- In `_buildCompactDefenderCard` (line 369), replace `_buildTypeIcon(defender.type),` with `DefenderTypeIcon(type: defender.type),`
- Delete the now-unused `_buildTypeIcon` method (lines 391-412).

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/bastions_page/presentation/widgets/defender_type_icon_test.dart`
Expected: PASS.

- [ ] **Step 5: Verify no regression**

Run: `flutter analyze lib/features/bastions_page/presentation/defenders_page.dart && flutter test test/features/bastions_page/`
Expected: No issues; all tests PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/features/bastions_page/presentation/widgets/defender_type_icon.dart lib/features/bastions_page/presentation/defenders_page.dart test/features/bastions_page/presentation/widgets/defender_type_icon_test.dart
git commit -m "refactor: extract DefenderTypeIcon widget"
```

---

### Task 3: `DefenderDetailSheet` with confirmation dialog (cancel path)

**Files:**
- Create: `lib/features/bastions_page/presentation/widgets/defender_detail_sheet.dart`
- Test: `test/features/bastions_page/presentation/defenders_page_test.dart` (create — this task adds display + cancel tests; Task 4 adds the remove-flow tests)

**Interfaces:**
- Consumes: `Defender` model, `DefenderTypeIcon` (Task 2), `ParchmentBorderPainter` (`lib/features/news_paper/presentation/widgets/parchment_border.dart`), `MedievalColors`, `DefendersCubit` (provided above the sheet via `BlocProvider`; only needed on the remove path).
- Produces: `DefenderDetailSheet({super.key, required Defender defender})` — modal bottom sheet content. `Future<void> _confirmRemove(BuildContext context)` — shows the confirm dialog; only proceeds on `true`. Task 4 relies on the exact copy: button `'Remove from Bastion'`, dialog title `'Remove {name}? '`, dialog body `'This cannot be undone.'`, dialog actions `'Cancel'` / `'Remove'`.

- [ ] **Step 1: Write the failing tests**

Create `test/features/bastions_page/presentation/defenders_page_test.dart`:

```dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:maura_bastion_system/api/api_client.dart';
import 'package:maura_bastion_system/api/defender_api.dart';
import 'package:maura_bastion_system/data/models/npcs/defender.dart';
import 'package:maura_bastion_system/data/enums/defender_type.dart';
import 'package:maura_bastion_system/features/bastions_page/logic/defenders_cubit.dart';
import 'package:maura_bastion_system/features/bastions_page/presentation/widgets/defender_detail_sheet.dart';

Defender testDefender() => const Defender(
      id: 'd1',
      name: 'Sir Cadogan',
      type: DefenderType.knight,
      description: 'A brave but reckless knight.',
      bastionId: 'bastion-1',
      acquisitionStory: 'Won at a card game.',
    );

Future<void> pumpSheet(WidgetTester tester) async {
  await tester.pumpWidget(
    BlocProvider<DefendersCubit>(
      create: (_) => DefendersCubit(
        bastionId: 'bastion-1',
        defenderApi: GetIt.I<DefenderApi>(),
      ),
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (sheetContext) => Center(
              child: TextButton(
                onPressed: () => showModalBottomSheet(
                  context: sheetContext,
                  builder: (_) => DefenderDetailSheet(defender: testDefender()),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    GetIt.I.reset();
    final apiClient = ApiClient(
      baseUrl: 'http://example.test',
      client: MockClient((request) async {
        return http.Response(
          jsonEncode({'success': false, 'message': 'unexpected'}),
          404,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    GetIt.I.registerSingleton<DefenderApi>(DefenderApi(client: apiClient));
  });

  testWidgets('detail sheet shows defender name, type, description and story',
      (tester) async {
    await pumpSheet(tester);

    expect(find.text('Sir Cadogan'), findsOneWidget);
    expect(find.text('Knight'), findsOneWidget);
    expect(find.text('A brave but reckless knight.'), findsOneWidget);
    expect(find.text('Won at a card game.'), findsOneWidget);
    expect(find.text('Remove from Bastion'), findsOneWidget);
  });

  testWidgets('cancelling the confirmation keeps the sheet open',
      (tester) async {
    await pumpSheet(tester);

    await tester.tap(find.text('Remove from Bastion'));
    await tester.pumpAndSettle();

    expect(find.text('Remove Sir Cadogan?'), findsOneWidget);
    expect(find.text('This cannot be undone.'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    // Dialog is gone, sheet is still open with the defender info.
    expect(find.text('Remove Sir Cadogan?'), findsNothing);
    expect(find.text('Sir Cadogan'), findsOneWidget);
    expect(find.text('Remove from Bastion'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/bastions_page/presentation/defenders_page_test.dart`
Expected: FAIL — `defender_detail_sheet.dart` doesn't exist.

- [ ] **Step 3: Write minimal implementation**

Create `lib/features/bastions_page/presentation/widgets/defender_detail_sheet.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:maura_bastion_system/core/themes/theme_colors.dart';
import 'package:maura_bastion_system/data/models/npcs/defender.dart';
import 'package:maura_bastion_system/features/bastions_page/logic/defenders_cubit.dart';
import 'package:maura_bastion_system/features/bastions_page/presentation/widgets/defender_type_icon.dart';
import 'package:maura_bastion_system/features/news_paper/presentation/widgets/parchment_border.dart';

class DefenderDetailSheet extends StatelessWidget {
  final Defender defender;

  const DefenderDetailSheet({super.key, required this.defender});

  Future<void> _confirmRemove(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final cubit = context.read<DefendersCubit>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: MedievalColors.parchmentLight,
        title: Text(
          'Remove ${defender.name ?? 'Unnamed Defender'}?',
          style: GoogleFonts.cinzel(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: MedievalColors.vermillion,
          ),
        ),
        content: Text(
          'This cannot be undone.',
          style: GoogleFonts.imFellEnglish(color: MedievalColors.sepiaInk),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await cubit.removeDefender(defender.id);
      navigator.pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('Defender removed')),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Failed to remove defender')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 0.9,
          colors: [
            MedievalColors.parchmentLight,
            MedievalColors.parchmentDark,
          ],
          stops: [0.6, 1.0],
        ),
      ),
      child: CustomPaint(
        painter: ParchmentBorderPainter(),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  DefenderTypeIcon(type: defender.type),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      defender.name ?? 'Unnamed Defender',
                      style: GoogleFonts.cinzel(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: MedievalColors.vermillion,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                defender.type.title,
                style: GoogleFonts.cinzel(
                  fontSize: 13,
                  color: MedievalColors.sepiaMuted,
                ),
              ),
              if (defender.description != null &&
                  defender.description!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  defender.description!,
                  style: GoogleFonts.imFellEnglish(
                    fontSize: 15,
                    color: MedievalColors.sepiaInk,
                  ),
                ),
              ],
              if (defender.acquisitionStory != null &&
                  defender.acquisitionStory!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'How they came to serve',
                  style: GoogleFonts.cinzel(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: MedievalColors.vermillion,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  defender.acquisitionStory!,
                  style: GoogleFonts.imFellEnglish(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: MedievalColors.sepiaInk,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MedievalColors.vermillion,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => _confirmRemove(context),
                  child: const Text('Remove from Bastion'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/bastions_page/presentation/defenders_page_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/features/bastions_page/presentation/widgets/defender_detail_sheet.dart test/features/bastions_page/presentation/defenders_page_test.dart
git commit -m "feat: add defender detail sheet with remove confirmation"
```

---

### Task 4: Wire card tap to the sheet (end-to-end remove flow)

**Files:**
- Modify: `lib/features/bastions_page/presentation/defenders_page.dart` (`_buildCompactDefenderCard`, around line 341)
- Modify: `test/features/bastions_page/presentation/defenders_page_test.dart` (add success + failure tests)

**Interfaces:**
- Consumes: `DefenderDetailSheet` (Task 3), `DefendersCubit.removeDefender` (Task 1), `DefenderApi` from `GetIt` (registered by `DefendersPage.build` consumers).

- [ ] **Step 1: Write the failing tests**

Add to the existing `main()` in `test/features/bastions_page/presentation/defenders_page_test.dart` (alongside the Task 3 tests). Add these helpers/imports at the top: `import 'package:maura_bastion_system/features/bastions_page/presentation/defenders_page.dart';`

Replace the `setUp` from Task 3 with a mock-driven one so the page can load a real defender and DELETE requests can be observed:

```dart
  http.Request? deleteRequest;
  var deleteSucceeds = true;

  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    GetIt.I.reset();
    deleteRequest = null;
    deleteSucceeds = true;
    final apiClient = ApiClient(
      baseUrl: 'http://example.test',
      client: MockClient((request) async {
        if (request.method == 'GET' &&
            request.url.path == '/maura/v1/defenders') {
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'ok',
              'data': [
                {
                  'id': 'd1',
                  'name': 'Sir Cadogan',
                  'type': 'knight',
                  'description': 'A brave but reckless knight.',
                  'bastionId': 'bastion-1',
                  'acquisitionStory': 'Won at a card game.',
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.method == 'DELETE' &&
            request.url.path == '/maura/v1/defenders/d1') {
          deleteRequest = request;
          if (!deleteSucceeds) {
            return http.Response(
              jsonEncode({'success': false, 'message': 'boom'}),
              500,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response(
            jsonEncode({'success': true, 'message': 'ok', 'data': null}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response(
          jsonEncode({'success': false, 'message': 'unexpected'}),
          404,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    GetIt.I.registerSingleton<DefenderApi>(DefenderApi(client: apiClient));
  });

  Future<void> pumpDefendersPage(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: DefendersPage(bastionId: 'bastion-1', bastionName: 'Test Bastion'),
      ),
    );
    await tester.pumpAndSettle();
  }
```

The two new tests (inside `main()`):

```dart
  testWidgets(
      'confirming remove DELETEs the defender, closes the sheet and shows a snackbar',
      (tester) async {
    await pumpDefendersPage(tester);
    expect(find.text('Sir Cadogan'), findsOneWidget);

    await tester.tap(find.text('Sir Cadogan'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Remove from Bastion'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();

    expect(deleteRequest, isNotNull);
    expect(deleteRequest!.method, 'DELETE');
    expect(deleteRequest!.url.path, '/maura/v1/defenders/d1');
    expect(find.text('Sir Cadogan'), findsNothing);
    expect(find.text('Defender removed'), findsOneWidget);
  });

  testWidgets(
      'failed removal shows an error snackbar and keeps the defender',
      (tester) async {
    deleteSucceeds = false;

    await pumpDefendersPage(tester);

    await tester.tap(find.text('Sir Cadogan'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Remove from Bastion'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();

    expect(find.text('Failed to remove defender'), findsOneWidget);
    // The name appears on both the card and the still-open sheet.
    expect(find.text('Sir Cadogan'), findsWidgets);
    expect(find.text('Remove from Bastion'), findsOneWidget);
  });
```

Note: the Task 3 tests keep working — their `setUp` now uses this mock, whose GET handler returns the defender JSON; `pumpSheet` builds its own `DefendersCubit` and never hits the mock, so behavior is unchanged.

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/bastions_page/presentation/defenders_page_test.dart`
Expected: FAIL — the two new tests time out/fail on `await tester.tap(find.text('Sir Cadogan'))` because the card has no tap handler yet (the sheet never opens). Task 3 tests still PASS.

- [ ] **Step 3: Write minimal implementation**

In `lib/features/bastions_page/presentation/defenders_page.dart`, replace `_buildCompactDefenderCard` (line 341) with:

```dart
  Widget _buildCompactDefenderCard(Defender defender) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          builder: (_) => DefenderDetailSheet(defender: defender),
        );
      },
      child: Container(
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
          borderRadius: BorderRadius.circular(14),
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
            padding: const EdgeInsets.all(10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                DefenderTypeIcon(type: defender.type),
                const SizedBox(width: 10),
                Text(
                  defender.name ?? 'Unnamed Defender',
                  style: GoogleFonts.cinzel(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: defender.name != null
                        ? MedievalColors.vermillion
                        : MedievalColors.sepiaMuted,
                    fontStyle: defender.name == null
                        ? FontStyle.italic
                        : FontStyle.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
```

Add import: `import 'package:maura_bastion_system/features/bastions_page/presentation/widgets/defender_detail_sheet.dart';`

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/features/bastions_page/presentation/defenders_page_test.dart`
Expected: PASS (4 tests).

- [ ] **Step 5: Full verification**

Run: `flutter analyze && flutter test`
Expected: No analyze issues; entire suite PASSes.

- [ ] **Step 6: Commit**

```bash
git add lib/features/bastions_page/presentation/defenders_page.dart test/features/bastions_page/presentation/defenders_page_test.dart
git commit -m "feat: wire defender card tap to detail sheet and removal"
```
