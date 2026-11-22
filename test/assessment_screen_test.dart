import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:ai_early_childhood_autism_risk_assessment/app_state.dart';
import 'package:ai_early_childhood_autism_risk_assessment/screens/assessment_result_screen.dart';
import 'package:ai_early_childhood_autism_risk_assessment/screens/assessment_screen.dart';
import 'package:ai_early_childhood_autism_risk_assessment/services/api_client.dart';
import 'package:ai_early_childhood_autism_risk_assessment/services/session_service.dart';

import 'helpers/fake_token_store.dart';

Map<String, Object?> questionnairePayload({int count = 12}) {
  return {
    'child_id': 'child-1',
    'age': {
      'date_of_birth': '2025-03-10',
      'age_years': 1,
      'age_months': 8,
      'total_months': 20,
      'age_group': '12-23 months',
    },
    'questions': [
      for (var i = 1; i <= count; i++)
        {
          'id': 'q$i',
          'question_text': 'Backend question $i',
          'domain': i.isEven ? 'social' : 'communication',
          'question_type': 'developmental',
          'min_age_months': 12,
          'max_age_months': 23,
          'sort_order': i,
          'is_active': true,
        },
    ],
    'answer_options': [
      {'id': 'o1', 'option_value': 'usually', 'option_label': 'Usually'},
      {'id': 'o2', 'option_value': 'sometimes', 'option_label': 'Sometimes'},
      {'id': 'o3', 'option_value': 'rarely', 'option_label': 'Rarely'},
      {'id': 'o4', 'option_value': 'not_sure', 'option_label': 'Not sure'},
    ],
  };
}

Map<String, Object?> resultPayload({String concernLevel = 'low'}) {
  return {
    'child_id': 'child-1',
    'status': 'complete',
    'concern_level': concernLevel,
    'concern_percentage': 8.33,
    'total_score': 2,
    'maximum_score': 24,
    'counted_answers': 12,
    'not_sure_answers': 0,
    'domains': {
      'communication': {
        'concern_percentage': 11.11,
        'counted_questions': 6,
      },
      'social': {'concern_percentage': 5.55, 'counted_questions': 6},
    },
    'parent_concerns': [
      {'question_id': 'q12', 'answer': 'rarely'},
    ],
    'disclaimer': 'This assessment is not a diagnostic tool.',
    'age': {
      'age_years': 1,
      'age_months': 8,
      'total_months': 20,
      'age_group': '12-23 months',
    },
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

Future<void> pumpAssessment(
  WidgetTester tester,
  SessionService session, {
  String? childId = 'child-1',
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: AssessmentScreen(
        childName: 'Ayaan',
        dateOfBirth: DateTime(2024, 5, 10),
        childId: childId,
        session: session,
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 450));
}

Future<void> tapNext(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('assessment-next')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 450));
}

