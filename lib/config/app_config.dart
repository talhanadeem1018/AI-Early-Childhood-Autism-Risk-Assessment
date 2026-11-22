import 'package:flutter/foundation.dart';

/// Runtime configuration for the FastAPI backend.
///
/// The backend runs with Uvicorn's default host and port:
/// `127.0.0.1:8000` on the development machine.
///
/// Development URLs:
/// - Android emulator: `http://10.0.2.2:8000` (the emulator alias for the host)
/// - Physical Android device: `http://<development-machine-LAN-IP>:8000`
///   Start Uvicorn with `--host 0.0.0.0` and keep the phone and computer on the
///   same network. Do not use `127.0.0.1` from a physical device.
/// - iOS simulator, desktop, web: `http://127.0.0.1:8000`
///
/// Override the base URL without editing source:
/// `flutter run --dart-define=API_BASE_URL=http://192.168.1.50:8000`
///
/// No production URL is assumed or hardcoded.
class AppConfig {
  AppConfig._();

  /// Shared prefix used by every backend router.
  static const String apiPrefix = '/api/v1';

  static const String _configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
  );

  static String get apiBaseUrl {
    if (_configuredBaseUrl.isNotEmpty) {
      return _configuredBaseUrl;
    }

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }

    return 'http://127.0.0.1:8000';
  }
}
