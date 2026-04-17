// lib/screens/weight_trend_screen.dart
//
// Weight trend tracker: pulls existing vital WT entries, computes 30-day
// percentage change, displays a trend chart, and provides quick weight entry.

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:cecelia_care_flutter/models/journal_entry.dart';
import 'package:cecelia_care_flutter/providers/active_elder_provider.dart';
import 'package:cecelia_care_flutter/providers/journal_service_provider.dart';
import 'package:cecelia_care_flutter/services/notification_service.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';
import 'package:cecelia_care_flutter/utils/haptic_utils.dart';
import 'package:cecelia_care_flutter/widgets/empty_state_widget.dart';

class WeightTrendScreen extends StatefulWidget {
  const WeightTrendScreen({super.key});

  @override
  State<WeightTrendScreen> createState() => _WeightTrendScreenState();
}

class _WeightTrendScreenState extends State<WeightTrendScreen> {
  final _weightCtrl = TextEditingController();
  String _unit = 'lbs';
  bool _isSaving = false;

  @override
  void dispose() {
    _weightCtrl.dispose();
    super.dispose();
  }

  List<_WeightPoint> _extractWeights(List<JournalEntry> entries) {
    final points = <_WeightPoint>[];
    for (final e in entries) {
      final vitalType = e.data?['vitalType'] as String? ?? '';
      if (vitalType != 'WT') continue;
      final valStr = e.data?['value'] as String? ?? '';
      final val = double.tryParse(valStr);
      if (val == null || val <= 0) continue;
      final unit = e.data?['unit'] as String? ?? 'lbs';
      points.add(_WeightPoint(
        value: val,
        unit: unit,
        date: e.entryTimestamp.toDate(),
        loggedBy: e.loggedByDisplayName ?? '',
      ));
    }
    // Sort oldest first for chart rendering.
    points.sort((a, b) => a.date.compareTo(b.date));
    return points;
  }

  double? _percentChange(List<_WeightPoint> points, int days) {
    if (points.length < 2) return null;
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final older = points.where((p) => p.date.isBefore(cutoff)).toList();
    if (older.isEmpty) return null;
    final baseline = older.last.valueLbs;
    final current = points.last.valueLbs;
    if (baseline == 0) return null;
    return ((current - baseline) / baseline) * 100;
  }

  Color _changeColor(double? pct) {
    if (pct == null) return AppTheme.textSecondary;
    if (pct <= -5) return AppTheme.statusRed;
    if (pct <= -3) return AppTheme.statusAmber;
    return AppTheme.statusGreen;
  }

