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
