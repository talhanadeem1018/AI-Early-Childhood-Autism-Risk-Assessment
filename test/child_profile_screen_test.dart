import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:ai_early_childhood_autism_risk_assessment/app_state.dart';
import 'package:ai_early_childhood_autism_risk_assessment/screens/child_profile_screen.dart';
import 'package:ai_early_childhood_autism_risk_assessment/screens/dashboard_screen.dart';
import 'package:ai_early_childhood_autism_risk_assessment/services/api_client.dart';
import 'package:ai_early_childhood_autism_risk_assessment/services/session_service.dart';

import 'helpers/fake_token_store.dart';

final Map<String, Object?> ayaan = {
  'id': 'child-1',
  'parent_id': 'parent-1',
  'child_name': 'Ayaan',
  'date_of_birth': '2024-05-10',
  'gender': 'Male',
  'created_at': '2024-05-10T12:34:56Z',
};

SessionService buildSession(MockClient client) {
  final store = FakeTokenStore()..accessToken = 'valid-token';

  return SessionService(
    tokenStore: store,
    apiClient: ApiClient(
      baseUrl: 'http://example.test',
      tokenProvider: store.readAccessToken,
      httpClient: client,
    ),
  );
}

Future<void> pumpScreen(WidgetTester tester, SessionService session) async {
  await tester.pumpWidget(
    MaterialApp(
      home: ChildProfileScreen(
        session: session,
        parentEmail: 'parent@example.com',
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

Future<void> tapSubmit(WidgetTester tester) async {
  final button = find.byKey(const Key('child-submit'));
  await tester.ensureVisible(button);
  await tester.pump();
  await tester.tap(button);
}

/// Opens the date picker and confirms its initial date (24 months ago).
Future<void> pickDefaultDateOfBirth(WidgetTester tester) async {
  final dobField = find.byKey(const Key('child-dob'));
  await tester.ensureVisible(dobField);
  await tester.pump();
  await tester.tap(dobField);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Select'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    AppState.childProfiles.clear();
    AppState.selectedChildProfileId = null;
  });

  testWidgets('loads and displays existing children', (tester) async {
    final session = buildSession(
      MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'data': [ayaan],
          }),
          200,
        );
      }),
    );

    await pumpScreen(tester, session);

    expect(find.text('Ayaan'), findsOneWidget);
    expect(find.byKey(const Key('children-empty')), findsNothing);
    expect(find.byKey(const Key('children-error')), findsNothing);
  });

  testWidgets('shows the empty state when there are no children', (
    tester,
  ) async {
    final session = buildSession(
      MockClient((request) async {
        return http.Response(
          jsonEncode({'success': true, 'data': <Object>[]}),
          200,
        );
      }),
    );

    await pumpScreen(tester, session);

    expect(find.byKey(const Key('children-empty')), findsOneWidget);
    expect(find.byKey(const Key('child-submit')), findsOneWidget);
  });

  testWidgets('shows a readable error and retries after a fetch failure', (
    tester,
  ) async {
    var attempts = 0;

    final session = buildSession(
      MockClient((request) async {
        attempts++;
        if (attempts == 1) {
          throw http.ClientException('offline', request.url);
        }
        return http.Response(
          jsonEncode({'success': true, 'data': <Object>[]}),
          200,
        );
      }),
    );

    await pumpScreen(tester, session);

    expect(find.byKey(const Key('children-error')), findsOneWidget);
    expect(find.textContaining('Unable to reach'), findsOneWidget);

    await tester.tap(find.byKey(const Key('children-retry')));
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('children-error')), findsNothing);
    expect(find.byKey(const Key('children-empty')), findsOneWidget);
  });

  testWidgets('shows a loading indicator while children are pending', (
    tester,
  ) async {
    final completer = Completer<http.Response>();

    final session = buildSession(
      MockClient((request) => completer.future),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ChildProfileScreen(
          session: session,
          parentEmail: 'parent@example.com',
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Loading your children...'), findsOneWidget);

    completer.complete(
      http.Response(
        jsonEncode({'success': true, 'data': <Object>[]}),
        200,
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Loading your children...'), findsNothing);
  });

  testWidgets('creates a child, refreshes the list, and shows success', (
    tester,
  ) async {
    final created = {
      'id': 'child-9',
      'parent_id': 'parent-1',
      'child_name': 'Hana',
      'date_of_birth': '2024-11-22',
      'gender': 'Female',
    };
    var getCount = 0;
    late http.Request postRequest;

    final session = buildSession(
      MockClient((request) async {
        if (request.method == 'POST') {
          postRequest = request;
          return http.Response(
            jsonEncode({
              'success': true,
              'data': created,
            }),
            200,
          );
        }

        getCount++;
        return http.Response(
          jsonEncode({
            'success': true,
            'data': getCount == 1 ? <Object>[] : [created],
          }),
          200,
        );
      }),
    );

    await pumpScreen(tester, session);

    await tester.enterText(find.byKey(const Key('child-name')), 'Hana');
    await pickDefaultDateOfBirth(tester);

    await tapSubmit(tester);
    await tester.pumpAndSettle();

    final body = jsonDecode(postRequest.body) as Map<String, dynamic>;
    expect(body['child_name'], 'Hana');
    expect(body.containsKey('parent_id'), isFalse);
    expect(body.containsKey('gender'), isFalse);
    expect(getCount, 2);
    expect(find.textContaining('Hana was added'), findsOneWidget);
    expect(find.text('Hana'), findsOneWidget);
  });

  testWidgets('sends the backend gender code and shows its label', (
    tester,
  ) async {
    final created = {
      'id': 'child-10',
      'parent_id': 'parent-1',
      'child_name': 'Hana',
      'date_of_birth': '2024-11-22',
      'gender': 'prefer_not_to_say',
    };
    var getCount = 0;
    late http.Request postRequest;

    final session = buildSession(
      MockClient((request) async {
        if (request.method == 'POST') {
          postRequest = request;
          return http.Response(
            jsonEncode({'success': true, 'data': created}),
            200,
          );
        }

        getCount++;
        return http.Response(
          jsonEncode({
            'success': true,
            'data': getCount == 1 ? <Object>[] : [created],
          }),
          200,
        );
      }),
    );

    await pumpScreen(tester, session);

    await tester.enterText(find.byKey(const Key('child-name')), 'Hana');
    await pickDefaultDateOfBirth(tester);

    final genderField = find.byKey(const Key('child-gender'));
    await tester.ensureVisible(genderField);
    await tester.pump();
    await tester.tap(genderField);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Prefer not to say').last);
    await tester.pumpAndSettle();

    await tapSubmit(tester);
    await tester.pumpAndSettle();

    final body = jsonDecode(postRequest.body) as Map<String, dynamic>;
    expect(body['gender'], 'prefer_not_to_say');
    expect(find.textContaining('Prefer not to say'), findsWidgets);
    expect(find.textContaining('prefer_not_to_say'), findsNothing);
  });

  testWidgets('shows a backend error when creation fails', (tester) async {
    final session = buildSession(
      MockClient((request) async {
        if (request.method == 'POST') {
          return http.Response(
            jsonEncode({'detail': 'Unable to create child profile.'}),
            400,
          );
        }
        return http.Response(
          jsonEncode({'success': true, 'data': <Object>[]}),
          200,
        );
      }),
    );

    await pumpScreen(tester, session);

    await tester.enterText(find.byKey(const Key('child-name')), 'Hana');
    await pickDefaultDateOfBirth(tester);

    await tapSubmit(tester);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('child-form-error')), findsOneWidget);
    expect(find.text('Unable to create child profile.'), findsOneWidget);
  });

  testWidgets('required field validation blocks submission', (tester) async {
    var posts = 0;

    final session = buildSession(
      MockClient((request) async {
        if (request.method == 'POST') posts++;
        return http.Response(
          jsonEncode({'success': true, 'data': <Object>[]}),
          200,
        );
      }),
    );

    await pumpScreen(tester, session);

    await tapSubmit(tester);
    await tester.pumpAndSettle();

    expect(find.text('Please enter the child’s name'), findsOneWidget);
    expect(
      find.text('Please select the child’s date of birth'),
      findsOneWidget,
    );
    expect(posts, 0);
  });

  testWidgets('does not submit twice while a request is running', (
    tester,
  ) async {
    final completer = Completer<http.Response>();
    var posts = 0;

    final session = buildSession(
      MockClient((request) async {
        if (request.method == 'POST') {
          posts++;
          return completer.future;
        }
        return http.Response(
          jsonEncode({'success': true, 'data': <Object>[]}),
          200,
        );
      }),
    );

    await pumpScreen(tester, session);

    await tester.enterText(find.byKey(const Key('child-name')), 'Hana');
    await pickDefaultDateOfBirth(tester);

    await tester.tap(find.byKey(const Key('child-submit')));
    await tapSubmit(tester);
    await tapSubmit(tester);
    await tester.pump();

    expect(posts, 1);

    completer.complete(
      http.Response(
        jsonEncode({
          'success': true,
          'data': {
            'id': 'child-9',
            'child_name': 'Hana',
            'date_of_birth': '2024-11-22',
          },
        }),
        200,
      ),
    );
    await tester.pumpAndSettle();
  });

  testWidgets('selecting a child opens the dashboard with real values', (
    tester,
  ) async {
    final session = buildSession(
      MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'data': [ayaan],
          }),
          200,
        );
      }),
    );

    await pumpScreen(tester, session);

    await tester.tap(find.byKey(const Key('child-card-child-1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(DashboardScreen), findsOneWidget);
    expect(find.text('Ayaan'), findsWidgets);
    expect(AppState.selectedChildProfileId, 'child-1');
    expect(
      AppState.selectedChildProfile?.dateOfBirth,
      DateTime(2024, 5, 10),
    );
  });
}
