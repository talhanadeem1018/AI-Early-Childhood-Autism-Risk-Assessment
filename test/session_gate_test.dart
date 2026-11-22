import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:ai_early_childhood_autism_risk_assessment/screens/authenticated_screen.dart';
import 'package:ai_early_childhood_autism_risk_assessment/screens/welcome_screen.dart';
import 'package:ai_early_childhood_autism_risk_assessment/services/api_client.dart';
import 'package:ai_early_childhood_autism_risk_assessment/services/session_service.dart';
import 'package:ai_early_childhood_autism_risk_assessment/widgets/session_gate.dart';

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

void main() {
  testWidgets('no token shows WelcomeScreen', (tester) async {
    final store = FakeTokenStore();
    final session = buildSession(
      store,
      MockClient((request) async {
        fail('No request expected without a token.');
      }),
    );
    await session.restore();

    await tester.pumpWidget(MaterialApp(home: SessionGate(session: session)));
    await tester.pump();

    expect(find.byType(WelcomeScreen), findsOneWidget);
  });

  testWidgets('valid token marks the session authenticated', (tester) async {
    final store = FakeTokenStore()..accessToken = 'valid-token';
    final session = buildSession(
      store,
      MockClient((request) async {
        if (request.url.path.endsWith('/children/')) {
          return http.Response(
            jsonEncode({'success': true, 'data': <Object>[]}),
            200,
          );
        }

        return http.Response(
          jsonEncode({
            'success': true,
            'data': {'user_id': 'user-1', 'email': 'parent@example.com'},
          }),
          200,
        );
      }),
    );
    await session.restore();

    await tester.pumpWidget(MaterialApp(home: SessionGate(session: session)));
    await tester.pump();
    await tester.pump();

    expect(session.status, SessionStatus.authenticated);
    expect(find.byType(AuthenticatedScreen), findsOneWidget);
    expect(find.text('parent@example.com'), findsOneWidget);
  });

  testWidgets('logout clears tokens and returns to WelcomeScreen', (
    tester,
  ) async {
    final store = FakeTokenStore()
      ..accessToken = 'valid-token'
      ..refreshToken = 'valid-refresh';
    final session = buildSession(
      store,
      MockClient((request) async {
        if (request.url.path.endsWith('/children/')) {
          return http.Response(
            jsonEncode({'success': true, 'data': <Object>[]}),
            200,
          );
        }

        return http.Response(
          jsonEncode({
            'success': true,
            'data': {'user_id': 'user-1', 'email': 'parent@example.com'},
          }),
          200,
        );
      }),
    );
    await session.restore();

    await tester.pumpWidget(MaterialApp(home: SessionGate(session: session)));
    await tester.pump();
    await tester.pump();

    expect(find.byType(AuthenticatedScreen), findsOneWidget);

    await tester.tap(find.byKey(const Key('auth-logout')));
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(store.accessToken, isNull);
    expect(store.refreshToken, isNull);
    expect(session.status, SessionStatus.unauthenticated);
    expect(find.byType(WelcomeScreen), findsOneWidget);
  });

  testWidgets('invalid token is cleared and returns to WelcomeScreen', (
    tester,
  ) async {
    final store = FakeTokenStore()..accessToken = 'invalid-token';
    final session = buildSession(
      store,
      MockClient((request) async {
        return http.Response(
          jsonEncode({'detail': 'Invalid or expired authentication token.'}),
          401,
        );
      }),
    );
    await session.restore();

    await tester.pumpWidget(MaterialApp(home: SessionGate(session: session)));
    await tester.pump();

    expect(store.accessToken, isNull);
    expect(find.byType(WelcomeScreen), findsOneWidget);
  });

  testWidgets(
    'network failure shows the connection error and keeps the token',
    (tester) async {
      final store = FakeTokenStore()..accessToken = 'retained-token';
      final session = buildSession(
        store,
        MockClient((request) async {
          throw http.ClientException('offline', request.url);
        }),
      );
      await session.restore();

      await tester.pumpWidget(MaterialApp(home: SessionGate(session: session)));
      await tester.pump();

      expect(store.accessToken, 'retained-token');
      expect(find.text('Unable to connect'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
      expect(find.text('Continue to welcome'), findsOneWidget);
    },
  );

  testWidgets('loading state is shown while /auth/me is pending', (
    tester,
  ) async {
    final store = FakeTokenStore()..accessToken = 'pending-token';
    final responseCompleter = Completer<http.Response>();

    final session = buildSession(
      store,
      MockClient((request) => responseCompleter.future),
    );

    await tester.pumpWidget(MaterialApp(home: SessionGate(session: session)));
    await tester.pump();

    expect(find.text('Checking your session...'), findsOneWidget);

    responseCompleter.complete(
      http.Response(
        jsonEncode({'detail': 'Invalid or expired authentication token.'}),
        401,
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byType(WelcomeScreen), findsOneWidget);
  });
}
