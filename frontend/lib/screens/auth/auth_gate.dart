import 'package:flutter/material.dart';
import 'package:medischedule/application/application_shell.dart';
import 'package:medischedule/screens/auth/login_screen.dart';
import 'package:medischedule/services/api_client.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    ApiClient.loggedIn.addListener(returnToRoot);
  }

  @override
  void dispose() {
    ApiClient.loggedIn.removeListener(returnToRoot);
    super.dispose();
  }

  void returnToRoot() {
    if (ApiClient.loggedIn.value) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ApiClient.loggedIn,
      builder: (context, loggedIn, _) {
        if (loggedIn) return const ApplicationShell();
        return LoginScreen(onLoginSuccess: () {});
      },
    );
  }
}