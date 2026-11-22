import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:ai_early_childhood_autism_risk_assessment/services/api_client.dart';
import 'package:ai_early_childhood_autism_risk_assessment/services/session_service.dart';

import 'helpers/fake_token_store.dart';

void main() {
  test('no saved token leaves the session unauthenticated', () async {
    final store = FakeTokenStore();

    final session = SessionService(
      tokenStore: store,
      apiClient: ApiClient(
        baseUrl: 'http://example.test',
        tokenProvider: store.readAccessToken,
        httpClient: MockClient((request) async {
          fail('No request should be sent without a stored token.');
        }),
      ),
    );

    await session.restore();

    expect(session.status, SessionStatus.unauthenticated);
    expect(session.user, isNull);
  });

  test('valid token authenticates with /auth/me', () async {
    final store = FakeTokenStore()..accessToken = 'stored-token';
    late http.Request captured;

    final session = SessionService(
      tokenStore: store,
      apiClient: ApiClient(
        baseUrl: 'http://example.test',
        tokenProvider: store.readAccessToken,
        httpClient: MockClient((request) async {
          captured = request;
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {'user_id': 'user-1', 'email': 'parent@example.com'},
            }),
            200,
          );
        }),
      ),
    );

    await session.restore();

    expect(captured.url.toString(), 'http://example.test/api/v1/auth/me');
    expect(captured.headers['Authorization'], 'Bearer stored-token');
    expect(session.status, SessionStatus.authenticated);
    expect(session.user?.id, 'user-1');
    expect(session.user?.email, 'parent@example.com');
  });

  test('401 clears the stored token', () async {
    final store = FakeTokenStore()..accessToken = 'expired-token';

    final session = SessionService(
      tokenStore: store,
      apiClient: ApiClient(
        baseUrl: 'http://example.test',
        tokenProvider: store.readAccessToken,
        httpClient: MockClient((request) async {
          return http.Response(
            jsonEncode({'detail': 'Invalid or expired authentication token.'}),
            401,
          );
        }),
      ),
    );

    await session.restore();

    expect(store.cleared, isTrue);
    expect(store.accessToken, isNull);
    expect(session.status, SessionStatus.unauthenticated);
  });

  test(
    'network failure reports a connection error and retains the token',
    () async {
      final store = FakeTokenStore()..accessToken = 'possibly-valid-token';

      final session = SessionService(
        tokenStore: store,
        apiClient: ApiClient(
          baseUrl: 'http://example.test',
          tokenProvider: store.readAccessToken,
          httpClient: MockClient((request) async {
            throw http.ClientException('offline', request.url);
          }),
        ),
      );

      await session.restore();

      expect(session.status, SessionStatus.connectionError);
      expect(store.accessToken, 'possibly-valid-token');
      expect(store.cleared, isFalse);
      expect(session.connectionErrorMessage, contains('Unable to reach'));
    },
  );

  test('login stores tokens and marks the session authenticated', () async {
    final store = FakeTokenStore();

    final session = SessionService(
      tokenStore: store,
      apiClient: ApiClient(
        baseUrl: 'http://example.test',
        tokenProvider: store.readAccessToken,
        httpClient: MockClient((request) async {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'user_id': 'user-2',
                'email': 'parent2@example.com',
                'access_token': 'new-access-token',
                'refresh_token': 'new-refresh-token',
              },
            }),
            200,
          );
        }),
      ),
    );

    final user = await session.login(
      email: 'parent2@example.com',
      password: 'password1',
    );

    expect(user.email, 'parent2@example.com');
    expect(store.accessToken, 'new-access-token');
    expect(store.refreshToken, 'new-refresh-token');
    expect(session.status, SessionStatus.authenticated);
  });

  test('does not log passwords or tokens', () async {
    final store = FakeTokenStore();
    final logs = <String>[];
    final originalDebugPrint = debugPrint;

    debugPrint = (String? message, {int? wrapWidth}) {
      if (message != null) logs.add(message);
    };

    try {
      final session = SessionService(
        tokenStore: store,
        apiClient: ApiClient(
          baseUrl: 'http://example.test',
          tokenProvider: store.readAccessToken,
          httpClient: MockClient((request) async {
            return http.Response(
              jsonEncode({
                'success': true,
                'data': {
                  'user_id': 'user-3',
                  'email': 'parent3@example.com',
                  'access_token': 'secret-access-token',
                  'refresh_token': 'secret-refresh-token',
                },
              }),
              200,
            );
          }),
        ),
      );

      await session.login(email: 'parent3@example.com', password: 'password1');
    } finally {
      debugPrint = originalDebugPrint;
    }

    final output = logs.join('\n');
    expect(output, isNot(contains('password1')));
    expect(output, isNot(contains('secret-access-token')));
    expect(output, isNot(contains('secret-refresh-token')));
  });

  test('logout clears local tokens', () async {
    final store = FakeTokenStore()
      ..accessToken = 'access'
      ..refreshToken = 'refresh';

    final session = SessionService(
      tokenStore: store,
      apiClient: ApiClient(
        baseUrl: 'http://example.test',
        tokenProvider: store.readAccessToken,
      ),
    );

    await session.logout();

    expect(store.accessToken, isNull);
    expect(store.refreshToken, isNull);
    expect(store.cleared, isTrue);
    expect(session.status, SessionStatus.unauthenticated);
  });
}
