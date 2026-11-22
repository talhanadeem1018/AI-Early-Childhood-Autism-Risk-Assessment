import '../config/app_config.dart';
import 'api_client.dart';
import 'token_storage.dart';

class AuthUser {
  const AuthUser({required this.id, required this.email});

  final String id;
  final String email;

  factory AuthUser.fromApiData(Map<String, dynamic> data) {
    return AuthUser(
      id: (data['user_id'] ?? '').toString(),
      email: (data['email'] ?? '').toString(),
    );
  }
}

class RegisterResult {
  const RegisterResult({
    required this.userId,
    required this.email,
    required this.emailVerificationRequired,
  });

  final String userId;
  final String email;
  final bool emailVerificationRequired;
}

/// Parent authentication through the existing backend endpoints.
class AuthService {
  AuthService({required ApiClient api, required TokenStore tokens})
    : _api = api,
      _tokens = tokens;

  final ApiClient _api;
  final TokenStore _tokens;

  Future<RegisterResult> register({
    required String email,
    required String password,
  }) async {
    final response = await _api.post(
      '${AppConfig.apiPrefix}/auth/register',
      body: {'email': email, 'password': password},
      authenticated: false,
    );

    final data = _requireData(response);

    return RegisterResult(
      userId: (data['user_id'] ?? '').toString(),
      email: (data['email'] ?? '').toString(),
      emailVerificationRequired: data['email_verification_required'] == true,
    );
  }

  /// Logs in and stores the returned Supabase tokens securely.
  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    final response = await _api.post(
      '${AppConfig.apiPrefix}/auth/login',
      body: {'email': email, 'password': password},
      authenticated: false,
    );

    final data = _requireData(response);
    final accessToken = (data['access_token'] ?? '').toString();
    final refreshToken = (data['refresh_token'] ?? '').toString();

    if (accessToken.isEmpty) {
      throw const ApiException(
        0,
        'Login succeeded but no access token was returned.',
      );
    }

    await _tokens.saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken.isEmpty ? null : refreshToken,
    );

    return AuthUser.fromApiData(data);
  }

  Future<AuthUser> me() async {
    final response = await _api.get('${AppConfig.apiPrefix}/auth/me');
    return AuthUser.fromApiData(_requireData(response));
  }

  Future<void> logout() {
    return _tokens.clear();
  }

  Map<String, dynamic> _requireData(Map<String, dynamic> response) {
    final data = response['data'];

    if (data is Map<String, dynamic>) {
      return data;
    }

    throw const ApiException(0, 'The server returned an unexpected response.');
  }
}
