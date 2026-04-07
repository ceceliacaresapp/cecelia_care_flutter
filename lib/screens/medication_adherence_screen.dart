// lib/screens/medication_adherence_screen.dart
//
// Medication adherence analytics: per-med breakdown, overall gauge,
// heatmap, insights. All data from existing MedicationEntry docs.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;

import 'package:cecelia_care_flutter/models/medication_entry.dart';
import 'package:cecelia_care_flutter/providers/active_elder_provider.dart';
import 'package:cecelia_care_flutter/services/firestore_service.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';

class MedicationAdherenceScreen extends StatefulWidget {
  const MedicationAdherenceScreen({super.key});

  @override
  State<MedicationAdherenceScreen> createState() =>
      _MedicationAdherenceScreenState();
}

class _MedicationAdherenceScreenState
    extends State<MedicationAdherenceScreen> {
  int _periodDays = 30;

  Color _adherenceColor(double pct) {
    if (pct >= 90) return AppTheme.statusGreen;
    if (pct >= 70) return AppTheme.statusAmber;
    return AppTheme.statusRed;
  }

  @override
  Widget build(BuildContext context) {
    final elderId =
        context.watch<ActiveElderProvider>().activeElder?.id ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Medication Adherence')),
      body: elderId.isEmpty
          ? const Center(child: Text('No care recipient selected.'))
          : StreamBuilder<List<MedicationEntry>>(
              stream:
                  context.read<FirestoreService>().medsForElder(elderId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                      child: Text('Something went wrong.',
                          style: TextStyle(color: Colors.red)));
                }
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allEntries = snapshot.data ?? [];
                final cutoff = DateTime.now()
                    .subtract(Duration(days: _periodDays));
                final entries = allEntries
                    .where(
                        (e) => e.createdAt.toDate().isAfter(cutoff))
                    .toList();

                return _buildContent(entries);
              },
            ),
    );
  }

  Widget _buildContent(List<MedicationEntry> entries) {
    // Group by medication name.
    final grouped = <String, List<MedicationEntry>>{};
    for (final e in entries) {
      grouped.putIfAbsent(e.name, () => []).add(e);
    }

    // Overall stats.
    final totalExpected = entries.length;
    final totalTaken = entries.where((e) => e.taken).length;
    final overallPct =
        totalExpected > 0 ? (totalTaken / totalExpected) * 100 : 0.0;

    // Per-med stats.
    final medStats = <_MedStat>[];
    for (final name in grouped.keys) {
      final medEntries = grouped[name]!;
      final taken = medEntries.where((e) => e.taken).length;
      final total = medEntries.length;
      final pct = total > 0 ? (taken / total) * 100 : 0.0;

      // Trend: compare first half to second half.
      String trend = 'stable';
      if (medEntries.length >= 4) {
        final mid = medEntries.length ~/ 2;
        final first = medEntries.sublist(0, mid);
        final second = medEntries.sublist(mid);
        final pct1 = first.where((e) => e.taken).length / first.length;
        final pct2 = second.where((e) => e.taken).length / second.length;
        if (pct2 - pct1 > 0.1) trend = 'improving';
        if (pct1 - pct2 > 0.1) trend = 'declining';
      }

      medStats.add(_MedStat(
        name: name,
        dose: medEntries.last.dose,
        taken: taken,
        total: total,
        pct: pct,
        trend: trend,
      ));
    }
    medStats.sort((a, b) => b.pct.compareTo(a.pct));

    // Heatmap: one entry per day.
    final heatmap = <DateTime, _DayStatus>{};
    for (final e in entries) {
      final day = DateTime(e.createdAt.toDate().year,
          e.createdAt.toDate().month, e.createdAt.toDate().day);
      heatmap.putIfAbsent(day, () => _DayStatus(0, 0));
      heatmap[day]!.total++;
      if (e.taken) heatmap[day]!.taken++;
    }

    // Streak: consecutive days with all meds taken.
    int streak = 0;
    var checkDay = DateTime.now();
    while (true) {
      final day = DateTime(checkDay.year, checkDay.month, checkDay.day);
      final status = heatmap[day];
      if (status != null && status.total > 0 && status.taken == status.total) {
        streak++;
        checkDay = checkDay.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Period selector ───────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [30, 60, 90].map((d) {
            final selected = _periodDays == d;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ChoiceChip(
                label: Text('${d}d'),
                selected: selected,
                onSelected: (_) => setState(() => _periodDays = d),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        // ── Overall gauge ────────────────────────────────────
        Card(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                SizedBox(
                  width: 100,
                  height: 100,
                  child: CustomPaint(
                    painter: _GaugePainter(
                      pct: overallPct / 100,
                      color: _adherenceColor(overallPct),
                    ),
                    child: Center(
                      child: Text(
                        '${overallPct.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: _adherenceColor(overallPct),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text('Overall Adherence',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                Text('$totalTaken of $totalExpected doses taken',
                    style: TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary)),
                if (streak > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '\uD83D\uDD25 $streak-day streak — all meds taken!',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.statusGreen),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // ── Heatmap ──────────────────────────────────────────
        if (heatmap.isNotEmpty) ...[
          const Text('DAILY HEATMAP',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                  color: AppTheme.textSecondary)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 3,
            runSpacing: 3,
            children: List.generate(_periodDays, (i) {
              final day = DateTime.now()
                  .subtract(Duration(days: _periodDays - 1 - i));
              final normalized =
                  DateTime(day.year, day.month, day.day);
              final status = heatmap[normalized];
              Color color;
              if (status == null || status.total == 0) {
                color = Colors.grey.shade200;
              } else if (status.taken == status.total) {
                color = AppTheme.statusGreen;
              } else if (status.taken > 0) {
                color = AppTheme.statusAmber;
              } else {
                color = AppTheme.statusRed;
              }
              return Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
        ],

        // ── Per-medication breakdown ─────────────────────────
        const Text('BY MEDICATION',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
                color: AppTheme.textSecondary)),
        const SizedBox(height: 8),
        ...medStats.map((m) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(m.name,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600)),
                        ),
                        Text('${m.pct.toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _adherenceColor(m.pct),
                            )),
                      ],
                    ),
                    if (m.dose.isNotEmpty)
                      Text(m.dose,
                          style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary)),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: m.pct / 100,
                        minHeight: 6,
                        backgroundColor:
                            _adherenceColor(m.pct).withValues(alpha: 0.12),
                        valueColor: AlwaysStoppedAnimation<Color>(
                            _adherenceColor(m.pct)),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text('${m.taken} of ${m.total} doses',
                            style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.textSecondary)),
                        const Spacer(),
                        Icon(
                          m.trend == 'improving'
                              ? Icons.trending_up
                              : m.trend == 'declining'
                                  ? Icons.trending_down
                                  : Icons.trending_flat,
                          size: 14,
                          color: m.trend == 'improving'
                              ? AppTheme.statusGreen
                              : m.trend == 'declining'
                                  ? AppTheme.statusRed
                                  : AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(m.trend,
                            style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.textSecondary)),
                      ],
                    ),
                  ],
                ),
              ),
            )),
      ],
    );
  }
}

class _MedStat {
  final String name;
  final String dose;
  final int taken;
  final int total;
  final double pct;
  final String trend;
  const _MedStat({
    required this.name,
    required this.dose,
    required this.taken,
    required this.total,
    required this.pct,
    required this.trend,
  });
}

class _DayStatus {
  int taken;
  int total;
  _DayStatus(this.taken, this.total);
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({required this.pct, required this.color});
  final double pct;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 6;

    // Background arc.
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi * 0.75,
      math.pi * 1.5,
      false,
      Paint()
        ..color = color.withValues(alpha: 0.12)
        ..strokeWidth = 10
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Foreground arc.
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi * 0.75,
      math.pi * 1.5 * pct.clamp(0, 1),
      false,
      Paint()
        ..color = color
        ..strokeWidth = 10
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) =>
      oldDelegate.pct != pct || oldDelegate.color != color;
}
