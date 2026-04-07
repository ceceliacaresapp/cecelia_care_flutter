// lib/widgets/wellness_summary_card.dart
//
// Dashboard card showing a 7-day wellness snapshot.
//
// Shows:
//   • Mini sparkline of daily wellbeing scores (last 7 days)
//   • Current wellbeing score + risk level color
//   • Best and worst dimensions this week
//   • Streak count + level
//   • Tap to navigate to Self Care tab
//
// Pure presentation — accepts all data via constructor, no provider reads.

import 'dart:math' as math;
import 'package:flutter/material.dart';

const _kCardColor = Color(0xFF8E24AA); // purple — matches Self Care

class WellnessSummaryCard extends StatelessWidget {
  const WellnessSummaryCard({
    super.key,
    required this.wellbeingScore,
    required this.burnoutRiskLevel,
    required this.dailyScores,
    required this.dimensionAverages,
    required this.currentStreak,
    required this.level,
    required this.levelTitle,
    required this.hasCheckedInToday,
    this.onTap,
  });

  /// Current 7-day average wellbeing (0–100).
  final double wellbeingScore;

  /// 'green', 'yellow', or 'red' — drives the score badge color.
  final String burnoutRiskLevel;

  /// Up to 7 daily wellbeing scores, oldest first. Used for sparkline.
  final List<double> dailyScores;

  /// 7-day dimension averages: {'Mood': 3.4, 'Sleep': 2.8, ...}
  final Map<String, double> dimensionAverages;

  final int currentStreak;
  final int level;
  final String levelTitle;
  final bool hasCheckedInToday;

  /// Navigate to the Self Care tab.
  final VoidCallback? onTap;

  Color get _riskColor {
    switch (burnoutRiskLevel) {
      case 'green':
        return const Color(0xFF43A047);
      case 'yellow':
        return const Color(0xFFF9A825);
      case 'red':
        return const Color(0xFFE53935);
      default:
        return _kCardColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Find best and worst dimensions
    String? bestDim;
    String? worstDim;
    double bestVal = 0;
    double worstVal = 6;
    for (final e in dimensionAverages.entries) {
      if (e.value > bestVal) {
        bestVal = e.value;
        bestDim = e.key;
      }
      if (e.value < worstVal) {
        worstVal = e.value;
        worstDim = e.key;
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _kCardColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _kCardColor.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: _kCardColor.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row: title + score badge ─────────────────────
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: _kCardColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.favorite_outline,
                      color: _kCardColor, size: 16),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Your wellness this week',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _kCardColor,
                    ),
                  ),
                ),
                // Score badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _riskColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _riskColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '${wellbeingScore.toInt()}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _riskColor,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ── Sparkline ───────────────────────────────────────────
            if (dailyScores.length >= 2)
              SizedBox(
                height: 40,
                child: CustomPaint(
                  size: const Size(double.infinity, 40),
                  painter: _SparklinePainter(
                    values: dailyScores,
                    color: _riskColor,
                  ),
                ),
              ),

            if (dailyScores.length >= 2) const SizedBox(height: 12),

            // ── Best / worst dimensions ─────────────────────────────
            if (dimensionAverages.isNotEmpty)
              Row(
                children: [
                  if (bestDim != null)
                    _DimChip(
                      icon: Icons.arrow_upward,
                      label: bestDim,
                      value: bestVal,
                      color: const Color(0xFF43A047),
                    ),
                  if (bestDim != null && worstDim != null)
                    const SizedBox(width: 10),
                  if (worstDim != null)
                    _DimChip(
                      icon: Icons.arrow_downward,
                      label: worstDim,
                      value: worstVal,
                      color: const Color(0xFFE53935),
                    ),
                ],
              ),

            if (dimensionAverages.isNotEmpty) const SizedBox(height: 12),

            // ── Streak + level row ──────────────────────────────────
            Row(
              children: [
                // Streak
                if (currentStreak > 0) ...[
                  Icon(Icons.local_fire_department,
                      size: 14, color: const Color(0xFFF57C00)),
                  const SizedBox(width: 3),
                  Text(
                    '$currentStreak day${currentStreak == 1 ? '' : 's'}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFF57C00),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                // Level
                Icon(Icons.star_outline,
                    size: 14, color: _kCardColor),
                const SizedBox(width: 3),
                Text(
                  'Lv $level · $levelTitle',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _kCardColor.withValues(alpha: 0.8),
                  ),
                ),
                const Spacer(),
                // Check-in status
                if (!hasCheckedInToday)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _kCardColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_circle_outline,
                            size: 12, color: _kCardColor),
                        SizedBox(width: 4),
                        Text(
                          'Check in',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: _kCardColor,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  const Icon(Icons.check_circle,
                      size: 16, color: Color(0xFF43A047)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Dimension chip — shows best/worst with arrow icon
// ---------------------------------------------------------------------------
class _DimChip extends StatelessWidget {
  const _DimChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
  final IconData icon;
  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            '$label ${value.toStringAsFixed(1)}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sparkline painter — simple line chart for 7 daily scores
// ---------------------------------------------------------------------------
class _SparklinePainter extends CustomPainter {
  _SparklinePainter({required this.values, required this.color});
  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    final n = values.length;
    final minV = values.reduce(math.min).clamp(0.0, 100.0);
    final maxV = values.reduce(math.max).clamp(0.0, 100.0);
    final range = (maxV - minV).clamp(10.0, 100.0); // min range to avoid flat

    final points = <Offset>[];
    for (int i = 0; i < n; i++) {
      final x = i / (n - 1) * size.width;
      final y = size.height - ((values[i] - minV) / range * size.height);
      points.add(Offset(x, y.clamp(2.0, size.height - 2.0)));
    }

    // Fill area under the line
    final fillPath = Path()..moveTo(0, size.height);
    for (final p in points) {
      fillPath.lineTo(p.dx, p.dy);
    }
    fillPath.lineTo(size.width, size.height);
    fillPath.close();
    canvas.drawPath(
      fillPath,
      Paint()..color = color.withValues(alpha: 0.08),
    );

    // Draw line
    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(
      linePath,
      Paint()
        ..color = color.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Draw dots
    for (int i = 0; i < points.length; i++) {
      canvas.drawCircle(
        points[i],
        i == points.length - 1 ? 4 : 2.5,
        Paint()..color = i == points.length - 1 ? color : color.withValues(alpha: 0.5),
      );
    }
  }

  @override
  bool shouldRepaint(_SparklinePainter old) =>
      old.values != values || old.color != color;
}
