// lib/widgets/time_since_card.dart
//
// Dashboard card showing time elapsed since key care events. Gives the
// caregiver an at-a-glance "what's overdue" view without opening any
// other screen.
//
// Data comes entirely from journal entry timestamps — no new Firestore
// queries. The parent passes in the latest entries and this widget does
// the math.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:cecelia_care_flutter/models/entry_types.dart';
import 'package:cecelia_care_flutter/models/journal_entry.dart';
import 'package:cecelia_care_flutter/providers/active_elder_provider.dart';
import 'package:cecelia_care_flutter/providers/journal_service_provider.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';

class TimeSinceCard extends StatefulWidget {
  const TimeSinceCard({super.key});

  @override
  State<TimeSinceCard> createState() => _TimeSinceCardState();
}

class _TimeSinceCardState extends State<TimeSinceCard> {
  Stream<List<JournalEntry>>? _stream;
  String? _streamElderId;

  @override
  Widget build(BuildContext context) {
    final elder = context.watch<ActiveElderProvider>().activeElder;
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (elder == null || uid.isEmpty) return const SizedBox.shrink();

    // Cache the stream per elder — same pattern as other dashboard cards.
    if (_stream == null || _streamElderId != elder.id) {
      _stream = context.read<JournalServiceProvider>().getJournalEntriesStream(
            elderId: elder.id,
            currentUserId: uid,
          );
      _streamElderId = elder.id;
    }

    return StreamBuilder<List<JournalEntry>>(
      stream: _stream,
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        final entries = snap.data!;
        final now = DateTime.now();

        // Build the tracker rows by finding the most recent entry per
        // tracked type. We only show types that have at least one entry.
        final rows = <_TrackerRow>[];
        for (final spec in _trackedTypes) {
          final latest = entries
              .where((e) => e.type == spec.type)
              .toList();
          if (latest.isEmpty) continue;
          final last = latest.first.entryTimestamp.toDate();
          final elapsed = now.difference(last);
          rows.add(_TrackerRow(
            label: spec.label,
            icon: spec.icon,
            color: spec.color,
            elapsed: elapsed,
            overdue: spec.overdueAfter != null &&
                elapsed > spec.overdueAfter!,
            overdueLabel: spec.overdueLabel,
          ));
        }

        if (rows.isEmpty) return const SizedBox.shrink();

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
            side: BorderSide(
                color: AppTheme.textLight.withValues(alpha: 0.3)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.schedule, size: 16, color: AppTheme.textSecondary),
                    SizedBox(width: 6),
                    Text('Time since last',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800)),
                  ],
                ),
                const SizedBox(height: 10),
                ...rows.map(_buildRow),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRow(_TrackerRow r) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: (r.overdue ? AppTheme.dangerColor : r.color)
                  .withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(r.icon,
                size: 14,
                color: r.overdue ? AppTheme.dangerColor : r.color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(r.label,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600)),
          ),
          Text(
            _formatElapsed(r.elapsed),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: r.overdue ? AppTheme.dangerColor : AppTheme.textSecondary,
            ),
          ),
          if (r.overdue) ...[
            const SizedBox(width: 4),
            Tooltip(
              message: r.overdueLabel ?? 'Overdue',
              child: Icon(Icons.warning_amber,
                  size: 14, color: AppTheme.dangerColor),
            ),
          ],
        ],
      ),
    );
  }

  static String _formatElapsed(Duration d) {
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    if (d.inDays == 1) return '1 day ago';
    if (d.inDays < 30) return '${d.inDays} days ago';
    final months = (d.inDays / 30).floor();
    return months == 1 ? '1 month ago' : '$months months ago';
  }
}

class _TrackerRow {
  final String label;
  final IconData icon;
  final Color color;
  final Duration elapsed;
  final bool overdue;
  final String? overdueLabel;

  const _TrackerRow({
    required this.label,
    required this.icon,
    required this.color,
    required this.elapsed,
    required this.overdue,
    this.overdueLabel,
  });
}

/// Types we track + their "overdue" thresholds.
class _TrackedType {
  final EntryType type;
  final String label;
  final IconData icon;
  final Color color;
  final Duration? overdueAfter;
  final String? overdueLabel;

  const _TrackedType({
    required this.type,
    required this.label,
    required this.icon,
    required this.color,
    this.overdueAfter,
    this.overdueLabel,
  });
}

const List<_TrackedType> _trackedTypes = [
  _TrackedType(
    type: EntryType.medication,
    label: 'Medication log',
    icon: Icons.medication_outlined,
    color: AppTheme.tileBlue,
    overdueAfter: Duration(hours: 24),
    overdueLabel: 'No med logged in 24h',
  ),
  _TrackedType(
    type: EntryType.pain,
    label: 'Pain entry',
    icon: Icons.healing_outlined,
    color: AppTheme.statusRed,
  ),
  _TrackedType(
    type: EntryType.mood,
    label: 'Mood check-in',
    icon: Icons.sentiment_satisfied_outlined,
    color: AppTheme.tilePinkBright,
    overdueAfter: Duration(days: 2),
    overdueLabel: 'No mood check in 2 days',
  ),
  _TrackedType(
    type: EntryType.vital,
    label: 'Vital reading',
    icon: Icons.monitor_heart_outlined,
    color: AppTheme.tileOrange,
    overdueAfter: Duration(days: 7),
    overdueLabel: 'No vitals in a week',
  ),
  _TrackedType(
    type: EntryType.hydration,
    label: 'Fluid intake',
    icon: Icons.local_drink_outlined,
    color: Color(0xFF0288D1),
    overdueAfter: Duration(hours: 12),
    overdueLabel: 'No fluids logged in 12h',
  ),
  _TrackedType(
    type: EntryType.incontinence,
    label: 'Continence log',
    icon: Icons.water_drop_outlined,
    color: AppTheme.tileBrown,
  ),
  _TrackedType(
    type: EntryType.handoff,
    label: 'Shift handoff',
    icon: Icons.swap_horiz_outlined,
    color: AppTheme.tileTeal,
    overdueAfter: Duration(hours: 12),
    overdueLabel: 'No handoff in 12h',
  ),
];
