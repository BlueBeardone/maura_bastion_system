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
