import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'api_exception.dart';
import 'api_response.dart';

final String _baseUrl = Platform.environment['URL'] ?? 'http://localhost:8080';

class ApiClient {
  final String baseUrl;
  final http.Client _client;
  String? _authToken;

  ApiClient({String? baseUrl, http.Client? client})
      : baseUrl = baseUrl ?? _baseUrl,
        _client = client ?? http.Client();

  void setAuthToken(String? token) {
    _authToken = token;
  }

  String? get authToken => _authToken;

  Map<String, String> get _headers {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
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
    final request = http.Request(method, Uri.parse('$baseUrl$path'));
    request.headers.addAll(_headers);

    if (body != null) {
      request.body = jsonEncode(body);
    }

    try {
      final streamed = await _client.send(request);
      final response = await http.Response.fromStream(streamed);
      final json =
          jsonDecode(response.body) as Map<String, dynamic>;

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
    } on http.ClientException catch (e) {
      throw ApiException(
        statusCode: 0,
        message: 'Connection failed: ${e.message}',
      );
    } on FormatException catch (e) {
      throw ApiException(
        statusCode: 0,
        message: 'Invalid response format: ${e.message}',
      );
    }
  }
}