import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart'; // Corrected import

import '../l10n/app_localizations.dart';
import '../locator.dart';
import '../providers/active_elder_provider.dart';
import '../providers/medication_provider.dart';
import '../screens/caregiver_journal/caregiver_journal_screen.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/medications/medication_manager_screen.dart';
import '../screens/medications_screen.dart';
import '../screens/route_error_screen.dart';
import '../screens/settings_screen.dart';
import '../services/firestore_service.dart';
import '../services/rxnav_service.dart';

/// A stream-based helper to make GoRouter reactive to state changes, like authentication.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
          (dynamic _) => notifyListeners(),
        );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

/// Centralized navigation configuration for the entire application.
///
/// This class uses the `go_router` package to define all routes, handle
/// authentication-based redirects, and manage route-level state providers.
class AppRouter {
  final _logger = Logger();

  late final GoRouter router = GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,

    // Rebuilds the router's state when the user's auth state changes.
    refreshListenable:
        GoRouterRefreshStream(FirebaseAuth.instance.authStateChanges()),

    // Handles redirects based on authentication status.
    redirect: (BuildContext context, GoRouterState state) {
      final bool loggedIn = FirebaseAuth.instance.currentUser != null;
      final bool isPublicRoute = state.uri.toString() == '/login';

      if (!loggedIn && !isPublicRoute) {
        return '/login'; // Redirect to login if not authenticated.
      }
      if (loggedIn && isPublicRoute) {
        return '/'; // Redirect from login to home if already authenticated.
      }
      return null; // No redirect needed.
    },

    // Defines all application routes.
    routes: [
      GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/medications-list',
        pageBuilder: (context, state) {
          final l10n = AppLocalizations.of(context)!;
          final activeElder =
              Provider.of<ActiveElderProvider>(context, listen: false)
                  .activeElder;

          if (activeElder == null) {
            return MaterialPage(
              child: RouteErrorScreen(
                message: l10n.settingsNoActiveElderSelected,
                buttonText: l10n.goToSettingsButton,
                routeToNavigateTo: '/settings',
              ),
            );
          }

          // Provides MedicationProvider scoped specifically to this route.
          return MaterialPage(
            child: ChangeNotifierProvider<MedicationProvider>(
              create: (context) => MedicationProvider(
                elderId: activeElder.id,
                firestoreService: context.read<FirestoreService>(),
                rxNavService: locator<RxNavService>(),
              ),
              child: const MedicationsScreen(),
            ),
          );
        },
      ),
      GoRoute(
        path: '/medications',
        pageBuilder: (context, state) {
          final l10n = AppLocalizations.of(context)!;
          final String? elderId = state.extra as String?;

          if (elderId == null || elderId.isEmpty) {
            _logger.w(
                "Route '/medications': elderId is missing from state.extra.");
            return MaterialPage(
              child: RouteErrorScreen(
                message: l10n.errorElderIdMissing,
                buttonText: l10n.goToSettingsButton,
                routeToNavigateTo: '/settings',
              ),
            );
          }

          return MaterialPage(
            child: ChangeNotifierProvider<MedicationProvider>(
              create: (context) => MedicationProvider(
                elderId: elderId,
                firestoreService: context.read<FirestoreService>(),
                rxNavService: locator<RxNavService>(),
              ),
              child: const MedicationManagerScreen(),
            ),
          );
        },
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) {
          return SettingsScreen(
            navigateToManageCareRecipientProfiles: () =>
                context.push('/manage-profiles'),
          );
        },
      ),
      GoRoute(
        path: '/caregiver-journal',
        name: 'caregiver-journal',
        builder: (context, state) => const CareGiverJournalScreen(),
      ),
      // TODO: Define '/manage-profiles' route if needed by SettingsScreen.
    ],

    // Defines the screen to show when a route is not found.
    errorBuilder: (context, state) {
      _logger.e('Routing error: ${state.error}', error: state.error);
      final l10n = AppLocalizations.of(context);
      return RouteErrorScreen(
        message:
            l10n?.routeErrorGenericMessage ?? 'An unexpected error occurred.',
        buttonText: l10n?.goHomeButton ?? 'Go Home',
        routeToNavigateTo: '/',
      );
    },
  );
}