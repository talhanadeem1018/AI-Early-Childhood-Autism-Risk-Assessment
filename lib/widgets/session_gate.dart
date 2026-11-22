import 'package:flutter/material.dart';

import '../screens/authenticated_screen.dart';
import '../screens/welcome_screen.dart';
import '../services/session_service.dart';

/// Chooses the first screen based on the stored session.
///
/// A valid session opens a real authenticated screen. The dashboard still
/// requires child data that Step 4 will load from the backend, so no dashboard
/// constructor values are invented here.
class SessionGate extends StatefulWidget {
  const SessionGate({super.key, this.session});

  final SessionService? session;

  @override
  State<SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<SessionGate> {
  late final SessionService _session;
  bool _continueToWelcome = false;

  @override
  void initState() {
    super.initState();
    _session = widget.session ?? SessionService.instance;
    _session.addListener(_handleSessionChanged);

    if (_session.status == SessionStatus.unknown) {
      _session.restore();
    }
  }

  @override
  void dispose() {
    _session.removeListener(_handleSessionChanged);
    super.dispose();
  }

  void _handleSessionChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_session.status == SessionStatus.authenticated) {
      return AuthenticatedScreen(session: _session);
    }

    if (_continueToWelcome) {
      return WelcomeScreen(session: _session);
    }

    switch (_session.status) {
      case SessionStatus.unknown:
      case SessionStatus.restoring:
        return const _SessionLoadingScreen();
      case SessionStatus.unauthenticated:
        return WelcomeScreen(session: _session);
      case SessionStatus.authenticated:
        return AuthenticatedScreen(session: _session);
      case SessionStatus.connectionError:
        return _SessionConnectionErrorScreen(
          message: _session.connectionErrorMessage,
          onRetry: () {
            setState(() => _continueToWelcome = false);
            _session.restore();
          },
          onContinue: () {
            setState(() => _continueToWelcome = true);
          },
        );
    }
  }
}

class _SessionLoadingScreen extends StatelessWidget {
  const _SessionLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF3FAF9),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Color(0xFF347F83)),
            SizedBox(height: 16),
            Text(
              'Checking your session...',
              style: TextStyle(color: Color(0xFF587477), fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionConnectionErrorScreen extends StatelessWidget {
  const _SessionConnectionErrorScreen({
    required this.message,
    required this.onRetry,
    required this.onContinue,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3FAF9),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5F3F1),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Icon(
                      Icons.cloud_off_rounded,
                      color: Color(0xFF347F83),
                      size: 38,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Unable to connect',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF235B68),
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF657D80),
                      fontSize: 13,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    'Your saved sign-in was not deleted. Check that the backend is running and the API address is correct.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF829497),
                      fontSize: 11,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh_rounded, size: 19),
                      label: const Text('Try again'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: onContinue,
                    child: const Text('Continue to welcome'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
