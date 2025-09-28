// lib/src/app.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:naihydro/src/features/auth/presentation/data/auth_service.dart';
import 'package:naihydro/src/features/auth/presentation/home_page.dart';
import 'features/auth/presentation/landing_page.dart';
import 'features/auth/presentation/login_page.dart';
import 'features/auth/presentation/signup_page.dart';


class NaiHydroApp extends StatelessWidget {
  const NaiHydroApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Single AuthService injected across pages (simple DI)
    final authService = AuthService();

    return MaterialApp(
      title: 'NaiHydro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      home: AuthGate(authService: authService),
    );
  }
}

/// AuthGate listens to Firebase auth changes and shows Home when signed in.
/// If signed out, it shows LandingPage and allows navigation to Login / Signup.
class AuthGate extends StatelessWidget {
  final AuthService authService;
  const AuthGate({required this.authService, super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // waiting for auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final user = snapshot.data;
        if (user != null) {
          // Signed in -> show Home
          return HomePage(
            authService: authService,
            onSignOut: () async {
              await authService.signOut();
            },
          );
        }

        // Signed out -> Landing
        return LandingPage(
          onSignUp: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => SignupPage(
                onSuccess: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => HomePage(authService: authService, onSignOut: () async => await authService.signOut()),
                  ),
                ),
                onBack: () => Navigator.of(context).pop(),
              ),
            ));
          },
          onLogin: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => LoginPage(
                authService: authService,
                onSuccess: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => HomePage(authService: authService, onSignOut: () async => await authService.signOut()),
                  ),
                ),
                onBack: () => Navigator.of(context).pop(),
              ),
            ));
          },
        );
      },
    );
  }
}
