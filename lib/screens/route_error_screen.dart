// lib/screens/route_error_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cecelia_care_flutter/l10n/app_localizations.dart';

class RouteErrorScreen extends StatelessWidget {
  final String message;
  final String? buttonText;
  final String? routeToNavigateTo;

  const RouteErrorScreen({
    super.key,
    required this.message,
    this.buttonText,
    this.routeToNavigateTo,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context); // Get the theme for consistent styling

    return Scaffold(
      appBar: AppBar(
        // Using a more specific key for the title is clearer.
        title: Text(l10n.errorTitle),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                // --- STYLE UPDATE ---
                // Replaced hardcoded color with a theme-based color.
                color: theme.colorScheme.error,
                size: 60,
              ),
              const SizedBox(height: 20),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 30),
              if (buttonText != null && routeToNavigateTo != null)
                ElevatedButton(
                  onPressed: () => GoRouter.of(context).go(routeToNavigateTo!),
                  child: Text(buttonText!),
                )
              else
                ElevatedButton(
                  onPressed: () {
                    if (GoRouter.of(context).canPop()) {
                      GoRouter.of(context).pop();
                    } else {
                      GoRouter.of(context).go('/'); // Fallback to home
                    }
                  },
                  child: Text(l10n.okButton),
                ),
            ],
          ),
        ),
      ),
    );
  }
}