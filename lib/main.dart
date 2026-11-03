import 'package:flutter/material.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'services/api.dart';

void main() => runApp(const SalonApp());

class SalonApp extends StatelessWidget {
  const SalonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Salon Booking',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF8E3B72),
      ),
      home: const AuthGate(),
    );
  }
}

/// Shows the login screen or the app depending on the (demo) sign-in state.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: Auth.signedIn,
      builder: (context, signedIn, _) =>
          signedIn ? const HomeScreen() : const AuthScreen(),
    );
  }
}
