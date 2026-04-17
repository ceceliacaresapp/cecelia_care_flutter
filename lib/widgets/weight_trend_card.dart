// lib/widgets/weight_trend_card.dart
//
// Compact dashboard card showing latest weight, sparkline, and % change.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import 'package:cecelia_care_flutter/models/journal_entry.dart';
import 'package:cecelia_care_flutter/providers/active_elder_provider.dart';
import 'package:cecelia_care_flutter/providers/journal_service_provider.dart';
import 'package:cecelia_care_flutter/screens/weight_trend_screen.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';

class WeightTrendCard extends StatefulWidget {
  const WeightTrendCard({super.key});

  @override
  State<WeightTrendCard> createState() => _WeightTrendCardState();
}

class _WeightTrendCardState extends State<WeightTrendCard> {
  Stream<List<JournalEntry>>? _stream;
  String? _streamElderId;
  String? _streamUserId;

  @override
  Widget build(BuildContext context) {
    final elderId =
        context.watch<ActiveElderProvider>().activeElder?.id ?? '';
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    if (elderId.isEmpty) return const SizedBox.shrink();

    // Cache the stream so we don't create a new Firestore listener on
    // every parent rebuild (which happens whenever any provider on the
    // dashboard notifies).
    if (_stream == null ||
        _streamElderId != elderId ||
        _streamUserId != currentUserId) {
      _stream = context
          .read<JournalServiceProvider>()
          .getJournalEntriesStream(
            elderId: elderId,
            currentUserId: currentUserId,
            entryTypeFilter: 'vital',
          );
      _streamElderId = elderId;
      _streamUserId = currentUserId;
    }

    return StreamBuilder<List<JournalEntry>>(
      stream: _stream,
      builder: (context, snapshot) {
        final entries = snapshot.data ?? [];
        final weights = <_Pt>[];
        for (final e in entries) {
          if ((e.data?['vitalType'] as String? ?? '') != 'WT') continue;
          final val = double.tryParse(e.data?['value'] as String? ?? '');
          if (val == null || val <= 0) continue;
          final unit = e.data?['unit'] as String? ?? 'lbs';
          weights.add(_Pt(
            lbs: unit == 'kg' ? val * 2.20462 : val,
            display: val,
            unit: unit,
            date: e.entryTimestamp.toDate(),
          ));
        }
        weights.sort((a, b) => a.date.compareTo(b.date));

        if (weights.isEmpty) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox.shrink();
          }
          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
              side: BorderSide(
                  color: AppTheme.textLight.withValues(alpha: 0.4)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Icon(Icons.monitor_weight_outlined,
                      size: 20, color: AppTheme.textSecondary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Log a weight vital to start tracking trends.',
                      style: TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final latest = weights.last;
        double? pct30;
        if (weights.length >= 2) {
          final cutoff = DateTime.now().subtract(const Duration(days: 30));
          final older = weights.where((w) => w.date.isBefore(cutoff)).toList();
          if (older.isNotEmpty) {
            pct30 = ((latest.lbs - older.last.lbs) / older.last.lbs) * 100;
          }
        }

        final isAlert = pct30 != null && pct30 <= -5;
        final pctColor = pct30 == null
            ? AppTheme.textSecondary
            : pct30 <= -5
                ? AppTheme.statusRed
                : pct30 <= -3
                    ? AppTheme.statusAmber
                    : AppTheme.statusGreen;

        return GestureDetector(
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const WeightTrendScreen())),
          child: Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
              side: isAlert
                  ? BorderSide(color: AppTheme.statusRed.withValues(alpha: 0.4))
                  : BorderSide.none,
            ),
            color: isAlert
                ? AppTheme.statusRed.withValues(alpha: 0.03)
                : null,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Left: weight + date
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (isAlert)
                              Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: Icon(Icons.warning_amber,
                                    size: 16, color: AppTheme.statusRed),
                              ),
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: latest.display),
                              duration: const Duration(milliseconds: 800),
                              curve: Curves.easeOut,
                              builder: (_, v, __) => Text(
                                '${v.toStringAsFixed(1)} ${latest.unit}',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: pctColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          DateFormat('MMM d').format(latest.date),
                          style: TextStyle(
                              fontSize: 11, color: AppTheme.textSecondary),
                        ),
                        if (pct30 != null)
                          Text(
                            '${pct30 >= 0 ? '+' : ''}${pct30.toStringAsFixed(1)}% (30d)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: pctColor,
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Right: mini sparkline
                  if (weights.length >= 2)
                    SizedBox(
                      width: 80,
                      height: 40,
                      child: CustomPaint(
                        painter: _SparklinePainter(
                          values: weights
                              .skip(weights.length > 10 ? weights.length - 10 : 0)
                              .map((w) => w.lbs)
                              .toList(),
                          color: pctColor,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({required this.values, required this.color});
  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final min = values.reduce((a, b) => a < b ? a : b) - 1;
    final max = values.reduce((a, b) => a > b ? a : b) + 1;
    final range = max - min;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path();
    for (int i = 0; i < values.length; i++) {
      final x = (i / (values.length - 1)) * size.width;
      final y = size.height - ((values[i] - min) / range) * size.height;
      if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.color != color;
}

class _Pt {
  final double lbs;
  final double display;
  final String unit;
  final DateTime date;
  const _Pt({required this.lbs, required this.display, required this.unit, required this.date});
}
