# URL Validation Utility Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Validate user-entered image URLs (format + reachability, blocking save) and harden all image display sites behind a shared `SafeNetworkImage` widget.

**Architecture:** A pure-Dart `UrlValidator` in `lib/core/utils/` does sync format checks and async reachability checks (HEAD with GET fallback, 5s timeout) over `package:http`. A `SafeNetworkImage` widget shows the placeholder for invalid URLs and on load failure. Forms wire the validator into submit flow; eight `Image.network` call sites swap to `SafeNetworkImage`.

**Tech Stack:** Dart SDK ^3.11.0, Flutter, `package:http` ^1.6.0 (already in pubspec), `flutter_test` + `package:http/testing.dart` MockClient.

**Spec:** `docs/superpowers/specs/2026-09-09-url-validation-design.md`

## Global Constraints

- No new pubspec dependencies (`http` ^1.6.0 already present).
- Match existing code style: wildcard parameters in builders (`errorBuilder: (_, _, _) => ...`), `MedievalColors` for theming, no comments in new code.
- Error messages exactly: `'Please enter a valid URL (https://...)'` and `'Image URL is unreachable'`.
- Reachability: HTTP HEAD first, GET fallback on 405, 5s timeout (injectable for tests), 2xx/3xx = reachable, any exception = unreachable.
- Empty URL stays optional in both forms (empty passes validation).
- Spec deviation (deliberate): Flutter `FormFieldValidator` is synchronous, so the reachability check runs in the submit handler instead of an async validator. Behavior is identical: save is blocked with a visible error.

---

### Task 1: `UrlValidator`

**Files:**
- Create: `lib/core/utils/url_validator.dart`
- Test: `test/core/utils/url_validator_test.dart`

**Interfaces:**
- Consumes: `package:http` `Client`.
- Produces: `enum UrlCheckResult { valid, invalidFormat, unreachable }`; `static bool UrlValidator.isValidFormat(String? url)`; `static Future<UrlCheckResult> UrlValidator.check(String? url, {http.Client? client, Duration timeout})` (timeout defaults to 5s). Later tasks use both.

- [ ] **Step 1: Write the failing test**

```dart
// test/core/utils/url_validator_test.dart
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:maura_bastion_system/core/utils/url_validator.dart';

void main() {
  group('isValidFormat', () {
    test('accepts https URL', () {
      expect(UrlValidator.isValidFormat('https://example.com/img.png'), isTrue);
    });

    test('accepts http URL', () {
      expect(UrlValidator.isValidFormat('http://example.com/img.png'), isTrue);
    });

    test('rejects null', () {
      expect(UrlValidator.isValidFormat(null), isFalse);
    });

    test('rejects empty string', () {
      expect(UrlValidator.isValidFormat(''), isFalse);
    });

    test('rejects whitespace only', () {
      expect(UrlValidator.isValidFormat('   '), isFalse);
    });

    test('rejects missing scheme', () {
      expect(UrlValidator.isValidFormat('example.com/img.png'), isFalse);
    });

    test('rejects non-http scheme', () {
      expect(UrlValidator.isValidFormat('ftp://example.com/img.png'), isFalse);
    });

    test('rejects scheme with no host', () {
      expect(UrlValidator.isValidFormat('http://'), isFalse);
    });
  });

  group('check', () {
    test('returns invalidFormat for null without touching network', () async {
      var called = false;
      final client = MockClient((request) async {
        called = true;
        return http.Response('', 200);
      });
      final result = await UrlValidator.check(null, client: client);
      expect(result, UrlCheckResult.invalidFormat);
      expect(called, isFalse);
    });

    test('returns invalidFormat for malformed URL without touching network',
        () async {
      var called = false;
      final client = MockClient((request) async {
        called = true;
        return http.Response('', 200);
      });
      final result = await UrlValidator.check('not a url', client: client);
      expect(result, UrlCheckResult.invalidFormat);
      expect(called, isFalse);
    });

    test('returns valid on 200 HEAD', () async {
      final client = MockClient((request) async => http.Response('', 200));
      final result = await UrlValidator.check(
        'https://example.com/img.png',
        client: client,
      );
      expect(result, UrlCheckResult.valid);
    });

    test('returns valid on 301 redirect status', () async {
      final client = MockClient((request) async => http.Response('', 301));
      final result = await UrlValidator.check(
        'https://example.com/img.png',
        client: client,
      );
      expect(result, UrlCheckResult.valid);
    });

    test('returns unreachable on 404', () async {
      final client = MockClient((request) async => http.Response('', 404));
      final result = await UrlValidator.check(
        'https://example.com/missing.png',
        client: client,
      );
      expect(result, UrlCheckResult.unreachable);
    });

    test('falls back to GET when HEAD returns 405', () async {
      final methods = <String>[];
      final client = MockClient((request) async {
        methods.add(request.method);
        if (request.method == 'HEAD') return http.Response('', 405);
        return http.Response('', 200);
      });
      final result = await UrlValidator.check(
        'https://example.com/img.png',
        client: client,
      );
      expect(result, UrlCheckResult.valid);
      expect(methods, ['HEAD', 'GET']);
    });

    test('returns unreachable when client throws', () async {
      final client = MockClient((request) async => throw Exception('boom'));
      final result = await UrlValidator.check(
        'https://example.com/img.png',
        client: client,
      );
      expect(result, UrlCheckResult.unreachable);
    });

    test('returns unreachable on timeout', () async {
      final client = MockClient(
        (request) => Completer<http.Response>().future,
      );
      final result = await UrlValidator.check(
        'https://example.com/img.png',
        client: client,
        timeout: const Duration(milliseconds: 50),
      );
      expect(result, UrlCheckResult.unreachable);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/utils/url_validator_test.dart`
