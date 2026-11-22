import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:ai_early_childhood_autism_risk_assessment/app_state.dart';
import 'package:ai_early_childhood_autism_risk_assessment/screens/assessment_history_screen.dart';
import 'package:ai_early_childhood_autism_risk_assessment/screens/assessment_result_screen.dart';
import 'package:ai_early_childhood_autism_risk_assessment/services/api_client.dart';
import 'package:ai_early_childhood_autism_risk_assessment/services/session_service.dart';

import 'helpers/fake_token_store.dart';

Map<String, Object?> historyRow({
  required String id,
  String level = 'moderate',
  String createdAt = '2026-11-22 10:30:00',
  bool minimal = false,
}) {
  return {
    'id': id,
    'child_id': 'child-1',
    'created_at': createdAt,
    if (!minimal) ...{
      'age_years': 1,
      'age_months': 8,
      'total_months': 20,
      'age_group': '12-23 months',
      'answers': {'q1': 'usually', 'q12': 'rarely'},
      'concern_level': level,
      'concern_percentage': 33.33,
      'total_score': 8,
      'maximum_score': 24,
      'counted_answers': 12,
      'not_sure_answers': 0,
      'domains': {
        'communication': {
          'concern_percentage': 50.0,
          'counted_questions': 4,
        },
      },
      'parent_concerns': [
        {'question_id': 'q12', 'answer': 'rarely'},
      ],
      'disclaimer': 'This assessment is not a diagnostic tool.',
    } else ...{'concern_level': level},
  };
}

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

