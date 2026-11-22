import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:ai_early_childhood_autism_risk_assessment/screens/child_profile_screen.dart';
import 'package:ai_early_childhood_autism_risk_assessment/services/api_client.dart';
import 'package:ai_early_childhood_autism_risk_assessment/services/child_service.dart';

ChildService buildService(MockClient client, {String? token = 'token-1'}) {
  return ChildService(
    api: ApiClient(
      baseUrl: 'http://example.test',
      httpClient: client,
      tokenProvider: () async => token,
    ),
  );
}

void main() {
  group('ChildService.fetchChildren', () {
    test('parses children and sends the bearer token', () async {
      late http.Request captured;

      final service = buildService(
        MockClient((request) async {
          captured = request;
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'Children retrieved successfully.',
              'data': [
                {
                  'id': 'child-1',
                  'parent_id': 'parent-1',
                  'child_name': 'Ayaan',
                  'date_of_birth': '2024-05-10',
                  'gender': 'Male',
                  'created_at': '2024-05-10T12:34:56Z',
                },
              ],
            }),
            200,
          );
        }),
      );

      final children = await service.fetchChildren();

      expect(captured.url.path, '/api/v1/children/');
      expect(captured.method, 'GET');
      expect(captured.headers['Authorization'], 'Bearer token-1');
      expect(children, hasLength(1));
      expect(children.single.id, 'child-1');
      expect(children.single.childName, 'Ayaan');
      expect(children.single.dateOfBirth, DateTime(2024, 5, 10));
      expect(children.single.gender, 'Male');
      expect(children.single.createdAt, DateTime(2024, 5, 10));
    });

    test('returns an empty list when the parent has no children', () async {
      final service = buildService(
        MockClient((request) async {
          return http.Response(
            jsonEncode({'success': true, 'data': <Object>[]}),
            200,
          );
        }),
      );

      expect(await service.fetchChildren(), isEmpty);
    });

    test('surfaces a network failure', () async {
      final service = buildService(
        MockClient((request) async {
          throw http.ClientException('offline', request.url);
        }),
      );

      await expectLater(
        service.fetchChildren(),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 0)
              .having((e) => e.message, 'message', contains('Unable to reach')),
        ),
      );
    });

    test('surfaces a backend error', () async {
      final service = buildService(
        MockClient((request) async {
          return http.Response(
            jsonEncode({'detail': 'Unable to retrieve children.'}),
            500,
          );
        }),
      );

      await expectLater(
        service.fetchChildren(),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 500)
              .having(
                (e) => e.message,
                'message',
                'Unable to retrieve children.',
              ),
        ),
      );
    });
  });

  group('ChildService.createChild', () {
    test('posts the verified backend fields and parses the created child',
        () async {
      late http.Request captured;

      final service = buildService(
        MockClient((request) async {
          captured = request;
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'Child profile created successfully.',
              'data': {
                'id': 'child-2',
                'parent_id': 'parent-1',
                'child_name': 'Hira',
                'date_of_birth': '2025-01-09',
                'gender': 'female',
              },
            }),
            200,
          );
        }),
      );

      final child = await service.createChild(
        childName: 'Hira',
        dateOfBirth: DateTime(2025, 1, 9),
        gender: 'female',
      );

      expect(captured.method, 'POST');
      expect(captured.url.path, '/api/v1/children/');
      expect(captured.headers['Authorization'], 'Bearer token-1');

      final body = jsonDecode(captured.body) as Map<String, dynamic>;
      expect(body['child_name'], 'Hira');
      expect(body['date_of_birth'], '2025-01-09');
      expect(body['gender'], 'female');
      expect(body.containsKey('parent_id'), isFalse);

      expect(child.id, 'child-2');
      expect(child.childName, 'Hira');
      expect(child.dateOfBirth, DateTime(2025, 1, 9));
    });

    test('sends the exact backend gender code for every option', () async {
      for (final gender in childGenderValues) {
        late http.Request captured;

        final service = buildService(
          MockClient((request) async {
            captured = request;
            return http.Response(
              jsonEncode({
                'success': true,
                'data': {
                  'id': 'child-g',
                  'child_name': 'Sara',
                  'date_of_birth': '2025-03-04',
                  'gender': gender,
                },
              }),
              200,
            );
          }),
        );

        await service.createChild(
          childName: 'Sara',
          dateOfBirth: DateTime(2025, 3, 4),
          gender: gender,
        );

        final body = jsonDecode(captured.body) as Map<String, dynamic>;
        expect(body['gender'], gender);
      }

      expect(childGenderValues, ['male', 'female', 'prefer_not_to_say']);
    });

    test('omits gender when it was not provided', () async {
      late http.Request captured;

      final service = buildService(
        MockClient((request) async {
          captured = request;
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'id': 'child-3',
                'child_name': 'Ali',
                'date_of_birth': '2025-02-01',
              },
            }),
            200,
          );
        }),
      );

      await service.createChild(
        childName: 'Ali',
        dateOfBirth: DateTime(2025, 2, 1),
      );

      final body = jsonDecode(captured.body) as Map<String, dynamic>;
      expect(body.containsKey('gender'), isFalse);
    });

    test('surfaces a creation failure', () async {
      final service = buildService(
        MockClient((request) async {
          return http.Response(
            jsonEncode({'detail': 'Unable to create child profile.'}),
            400,
          );
        }),
      );

      await expectLater(
        service.createChild(
          childName: 'Ali',
          dateOfBirth: DateTime(2025, 2, 1),
        ),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 400)
              .having(
                (e) => e.message,
                'message',
                'Unable to create child profile.',
              ),
        ),
      );
    });
  });

  group('age calculation', () {
    final now = DateTime(2026, 11, 22);

    test('counts whole months only after the same day of month', () {
      expect(ageInMonths(DateTime(2025, 11, 22), now: now), 12);
      expect(ageInMonths(DateTime(2025, 11, 23), now: now), 11);
      expect(ageInMonths(DateTime(2024, 5, 10), now: now), 30);
    });

    test('formats a readable age', () {
      expect(formatAgeLabel(DateTime(2025, 11, 22), now: now), '1 years old');
      expect(
        formatAgeLabel(DateTime(2025, 8, 22), now: now),
        '1 years, 3 months old',
      );
      expect(formatAgeLabel(DateTime(2026, 5, 22), now: now), '6 months old');
    });

    test('subtractMonths clamps short months', () {
      expect(subtractMonths(DateTime(2026, 3, 31), 1), DateTime(2026, 2, 28));
      expect(subtractMonths(DateTime(2026, 11, 22), 60), DateTime(2021, 11, 22));
    });
  });

  group('date of birth validation', () {
    final now = DateTime(2026, 11, 22);

    test('rejects a future date', () {
      expect(
        ChildProfileScreen.validateDateOfBirth(
          DateTime(2026, 11, 23),
          now: now,
        ),
        'A future date of birth is not allowed',
      );
    });

    test('rejects a child older than 60 months', () {
      expect(
        ChildProfileScreen.validateDateOfBirth(
          DateTime(2021, 10, 22),
          now: now,
        ),
        'This app supports children aged 0 to 60 months only',
      );
    });

    test('accepts children within 0 to 60 months', () {
      expect(
        ChildProfileScreen.validateDateOfBirth(
          DateTime(2021, 11, 22),
          now: now,
        ),
        isNull,
      );
      expect(
        ChildProfileScreen.validateDateOfBirth(now, now: now),
        isNull,
      );
    });

    test('rejects a missing date', () {
      expect(
        ChildProfileScreen.validateDateOfBirth(null, now: now),
        'Please select the child’s date of birth',
      );
    });
  });
}
