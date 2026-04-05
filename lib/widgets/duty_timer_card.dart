// lib/widgets/duty_timer_card.dart
//
// Dashboard card showing elapsed time since the last shift handoff.
// Color-coded urgency: green (<8h), amber (8-12h), red (12h+).
// Auto-updates every minute via Timer.periodic.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:cecelia_care_flutter/models/elder_profile.dart';
import 'package:cecelia_care_flutter/models/journal_entry.dart';
import 'package:cecelia_care_flutter/providers/active_elder_provider.dart';
import 'package:cecelia_care_flutter/providers/journal_service_provider.dart';
import 'package:cecelia_care_flutter/screens/forms/handoff_form.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';

class DutyTimerCard extends StatefulWidget {
  const DutyTimerCard({super.key});

  @override
  State<DutyTimerCard> createState() => _DutyTimerCardState();
}

class _DutyTimerCardState extends State<DutyTimerCard> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  // ── Helpers ─────────────────────────────────────────────────────

  static const Duration _standardShift = Duration(hours: 8);
  static const Duration _longShift = Duration(hours: 12);

  static const Color _greenColor = Color(0xFF43A047);
  static const Color _amberColor = Color(0xFFF57C00);
  static const Color _redColor = Color(0xFFE53935);

  Color _colorForDuration(Duration d) {
    if (d >= _longShift) return _redColor;
    if (d >= _standardShift) return _amberColor;
    return _greenColor;
  }

  String _formatElapsed(Duration d) {
    if (d.inDays > 0) return '${d.inDays}d ${d.inHours % 24}h';
    if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes % 60}m';
    return '${d.inMinutes}m';
  }

  double _progressFraction(Duration d) {
    return (d.inMinutes / _standardShift.inMinutes).clamp(0.0, 1.0);
  }

  void _openHandoffForm(ElderProfile elder) {
    final journalService = context.read<JournalServiceProvider>();
    final currentDateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(sheetContext).size.height * 0.92,
          ),
          decoration: BoxDecoration(
            color: Theme.of(sheetContext).scaffoldBackgroundColor,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ChangeNotifierProvider.value(
            value: journalService,
            child: HandoffForm(
              onClose: () => Navigator.of(sheetContext).pop(),
              currentDate: currentDateStr,
              activeElder: elder,
            ),
          ),
        ),
      ),
    );
  }

  // ── Build ───────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final elderProvider = context.watch<ActiveElderProvider>();
    final activeElder = elderProvider.activeElder;
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    if (activeElder == null || currentUserId.isEmpty) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<List<JournalEntry>>(
      stream: context.read<JournalServiceProvider>().getJournalEntriesStream(
            elderId: activeElder.id,
            currentUserId: currentUserId,
            entryTypeFilter: 'handoff',
          ),
      builder: (context, snapshot) {
        final entries = snapshot.data ?? [];
        final latest = entries.isNotEmpty ? entries.first : null;

        return _buildCard(
          context,
          latest: latest,
          elder: activeElder,
          canLog: elderProvider.canLog,
        );
      },
    );
  }

  Widget _buildCard(
    BuildContext context, {
    JournalEntry? latest,
    required ElderProfile elder,
    required bool canLog,
  }) {
    // ── Empty state ──────────────────────────────────────────────
    if (latest == null) {
      return Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.timer_outlined,
                      size: 18, color: AppTheme.textSecondary),
                  const SizedBox(width: 6),
                  Text('DUTY TIMER',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                        color: AppTheme.textSecondary,
                      )),
                ],
              ),
              const SizedBox(height: 12),
              const Text('No handoff notes yet.',
                  style: TextStyle(fontSize: 14)),
              const Text('Log your first one to start tracking.',
                  style: TextStyle(fontSize: 13, color: Colors.grey)),
              if (canLog) ...[
                const SizedBox(height: 10),
                _HandoffButton(onTap: () => _openHandoffForm(elder)),
              ],
            ],
          ),
        ),
      );
    }

    // ── Active timer state ───────────────────────────────────────
    final now = DateTime.now();
    final handoffTime = latest.entryTimestamp.toDate();
    final elapsed = now.difference(handoffTime);
    final color = _colorForDuration(elapsed);
    final progress = _progressFraction(elapsed);

    // Context line: who + shift + when
    final who = latest.loggedByDisplayName ?? 'Someone';
    final shiftName = latest.data?['shift'] as String?;
    final isToday = handoffTime.day == now.day &&
        handoffTime.month == now.month &&
        handoffTime.year == now.year;
    final timeLabel = isToday
        ? DateFormat('h:mm a').format(handoffTime)
        : 'Yesterday ${DateFormat('h:mm a').format(handoffTime)}';
    final contextParts = <String>[
      '$who clocked in',
      if (shiftName != null && shiftName.isNotEmpty) shiftName,
      timeLabel,
    ];

    // Card tint for long shifts
    Color? cardTint;
    if (elapsed >= _longShift) {
      cardTint = _redColor.withValues(alpha: 0.04);
    } else if (elapsed >= _standardShift) {
      cardTint = _amberColor.withValues(alpha: 0.04);
    }

    return Card(
      elevation: 1,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: cardTint,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Icon(Icons.timer_outlined, size: 18, color: color),
                const SizedBox(width: 6),
                Text('ON DUTY',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                      color: color,
                    )),
                const Spacer(),
                Text(_formatElapsed(elapsed),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: color,
                    )),
              ],
            ),
            const SizedBox(height: 12),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: color.withValues(alpha: 0.12),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            const SizedBox(height: 10),

            // Context line
            Text(
              contextParts.join(' \u00B7 '),
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            // Handoff action
            if (canLog) ...[
              const SizedBox(height: 8),
              _HandoffButton(onTap: () => _openHandoffForm(elder)),
            ],
          ],
        ),
      ),
    );
  }
}

class _HandoffButton extends StatelessWidget {
  const _HandoffButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Log Handoff',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor,
              )),
          const SizedBox(width: 4),
          Icon(Icons.arrow_forward,
              size: 14, color: AppTheme.primaryColor),
        ],
      ),
    );
  }
}
