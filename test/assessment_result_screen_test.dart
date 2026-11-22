import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ai_early_childhood_autism_risk_assessment/screens/assessment_result_screen.dart';
import 'package:ai_early_childhood_autism_risk_assessment/services/assessment_service.dart';

Map<String, dynamic> resultPayload({String concernLevel = 'low'}) => {
  'child_id': 'child-1',
  'status': 'complete',
  'concern_level': concernLevel,
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
    {'question_id': 'q3', 'answer': 'not_sure'},
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

AssessmentResult buildResult({String concernLevel = 'low'}) {
  return AssessmentResult.fromApiData(
    resultPayload(concernLevel: concernLevel),
    recordedAt: DateTime(2026, 11, 22, 14, 5),
  );
}

Future<void> pumpResult(
  WidgetTester tester,
  AssessmentResult result, {
  Map<String, String> questionTexts = const {
    'q3': 'Does your child respond to their name?',
  },
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: AssessmentResultScreen(
        childName: 'Ayaan',
        result: result,
        questionTexts: questionTexts,
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('displays a low concern result', (tester) async {
    await pumpResult(tester, buildResult(concernLevel: 'low'));

    expect(find.text('Low concern'), findsOneWidget);
    expect(find.byKey(const Key('result-concern-level')), findsOneWidget);
  });

  testWidgets('displays a moderate concern result', (tester) async {
    await pumpResult(tester, buildResult(concernLevel: 'moderate'));

    expect(find.text('Moderate concern'), findsOneWidget);
  });

  testWidgets('displays a high concern result', (tester) async {
    await pumpResult(tester, buildResult(concernLevel: 'high'));

    expect(find.text('High concern'), findsOneWidget);
  });

  testWidgets('displays child, age, percentage, score and date from the API', (
    tester,
  ) async {
    await pumpResult(tester, buildResult());

    expect(find.text('Ayaan'), findsOneWidget);
    expect(find.text('12-23 months • 20 months'), findsOneWidget);
    expect(find.text('33.3%'), findsOneWidget);
    expect(find.text('8 / 24'), findsOneWidget);
    expect(find.text('12 / 0'), findsOneWidget);
    expect(find.textContaining('22/11/2026'), findsOneWidget);
    expect(
      find.textContaining('developmental monitoring'),
      findsWidgets,
    );
  });

  testWidgets('renders domain results from the backend', (tester) async {
    await pumpResult(tester, buildResult());

    expect(find.text('Domain results'), findsOneWidget);
    expect(find.byKey(const Key('result-domain-communication')), findsOneWidget);
    expect(find.byKey(const Key('result-domain-social')), findsOneWidget);
    expect(find.text('Communication'), findsOneWidget);
    expect(find.text('Social'), findsOneWidget);
    expect(find.text('4 questions counted'), findsNWidgets(2));
  });

  testWidgets('renders parent concerns and the backend disclaimer', (
    tester,
  ) async {
    await pumpResult(tester, buildResult());

    expect(find.byKey(const Key('result-parent-concerns')), findsOneWidget);
    expect(
      find.text('Does your child respond to their name?'),
      findsOneWidget,
    );
    expect(find.text('Answer: Not sure'), findsOneWidget);
    expect(find.byKey(const Key('result-disclaimer')), findsOneWidget);
    expect(
      find.textContaining('not a diagnostic tool'),
      findsNothing,
    );
    expect(
      find.textContaining('does not replace an evaluation'),
      findsOneWidget,
    );
  });

  testWidgets('omits fields the backend did not return', (tester) async {
    final result = AssessmentResult.fromApiData({'concern_level': 'low'});

    await pumpResult(tester, result);

    expect(find.text('Low concern'), findsOneWidget);
    expect(find.text('Concern percentage'), findsNothing);
    expect(find.text('Domain results'), findsNothing);
    expect(find.byKey(const Key('result-parent-concerns')), findsNothing);
    expect(find.byKey(const Key('result-disclaimer')), findsNothing);
    expect(
      find.textContaining('not a diagnosis of autism'),
      findsOneWidget,
    );
  });

  testWidgets('back to dashboard navigates out of the result screen', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AssessmentResultScreen(
                        childName: 'Ayaan',
                        result: buildResult(),
                      ),
                    ),
                  );
                },
                child: const Text('Open result'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open result'));
    await tester.pumpAndSettle();

    expect(find.byType(AssessmentResultScreen), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('result-back')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('result-back')));
    await tester.pumpAndSettle();

    expect(find.byType(AssessmentResultScreen), findsNothing);
    expect(find.text('Open result'), findsOneWidget);
  });
}
