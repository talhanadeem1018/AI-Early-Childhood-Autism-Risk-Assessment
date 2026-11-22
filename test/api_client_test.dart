import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:ai_early_childhood_autism_risk_assessment/services/api_client.dart';

void main() {
  test('attaches the bearer token to authenticated requests', () async {
    late http.Request captured;

    final api = ApiClient(
      baseUrl: 'http://example.test/',
      tokenProvider: () async => 'test-token',
      httpClient: MockClient((request) async {
        captured = request;
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {'ok': true},
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    final response = await api.get('/api/v1/children/');

    expect(response['success'], true);
    expect(captured.url.toString(), 'http://example.test/api/v1/children/');
    expect(captured.headers['Authorization'], 'Bearer test-token');
  });

  test('does not attach a token to public requests', () async {
    late http.Request captured;

    final api = ApiClient(
      baseUrl: 'http://example.test',
      tokenProvider: () async => 'test-token',
      httpClient: MockClient((request) async {
        captured = request;
        return http.Response(jsonEncode({'success': true, 'data': {}}), 200);
      }),
    );

    await api.post(
      '/api/v1/auth/login',
      body: {'email': 'parent@example.com', 'password': 'password1'},
      authenticated: false,
    );

    expect(captured.headers.containsKey('Authorization'), isFalse);
    expect(captured.headers['Content-Type'], contains('application/json'));
    expect(jsonDecode(captured.body)['email'], 'parent@example.com');
  });

  test('surfaces backend error detail and status code', () async {
    final api = ApiClient(
      baseUrl: 'http://example.test',
      httpClient: MockClient((request) async {
        return http.Response(
          jsonEncode({'detail': 'Invalid email or password.'}),
          401,
        );
      }),
    );

    expect(
      () => api.get('/api/v1/auth/me'),
      throwsA(
        isA<ApiException>()
            .having((error) => error.statusCode, 'statusCode', 401)
            .having((error) => error.isUnauthorized, 'isUnauthorized', true)
            .having(
              (error) => error.message,
              'message',
              'Invalid email or password.',
            ),
      ),
    );
  });

  test('rejects invalid JSON without crashing', () async {
    final api = ApiClient(
      baseUrl: 'http://example.test',
      httpClient: MockClient((request) async {
        return http.Response('not-json', 200);
      }),
    );

    expect(
      () => api.get('/api/v1/auth/me'),
      throwsA(
        isA<ApiException>().having(
          (error) => error.message,
          'message',
          'The server returned an unexpected response.',
        ),
      ),
    );
  });

  test('times out safely', () async {
    final api = ApiClient(
      baseUrl: 'http://example.test',
      timeout: const Duration(milliseconds: 10),
      httpClient: MockClient((request) async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        return http.Response(jsonEncode({'success': true, 'data': {}}), 200);
      }),
    );

    expect(
      () => api.get('/api/v1/auth/me'),
      throwsA(
        isA<ApiException>()
            .having((error) => error.statusCode, 'statusCode', 0)
            .having(
              (error) => error.message,
              'message',
              contains('took too long'),
            ),
      ),
    );
  });

  test('maps an unreachable server to a connection error', () async {
    final api = ApiClient(
      baseUrl: 'http://example.test',
      httpClient: MockClient((request) async {
        throw http.ClientException('offline', request.url);
      }),
    );

    expect(
      () => api.get('/api/v1/auth/me'),
      throwsA(
        isA<ApiException>()
            .having((error) => error.statusCode, 'statusCode', 0)
            .having(
              (error) => error.message,
              'message',
              contains('Unable to reach the server'),
            ),
      ),
    );
  });
}
