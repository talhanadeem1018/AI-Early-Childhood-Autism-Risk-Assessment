import 'package:flutter/foundation.dart';

import 'api_client.dart';
import 'auth_service.dart';
import 'token_storage.dart';

enum SessionStatus {
  unknown,
  restoring,
  unauthenticated,
  authenticated,
  connectionError,
}

/// Restores and validates the parent session at application startup.
///
/// Tokens are only cleared for a missing token or a 401 response. A network
/// failure leaves the stored token intact so a later retry can validate it.
class SessionService extends ChangeNotifier {
  SessionService({
    TokenStore? tokenStore,
    ApiClient? apiClient,
    AuthService? authService,
  }) : _tokens = tokenStore ?? SecureTokenStore() {
    _api = apiClient ?? ApiClient(tokenProvider: _tokens.readAccessToken);
    _auth = authService ?? AuthService(api: _api, tokens: _tokens);
  }

  static final SessionService instance = SessionService();

  final TokenStore _tokens;

  late final ApiClient _api;
  late final AuthService _auth;

  SessionStatus _status = SessionStatus.unknown;
  AuthUser? _user;
  Object? _lastError;

  SessionStatus get status => _status;

  AuthUser? get user => _user;

  Object? get lastError => _lastError;

  bool get isAuthenticated => _status == SessionStatus.authenticated;

  ApiClient get api => _api;

  AuthService get auth => _auth;

  String get connectionErrorMessage {
    final error = _lastError;

    if (error is ApiException) {
      return error.message;
    }

    return 'Unable to check your session. Please check your connection and try again.';
  }

  /// Validates a stored access token against `GET /api/v1/auth/me`.
  Future<void> restore() async {
    _status = SessionStatus.restoring;
    _lastError = null;
    notifyListeners();

    try {
      final token = await _tokens.readAccessToken();

      if (token == null || token.trim().isEmpty) {
        _user = null;
        _status = SessionStatus.unauthenticated;
        return;
      }

      final user = await _auth.me();

      if (user.id.isEmpty) {
        await _tokens.clear();
        _user = null;
        _status = SessionStatus.unauthenticated;
        return;
      }

      _user = user;
      _status = SessionStatus.authenticated;
    } on ApiException catch (error) {
      _lastError = error;

      if (error.isUnauthorized) {
        await _tokens.clear();
        _user = null;
        _status = SessionStatus.unauthenticated;
      } else {
        // Keep the token: the server may simply be unreachable.
        _user = null;
        _status = SessionStatus.connectionError;
      }
    } catch (error) {
      _lastError = error;
      _user = null;
      _status = SessionStatus.connectionError;
    } finally {
      notifyListeners();
    }
  }

  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    _lastError = null;

    final user = await _auth.login(email: email, password: password);

    _user = user;
    _status = SessionStatus.authenticated;
    notifyListeners();

    return user;
  }

  /// Clears local tokens. The backend exposes no logout endpoint.
  Future<void> logout() async {
    await _auth.logout();
    _user = null;
    _status = SessionStatus.unauthenticated;
    _lastError = null;
    notifyListeners();
  }
}
