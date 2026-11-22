import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:ai_early_childhood_autism_risk_assessment/main.dart';
import 'package:ai_early_childhood_autism_risk_assessment/screens/auth_screen.dart';
import 'package:ai_early_childhood_autism_risk_assessment/screens/authenticated_screen.dart';
import 'package:ai_early_childhood_autism_risk_assessment/screens/child_profile_screen.dart';
import 'package:ai_early_childhood_autism_risk_assessment/services/api_client.dart';
import 'package:ai_early_childhood_autism_risk_assessment/services/session_service.dart';

import 'helpers/fake_token_store.dart';

void main() {
  testWidgets('logging in from Welcome opens the authenticated screen', (
    tester,
  ) async {
    final store = FakeTokenStore();

    final session = SessionService(
      tokenStore: store,
      apiClient: ApiClient(
        baseUrl: 'http://example.test',
        tokenProvider: store.readAccessToken,
        httpClient: MockClient((request) async {
          if (request.url.path.endsWith('/children/')) {
            return http.Response(
              jsonEncode({'success': true, 'data': <Object>[]}),
              200,
            );
          }

          return http.Response(
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
          );
        }),
      ),
    );
    await session.restore();

    await tester.pumpWidget(MyApp(session: session));
    await tester.pump();

    final loginButton = find.byKey(const Key('welcome-login'));
    await tester.ensureVisible(loginButton);
    await tester.pump();
    await tester.tap(loginButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(AuthScreen), findsOneWidget);

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
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(session.status, SessionStatus.authenticated);
    expect(find.byType(AuthenticatedScreen), findsOneWidget);
    expect(find.byType(ChildProfileScreen), findsOneWidget);
    expect(find.text('Your Children'), findsOneWidget);
  });
}