Expected: FAIL — `url_validator.dart` does not exist yet (import error).

- [ ] **Step 3: Write the implementation**

```dart
// lib/core/utils/url_validator.dart
import 'package:http/http.dart' as http;

enum UrlCheckResult { valid, invalidFormat, unreachable }

class UrlValidator {
  static bool isValidFormat(String? url) {
    if (url == null || url.trim().isEmpty) return false;
    final uri = Uri.tryParse(url.trim());
    if (uri == null) return false;
    if (uri.scheme != 'http' && uri.scheme != 'https') return false;
    if (uri.host.isEmpty) return false;
    return true;
  }

  static Future<UrlCheckResult> check(
    String? url, {
    http.Client? client,
    Duration timeout = const Duration(seconds: 5),
  }) async {
    if (!isValidFormat(url)) return UrlCheckResult.invalidFormat;

    final uri = Uri.parse(url!.trim());
    final effectiveClient = client ?? http.Client();
    try {
      var response = await effectiveClient.head(uri).timeout(timeout);
      if (response.statusCode == 405) {
        response = await effectiveClient.get(uri).timeout(timeout);
      }
      if (response.statusCode >= 200 && response.statusCode < 400) {
        return UrlCheckResult.valid;
      }
      return UrlCheckResult.unreachable;
    } catch (_) {
      return UrlCheckResult.unreachable;
    } finally {
      if (client == null) effectiveClient.close();
    }
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/utils/url_validator_test.dart`
Expected: PASS (all tests).

- [ ] **Step 5: Commit**

```bash
git add lib/core/utils/url_validator.dart test/core/utils/url_validator_test.dart
git commit -m "feat: add UrlValidator with format and reachability checks"
```

---

### Task 2: `SafeNetworkImage`

**Files:**
- Create: `lib/core/utils/safe_network_image.dart`
- Test: `test/core/utils/safe_network_image_test.dart`

**Interfaces:**
- Consumes: `UrlValidator.isValidFormat` from Task 1.
- Produces: `SafeNetworkImage({Key? key, required String? url, required Widget placeholder, double? height, double? width, BoxFit fit})` with `fit` defaulting to `BoxFit.cover`. Tasks 4 and 5 use this constructor.

- [ ] **Step 1: Write the failing test**

```dart
// test/core/utils/safe_network_image_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maura_bastion_system/core/utils/safe_network_image.dart';

void main() {
  const placeholderKey = Key('placeholder');

  Widget buildWidget(String? url) {
    return MaterialApp(
      home: Scaffold(
        body: SafeNetworkImage(
          url: url,
          placeholder: Container(key: placeholderKey),
          height: 100,
          width: 100,
        ),
      ),
    );
  }

  testWidgets('shows placeholder for null url', (tester) async {
    await tester.pumpWidget(buildWidget(null));
    expect(find.byKey(placeholderKey), findsOneWidget);
  });

  testWidgets('shows placeholder for empty url', (tester) async {
    await tester.pumpWidget(buildWidget(''));
    expect(find.byKey(placeholderKey), findsOneWidget);
  });

  testWidgets('shows placeholder for malformed url', (tester) async {
    await tester.pumpWidget(buildWidget('not-a-url'));
    expect(find.byKey(placeholderKey), findsOneWidget);
  });

  testWidgets('shows placeholder when image fails to load', (tester) async {
    await tester.pumpWidget(buildWidget('https://127.0.0.1:1/broken.png'));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.byKey(placeholderKey), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/utils/safe_network_image_test.dart`
