import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:ai_early_childhood_autism_risk_assessment/services/api_client.dart';
import 'package:ai_early_childhood_autism_risk_assessment/services/assessment_service.dart';

AssessmentService buildService(MockClient client, {String? token = 'token-1'}) {
  return AssessmentService(
    api: ApiClient(
      baseUrl: 'http://example.test',
      httpClient: client,
      tokenProvider: () async => token,
    ),
  );
}

Map<String, Object?> questionnairePayload({int totalMonths = 20}) {
  return {
    'child_id': 'child-1',
    'age': {
      'date_of_birth': '2025-03-10',
      'age_years': 1,
      'age_months': 8,
      'total_months': totalMonths,
      'age_group': '12-23 months',
    },
    'questions': [
      for (var i = 1; i <= 12; i++)
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
      {'id': 'o2', 'option_value': 'sometimes', 'option_label': 'Sometimes'},
      {'id': 'o1', 'option_value': 'usually', 'option_label': 'Usually'},
      {'id': 'o4', 'option_value': 'not_sure', 'option_label': 'Not sure'},
      {'id': 'o3', 'option_value': 'rarely', 'option_label': 'Rarely'},
    ],
  };
}

void main() {
  test('requests the selected child ID with a bearer token', () async {
    late http.Request captured;

    final service = buildService(
      MockClient((request) async {
        captured = request;
        return http.Response(
          jsonEncode({'success': true, 'data': questionnairePayload()}),
          200,
        );
      }),
    );

    await service.fetchQuestionnaire('child-42');

    expect(captured.method, 'GET');
    expect(
      captured.url.path,
      '/api/v1/assessment/questionnaire/child-42',
    );
    expect(captured.headers['Authorization'], 'Bearer token-1');
  });

  test('parses 12 questions with IDs, text and domains', () async {
    final service = buildService(
      MockClient((request) async {
        return http.Response(
          jsonEncode({'success': true, 'data': questionnairePayload()}),
          200,
        );
      }),
    );

    final questionnaire = await service.fetchQuestionnaire('child-1');

    expect(questionnaire.childId, 'child-1');
    expect(questionnaire.totalMonths, 20);
    expect(questionnaire.ageGroup, '12-23 months');
    expect(questionnaire.questions, hasLength(12));
    expect(questionnaire.questions.first.id, 'q1');
    expect(questionnaire.questions.first.text, 'Backend question 1');
    expect(questionnaire.questions.first.domain, 'communication');
    expect(questionnaire.questions[1].domain, 'social');
  });

  test('uses backend option values and labels in canonical order', () async {
    final service = buildService(
      MockClient((request) async {
        return http.Response(
          jsonEncode({'success': true, 'data': questionnairePayload()}),
          200,
        );
      }),
    );

    final questionnaire = await service.fetchQuestionnaire('child-1');

    expect(
      questionnaire.options.map((option) => option.value).toList(),
      ['usually', 'sometimes', 'rarely', 'not_sure'],
    );
    expect(
      questionnaire.options.map((option) => option.label).toList(),
      ['Usually', 'Sometimes', 'Rarely', 'Not sure'],
    );
  });

  test('derives a readable label when the backend has no label column',
      () async {
    final payload = questionnairePayload();
    payload['answer_options'] = [
      {'id': 'o1', 'option_value': 'usually'},
      {'id': 'o4', 'option_value': 'not_sure'},
    ];

    final service = buildService(
      MockClient((request) async {
        return http.Response(
          jsonEncode({'success': true, 'data': payload}),
          200,
        );
      }),
    );

    final questionnaire = await service.fetchQuestionnaire('child-1');

    expect(questionnaire.options.first.label, 'Usually');
    expect(questionnaire.options.last.label, 'Not sure');
  });

  test('surfaces a network failure', () async {
    final service = buildService(
      MockClient((request) async {
        throw http.ClientException('offline', request.url);
      }),
    );

    await expectLater(
      service.fetchQuestionnaire('child-1'),
      throwsA(
        isA<ApiException>()
            .having((e) => e.statusCode, 'statusCode', 0)
            .having((e) => e.message, 'message', contains('Unable to reach')),
      ),
    );
  });

  test('surfaces a backend error message', () async {
    final service = buildService(
      MockClient((request) async {
        return http.Response(
          jsonEncode({
            'detail': 'Child not found or you do not have permission.',
          }),
          422,
        );
      }),
    );

    await expectLater(
      service.fetchQuestionnaire('child-1'),
      throwsA(
        isA<ApiException>()
            .having((e) => e.statusCode, 'statusCode', 422)
            .having(
              (e) => e.message,
              'message',
              'Child not found or you do not have permission.',
            ),
      ),
    );
  });

  test('rejects an empty question list', () async {
    final payload = questionnairePayload();
    payload['questions'] = <Object>[];

    final service = buildService(
      MockClient((request) async {
        return http.Response(
          jsonEncode({'success': true, 'data': payload}),
          200,
        );
      }),
    );

    await expectLater(
      service.fetchQuestionnaire('child-1'),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'message',
          contains('No questionnaire questions'),
        ),
      ),
    );
  });

  test('rejects a response with no answer options', () async {
    final payload = questionnairePayload();
    payload['answer_options'] = <Object>[];

    final service = buildService(
      MockClient((request) async {
        return http.Response(
          jsonEncode({'success': true, 'data': payload}),
          200,
        );
      }),
    );

    await expectLater(
      service.fetchQuestionnaire('child-1'),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'message',
          contains('No answer options'),
        ),
      ),
    );
  });

  test('rejects an unexpected envelope', () async {
    final service = buildService(
      MockClient((request) async {
        return http.Response(
          jsonEncode({'success': true, 'data': <Object>[]}),
          200,
        );
      }),
    );

    await expectLater(
      service.fetchQuestionnaire('child-1'),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'message',
          contains('unexpected questionnaire'),
        ),
      ),
    );
  });

  group('submitAssessment', () {
    Map<String, Object?> resultPayload() => {
      'child_id': 'child-1',
      'status': 'complete',
      'concern_level': 'moderate',
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
        'social': {'concern_percentage': 16.67, 'counted_questions': 4},
      },
      'parent_concerns': [
        {'question_id': 'q12', 'answer': 'rarely'},
      ],
      'disclaimer':
          'This assessment is for developmental monitoring and early '
          'identification of concerns.',
      'age': {
        'age_years': 1,
        'age_months': 8,
        'total_months': 20,
        'age_group': '12-23 months',
      },
    };

    test('posts the real child ID, all answers and the bearer token', () async {
      late http.Request captured;

      final service = buildService(
        MockClient((request) async {
          captured = request;
          return http.Response(
            jsonEncode({'success': true, 'data': resultPayload()}),
            200,
          );
        }),
      );

      final answers = {
        for (var i = 1; i <= 12; i++) 'q$i': 'usually',
      };

      await service.submitAssessment(
        childId: 'child-42',
        answers: answers,
      );

      expect(captured.method, 'POST');
      expect(captured.url.path, '/api/v1/assessment/submit');
      expect(captured.headers['Authorization'], 'Bearer token-1');

      final body = jsonDecode(captured.body) as Map<String, dynamic>;
      expect(body['child_id'], 'child-42');
      expect(body['answers'], answers);
    });

    test('parses the backend-scored result', () async {
      final service = buildService(
        MockClient((request) async {
          return http.Response(
            jsonEncode({'success': true, 'data': resultPayload()}),
            200,
          );
        }),
      );

      final result = await service.submitAssessment(
        childId: 'child-1',
        answers: {'q1': 'usually'},
      );

      expect(result.childId, 'child-1');
      expect(result.concernLevel, 'moderate');
      expect(result.concernPercentage, 33.33);
      expect(result.totalScore, 8);
      expect(result.maximumScore, 24);
      expect(result.countedAnswers, 12);
      expect(result.notSureAnswers, 0);
      expect(result.ageGroup, '12-23 months');
      expect(result.totalMonths, 20);
      expect(result.domains, hasLength(2));
      expect(result.domains.first.domain, 'communication');
      expect(result.domains.first.concernPercentage, 50.0);
      expect(result.domains.first.countedQuestions, 4);
      expect(result.parentConcerns.single.questionId, 'q12');
      expect(result.parentConcerns.single.answer, 'rarely');
      expect(result.disclaimer, contains('developmental monitoring'));
    });

    test('tolerates missing optional result fields', () async {
      final service = buildService(
        MockClient((request) async {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {'concern_level': 'low'},
            }),
            200,
          );
        }),
      );

      final result = await service.submitAssessment(
        childId: 'child-1',
        answers: {'q1': 'usually'},
      );

      expect(result.concernLevel, 'low');
      expect(result.concernPercentage, isNull);
      expect(result.totalScore, isNull);
      expect(result.domains, isEmpty);
      expect(result.parentConcerns, isEmpty);
      expect(result.disclaimer, isEmpty);
    });

    test('rejects a result without a concern level', () async {
      final service = buildService(
        MockClient((request) async {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {'total_score': 3},
            }),
            200,
          );
        }),
      );

      await expectLater(
        service.submitAssessment(childId: 'child-1', answers: {}),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            contains('without a concern level'),
          ),
        ),
      );
    });

    test('surfaces a 422 validation error', () async {
      final service = buildService(
        MockClient((request) async {
          return http.Response(
            jsonEncode({
              'detail': 'Please answer every question exactly once.',
            }),
            422,
          );
        }),
      );

      await expectLater(
        service.submitAssessment(childId: 'child-1', answers: {'q1': 'usually'}),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 422)
              .having(
                (e) => e.message,
                'message',
                'Please answer every question exactly once.',
              ),
        ),
      );
    });

    test('surfaces a network failure', () async {
      final service = buildService(
        MockClient((request) async {
          throw http.ClientException('offline', request.url);
        }),
      );

      await expectLater(
        service.submitAssessment(childId: 'child-1', answers: {}),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 0)),
      );
    });
  });

  group('fetchHistory', () {
    Map<String, Object?> historyRow({
      String id = 'h1',
      String level = 'moderate',
      String createdAt = '2026-11-22T10:30:00',
      bool minimal = false,
    }) => {
      'id': id,
      'child_id': 'child-1',
      'created_at': createdAt,
      'child_name': 'Ayaan',
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
        'disclaimer': 'Not a diagnostic tool.',
      } else ...{'concern_level': level},
    };

    test('requests the selected child history with a bearer token', () async {
      late http.Request captured;

      final service = buildService(
        MockClient((request) async {
          captured = request;
          return http.Response(
            jsonEncode({'success': true, 'data': <Object>[]}),
            200,
          );
        }),
      );

      await service.fetchHistory('child-42');

      expect(captured.method, 'GET');
      expect(
        captured.url.path,
        '/api/v1/assessment/history/child-42',
      );
      expect(captured.headers['Authorization'], 'Bearer token-1');
    });

    test('parses saved rows into history entries', () async {
      final service = buildService(
        MockClient((request) async {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': [historyRow()],
            }),
            200,
          );
        }),
      );

      final entries = await service.fetchHistory('child-1');

      expect(entries, hasLength(1));

      final entry = entries.single;
      expect(entry.id, 'h1');
      expect(entry.childId, 'child-1');
      expect(entry.createdAt, DateTime(2026, 11, 22, 10, 30));
      expect(entry.answers, {'q1': 'usually', 'q12': 'rarely'});
      expect(entry.result.concernLevel, 'moderate');
      expect(entry.result.concernPercentage, 33.33);
      expect(entry.result.totalScore, 8);
      expect(entry.result.maximumScore, 24);
      expect(entry.result.ageGroup, '12-23 months');
      expect(entry.result.totalMonths, 20);
      expect(entry.result.domains.single.domain, 'communication');
      expect(entry.result.parentConcerns.single.questionId, 'q12');
    });

    test('sorts newest first even if the response is unordered', () async {
      final service = buildService(
        MockClient((request) async {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': [
                historyRow(
                  id: 'older',
                  createdAt: '2026-11-01T08:00:00',
                ),
                historyRow(
                  id: 'newer',
                  createdAt: '2026-11-20T08:00:00',
                ),
              ],
            }),
            200,
          );
        }),
      );

      final entries = await service.fetchHistory('child-1');

      expect(entries.map((entry) => entry.id).toList(), ['newer', 'older']);
    });

    test('handles missing optional fields', () async {
      final service = buildService(
        MockClient((request) async {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': [historyRow(level: 'low', minimal: true)],
            }),
            200,
          );
        }),
      );

      final entries = await service.fetchHistory('child-1');

      expect(entries.single.result.concernLevel, 'low');
      expect(entries.single.result.concernPercentage, isNull);
      expect(entries.single.result.totalScore, isNull);
      expect(entries.single.result.domains, isEmpty);
      expect(entries.single.answers, isEmpty);
    });

    test('rejects an unexpected history envelope', () async {
      final service = buildService(
        MockClient((request) async {
          return http.Response(
            jsonEncode({'success': true, 'data': {'rows': []}}),
            200,
          );
        }),
      );

      await expectLater(
        service.fetchHistory('child-1'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            contains('unexpected assessment history'),
          ),
        ),
      );
    });

    test('surfaces a backend error', () async {
      final service = buildService(
        MockClient((request) async {
          return http.Response(
            jsonEncode({'detail': 'Unable to retrieve assessment history.'}),
            500,
          );
        }),
      );

      await expectLater(
        service.fetchHistory('child-1'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 500)
              .having(
                (e) => e.message,
                'message',
                'Unable to retrieve assessment history.',
              ),
        ),
      );
    });
  });
}