Future<void> pumpHistory(
  WidgetTester tester,
  SessionService session, {
  String childId = 'child-1',
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: AssessmentHistoryScreen(
        childId: childId,
        childName: 'Ayaan',
        session: session,
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

void main() {
  setUp(() {
    AppState.assessmentRecords.clear();
  });

  testWidgets('shows a loading state while history is pending', (tester) async {
    final completer = Completer<http.Response>();

    final session = buildSession(
      MockClient((request) => completer.future),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: AssessmentHistoryScreen(
          childId: 'child-1',
          childName: 'Ayaan',
          session: session,
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('history-loading')), findsOneWidget);

    completer.complete(
      http.Response(
        jsonEncode({'success': true, 'data': <Object>[]}),
        200,
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('history-loading')), findsNothing);
  });

  testWidgets('shows the empty state when there are no assessments', (
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

    await pumpHistory(tester, session);

    expect(find.byKey(const Key('history-empty')), findsOneWidget);
  });

  testWidgets('uses the selected child ID for the history request', (
    tester,
  ) async {
    late Uri requested;

    final session = buildSession(
      MockClient((request) async {
        requested = request.url;
        return http.Response(
          jsonEncode({'success': true, 'data': <Object>[]}),
          200,
        );
      }),
    );

    await pumpHistory(tester, session, childId: 'child-99');

    expect(requested.path, '/api/v1/assessment/history/child-99');
  });

  testWidgets('shows multiple records newest first with timestamps', (
    tester,
  ) async {
    final session = buildSession(
      MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'data': [
              historyRow(
                id: 'older',
                level: 'low',
                createdAt: '2026-11-01 08:00:00',
              ),
              historyRow(
                id: 'newest',
                level: 'high',
                createdAt: '2026-11-22 10:30:00',
              ),
              historyRow(
                id: 'middle',
                level: 'moderate',
                createdAt: '2026-11-10 09:15:00',
              ),
            ],
          }),
          200,
        );
      }),
    );

    await pumpHistory(tester, session);

    expect(find.text('High concern'), findsOneWidget);
    expect(find.text('Moderate concern'), findsOneWidget);
    expect(find.text('Low concern'), findsOneWidget);
    expect(find.textContaining('22/11/2026 10:30'), findsOneWidget);
    expect(find.textContaining('01/11/2026 08:00'), findsOneWidget);

    expect(
      tester.getTopLeft(find.text('High concern')).dy,
      lessThan(tester.getTopLeft(find.text('Moderate concern')).dy),
    );
    expect(
      tester.getTopLeft(find.text('Moderate concern')).dy,
      lessThan(tester.getTopLeft(find.text('Low concern')).dy),
    );
  });

  testWidgets('handles missing optional fields safely', (tester) async {
    final session = buildSession(
      MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'data': [historyRow(id: 'minimal', level: 'low', minimal: true)],
          }),
          200,
        );
      }),
    );

    await pumpHistory(tester, session);

    expect(find.text('Low concern'), findsOneWidget);
  });

  testWidgets('shows an error and retries', (tester) async {
    var attempts = 0;

    final session = buildSession(
      MockClient((request) async {
        attempts++;
        if (attempts == 1) {
          return http.Response(
            jsonEncode({'detail': 'Unable to retrieve assessment history.'}),
            500,
          );
        }
        return http.Response(
          jsonEncode({
            'success': true,
            'data': [historyRow(id: 'h1')],
          }),
          200,
        );
      }),
    );

    await pumpHistory(tester, session);

    expect(find.byKey(const Key('history-error')), findsOneWidget);
    expect(
      find.text('The server could not load assessment history. Please try again.'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('history-retry')));
    await tester.pump();
    await tester.pump();

    expect(find.text('Moderate concern'), findsOneWidget);
  });

  testWidgets('reloads when a new assessment is submitted', (tester) async {
    final rows = <Map<String, Object?>>[
      historyRow(id: 'h1', level: 'low'),
    ];

    final session = buildSession(
      MockClient((request) async {
        return http.Response(
          jsonEncode({'success': true, 'data': rows}),
          200,
        );
      }),
    );

    await pumpHistory(tester, session);

    expect(find.byKey(const Key('history-card-h1')), findsOneWidget);
    expect(find.byKey(const Key('history-card-h2')), findsNothing);

    rows.add(historyRow(id: 'h2', level: 'high'));

    AppState.notifyAssessmentHistoryChanged();
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('history-card-h2')), findsOneWidget);
    expect(find.byKey(const Key('history-card-h1')), findsOneWidget);
  });

  testWidgets('does not display legacy local assessment records', (
    tester,
  ) async {
    AppState.assessmentRecords.add(
      AssessmentRecord(
        id: 'local-1',
        childName: 'Ayaan',
        date: DateTime(2026, 11, 20),
        results: const {
          'communication': {'Yes': 3},
        },
        notes: const {'__checklist_age_months': '20'},
      ),
    );

    final session = buildSession(
      MockClient((request) async {
        return http.Response(
          jsonEncode({'success': true, 'data': <Object>[]}),
          200,
        );
      }),
    );

    await pumpHistory(tester, session);

    expect(find.byKey(const Key('history-empty')), findsOneWidget);
    expect(find.textContaining('CDC checklist'), findsNothing);
  });

  testWidgets('opens result details for a saved assessment', (tester) async {
    final session = buildSession(
      MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'data': [historyRow(id: 'h1', level: 'high')],
          }),
          200,
        );
      }),
    );

    await pumpHistory(tester, session);

    await tester.tap(find.byKey(const Key('history-card-h1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(AssessmentResultScreen), findsOneWidget);
    expect(find.byKey(const Key('result-concern-level')), findsOneWidget);
    expect(find.text('High concern'), findsWidgets);
    expect(find.text('8 / 24'), findsOneWidget);
  });

  testWidgets('RecentAssessmentCard shows the latest backend assessment', (
    tester,
  ) async {
    final session = buildSession(
      MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'data': [
              historyRow(
                id: 'newest',
                level: 'high',
                createdAt: '2026-11-22 10:30:00',
              ),
              historyRow(
                id: 'older',
                level: 'low',
                createdAt: '2026-11-01 08:00:00',
              ),
            ],
          }),
          200,
        );
      }),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RecentAssessmentCard(
            childId: 'child-1',
            childName: 'Ayaan',
            session: session,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('High concern'), findsOneWidget);
    expect(find.text('Low concern'), findsNothing);
    expect(find.textContaining('22/11/2026 10:30'), findsOneWidget);
  });

  testWidgets('AssessmentHistoryCount reports the backend count', (
    tester,
  ) async {
    final session = buildSession(
      MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'data': [
              historyRow(id: 'h1'),
              historyRow(id: 'h2', createdAt: '2026-11-01 08:00:00'),
            ],
          }),
          200,
        );
      }),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: AssessmentHistoryCount(
          childId: 'child-1',
          session: session,
          builder: (context, count) => Text(
            'count:${count ?? 'null'}',
            key: const Key('history-count'),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('count:2'), findsOneWidget);
  });
}
