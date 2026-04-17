// lib/widgets/adherence_summary_card.dart
//
// Compact dashboard card showing 7-day medication adherence rate.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:cecelia_care_flutter/models/medication_entry.dart';
import 'package:cecelia_care_flutter/providers/active_elder_provider.dart';
import 'package:cecelia_care_flutter/services/firestore_service.dart';
import 'package:cecelia_care_flutter/screens/medication_adherence_screen.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';

class AdherenceSummaryCard extends StatefulWidget {
  const AdherenceSummaryCard({super.key});

  @override
  State<AdherenceSummaryCard> createState() => _AdherenceSummaryCardState();
}

class _AdherenceSummaryCardState extends State<AdherenceSummaryCard> {
  Stream<List<MedicationEntry>>? _stream;
  String? _streamElderId;

  Color _color(double pct) {
    if (pct >= 90) return AppTheme.statusGreen;
    if (pct >= 70) return AppTheme.statusAmber;
    return AppTheme.statusRed;
  }

  @override
  Widget build(BuildContext context) {
    final elderId =
        context.watch<ActiveElderProvider>().activeElder?.id ?? '';
    if (elderId.isEmpty) return const SizedBox.shrink();

    if (_stream == null || _streamElderId != elderId) {
      _stream = context.read<FirestoreService>().medsForElder(elderId);
      _streamElderId = elderId;
    }

    return StreamBuilder<List<MedicationEntry>>(
      stream: _stream,
      builder: (context, snapshot) {
        final allEntries = snapshot.data ?? [];
        final cutoff =
            DateTime.now().subtract(const Duration(days: 7));
        final recent = allEntries
            .where((e) => e.createdAt.toDate().isAfter(cutoff))
            .toList();

        if (recent.isEmpty) return const SizedBox.shrink();

        final taken = recent.where((e) => e.taken).length;
        final total = recent.length;
        final pct = (taken / total) * 100;
        final color = _color(pct);

        // Count meds at 100%.
        final grouped = <String, List<MedicationEntry>>{};
        for (final e in recent) {
          grouped.putIfAbsent(e.name, () => []).add(e);
        }
        final perfect = grouped.values
            .where((entries) => entries.every((e) => e.taken))
            .length;

        return GestureDetector(
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const MedicationAdherenceScreen())),
          child: Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
              side: pct < 70
                  ? BorderSide(
                      color: AppTheme.statusRed.withValues(alpha: 0.3))
                  : BorderSide.none,
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Gauge
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: pct / 100,
                          strokeWidth: 5,
                          backgroundColor: color.withValues(alpha: 0.12),
                          valueColor:
                              AlwaysStoppedAnimation<Color>(color),
                        ),
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: pct),
                          duration: const Duration(milliseconds: 800),
                          curve: Curves.easeOut,
                          builder: (_, v, __) => Text(
                            '${v.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Med Adherence (7d)',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                        Text(
                          '$perfect of ${grouped.length} meds at 100%',
                          style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right,
                      size: 18, color: AppTheme.textLight),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
