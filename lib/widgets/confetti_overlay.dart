// lib/widgets/confetti_overlay.dart
//
// Reusable confetti overlay. Wrap any subtree (typically the app Scaffold)
// and call ConfettiOverlay.trigger(context) from anywhere below to fire
// a celebration burst from the top center.
//
// Uses the `confetti` package (^0.7.0).

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

  static _ConfettiScope? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_ConfettiScope>();
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
  /// Safe to call even if no overlay exists — silently no-ops.
  static void trigger(BuildContext context) {
    final scope = _ConfettiScope.of(context);
    if (scope != null) {
      scope.controller.play();
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
                Color(0xFFE91E63), // pink
                Color(0xFF1E88E5), // blue
                Color(0xFF43A047), // green
                Color(0xFFFFC107), // gold
                Color(0xFF8E24AA), // purple
                Color(0xFFF57C00), // orange
                Color(0xFF00897B), // teal
              ],
            ),
          ),
        ],
      ),
    );
  }
}
