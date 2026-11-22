import 'package:ai_early_childhood_autism_risk_assessment/services/token_storage.dart';

class FakeTokenStore implements TokenStore {
  String? accessToken;
  String? refreshToken;
  bool cleared = false;

  @override
  Future<String?> readAccessToken() async => accessToken;

  @override
  Future<String?> readRefreshToken() async => refreshToken;

  @override
  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    this.accessToken = accessToken;
    this.refreshToken = refreshToken;
    cleared = false;
  }

  @override
  Future<void> clear() async {
    accessToken = null;
    refreshToken = null;
    cleared = true;
  }
}