Expected: FAIL — `safe_network_image.dart` does not exist yet (import error).

- [ ] **Step 3: Write the implementation**

```dart
// lib/core/utils/safe_network_image.dart
import 'package:flutter/material.dart';

import 'package:maura_bastion_system/core/utils/url_validator.dart';

class SafeNetworkImage extends StatelessWidget {
  final String? url;
  final Widget placeholder;
  final double? height;
  final double? width;
  final BoxFit fit;

  const SafeNetworkImage({
    super.key,
    required this.url,
    required this.placeholder,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    if (!UrlValidator.isValidFormat(url)) return placeholder;
    return Image.network(
      url!,
      height: height,
      width: width,
      fit: fit,
      errorBuilder: (_, _, _) => placeholder,
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/utils/safe_network_image_test.dart`
Expected: PASS (all tests). If the load-failure test times out on `pumpAndSettle`, wrap the test body in `tester.runAsync` — the test framework's `HttpOverrides` returns status 400 immediately, so no real network is touched:

```dart
  testWidgets('shows placeholder when image fails to load', (tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(buildWidget('https://127.0.0.1:1/broken.png'));
      await tester.pumpAndSettle(const Duration(seconds: 1));
    });
    expect(find.byKey(placeholderKey), findsOneWidget);
  });
```

- [ ] **Step 5: Commit**

```bash
git add lib/core/utils/safe_network_image.dart test/core/utils/safe_network_image_test.dart
git commit -m "feat: add SafeNetworkImage widget with placeholder fallback"
```

---

### Task 3: Wire URL validation into both forms

**Files:**
- Modify: `lib/features/bastions_page/presentation/bastion_creation_page.dart`
- Modify: `lib/features/bastions_page/presentation/hirelings_page.dart`

**Interfaces:**
- Consumes: `UrlValidator.check`, `UrlValidator.isValidFormat`, `UrlCheckResult.unreachable` from Task 1.
- Produces: nothing consumed downstream.

- [ ] **Step 1: Add validation to `bastion_creation_page.dart`**

Add the import after the existing `core/themes` import:

```dart
import 'package:maura_bastion_system/core/utils/url_validator.dart';
```

Replace the image URL field call (currently lines 116-120, no validator):

```dart
              _buildTextField(
                controller: _imageUrlController,
                label: 'Image URL (optional)',
                hint: 'https://...',
              ),
```

with:

```dart
              _buildTextField(
                controller: _imageUrlController,
                label: 'Image URL (optional)',
                hint: 'https://...',
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  return UrlValidator.isValidFormat(v.trim())
                      ? null
                      : 'Please enter a valid URL (https://...)';
                },
              ),
```

In `_createBastion`, insert the reachability check after the controller reads (line 55 `final imgUrl = ...`) and before `final cubit = BastionCubit(...)`:

```dart
    if (imgUrl.isNotEmpty) {
      final result = await UrlValidator.check(imgUrl);
      if (result == UrlCheckResult.unreachable) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image URL is unreachable')),
        );
        return;
      }
    }
```

- [ ] **Step 2: Add validation to `hirelings_page.dart`**

Add the import:

```dart
import 'package:maura_bastion_system/core/utils/url_validator.dart';
```

Replace the Image URL `TextFormField` (currently lines 230-237):

```dart
              TextFormField(
                initialValue: _imgUrl,
                decoration: const InputDecoration(
                  labelText: 'Image URL',
                  prefixIcon: Icon(Icons.image),
                ),
                onSaved: (value) => _imgUrl = value?.trim() ?? '',
              ),
```

with:

```dart
              TextFormField(
                initialValue: _imgUrl,
                decoration: const InputDecoration(
                  labelText: 'Image URL',
                  prefixIcon: Icon(Icons.image),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  return UrlValidator.isValidFormat(v.trim())
                      ? null
                      : 'Please enter a valid URL (https://...)';
                },
                onSaved: (value) => _imgUrl = value?.trim() ?? '',
              ),
```

