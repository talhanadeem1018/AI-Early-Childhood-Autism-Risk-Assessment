import 'package:flutter_test/flutter_test.dart';

import 'package:ai_early_childhood_autism_risk_assessment/main.dart';
import 'package:ai_early_childhood_autism_risk_assessment/screens/welcome_screen.dart';
import 'package:ai_early_childhood_autism_risk_assessment/services/api_client.dart';
import 'package:ai_early_childhood_autism_risk_assessment/services/session_service.dart';

import 'helpers/fake_token_store.dart';

void main() {
  testWidgets('App launches on the WelcomeScreen', (WidgetTester tester) async {
    final store = FakeTokenStore();
    final session = SessionService(
      tokenStore: store,
      apiClient: ApiClient(
        baseUrl: 'http://example.test',
        tokenProvider: store.readAccessToken,
      ),
    );
    await session.restore();

    await tester.pumpWidget(MyApp(session: session));
    await tester.pump();

    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
  });
}
