// lib/widgets/sleep_rhythm_radial.dart
//
// 24-hour radial chart for a single SleepRhythmDay. Layout (math
// convention; Flutter's Canvas uses the same):
//   12 AM  → top of circle (angle -π/2)
//   6  AM  → right (angle 0)
//   12 PM  → bottom (+π/2)
//   6  PM  → left (±π)
//
// The painter draws:
//   • tick ring with hour marks + major 6-hour labels
//   • behavioral "correlation" dots just outside the ring (red = high
//     severity) at their wall-clock angle
//   • main sleep arc (thick indigo band on the ring)
//   • nap arcs (teal bands on the ring, slightly inset)
//   • night-waking ticks inside the main sleep arc
//   • central readout: bedtime / wake / total / fragmentation

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:cecelia_care_flutter/models/sleep_rhythm.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';

const Color _kSleepBand = AppTheme.tileIndigoDeep;
const Color _kNapBand = AppTheme.tileTeal;
const Color _kWakeTick = AppTheme.statusAmber;
const Color _kBehaviorMild = Color(0xFFF9A825);
const Color _kBehaviorSevere = AppTheme.dangerColor;

/// Rendering options — the same painter is reused for the 280px hero
/// chart and the 120px 7-day stack.
class SleepRhythmRadialOptions {
  final bool showHourLabels;
  final bool showCenterReadout;
  final bool showLegend;
  final double strokeWidth;

  const SleepRhythmRadialOptions({
    this.showHourLabels = true,
    this.showCenterReadout = true,
    this.showLegend = false,
    this.strokeWidth = 14,
  });

  const SleepRhythmRadialOptions.compact({
    this.showHourLabels = false,
    this.showCenterReadout = false,
    this.showLegend = false,
    this.strokeWidth = 8,
  });
}

class SleepRhythmRadialChart extends StatelessWidget {
  const SleepRhythmRadialChart({
    super.key,
    required this.day,
    this.options = const SleepRhythmRadialOptions(),
    this.size = 280,
  });

  final SleepRhythmDay day;
  final SleepRhythmRadialOptions options;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _SleepRhythmRadialPainter(day: day, options: options),
      ),
    );
  }
}

class _SleepRhythmRadialPainter extends CustomPainter {
  _SleepRhythmRadialPainter({required this.day, required this.options});

  final SleepRhythmDay day;
  final SleepRhythmRadialOptions options;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final padding = options.showHourLabels ? 18.0 : 6.0;
    final radius = (math.min(size.width, size.height) / 2) - padding;

