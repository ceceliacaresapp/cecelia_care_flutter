// lib/widgets/confetti_overlay.dart
//
// Reusable confetti overlay. Wrap any subtree (typically the app Scaffold)
// and call ConfettiOverlay.trigger(context) from anywhere below to fire
// a celebration burst from the top center.
//
// Uses the `confetti` package (^0.7.0).

import 'package:cecelia_care_flutter/utils/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';

// ---------------------------------------------------------------------------
// InheritedWidget so descendants can find the overlay without a global key.
// ---------------------------------------------------------------------------
class _ConfettiScope extends InheritedWidget {
  const _ConfettiScope({
    required this.controller,
    required super.child,
  });

  final ConfettiController controller;

  /// Uses findAncestorWidgetOfExactType instead of
  /// dependOnInheritedWidgetOfExactType to avoid registering a dependency.
  /// This prevents the '_dependents.isEmpty' assertion error when the
  /// calling widget is being disposed during navigation transitions.
  static _ConfettiScope? of(BuildContext context) {
    return context.findAncestorWidgetOfExactType<_ConfettiScope>();
  }

  @override
  bool updateShouldNotify(_ConfettiScope old) => controller != old.controller;
}

// ---------------------------------------------------------------------------
// ConfettiOverlay — wraps a child with a Stack containing a ConfettiWidget
// anchored to the top center. The blast shoots downward in a cone.
// ---------------------------------------------------------------------------
class ConfettiOverlay extends StatefulWidget {
  const ConfettiOverlay({super.key, required this.child});

  final Widget child;

  /// Fire a confetti burst from the nearest ConfettiOverlay ancestor.
  /// Safe to call even if no overlay exists or during disposal — silently no-ops.
  static void trigger(BuildContext context) {
    try {
      final scope = _ConfettiScope.of(context);
      if (scope != null) {
        scope.controller.play();
      }
    } catch (_) {
      // Silently ignore — confetti is decorative, never worth crashing for.
    }
  }

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay> {
  late final ConfettiController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _ConfettiScope(
      controller: _controller,
      child: Stack(
        children: [
          // The actual page content
          widget.child,

          // Confetti emitter — top center, shoots downward
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _controller,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              emissionFrequency: 0.05,
              numberOfParticles: 25,
              maxBlastForce: 30,
              minBlastForce: 10,
              gravity: 0.15,
              colors: const [
                AppTheme.tilePinkBright, // pink
                AppTheme.tileBlue, // blue
                AppTheme.statusGreen, // green
                AppTheme.tileGold, // gold
                AppTheme.tilePurple, // purple
                AppTheme.tileOrange, // orange
                AppTheme.tileTeal, // teal
              ],
            ),
          ),
        ],
      ),
    );
  }
}