Make the Recruit button handler async and check reachability between `save()` and the cubit call. Replace (currently lines 250-274):

```dart
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    _formKey.currentState?.save();
                    context.read<HirelingsCubit>().addHireling(
```

with:

```dart
                onPressed: () async {
                  if (_formKey.currentState?.validate() ?? false) {
                    _formKey.currentState?.save();
                    if (_imgUrl.isNotEmpty) {
                      final result = await UrlValidator.check(_imgUrl);
                      if (result == UrlCheckResult.unreachable) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Image URL is unreachable'),
                          ),
                        );
                        return;
                      }
                    }
                    context.read<HirelingsCubit>().addHireling(
```

(The rest of the handler — `addHireling` args, reset, `setState`, `pop`, snackbar — stays unchanged; the new `return` keeps it from running on unreachable URLs.)

- [ ] **Step 3: Verify**

Run: `flutter analyze lib/features/bastions_page/presentation/bastion_creation_page.dart lib/features/bastions_page/presentation/hirelings_page.dart`
Expected: `No issues found!`

Run: `flutter test`
Expected: All existing tests PASS (forms have no dedicated tests; nothing existing breaks).

Manual smoke check (optional): run the app, open bastion creation, type `not-a-url` in Image URL, submit → inline format error; type `https://example.com/nonexistent-xyz` → "Image URL is unreachable" snackbar; empty URL saves normally.

- [ ] **Step 4: Commit**

```bash
git add lib/features/bastions_page/presentation/bastion_creation_page.dart lib/features/bastions_page/presentation/hirelings_page.dart
git commit -m "feat: validate image URLs in bastion creation and hireling forms"
```

---

### Task 4: `SafeNetworkImage` in bastions page display sites

**Files:**
- Modify: `lib/features/bastions_page/presentation/bastion_page.dart`
- Modify: `lib/features/bastions_page/presentation/facility_page.dart` (2 sites)
- Modify: `lib/features/bastions_page/presentation/facility_selection_page.dart`
- Modify: `lib/features/bastions_page/presentation/bastion_main_screen.dart`
- Modify: `lib/features/bastions_page/presentation/hirelings_page.dart`

**Interfaces:**
- Consumes: `SafeNetworkImage` from Task 2.
- Produces: nothing consumed downstream.

**Pattern for every swap:** add the import, replace the `Image.network(...)` call inside the existing `ClipRRect`/`ClipOval` with a `SafeNetworkImage`, passing the site's existing `errorBuilder` widget as `placeholder`. Outer null-guards and framing (Stack, nail dots, borders) stay unchanged. Remove `errorBuilder` — `SafeNetworkImage` owns it.

- [ ] **Step 1: Swap `bastion_page.dart` `_buildFramedImage` (line ~422)**

Add import:

```dart
import 'package:maura_bastion_system/core/utils/safe_network_image.dart';
```

Replace:

```dart
            ClipRRect(
              child: Image.network(
                facility.imgUrl!,
                height: 100,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _imagePlaceholder('No Engraving'),
              ),
            ),
```

with:

```dart
            ClipRRect(
              child: SafeNetworkImage(
                url: facility.imgUrl,
                placeholder: _imagePlaceholder('No Engraving'),
                height: 100,
                width: double.infinity,
              ),
            ),
```

- [ ] **Step 2: Swap `facility_page.dart` `_buildImage` (line ~290)**

Add import as in Step 1. Replace:

```dart
            ClipRRect(
              child: Image.network(
                facility.imgUrl!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _imagePlaceholder(),
              ),
            ),
```

with:

```dart
            ClipRRect(
              child: SafeNetworkImage(
                url: facility.imgUrl,
                placeholder: _imagePlaceholder(),
                height: 200,
                width: double.infinity,
              ),
            ),
```

- [ ] **Step 3: Swap `facility_page.dart` `_buildHirelingPortrait` (line ~599)**

Replace:

```dart
        child: ClipOval(
          child: Image.network(
            hireling.imgUrl!,
            width: portraitSize,
            height: portraitSize,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _hirelingPortraitPlaceholder(),
          ),
        ),
```

with:

```dart
        child: ClipOval(
          child: SafeNetworkImage(
            url: hireling.imgUrl,
            placeholder: _hirelingPortraitPlaceholder(),
            width: portraitSize,
            height: portraitSize,
          ),
        ),
```

