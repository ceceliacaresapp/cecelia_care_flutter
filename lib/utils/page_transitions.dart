// lib/utils/page_transitions.dart
//
// Custom page route transitions for polished screen-to-screen navigation.
//
//   • FadeSlideRoute — fade + 30px upward slide (default for push nav)
//   • FadeRoute — simple crossfade (for tab-style switches)
//
// Usage:
//   Navigator.push(context, FadeSlideRoute(page: const SomeScreen()));

import 'package:flutter/material.dart';

/// Fade-in + slide-up from 30px below. The standard push transition for
/// all tile/button navigations in the app.
class FadeSlideRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  FadeSlideRoute({
    required this.page,
    super.settings,
    super.fullscreenDialog,
  }) : super(
          pageBuilder: (_, __, ___) => page,
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 250),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final fade = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            );
            final slide = Tween<Offset>(
              begin: const Offset(0, 0.06), // ~30px on a 500px screen
              end: Offset.zero,
            ).animate(fade);

            return FadeTransition(
              opacity: fade,
              child: SlideTransition(
                position: slide,
                child: child,
              ),
            );
          },
        );
}

/// Simple crossfade — no slide. Used for lighter transitions like tab
/// content swaps or modal replacements.
class FadeRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  FadeRoute({
    required this.page,
    super.settings,
    super.fullscreenDialog,
  }) : super(
          pageBuilder: (_, __, ___) => page,
          transitionDuration: const Duration(milliseconds: 250),
          reverseTransitionDuration: const Duration(milliseconds: 200),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              ),
              child: child,
            );
          },
        );
}
