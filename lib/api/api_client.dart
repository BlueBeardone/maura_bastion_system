import 'dart:convert';
import 'dart:io';

import 'api_exception.dart';
import 'api_response.dart';

class ApiClient {
  final String baseUrl;
  String? _authToken;

  ApiClient({this.baseUrl = 'http://localhost:8080'});

  void setAuthToken(String? token) {
    _authToken = token;
  }

  String? get authToken => _authToken;

  Map<String, String> get _headers {
    final headers = <String, String>{
      HttpHeaders.contentTypeHeader: 'application/json',
      HttpHeaders.acceptHeader: 'application/json',
    };
    if (_authToken != null) {
      headers[HttpHeaders.authorizationHeader] = 'Bearer $_authToken';
    }
    return headers;
  }

  Future<T> get<T>(
    String path, {
    required T Function(dynamic json) parser,
  }) async {
    return _request<T>('GET', path, null, parser);
  }

  Future<T> post<T>(
    String path,
    Map<String, dynamic> body, {
    required T Function(dynamic json) parser,
  }) async {
    return _request<T>('POST', path, body, parser);
  }

  Future<T> put<T>(
    String path,
    Map<String, dynamic> body, {
    required T Function(dynamic json) parser,
  }) async {
    return _request<T>('PUT', path, body, parser);
  }

  Future<T> delete<T>(
    String path, {
    required T Function(dynamic json) parser,
  }) async {
    return _request<T>('DELETE', path, null, parser);
  }

  Future<T> _request<T>(
    String method,
    String path,
    Map<String, dynamic>? body,
    T Function(dynamic json) parser,
  ) async {
    final client = HttpClient();
    try {
      final uri = Uri.parse('$baseUrl$path');
      final request = await client.openUrl(method, uri);

      _headers.forEach((key, value) {
        request.headers.set(key, value);
      });

      if (body != null) {
        request.write(jsonEncode(body));
      }

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      final json = jsonDecode(responseBody) as Map<String, dynamic>;

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(
          statusCode: response.statusCode,
          message: json['message'] as String? ?? 'HTTP ${response.statusCode}',
        );
      }

      final apiResponse = ApiResponse.fromJson(json, dataParser: parser);

      if (!apiResponse.success) {
        throw ApiException(
          statusCode: response.statusCode,
          message: apiResponse.message ?? 'Unknown error',
        );
      }

      return apiResponse.data as T;
    } on SocketException catch (e) {
      throw ApiException(
        statusCode: 0,
        message: 'Connection failed: ${e.message}',
      );
    } on FormatException catch (e) {
      throw ApiException(
        statusCode: 0,
        message: 'Invalid response format: ${e.message}',
      );
    } finally {
      client.close();
    }
  }
}