- [ ] **Step 4: Swap `facility_selection_page.dart` `_buildFramedImage` (line ~409)**

Add import as in Step 1. Replace:

```dart
            ClipRRect(
              child: Image.network(
                facility.imgUrl!,
                height: 100,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _imagePlaceholder('No Engraving'),
              ),
            ),
```

with:

```dart
            ClipRRect(
              child: SafeNetworkImage(
                url: facility.imgUrl,
                placeholder: _imagePlaceholder('No Engraving'),
                height: 100,
                width: double.infinity,
              ),
            ),
```

- [ ] **Step 5: Swap `bastion_main_screen.dart` `_buildFramedImage` (line ~476)**

Add import as in Step 1. Replace:

```dart
            ClipRRect(
              child: Image.network(
                widget.bastion.imgUrl!,
                height: 100,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    _imagePlaceholder('Engraving Unavailable'),
              ),
            ),
```

with:

```dart
            ClipRRect(
              child: SafeNetworkImage(
                url: widget.bastion.imgUrl,
                placeholder: _imagePlaceholder('Engraving Unavailable'),
                height: 100,
                width: double.infinity,
              ),
            ),
```

- [ ] **Step 6: Swap `hirelings_page.dart` `_buildPortrait` (line ~446)**

Add import as in Step 1 (file already imports `url_validator` from Task 3 — keep both). Replace:

```dart
        child: ClipOval(
          child: Image.network(
            hireling.imgUrl!,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _portraitPlaceholder(size),
          ),
        ),
```

with:

```dart
        child: ClipOval(
          child: SafeNetworkImage(
            url: hireling.imgUrl,
            placeholder: _portraitPlaceholder(size),
            width: size,
            height: size,
          ),
        ),
```

- [ ] **Step 7: Verify**

Run: `grep -rn "Image.network" lib/features/bastions_page/`
Expected: no matches.

Run: `flutter analyze`
Expected: `No issues found!`

Run: `flutter test`
Expected: all tests PASS.

- [ ] **Step 8: Commit**

```bash
git add lib/features/bastions_page/presentation/bastion_page.dart lib/features/bastions_page/presentation/facility_page.dart lib/features/bastions_page/presentation/facility_selection_page.dart lib/features/bastions_page/presentation/bastion_main_screen.dart lib/features/bastions_page/presentation/hirelings_page.dart
git commit -m "refactor: route bastions page images through SafeNetworkImage"
```

---

### Task 5: `SafeNetworkImage` in newspaper articles + final verification

**Files:**
- Modify: `lib/features/news_paper/presentation/articles/news_article.dart`
- Modify: `lib/features/news_paper/presentation/articles/main_news_article.dart`

**Interfaces:**
- Consumes: `SafeNetworkImage` from Task 2.
- Produces: nothing consumed downstream.

- [ ] **Step 1: Swap `news_article.dart` `_buildFramedImage` (line ~119)**

Add import:

```dart
import 'package:maura_bastion_system/core/utils/safe_network_image.dart';
```

Replace:

```dart
          Image.network(
            imageUrl,
            height: 120,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _buildImagePlaceholder(),
          ),
```

with:

```dart
          SafeNetworkImage(
            url: imageUrl,
            placeholder: _buildImagePlaceholder(),
            height: 120,
            width: double.infinity,
          ),
```

- [ ] **Step 2: Swap `main_news_article.dart` `_buildFramedImage` (line ~84)**

Add import as in Step 1. Replace:

```dart
          Image.network(
            imageUrl,
            height: 280,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _buildImagePlaceholder(),
          ),
```

with:

```dart
          SafeNetworkImage(
            url: imageUrl,
            placeholder: _buildImagePlaceholder(),
            height: 280,
            width: double.infinity,
          ),
```

- [ ] **Step 3: Verify no raw `Image.network` remains anywhere**

Run: `grep -rn "Image.network" lib/`
Expected: no matches.

- [ ] **Step 4: Final full verification**

Run: `flutter analyze`
Expected: `No issues found!`

Run: `flutter test`
Expected: all tests PASS (existing suite plus the 12 new tests from Tasks 1-2).

- [ ] **Step 5: Commit**

```bash
git add lib/features/news_paper/presentation/articles/news_article.dart lib/features/news_paper/presentation/articles/main_news_article.dart
git commit -m "refactor: route newspaper article images through SafeNetworkImage"
```
