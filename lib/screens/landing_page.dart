// lib/screens/landing_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import 'signup_screen.dart';
// Import your AppLocalizations
import 'package:cecelia_care_flutter/l10n/app_localizations.dart';
// Or if it's generated in dart_tool:
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';

// AppTheme and AppStyles are not directly used for text here but kept for consistency
// import 'package:cecelia_care_flutter/utils/app_theme.dart';
// import 'package:cecelia_care_flutter/utils/app_styles.dart';

/// This widget listens to FirebaseAuth.authStateChanges() and:
///  • If still waiting for Firebase to initialize, shows a spinner.
///  • If the user is already signed in, shows a placeholder “Home” screen
///    (you can replace this later with your actual tab/home widget).
///  • If the user is not signed in, pushes the LoginScreen.
class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!; // Get AppLocalizations instance

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Still checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // If signed in, show a placeholder “already signed in” page
        if (snapshot.hasData) {
          return Scaffold(
            body: Center(
              child: Text(
                l10n.landingPageAlreadyLoggedIn, // Localized string
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                ), // Consider moving to AppStyles if used elsewhere
              ),
            ),
          );
        }

        // Otherwise, show the login screen
        // LoginScreen and SignUpScreen will handle their own internal localization
        return LoginScreen(
          onNavigateToSignUp: () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const SignUpScreen()));
          },
        );
      },
    );
  }
}
