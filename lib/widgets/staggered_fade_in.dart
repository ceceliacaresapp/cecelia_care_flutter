// lib/widgets/staggered_fade_in.dart
//
// Wrapper that fades + slides its child in with a staggered delay based on
// the item's index in a list or grid. Creates a "cascade" effect when a
// screen first appears.
//
// Usage:
//   ListView.builder(
//     itemBuilder: (_, i) => StaggeredFadeIn(
//       index: i,
//       child: MyListTile(...),
//     ),
//   )
//
// The animation fires once on mount and doesn't replay on rebuilds. Delay
// is capped at 500ms (index 10) so items deep in a long list don't wait
// forever.

import 'package:flutter/material.dart';

class StaggeredFadeIn extends StatefulWidget {
  const StaggeredFadeIn({
    super.key,
    required this.index,
    required this.child,
    this.delayPerItem = const Duration(milliseconds: 50),
    this.duration = const Duration(milliseconds: 350),
    this.slideOffset = 20.0,
    this.maxDelayIndex = 10,
  });

  /// Position in the list/grid — determines the stagger delay.
  final int index;

  /// The widget to animate in.
  final Widget child;

  /// Base delay between consecutive items.
  final Duration delayPerItem;

  /// Duration of the fade+slide animation itself.
  final Duration duration;

  /// Vertical slide distance in logical pixels (positive = from below).
  final double slideOffset;

  /// Items beyond this index get the same delay as this index (cap).
  final int maxDelayIndex;

  @override
  State<StaggeredFadeIn> createState() => _StaggeredFadeInState();
}

class _StaggeredFadeInState extends State<StaggeredFadeIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: Offset(0, widget.slideOffset),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    // Stagger: delay = min(index, maxDelayIndex) * delayPerItem
    final clamped = widget.index.clamp(0, widget.maxDelayIndex);
    final delay = widget.delayPerItem * clamped;
    Future.delayed(delay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return Opacity(
          opacity: _opacity.value,
          child: Transform.translate(
            offset: _slide.value,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
