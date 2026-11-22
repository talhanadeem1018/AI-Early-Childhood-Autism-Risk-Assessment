import 'package:flutter/material.dart';

import 'services/session_service.dart';
import 'widgets/session_gate.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.session});

  /// Optional injection point used by tests; production uses the singleton.
  final SessionService? session;

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NurtureSteps',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: SessionGate(session: session),
    );
  }
}
