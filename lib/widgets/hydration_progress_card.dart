// lib/widgets/hydration_progress_card.dart
//
// Dashboard card showing today's fluid intake as a progress ring toward
// a configurable daily goal.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cecelia_care_flutter/models/journal_entry.dart';
import 'package:cecelia_care_flutter/providers/active_elder_provider.dart';
import 'package:cecelia_care_flutter/providers/journal_service_provider.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';

class HydrationProgressCard extends StatefulWidget {
  const HydrationProgressCard({super.key});

  @override
  State<HydrationProgressCard> createState() => _HydrationProgressCardState();
}

class _HydrationProgressCardState extends State<HydrationProgressCard> {
  // Cached today's-hydration stream so dashboard rebuilds don't recreate
  // the Firestore listener every frame.
  Stream<List<JournalEntry>>? _stream;
  String? _streamElderId;
  String? _streamUserId;
  String? _streamDayKey;
  static const String _goalKey = 'hydration_daily_goal';
  static const double _defaultGoal = 64; // 64 oz
  double _goal = _defaultGoal;

  @override
  void initState() {
    super.initState();
    _loadGoal();
  }

  Future<void> _loadGoal() async {
    final sp = await SharedPreferences.getInstance();
    final saved = sp.getDouble(_goalKey);
    if (saved != null && mounted) setState(() => _goal = saved);
  }

  Future<void> _setGoal() async {
    final ctrl = TextEditingController(text: _goal.toStringAsFixed(0));
    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set Daily Goal'),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Goal (oz)',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final v = double.tryParse(ctrl.text);
              if (v != null && v > 0) Navigator.pop(ctx, v);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null) {
      final sp = await SharedPreferences.getInstance();
      await sp.setDouble(_goalKey, result);
      setState(() => _goal = result);
    }
  }

  static const Color _blue = Color(0xFF0288D1);

  @override
  Widget build(BuildContext context) {
    final elderId =
        context.watch<ActiveElderProvider>().activeElder?.id ?? '';
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    if (elderId.isEmpty) return const SizedBox.shrink();

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final dayKey = '${now.year}-${now.month}-${now.day}';

    if (_stream == null ||
        _streamElderId != elderId ||
        _streamUserId != currentUserId ||
        _streamDayKey != dayKey) {
      _stream = context
          .read<JournalServiceProvider>()
          .getJournalEntriesStream(
            elderId: elderId,
            currentUserId: currentUserId,
            entryTypeFilter: 'hydration',
            startDate: startOfDay,
          );
      _streamElderId = elderId;
      _streamUserId = currentUserId;
      _streamDayKey = dayKey;
    }

    return StreamBuilder<List<JournalEntry>>(
      stream: _stream,
      builder: (context, snapshot) {
        final entries = snapshot.data ?? [];

        // Sum today's volume (normalize ml → oz for display if mixed).
        double totalOz = 0;
        final recentLabels = <String>[];
        for (final e in entries) {
          final vol = (e.data?['volume'] is num)
              ? (e.data!['volume'] as num).toDouble()
              : double.tryParse(e.data?['volume']?.toString() ?? '') ?? 0;
          final unit = e.data?['unit'] as String? ?? 'oz';
          final inOz = unit == 'ml' ? vol / 29.574 : vol;
          totalOz += inOz;

          if (recentLabels.length < 4) {
            final type = e.data?['fluidType'] as String? ?? '';
            final time = e.data?['time'] as String? ?? '';
            final shortType = type.length > 8 ? '${type.substring(0, 7)}..' : type;
            recentLabels.add('${vol.toStringAsFixed(0)}$unit $shortType $time');
          }
        }

        final pct = _goal > 0 ? (totalOz / _goal).clamp(0.0, 1.0) : 0.0;
        final isAfternoon = now.hour >= 12;
        final color = pct >= 1.0
            ? AppTheme.statusGreen
            : (isAfternoon && pct < 0.5)
                ? AppTheme.statusAmber
                : _blue;

        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Progress ring
                SizedBox(
                  width: 60,
                  height: 60,
                  child: CustomPaint(
                    painter: _RingPainter(pct: pct, color: color),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('${totalOz.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: color,
                              )),
                          Text('of ${_goal.toStringAsFixed(0)}',
                              style: const TextStyle(fontSize: 9)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('Hydration',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: color,
                              )),
                          const Spacer(),
                          GestureDetector(
                            onTap: _setGoal,
                            child: Text('Set goal',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.primaryColor,
                                  decoration: TextDecoration.underline,
                                )),
                          ),
                        ],
                      ),
                      if (pct >= 1.0)
                        Text('Goal reached!',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.statusGreen))
                      else
                        Text(
                          '${(pct * 100).toStringAsFixed(0)}% of daily goal',
                          style: TextStyle(
                              fontSize: 12, color: AppTheme.textSecondary),
                        ),
                      if (recentLabels.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          recentLabels.join(' \u00B7 '),
                          style: TextStyle(
                              fontSize: 10, color: AppTheme.textLight),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.pct, required this.color});
  final double pct;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 5;

    canvas.drawCircle(
        center, radius,
        Paint()
          ..color = color.withValues(alpha: 0.12)
          ..strokeWidth = 6
          ..style = PaintingStyle.stroke);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 2 * pct.clamp(0, 1),
      false,
      Paint()
        ..color = color
        ..strokeWidth = 6
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.pct != pct || oldDelegate.color != color;
}
