import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:ai_early_childhood_autism_risk_assessment/screens/auth_screen.dart';
import 'package:ai_early_childhood_autism_risk_assessment/services/api_client.dart';
import 'package:ai_early_childhood_autism_risk_assessment/services/session_service.dart';

import 'helpers/fake_token_store.dart';

SessionService buildSession(FakeTokenStore store, MockClient client) {
  return SessionService(
    tokenStore: store,
    apiClient: ApiClient(
      baseUrl: 'http://example.test',
      tokenProvider: store.readAccessToken,
      httpClient: client,
    ),
  );
}

Future<void> pumpAuth(
  WidgetTester tester,
  SessionService session, {
  AuthMode mode = AuthMode.login,
}) async {
  if (session.status == SessionStatus.unknown) {
    await session.restore();
  }

  await tester.pumpWidget(
    MaterialApp(
      home: AuthScreen(session: session, initialMode: mode),
    ),
  );
  await tester.pump();
}

Future<void> tapSubmit(WidgetTester tester) async {
  final submitButton = find.byKey(const Key('auth-submit'));
  await tester.ensureVisible(submitButton);
  await tester.pump();
  await tester.tap(submitButton);
  await tester.pumpAndSettle();
}

Future<void> submitLogin(WidgetTester tester) async {
  await tester.enterText(
    find.byKey(const Key('auth-email')),
    'parent@example.com',
  );
  await tester.enterText(find.byKey(const Key('auth-password')), 'password1');
  await tapSubmit(tester);
}

void main() {
  testWidgets('successful registration shows verification message and does not '
      'authenticate', (tester) async {
    final store = FakeTokenStore();
    late http.Request captured;

    final session = buildSession(
      store,
      MockClient((request) async {
        captured = request;
        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Registration successful. Please verify your email.',
            'data': {
              'user_id': 'new-user',
              'email': 'new@example.com',
              'email_verification_required': true,
            },
          }),
          200,
        );
      }),
    );

    await pumpAuth(tester, session, mode: AuthMode.signup);

    await tester.enterText(
      find.byKey(const Key('auth-email')),
      'new@example.com',
    );
    await tester.enterText(find.byKey(const Key('auth-password')), 'password1');
    await tester.enterText(
      find.byKey(const Key('auth-confirm-password')),
      'password1',
    );
    await tapSubmit(tester);

    expect(captured.url.path, '/api/v1/auth/register');
    expect(jsonDecode(captured.body), {
      'email': 'new@example.com',
      'password': 'password1',
    });
    expect(captured.headers.containsKey('Authorization'), isFalse);
    expect(find.textContaining('Check your email'), findsOneWidget);
    expect(store.accessToken, isNull);
    expect(session.status, SessionStatus.unauthenticated);
  });

  testWidgets('registration failure shows a readable error', (tester) async {
    final store = FakeTokenStore();

    final session = buildSession(
      store,
      MockClient((request) async {
        return http.Response(
          jsonEncode({
            'detail':
                'Registration failed. Check backend logs for the actual error.',
          }),
          400,
        );
      }),
    );

    await pumpAuth(tester, session, mode: AuthMode.signup);

    await tester.enterText(
      find.byKey(const Key('auth-email')),
      'existing@example.com',
    );
    await tester.enterText(find.byKey(const Key('auth-password')), 'password1');
    await tester.enterText(
      find.byKey(const Key('auth-confirm-password')),
      'password1',
    );
    await tapSubmit(tester);

    expect(
      find.textContaining('Registration could not be completed'),
      findsOneWidget,
    );
    expect(store.accessToken, isNull);
    expect(session.status, SessionStatus.unauthenticated);
  });

  testWidgets('successful login stores both tokens and authenticates', (
    tester,
  ) async {
    final store = FakeTokenStore();
    late http.Request captured;

    final session = buildSession(
      store,
      MockClient((request) async {
        captured = request;
        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Login successful.',
            'data': {
              'user_id': 'user-1',
              'email': 'parent@example.com',
              'access_token': 'access-token-1',
              'refresh_token': 'refresh-token-1',
              'token_type': 'bearer',
              'expires_in': 3600,
            },
          }),
          200,
        );
      }),
    );

    await pumpAuth(tester, session);
    await submitLogin(tester);

    expect(captured.url.path, '/api/v1/auth/login');
    expect(jsonDecode(captured.body), {
      'email': 'parent@example.com',
      'password': 'password1',
    });
    expect(captured.headers.containsKey('Authorization'), isFalse);
    expect(store.accessToken, 'access-token-1');
    expect(store.refreshToken, 'refresh-token-1');
    expect(session.status, SessionStatus.authenticated);
    expect(session.user?.email, 'parent@example.com');
  });

  testWidgets('invalid credentials keep the session unauthenticated', (
    tester,
  ) async {
    final store = FakeTokenStore();

    final session = buildSession(
      store,
      MockClient((request) async {
        return http.Response(
          jsonEncode({
            'detail':
                'Invalid email or password, or email confirmation is required.',
          }),
          401,
        );
      }),
    );

    await pumpAuth(tester, session);
    await submitLogin(tester);

    expect(find.textContaining('Incorrect email or password'), findsOneWidget);
    expect(store.accessToken, isNull);
    expect(session.status, SessionStatus.unauthenticated);
  });

  testWidgets('login shows a loading state and blocks repeated submissions', (
    tester,
  ) async {
    final store = FakeTokenStore();
    final responseCompleter = Completer<http.Response>();
    var requestCount = 0;

    final session = buildSession(
      store,
      MockClient((request) {
        requestCount++;
        return responseCompleter.future;
      }),
    );

    await pumpAuth(tester, session);
    await tester.enterText(
      find.byKey(const Key('auth-email')),
      'parent@example.com',
    );
    await tester.enterText(find.byKey(const Key('auth-password')), 'password1');

    final submitButton = find.byKey(const Key('auth-submit'));
    await tester.ensureVisible(submitButton);
    await tester.pump();
    await tester.tap(submitButton);
    await tester.pump();

    expect(find.text('Logging in...'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    final button = tester.widget<FilledButton>(
      find.byKey(const Key('auth-submit')),
    );
    expect(button.onPressed, isNull);

    await tester.tap(find.byKey(const Key('auth-submit')), warnIfMissed: false);
    await tester.pump();
    expect(requestCount, 1);

    responseCompleter.complete(
      http.Response(
        jsonEncode({
          'success': true,
          'data': {
            'user_id': 'user-1',
            'email': 'parent@example.com',
            'access_token': 'access-token-1',
            'refresh_token': 'refresh-token-1',
          },
        }),
        200,
      ),
    );
    await tester.pumpAndSettle();

    expect(session.status, SessionStatus.authenticated);
  });

  testWidgets('network failure shows the connection error', (tester) async {
    final store = FakeTokenStore();

    final session = buildSession(
      store,
      MockClient((request) async {
        throw http.ClientException('offline', request.url);
      }),
    );

    await pumpAuth(tester, session);
    await submitLogin(tester);

    expect(find.textContaining('Unable to reach the server'), findsOneWidget);
    expect(session.status, SessionStatus.unauthenticated);
    expect(store.accessToken, isNull);
  });
}
