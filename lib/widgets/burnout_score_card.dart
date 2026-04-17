// lib/widgets/burnout_score_card.dart
//
// Visual burnout risk gauge for the Self Care tab.
//
// Shows:
//   • Circular score indicator (0–100) color-coded green/yellow/red
//   • Risk level label + message
//   • Nudge text (yellow/red only) with action suggestion
//   • Per-dimension breakdown bars (mood, sleep, exercise, social, me-time)
//   • Mood trend alert banner when 3+ consecutive low-mood days detected
//
// Reads from WellnessProvider — no direct Firestore access.

import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:cecelia_care_flutter/providers/wellness_provider.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';

// ---------------------------------------------------------------------------
// Color scheme per risk level
// ---------------------------------------------------------------------------
const _kGreenColor = AppTheme.statusGreen;
const _kYellowColor = Color(0xFFF9A825);
const _kRedColor = AppTheme.statusRed;

Color _colorForLevel(BurnoutRiskLevel level) {
  switch (level) {
    case BurnoutRiskLevel.green:
      return _kGreenColor;
    case BurnoutRiskLevel.yellow:
      return _kYellowColor;
    case BurnoutRiskLevel.red:
      return _kRedColor;
  }
}

IconData _iconForLevel(BurnoutRiskLevel level) {
  switch (level) {
    case BurnoutRiskLevel.green:
      return Icons.check_circle_outline;
    case BurnoutRiskLevel.yellow:
      return Icons.warning_amber_rounded;
    case BurnoutRiskLevel.red:
      return Icons.error_outline;
  }
}

String _levelLabel(BurnoutRiskLevel level) {
  switch (level) {
    case BurnoutRiskLevel.green:
      return 'Looking good';
    case BurnoutRiskLevel.yellow:
      return 'Take care';
    case BurnoutRiskLevel.red:
      return 'Burnout risk';
  }
}

// ---------------------------------------------------------------------------
// Main widget
// ---------------------------------------------------------------------------
class BurnoutScoreCard extends StatelessWidget {
  const BurnoutScoreCard({
    super.key,
    required this.burnoutStatus,
    required this.dimensionAverages,
    this.moodTrend,
    this.onTapRelief,
    this.onTapSos,
  });

  final BurnoutStatus burnoutStatus;
  final Map<String, double> dimensionAverages;
  final MoodTrend? moodTrend;

  /// Called when the user taps the nudge — navigates to a relief tool.
  final VoidCallback? onTapRelief;

  /// Called when burnout is red — navigates to SOS mode.
  final VoidCallback? onTapSos;

  @override
  Widget build(BuildContext context) {
    final color = _colorForLevel(burnoutStatus.level);
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left accent strip
              Container(width: 5, color: color),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Header: gauge + label ─────────────────────
                      Row(
                        children: [
                          _ScoreGauge(
                            score: burnoutStatus.score,
                            color: color,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      _iconForLevel(
                                          burnoutStatus.level),
                                      color: color,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _levelLabel(
                                          burnoutStatus.level),
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: color,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  burnoutStatus.message,
                                  style: theme.textTheme.bodySmall
                                      ?.copyWith(
                                    color:
                                        AppTheme.textSecondary,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // ── Mood trend alert ──────────────────────────
                      if (moodTrend != null && moodTrend!.alert) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: _kRedColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(AppTheme.radiusS),
                            border: Border.all(
                                color: _kRedColor.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.trending_down,
                                  color: _kRedColor, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  moodTrend!.message ??
                                      'Your mood has been low recently.',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: _kRedColor,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // ── Nudge action ──────────────────────────────
                      if (burnoutStatus.nudge != null) ...[
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: burnoutStatus.level ==
                                  BurnoutRiskLevel.red
                              ? onTapSos
                              : onTapRelief,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusS),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  burnoutStatus.level ==
                                          BurnoutRiskLevel.red
                                      ? Icons.spa_outlined
                                      : Icons
                                          .air_outlined,
                                  color: color,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    burnoutStatus.nudge!,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: color,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  size: 12,
                                  color: color.withValues(alpha: 0.6),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],

                      // ── Dimension breakdown ───────────────────────
                      if (dimensionAverages.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        const Text(
                          'THIS WEEK',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.8,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...dimensionAverages.entries.map(
                          (e) => _DimensionBar(
                            label: e.key,
                            value: e.value,
                            color: color,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Circular score gauge — custom painted arc
// ---------------------------------------------------------------------------
class _ScoreGauge extends StatelessWidget {
  const _ScoreGauge({required this.score, required this.color});
  final double score;
  final Color color;

  @override
  Widget build(BuildContext context) {
    // Display wellbeing (100 - burnout) so higher = better visually.
    final wellbeing = (100 - score).clamp(0, 100).toInt();

    return SizedBox(
      width: 72,
      height: 72,
      child: CustomPaint(
        painter: _GaugePainter(
          progress: wellbeing / 100,
          color: color,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$wellbeing',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              Text(
                'wellness',
                style: TextStyle(
                  fontSize: 9,
                  color: color.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({required this.progress, required this.color});
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    const startAngle = -math.pi * 0.75; // 7 o'clock
    const sweepFull = math.pi * 1.5; // 270° arc

    // Background track
    final bgPaint = Paint()
      ..color = color.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepFull,
      false,
      bgPaint,
    );

    // Progress arc
    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepFull * progress.clamp(0, 1),
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.progress != progress || old.color != color;
}

// ---------------------------------------------------------------------------
// Dimension bar — horizontal mini bar for each wellness dimension
// ---------------------------------------------------------------------------
class _DimensionBar extends StatelessWidget {
  const _DimensionBar({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final double value; // 1.0–5.0 average
  final Color color;

  @override
  Widget build(BuildContext context) {
    final normalized = ((value - 1) / 4).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(3),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: normalized,
                child: Container(
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 24,
            child: Text(
              value.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
