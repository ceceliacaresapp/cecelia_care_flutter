// lib/widgets/skeleton_loaders.dart
//
// Shimmer skeleton placeholders that replace CircularProgressIndicator on
// content-loading states. Research shows skeleton screens reduce perceived
// load time by 25-30% compared to spinners because users feel the app is
// "already rendering" instead of "stuck."
//
// Four reusable variants:
//   • SkeletonCard — rounded rect (assessments, budget cards)
//   • SkeletonListTile — avatar circle + 2 text lines (timeline, lists)
//   • SkeletonGrid — 3-column grid of rects (care screen, add-log)
//   • SkeletonDashboardSection — header line + card placeholder
//
// All variants share a single _ShimmerEffect animation built with
// ShaderMask + LinearGradient — no external package needed. The gradient
// cycles left-to-right at 1.5s period.
//
// Dark mode: lighter grey shimmer on dark surface. Light mode: grey shimmer
// on white. Detection via Theme.of(context).brightness.

import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────
// Shared shimmer effect
// ─────────────────────────────────────────────────────────────

class _ShimmerEffect extends StatefulWidget {
  const _ShimmerEffect({required this.child});
  final Widget child;

  @override
  State<_ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<_ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE0E0E0);
    final highlightColor =
        isDark ? const Color(0xFF3E3E3E) : const Color(0xFFF5F5F5);

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [baseColor, highlightColor, baseColor],
              stops: const [0.0, 0.5, 1.0],
              begin: Alignment(-1.0 + 2.0 * _ctrl.value, 0),
              end: Alignment(1.0 + 2.0 * _ctrl.value, 0),
            ).createShader(bounds);
          },
          child: child!,
        );
      },
      child: widget.child,
    );
  }
}

Widget _bone(double width, double height, {double radius = 8}) {
  return Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: Colors.white, // will be masked by shimmer
      borderRadius: BorderRadius.circular(radius),
    ),
  );
}

// ─────────────────────────────────────────────────────────────
// SkeletonCard
// ─────────────────────────────────────────────────────────────

/// Rounded rectangle placeholder — matches assessment cards, budget cards.
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key, this.height = 120, this.width});

  final double height;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return _ShimmerEffect(
      child: Container(
        width: width ?? double.infinity,
        height: height,
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SkeletonListTile
// ─────────────────────────────────────────────────────────────

/// Avatar circle + two text lines — matches timeline entries, list items.
class SkeletonListTile extends StatelessWidget {
  const SkeletonListTile({super.key});

  @override
  Widget build(BuildContext context) {
    return _ShimmerEffect(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            _bone(40, 40, radius: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _bone(double.infinity, 12),
                  const SizedBox(height: 8),
                  _bone(160, 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SkeletonGrid
// ─────────────────────────────────────────────────────────────

/// 3-column grid of rounded squares — matches care screen / add-log tiles.
class SkeletonGrid extends StatelessWidget {
  const SkeletonGrid({super.key, this.rows = 2});

  final int rows;

  @override
  Widget build(BuildContext context) {
    return _ShimmerEffect(
      child: Column(
        children: List.generate(rows, (r) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: List.generate(3, (c) {
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: c == 0 ? 0 : 5,
                      right: c == 2 ? 0 : 5,
                    ),
                    child: _bone(double.infinity, 80, radius: 12),
                  ),
                );
              }),
            ),
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SkeletonDashboardSection
// ─────────────────────────────────────────────────────────────

/// Section header line + card placeholder — matches a dashboard section
/// that hasn't loaded yet.
class SkeletonDashboardSection extends StatelessWidget {
  const SkeletonDashboardSection({super.key});

  @override
  Widget build(BuildContext context) {
    return _ShimmerEffect(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _bone(120, 12),
            const SizedBox(height: 10),
            _bone(double.infinity, 80, radius: 14),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SkeletonInline
// ─────────────────────────────────────────────────────────────

/// Tiny inline shimmer — used for small badge counts, folder counts, etc.
class SkeletonInline extends StatelessWidget {
  const SkeletonInline({super.key, this.width = 40, this.height = 12});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return _ShimmerEffect(
      child: _bone(width, height, radius: 4),
    );
  }
}
