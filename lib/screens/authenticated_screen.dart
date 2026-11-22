import 'package:flutter/material.dart';

import '../services/session_service.dart';
import 'child_profile_screen.dart';

/// Authenticated shell.
///
/// A successful login lands on child selection/creation, which is the first
/// screen that needs a real backend session. The child profile screen also
/// hosts the logout action.
class AuthenticatedScreen extends StatelessWidget {
  const AuthenticatedScreen({super.key, required this.session});

  final SessionService session;

  @override
  Widget build(BuildContext context) {
    return ChildProfileScreen(
      session: session,
      parentEmail: session.user?.email ?? '',
      onLogout: session.logout,
    );
  }
}