  Future<void> _logWeight(List<_WeightPoint> existing) async {
    final valStr = _weightCtrl.text.trim();
    final val = double.tryParse(valStr);
    if (val == null || val <= 0) return;

    setState(() => _isSaving = true);
    try {
      final journal = context.read<JournalServiceProvider>();
      final user = FirebaseAuth.instance.currentUser;
      final elderId =
          context.read<ActiveElderProvider>().activeElder?.id ?? '';
      if (user == null || elderId.isEmpty) return;

      final payload = <String, dynamic>{
        'vitalType': 'WT',
        'value': valStr,
        'unit': _unit,
        'stamp': Timestamp.now(),
        'time': DateFormat('HH:mm').format(DateTime.now()),
        'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
        'elderId': elderId,
        'loggedByUserId': user.uid,
        'loggedBy': user.displayName ?? user.email ?? 'Unknown',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isPublic': true,
        'visibleToUserIds': <String>[],
      };

      await journal.addJournalEntry('vital', payload, user.uid);
      HapticUtils.success();
      _weightCtrl.clear();

      // Check for weight loss alert after logging.
      if (existing.isNotEmpty) {
        final allPoints = [...existing, _WeightPoint(
          value: val, unit: _unit,
          date: DateTime.now(), loggedBy: '',
        )];
        final pct = _percentChange(allPoints, 30);
        if (pct != null && pct <= -5) {
          final elderName = context.read<ActiveElderProvider>()
              .activeElder?.profileName ?? '';
          await NotificationService.instance.checkAndFireWeightAlert(
            percentLoss: pct.abs(),
            elderName: elderName,
            elderId: elderId,
          );
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Weight logged.'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      debugPrint('Weight log error: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final elderId =
        context.watch<ActiveElderProvider>().activeElder?.id ?? '';
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Weight Trends')),
      body: elderId.isEmpty
          ? const Center(child: Text('No care recipient selected.'))
          : StreamBuilder<List<JournalEntry>>(
              stream: context
                  .read<JournalServiceProvider>()
                  .getJournalEntriesStream(
                    elderId: elderId,
                    currentUserId: currentUserId,
                    entryTypeFilter: 'vital',
                  ),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Something went wrong.',
                      style: TextStyle(color: Colors.red)));
                }
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final weights = _extractWeights(snapshot.data ?? []);
                return _buildContent(weights);
              },
            ),
    );
  }

  Widget _buildContent(List<_WeightPoint> weights) {
    final pct30 = _percentChange(weights, 30);
    final pct7 = _percentChange(weights, 7);
    final pct90 = _percentChange(weights, 90);
    final latest = weights.isNotEmpty ? weights.last : null;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Current weight hero ───────────────────────────────────
        Card(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusL)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                if (latest != null) ...[
                  Text('${latest.value} ${latest.unit}',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: _changeColor(pct30),
                      )),
                  Text(
                    'Last logged ${DateFormat('MMM d').format(latest.date)} by ${latest.loggedBy}',
                    style: TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ] else
                  const EmptyStateWidget(
                    icon: Icons.monitor_weight_outlined,
                    title: 'No weight data yet',
                    subtitle: 'Log a weight vital to start tracking trends.',
                    compact: true,
                  ),
                const SizedBox(height: 14),
                // Stats row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _StatChip('7 days', pct7),
                    _StatChip('30 days', pct30),
                    _StatChip('90 days', pct90),
                  ],
                ),
                if (pct30 != null && pct30 <= -5) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.statusRed.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppTheme.radiusS),
                      border: Border.all(
                          color: AppTheme.statusRed.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber,
                            size: 16, color: AppTheme.statusRed),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '>${pct30.abs().toStringAsFixed(1)}% weight loss in 30 days. '
                            'Consider discussing with their doctor.',
                            style: TextStyle(
                                fontSize: 12, color: AppTheme.statusRed),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // ── Trend chart ───────────────────────────────────────────
        if (weights.length >= 2) ...[
          const Text('TREND',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                  color: AppTheme.textSecondary)),
          const SizedBox(height: 8),
          SizedBox(
            height: 140,
            child: _WeightChart(points: weights),
          ),
          const SizedBox(height: 16),
        ],

        // ── Quick entry ───────────────────────────────────────────
        Card(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusM)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _weightCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Weight',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'lbs', label: Text('lbs')),
                    ButtonSegment(value: 'kg', label: Text('kg')),
                  ],
                  selected: {_unit},
                  onSelectionChanged: (s) =>
                      setState(() => _unit = s.first),
                  style: SegmentedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isSaving ? null : () => _logWeight(weights),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.entryActivityAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusS)),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Log'),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // ── History list ─���────────────────────────────────────────
        if (weights.isNotEmpty) ...[
          const Text('HISTORY',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                  color: AppTheme.textSecondary)),
          const SizedBox(height: 8),
          ...weights.reversed.map((w) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Text('${w.value} ${w.unit}',
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Text(DateFormat('MMM d, yyyy').format(w.date),
                        style: TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary)),
                  ],
                ),
              )),
        ],
      ],
    );
  }

  Widget _StatChip(String label, double? pct) {
    final color = _changeColor(pct);
    return Column(
      children: [
        Text(
          pct != null
              ? '${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(1)}%'
              : '\u2014',
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, color: color),
        ),
        Text(label,
            style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
      ],
    );
  }
}

// ── Chart widget ──────────────────────────────────────────────────

class _WeightChart extends StatelessWidget {
  const _WeightChart({required this.points});
  final List<_WeightPoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.length < 2) return const SizedBox.shrink();

    final values = points.map((p) => p.valueLbs).toList();
    final minV = values.reduce((a, b) => a < b ? a : b) - 2;
    final maxV = values.reduce((a, b) => a > b ? a : b) + 2;
    final range = maxV - minV;

    return CustomPaint(
      size: const Size(double.infinity, 140),
      painter: _ChartPainter(
        points: points,
        minV: minV,
        range: range == 0 ? 1 : range,
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter({
    required this.points,
    required this.minV,
    required this.range,
  });
  final List<_WeightPoint> points;
  final double minV;
  final double range;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final linePaint = Paint()
      ..color = AppTheme.entryActivityAccent
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = AppTheme.entryActivityAccent
      ..style = PaintingStyle.fill;

    final path = Path();
    for (int i = 0; i < points.length; i++) {
      final x = (i / (points.length - 1)) * size.width;
      final y =
          size.height - ((points[i].valueLbs - minV) / range) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      canvas.drawCircle(Offset(x, y), 3, dotPaint);
    }
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _ChartPainter oldDelegate) =>
      oldDelegate.points != points ||
      oldDelegate.minV != minV ||
      oldDelegate.range != range;
}

// ── Data class ──��─────────────────────────────────────────────────

class _WeightPoint {
  final double value;
  final String unit;
  final DateTime date;
  final String loggedBy;

  const _WeightPoint({
    required this.value,
    required this.unit,
    required this.date,
    required this.loggedBy,
  });

  /// Normalize to lbs for consistent comparison.
  double get valueLbs => unit == 'kg' ? value * 2.20462 : value;
}