    // ── Background ring ──────────────────────────────────────
    final ringPaint = Paint()
      ..color = AppTheme.backgroundGray
      ..strokeWidth = options.strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, ringPaint);

    // ── Hour ticks ───────────────────────────────────────────
    _drawTicks(canvas, center, radius);

    // ── Nap bands (drawn first, slightly inset so main sleep
    //    overlaps on top if they briefly collide) ─────────────
    for (final n in day.naps) {
      _drawArcForPeriod(
        canvas,
        center,
        radius - (options.strokeWidth * 0.1),
        n,
        _kNapBand,
        options.strokeWidth * 0.75,
      );
    }

    // ── Main sleep arc ───────────────────────────────────────
    final main = day.mainSleep;
    if (main != null) {
      _drawArcForPeriod(
        canvas,
        center,
        radius,
        main,
        _kSleepBand,
        options.strokeWidth,
      );

      // Night wakings as radial tick-marks INSIDE the main arc.
      for (final w in day.wakings) {
        _drawWakingTick(canvas, center, radius, w);
      }
    }

    // ── Behavioral correlation dots outside the ring ─────────
    for (final b in day.behaviors) {
      _drawBehaviorDot(canvas, center, radius, b);
    }

    // ── Center readout ───────────────────────────────────────
    if (options.showCenterReadout) {
      _drawCenterReadout(canvas, center, radius);
    }
  }

  // ---------------------------------------------------------------------------
  // Geometry helpers
  // ---------------------------------------------------------------------------

  /// Hour of [t] mapped to angle (radians). 0 = right (3 o'clock).
  /// Midnight → top, 6 AM → right, noon → bottom, 6 PM → left.
  double _angleForTime(DateTime t) {
    final minutesOfDay = t.hour * 60 + t.minute + t.second / 60.0;
    final dayFraction = minutesOfDay / (24 * 60);
    // At 00:00 we want -π/2 (top). 2π around clockwise.
    return -math.pi / 2 + dayFraction * 2 * math.pi;
  }

  Offset _pointAt(Offset center, double radius, double angle) {
    return Offset(
      center.dx + radius * math.cos(angle),
      center.dy + radius * math.sin(angle),
    );
  }

  void _drawTicks(Canvas canvas, Offset center, double radius) {
    final tickPaint = Paint()
      ..color = AppTheme.textLight.withValues(alpha: 0.6)
      ..strokeWidth = 0.8;
    final majorPaint = Paint()
      ..color = AppTheme.textSecondary
      ..strokeWidth = 1.4;

    for (int h = 0; h < 24; h++) {
      final angle = -math.pi / 2 + (h / 24) * 2 * math.pi;
      final isMajor = h % 6 == 0;
      final outer = _pointAt(center, radius + (isMajor ? 6 : 3), angle);
      final inner = _pointAt(center, radius - (isMajor ? 4 : 2), angle);
      canvas.drawLine(inner, outer, isMajor ? majorPaint : tickPaint);

      if (options.showHourLabels && isMajor) {
        final label = switch (h) {
          0 => '12a',
          6 => '6a',
          12 => '12p',
          18 => '6p',
          _ => '',
        };
        final painter = TextPainter(
          text: TextSpan(
            text: label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppTheme.textSecondary,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        final pos = _pointAt(center, radius + 14, angle);
        painter.paint(
          canvas,
          Offset(
            pos.dx - painter.width / 2,
            pos.dy - painter.height / 2,
          ),
        );
      }
    }
  }

  void _drawArcForPeriod(
    Canvas canvas,
    Offset center,
    double radius,
    SleepPeriod period,
    Color color,
    double strokeWidth,
  ) {
    // Clamp the period into the chronobiology window so arcs don't
    // exceed a full turn. Uses the local midnight of [start] as the
    // reference for angle math — the minutes from that midnight wrap
    // naturally into our -π/2 start.
    final startAngle = _angleForTime(period.start);
    final durationMinutes = period.duration.inMinutes.clamp(1, 24 * 60);
    final sweep = (durationMinutes / (24 * 60)) * 2 * math.pi;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweep,
      false,
      paint,
    );
  }

  void _drawWakingTick(
      Canvas canvas, Offset center, double radius, RhythmWakingMark w) {
    final angle = _angleForTime(w.at);
    final tickColor =
        w.returnedToSleep ? _kWakeTick : AppTheme.dangerColor;
    final inner = _pointAt(
      center,
      radius - options.strokeWidth / 2 - 1,
      angle,
    );
    final outer = _pointAt(
      center,
      radius + options.strokeWidth / 2 + 1,
      angle,
    );
    canvas.drawLine(
      inner,
      outer,
      Paint()
        ..color = tickColor
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawBehaviorDot(
      Canvas canvas, Offset center, double radius, RhythmBehaviorMark b) {
    final angle = _angleForTime(b.at);
    final dotRadius = options.strokeWidth < 10 ? 2.2 : 3.0;
    final color = b.severity >= 3 ? _kBehaviorSevere : _kBehaviorMild;
    final pos = _pointAt(
      center,
      radius + options.strokeWidth / 2 + 4,
      angle,
    );
    canvas.drawCircle(pos, dotRadius, Paint()..color = Colors.white);
    canvas.drawCircle(pos, dotRadius - 0.6, Paint()..color = color);
  }

  void _drawCenterReadout(Canvas canvas, Offset center, double radius) {
    final total = day.totalSleep;
    final main = day.mainSleep;

    final hoursText = _formatHours(total);

    final titlePainter = TextPainter(
      text: TextSpan(
        text: hoursText,
        style: TextStyle(
          fontSize: radius * 0.28,
          fontWeight: FontWeight.w800,
          color: main == null && hoursText == '—'
              ? AppTheme.textLight
              : _kSleepBand,
          height: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    titlePainter.paint(
      canvas,
      Offset(center.dx - titlePainter.width / 2,
          center.dy - titlePainter.height - 2),
    );

    final subtitle = main == null
        ? 'No sleep logged'
        : '${_fmtClock(main.start)} → ${_fmtClock(main.end)}';
    final subtitlePainter = TextPainter(
      text: TextSpan(
        text: subtitle,
        style: TextStyle(
          fontSize: radius * 0.10,
          fontWeight: FontWeight.w600,
          color: AppTheme.textSecondary,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    subtitlePainter.paint(
      canvas,
      Offset(center.dx - subtitlePainter.width / 2, center.dy + 4),
    );

    if (day.wakings.isNotEmpty || day.naps.isNotEmpty) {
      final detail =
          '${day.wakings.length} waking${day.wakings.length == 1 ? '' : 's'}'
          '${day.naps.isNotEmpty ? ' · ${day.naps.length} nap${day.naps.length == 1 ? '' : 's'}' : ''}';
      final detailPainter = TextPainter(
        text: TextSpan(
          text: detail,
          style: TextStyle(
            fontSize: radius * 0.088,
            color: AppTheme.textSecondary,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      detailPainter.paint(
        canvas,
        Offset(
          center.dx - detailPainter.width / 2,
          center.dy + subtitlePainter.height + 7,
        ),
      );
    }
  }

  String _formatHours(Duration d) {
    if (d.inMinutes <= 0) return '—';
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  String _fmtClock(DateTime t) {
    final h24 = t.hour;
    final m = t.minute.toString().padLeft(2, '0');
    final period = h24 >= 12 ? 'p' : 'a';
    final h12 = h24 % 12 == 0 ? 12 : h24 % 12;
    return '$h12:$m$period';
  }

  @override
  bool shouldRepaint(covariant _SleepRhythmRadialPainter old) =>
      old.day != day || old.options != options;
}
