import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';

/// Error returned by the backend or raised while reaching it.
///
/// `statusCode == 0` means the request never produced an HTTP response
/// (for example, the server was unreachable or the request timed out).
class ApiException implements Exception {
  const ApiException(this.statusCode, this.message, {this.details});

  final int statusCode;
  final String message;
  final Object? details;

  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => message;
}

/// Supplies the current Supabase access token, if one is stored.
typedef TokenProvider = Future<String?> Function();

/// Small JSON HTTP client for the Module 1 FastAPI backend.
///
/// It never invents response fields: callers receive the decoded response
/// envelope and read the `data` object themselves.
class ApiClient {
  ApiClient({
    String? baseUrl,
    http.Client? httpClient,
    TokenProvider? tokenProvider,
    this.timeout = const Duration(seconds: 20),
  }) : baseUrl = _normalizeBaseUrl(baseUrl ?? AppConfig.apiBaseUrl),
       _http = httpClient ?? http.Client(),
       _tokenProvider = tokenProvider;

  final String baseUrl;
  final Duration timeout;
  final http.Client _http;
  final TokenProvider? _tokenProvider;

  static String _normalizeBaseUrl(String value) {
    return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? query,
    bool authenticated = true,
  }) {
    return _send('GET', path, query: query, authenticated: authenticated);
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Object? body,
    bool authenticated = true,
  }) {
    return _send('POST', path, body: body, authenticated: authenticated);
  }

  Future<Map<String, dynamic>> put(
    String path, {
    Object? body,
    bool authenticated = true,
  }) {
    return _send('PUT', path, body: body, authenticated: authenticated);
  }

  Future<Map<String, dynamic>> delete(
    String path, {
    bool authenticated = true,
  }) {
    return _send('DELETE', path, authenticated: authenticated);
  }

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, String>? query,
    Object? body,
    bool authenticated = true,
  }) async {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    var uri = Uri.parse('$baseUrl$normalizedPath');

    if (query != null && query.isNotEmpty) {
      uri = uri.replace(queryParameters: query);
    }

    final headers = <String, String>{'Accept': 'application/json'};

    if (body != null) {
      headers['Content-Type'] = 'application/json';
    }

    if (authenticated) {
      final token = await _tokenProvider?.call();
      if (token != null && token.trim().isNotEmpty) {
        headers['Authorization'] = 'Bearer ${token.trim()}';
      }
    }

    http.Response response;

    try {
      final request = http.Request(method, uri)..headers.addAll(headers);

      if (body != null) {
        request.body = jsonEncode(body);
      }

      final streamedResponse = await _http.send(request).timeout(timeout);
      response = await http.Response.fromStream(
        streamedResponse,
      ).timeout(timeout);
    } on TimeoutException {
      throw const ApiException(
        0,
        'The server took too long to respond. Please try again.',
      );
    } on http.ClientException {
      throw const ApiException(
        0,
        'Unable to reach the server. Check your connection and the API address.',
      );
    }

    return _decodeResponse(response);
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    Map<String, dynamic>? decoded;

    if (response.body.trim().isNotEmpty) {
      try {
        final value = jsonDecode(response.body);
        if (value is Map<String, dynamic>) {
          decoded = value;
        }
      } on FormatException {
        decoded = null;
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (decoded == null) {
        throw ApiException(
          response.statusCode,
          'The server returned an unexpected response.',
        );
      }
      return decoded;
    }

    final detail = decoded?['detail'];
    throw ApiException(
      response.statusCode,
      _messageFromDetail(detail) ??
          'Request failed with status ${response.statusCode}.',
      details: detail,
    );
  }

  String? _messageFromDetail(Object? detail) {
    if (detail is String && detail.trim().isNotEmpty) {
      return detail;
    }

    if (detail is List) {
      final messages = detail
          .whereType<Map>()
          .map((item) => item['msg'])
          .whereType<String>()
          .where((message) => message.trim().isNotEmpty)
          .toList();

      if (messages.isNotEmpty) {
        return messages.join(' ');
      }
    }

    return null;
  }
}