void main() {
  setUp(() {
    AppState.childProfiles.clear();
    AppState.selectedChildProfileId = null;
    AppState.clearAssessmentDraft('child-1');
  });

  testWidgets('loads the backend question, age group and options', (
    tester,
  ) async {
    final session = buildSession(
      MockClient((request) async {
        return http.Response(
          jsonEncode({'success': true, 'data': questionnairePayload()}),
          200,
        );
      }),
    );

    await pumpAssessment(tester, session);

    expect(find.text('Backend question 1'), findsOneWidget);
    expect(find.text('Question 1 of 12'), findsOneWidget);
    expect(find.textContaining('12-23 months'), findsOneWidget);
    expect(find.text('Usually'), findsOneWidget);
    expect(find.text('Sometimes'), findsOneWidget);
    expect(find.text('Rarely'), findsOneWidget);
    expect(find.text('Not sure'), findsOneWidget);
    expect(find.text('Communication'), findsOneWidget);
  });

  testWidgets('shows a loading state while the questionnaire is pending', (
    tester,
  ) async {
    final completer = Completer<http.Response>();

    final session = buildSession(
      MockClient((request) => completer.future),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: AssessmentScreen(
          childName: 'Ayaan',
          dateOfBirth: DateTime(2024, 5, 10),
          childId: 'child-1',
          session: session,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Loading questionnaire...'), findsOneWidget);

    completer.complete(
      http.Response(
        jsonEncode({'success': true, 'data': questionnairePayload()}),
        200,
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Loading questionnaire...'), findsNothing);
    expect(find.text('Backend question 1'), findsOneWidget);
  });

  testWidgets('Next requires an answer', (tester) async {
    final session = buildSession(
      MockClient((request) async {
        return http.Response(
          jsonEncode({'success': true, 'data': questionnairePayload()}),
          200,
        );
      }),
    );

    await pumpAssessment(tester, session);

    await tapNext(tester);

    expect(
      find.text('Please select an answer before continuing.'),
      findsOneWidget,
    );
    expect(find.text('Backend question 2'), findsNothing);
  });

  testWidgets('Previous returns to the earlier question with its answer', (
    tester,
  ) async {
    final session = buildSession(
      MockClient((request) async {
        return http.Response(
          jsonEncode({'success': true, 'data': questionnairePayload()}),
          200,
        );
      }),
    );

    await pumpAssessment(tester, session);

    await tapAndSettle(tester, find.byKey(const Key('answer-usually')));
    await tapNext(tester);

    expect(find.text('Backend question 2'), findsOneWidget);

    await tester.tap(find.byKey(const Key('assessment-previous')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));

    expect(find.text('Backend question 1'), findsOneWidget);
    expect(find.text('Usually selected'), findsOneWidget);
  });

  testWidgets('maps the selected value to the backend question ID', (
    tester,
  ) async {
    final session = buildSession(
      MockClient((request) async {
        return http.Response(
          jsonEncode({'success': true, 'data': questionnairePayload()}),
          200,
        );
      }),
    );

    await pumpAssessment(tester, session);

    await tapAndSettle(tester, find.byKey(const Key('answer-rarely')));

    expect(AppState.assessmentDraftFor('child-1'), {'q1': 'rarely'});

    await tapNext(tester);
    await tapAndSettle(tester, find.byKey(const Key('answer-not_sure')));

    expect(AppState.assessmentDraftFor('child-1'), {
      'q1': 'rarely',
      'q2': 'not_sure',
    });
  });

  testWidgets('loads all 12 questions and submits the complete set', (
    tester,
  ) async {
    late http.Request submitRequest;

    final session = buildSession(
      MockClient((request) async {
        if (request.method == 'POST') {
          submitRequest = request;
          return http.Response(
            jsonEncode({'success': true, 'data': resultPayload()}),
            200,
          );
        }
        return http.Response(
          jsonEncode({'success': true, 'data': questionnairePayload()}),
          200,
        );
      }),
    );

    await pumpAssessment(tester, session);

    final historyRevision = AppState.assessmentHistoryRevision.value;

    for (var i = 1; i <= 12; i++) {
      expect(find.text('Question $i of 12'), findsOneWidget);
      expect(find.text('Backend question $i'), findsOneWidget);

      await tapAndSettle(tester, find.byKey(const Key('answer-usually')));
      await tapNext(tester);
    }

    final body = jsonDecode(submitRequest.body) as Map<String, dynamic>;
    final answers = body['answers'] as Map<String, dynamic>;

    expect(submitRequest.url.path, '/api/v1/assessment/submit');
    expect(body['child_id'], 'child-1');
    expect(answers, hasLength(12));
    expect(answers['q1'], 'usually');
    expect(answers['q12'], 'usually');
    expect(find.byType(AssessmentResultScreen), findsOneWidget);
    expect(find.text('Low concern'), findsOneWidget);
    expect(
      AppState.assessmentHistoryRevision.value,
      historyRevision + 1,
    );
  });

  testWidgets('shows a submitting state and prevents duplicate submission', (
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
          jsonEncode({'success': true, 'data': questionnairePayload()}),
          200,
        );
      }),
    );

    await pumpAssessment(tester, session);

    for (var i = 1; i <= 12; i++) {
      await tapAndSettle(tester, find.byKey(const Key('answer-usually')));
      await tester.tap(find.byKey(const Key('assessment-next')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 450));
    }

    expect(find.text('Submitting...'), findsOneWidget);
    expect(posts, 1);

    // A second tap while the request is in flight must be ignored.
    await tester.tap(find.byKey(const Key('assessment-next')));
    await tester.pump();
    expect(posts, 1);

    completer.complete(
      http.Response(
        jsonEncode({'success': true, 'data': resultPayload()}),
        200,
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));

    expect(find.byType(AssessmentResultScreen), findsOneWidget);
  });

  testWidgets('a failed submission keeps answers and retry succeeds', (
    tester,
  ) async {
    var attempts = 0;

    final session = buildSession(
      MockClient((request) async {
        if (request.method == 'POST') {
          attempts++;
          if (attempts == 1) {
            return http.Response(
              jsonEncode({'detail': 'Unable to calculate and save assessment.'}),
              500,
            );
          }
          return http.Response(
            jsonEncode({'success': true, 'data': resultPayload()}),
            200,
          );
        }
        return http.Response(
          jsonEncode({'success': true, 'data': questionnairePayload()}),
          200,
        );
      }),
    );

    await pumpAssessment(tester, session);

    for (var i = 1; i <= 12; i++) {
      await tapAndSettle(tester, find.byKey(const Key('answer-usually')));
      await tapNext(tester);
    }

    expect(find.byKey(const Key('assessment-submit-error')), findsOneWidget);
    expect(
      find.text('The server could not score the assessment. Please try again.'),
      findsOneWidget,
    );
    expect(find.text('Backend question 12'), findsOneWidget);
    expect(AppState.assessmentDraftFor('child-1'), hasLength(12));

    final retry = find.byKey(const Key('assessment-submit-retry'));
    await tester.ensureVisible(retry);
    await tester.pump();
    await tester.tap(retry);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));

    expect(attempts, 2);
    expect(find.byType(AssessmentResultScreen), findsOneWidget);
  });

  testWidgets('a network failure during submission can be retried', (
    tester,
  ) async {
    var attempts = 0;

    final session = buildSession(
      MockClient((request) async {
        if (request.method == 'POST') {
          attempts++;
          if (attempts == 1) {
            throw http.ClientException('offline', request.url);
          }
          return http.Response(
            jsonEncode({'success': true, 'data': resultPayload()}),
            200,
          );
        }
        return http.Response(
          jsonEncode({'success': true, 'data': questionnairePayload()}),
          200,
        );
      }),
    );

    await pumpAssessment(tester, session);

    for (var i = 1; i <= 12; i++) {
      await tapAndSettle(tester, find.byKey(const Key('answer-usually')));
      await tapNext(tester);
    }

    expect(find.textContaining('Unable to reach'), findsOneWidget);
    expect(find.text('Backend question 12'), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(const Key('assessment-submit-retry')),
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('assessment-submit-retry')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));

    expect(find.byType(AssessmentResultScreen), findsOneWidget);
  });

  testWidgets('shows the API error and retries successfully', (tester) async {
    var attempts = 0;

    final session = buildSession(
      MockClient((request) async {
        attempts++;
        if (attempts == 1) {
          return http.Response(
            jsonEncode({'detail': 'Unable to retrieve questionnaire.'}),
            500,
          );
        }
        return http.Response(
          jsonEncode({'success': true, 'data': questionnairePayload()}),
          200,
        );
      }),
    );

    await pumpAssessment(tester, session);

    expect(find.text('Unable to retrieve questionnaire.'), findsNothing);
    expect(
      find.text('The server could not load the questionnaire. Please try again.'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('assessment-retry')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));

    expect(find.text('Backend question 1'), findsOneWidget);
  });

  testWidgets('shows a network error and retries', (tester) async {
    var attempts = 0;

    final session = buildSession(
      MockClient((request) async {
        attempts++;
        if (attempts == 1) {
          throw http.ClientException('offline', request.url);
        }
        return http.Response(
          jsonEncode({'success': true, 'data': questionnairePayload()}),
          200,
        );
      }),
    );

    await pumpAssessment(tester, session);

    expect(find.textContaining('Unable to reach'), findsOneWidget);

    await tester.tap(find.byKey(const Key('assessment-retry')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));

    expect(find.text('Backend question 1'), findsOneWidget);
  });

  testWidgets('handles an empty questionnaire response', (tester) async {
    final session = buildSession(
      MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'data': questionnairePayload(count: 0),
          }),
          200,
        );
      }),
    );

    await pumpAssessment(tester, session);

    expect(find.byKey(const Key('assessment-error')), findsOneWidget);
    expect(
      find.textContaining('No questionnaire questions'),
      findsOneWidget,
    );
  });

  testWidgets('does not request a questionnaire without a selected child', (
    tester,
  ) async {
    var requests = 0;

    final session = buildSession(
      MockClient((request) async {
        requests++;
        return http.Response(
          jsonEncode({'success': true, 'data': questionnairePayload()}),
          200,
        );
      }),
    );

    await pumpAssessment(tester, session, childId: null);

    expect(
      find.text('Select a child profile before starting the assessment.'),
      findsOneWidget,
    );
    expect(requests, 0);
  });

  testWidgets('uses the backend child ID from the selected profile', (
    tester,
  ) async {
    AppState.childProfiles.add(
      ChildProfileRecord(
        id: 'server-child-77',
        childName: 'Ayaan',
        dateOfBirth: DateTime(2025, 3, 10),
        gender: 'Male',
        parentName: 'Parent',
        parentEmail: 'parent@example.com',
        relationship: '',
        phone: '',
        createdAt: DateTime(2025, 3, 10),
      ),
    );
    AppState.selectedChildProfileId = 'server-child-77';

    late Uri requested;

    final session = buildSession(
      MockClient((request) async {
        requested = request.url;
        return http.Response(
          jsonEncode({'success': true, 'data': questionnairePayload()}),
          200,
        );
      }),
    );

    await pumpAssessment(tester, session, childId: null);

    expect(
      requested.path,
      '/api/v1/assessment/questionnaire/server-child-77',
    );
  });
}
