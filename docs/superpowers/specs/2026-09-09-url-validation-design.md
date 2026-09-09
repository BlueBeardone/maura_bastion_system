# URL Validation Utility — Design

**Date:** 2026-09-09
**Status:** Approved
**Scope:** `lib/core/utils/`, two forms, eight image display sites

## Problem

Image URLs are user-entered (bastion creation, hireling forms) but never validated — malformed or dead URLs are saved to the backend. At display time, eight call sites pass those strings straight to `Image.network(...)`; some only guard `imgUrl != null` (not empty), and malformed input can throw before `errorBuilder` runs. There is no single place that decides whether a URL string is safe to use.

## Goal

A reusable URL utility that (1) validates format synchronously and (2) verifies reachability with a real network check, blocking form submission when a URL is unreachable — plus a `SafeNetworkImage` widget so display sites share one hardened code path.

## Non-Goals

- No check that the URL actually serves an image (content-type inspection) — format + reachability only.
- No changes to `api_client.dart` baseUrl handling (internal config, not user-supplied).
- No changes to fake/test data URLs.
- No reactivity: a URL validated at save time is not re-checked later; dead-at-load-time links fall back to the placeholder via `errorBuilder`.

## Design

### 1. `UrlValidator` — `lib/core/utils/url_validator.dart`

Pure Dart logic on top of `package:http` (already a dependency). No Flutter imports.

```dart
enum UrlCheckResult { valid, invalidFormat, unreachable }

class UrlValidator {
  /// Sync. True if: Uri.tryParse succeeds, scheme is http/https,
  /// and host is non-empty. Null/empty → false.
  static bool isValidFormat(String? url);

  /// Async. Format check first; if valid, HTTP HEAD with a GET fallback
  /// (some servers reject HEAD with 405), 5s timeout, follows redirects.
  /// Any 2xx/3xx status counts as reachable.
  /// Null/empty → UrlCheckResult.invalidFormat (callers decide if empty is OK).
  static Future<UrlCheckResult> check(String? url, {http.Client? client});
}
```

- Injects `http.Client` (defaults to `http.Client()`); a `MockClient` can be passed in tests.
- Exceptions from the HTTP layer (timeout, `SocketException`, etc.) are caught and mapped to `UrlCheckResult.unreachable`.

### 2. `SafeNetworkImage` — `lib/core/utils/safe_network_image.dart`

```dart
SafeNetworkImage(
  String? url,
  Widget placeholder,   // shown for null/empty/invalid-format/load error
  double? height,
  double? width,
  BoxFit fit,
)
```

Behavior:

- `!UrlValidator.isValidFormat(url)` → placeholder immediately, no network call, no synchronous throw.
- Otherwise `Image.network` with an `errorBuilder` that shows the placeholder (covers dead-at-load-time links).

### 3. Form integration

`bastion_creation_page.dart` and `hirelings_page.dart` use an async `FormFieldValidator` that calls `UrlValidator.check()`:

- `valid` → passes.
- `invalidFormat` → error "Please enter a valid URL (https://...)".
- `unreachable` → error "URL is unreachable".

Empty stays optional where it is today (existing empty-check returns null before invoking the URL validator). Async validators run on submit, so no debounce is needed.

### 4. Display integration

Eight `Image.network(...)` sites swap the image call for `SafeNetworkImage(...)`, keeping each page's existing placeholder and framing (the framed `Stack`/nail-dot decorations stay in the pages):

- `features/bastions_page/presentation/bastion_page.dart` (`_buildFramedImage`)
- `features/bastions_page/presentation/facility_page.dart` (2 sites)
- `features/bastions_page/presentation/facility_selection_page.dart`
- `features/bastions_page/presentation/bastion_main_screen.dart`
- `features/bastions_page/presentation/hirelings_page.dart`
- `features/news_paper/presentation/articles/news_article.dart`
- `features/news_paper/presentation/articles/main_news_article.dart`

## Error Handling Summary

| Stage | Failure | Behavior |
|---|---|---|
| Form save | Invalid format | Validation error, save blocked |
| Form save | Unreachable (404/timeout/no host) | Validation error, save blocked |
| Display | Invalid format / empty / null | Placeholder, no `Image.network` call |
| Display | Load failure (dead link) | `errorBuilder` → placeholder |

## Testing

- **`UrlValidator` unit tests** (`test/core/utils/url_validator_test.dart`):
  - `isValidFormat`: valid http/https URLs, missing scheme, wrong scheme (ftp), empty, null, no-host strings.
  - `check` with `MockClient`: 200 → valid; 404 → unreachable; 405 on HEAD then 200 on GET → valid (fallback); client exception/timeout → unreachable; invalid format skips network entirely.
- **`SafeNetworkImage` widget tests** (`test/core/utils/safe_network_image_test.dart`):
  - Null/empty/invalid-format URL renders placeholder without network.
  - Load failure renders placeholder.
- `flutter analyze` clean.
