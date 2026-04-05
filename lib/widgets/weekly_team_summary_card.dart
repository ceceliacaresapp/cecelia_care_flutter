// lib/widgets/weekly_team_summary_card.dart
//
// Auto-generated weekly celebration card. Summarizes the care team's
// contributions in a warm, acknowledgment-focused tone. Queries the past
// 7 days of journal entries, groups by caregiver, and highlights each
// person's top contribution.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:cecelia_care_flutter/models/journal_entry.dart';
import 'package:cecelia_care_flutter/models/entry_types.dart';
import 'package:cecelia_care_flutter/providers/active_elder_provider.dart';
import 'package:cecelia_care_flutter/services/firestore_service.dart';

class WeeklyTeamSummaryCard extends StatefulWidget {
  const WeeklyTeamSummaryCard({super.key});

  @override
  State<WeeklyTeamSummaryCard> createState() => _WeeklyTeamSummaryCardState();
}

class _WeeklyTeamSummaryCardState extends State<WeeklyTeamSummaryCard> {
  final FirestoreService _firestore = FirestoreService();
  _WeeklySummary? _summary;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  /// Returns the Monday 00:00 of the current or most recent week.
  DateTime _weekStart() {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    return DateTime(monday.year, monday.month, monday.day);
  }

  Future<void> _loadSummary() async {
    final elderProv = context.read<ActiveElderProvider>();
    final elder = elderProv.activeElder;
    if (elder == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    final start = _weekStart();
    final end = start.add(const Duration(days: 6, hours: 23, minutes: 59));

    try {
      // Fetch this week's entries.
      final entries = await _firestore
          .getJournalEntriesStreamForElders(
            elderIds: [elder.id],
            currentUserId: '', // We want all entries, visibility handled by rules.
            startDate: start,
            endDate: end,
          )
          .first;

      // Fetch associated users for name resolution.
      final users = await _firestore.getAssociatedUsersForElder(elder.id);
      final nameMap = <String, String>{};
      for (final u in users) {
        nameMap[u.uid] = u.displayName.isNotEmpty ? u.displayName : u.email;
      }

      // Group by user.
      final perUser = <String, List<JournalEntry>>{};
      for (final e in entries) {
        perUser.putIfAbsent(e.loggedByUserId, () => []).add(e);
      }

      // Build per-person highlights.
      final highlights = <_PersonHighlight>[];
      for (final uid in perUser.keys) {
        final userEntries = perUser[uid]!;
        final name = nameMap[uid] ?? uid;

        // Find their most-logged type.
        final typeCounts = <EntryType, int>{};
        for (final e in userEntries) {
          typeCounts[e.type] = (typeCounts[e.type] ?? 0) + 1;
        }
        final topType = typeCounts.entries
            .reduce((a, b) => a.value >= b.value ? a : b);

        highlights.add(_PersonHighlight(
          name: name,
          totalEntries: userEntries.length,
          topType: topType.key,
          topTypeCount: topType.value,
          topTypeLabel: _typeLabel(topType.key),
        ));
      }

      // Sort by total entries descending — top contributor first.
      highlights.sort((a, b) => b.totalEntries.compareTo(a.totalEntries));

      // Count total reactions across all entries.
      int totalReactions = 0;
      for (final e in entries) {
        totalReactions += e.reactionCount;
      }

      // Unique active days.
      final activeDays = entries.map((e) => e.dateString).toSet().length;

      if (mounted) {
        setState(() {
          _summary = _WeeklySummary(
            totalEntries: entries.length,
            activeDays: activeDays,
            caregiverCount: perUser.keys.length,
            highlights: highlights,
            totalReactions: totalReactions,
            weekLabel:
                'Week of ${DateFormat('MMM d').format(start)}',
          );
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('WeeklyTeamSummaryCard: error loading summary: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  String _typeLabel(EntryType t) {
    switch (t) {
      case EntryType.medication: return 'medication logs';
      case EntryType.meal: return 'meal logs';
      case EntryType.mood: return 'mood check-ins';
      case EntryType.sleep: return 'sleep logs';
      case EntryType.pain: return 'pain assessments';
      case EntryType.vital: return 'vital readings';
      case EntryType.activity: return 'activity logs';
      case EntryType.expense: return 'expense entries';
      case EntryType.handoff: return 'shift handoffs';
      case EntryType.incontinence: return 'continence logs';
      case EntryType.message: return 'team messages';
      default: return 'care entries';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox.shrink();
    if (_summary == null || _summary!.totalEntries == 0) {
      return const SizedBox.shrink();
    }

    final s = _summary!;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Text('\uD83C\uDF89',
                    style: TextStyle(fontSize: 24)), // 🎉
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Team Celebration',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4E342E),
                          )),
                      Text(s.weekLabel,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF8D6E63),
                          )),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Team totals
            Text(
              _buildTeamMessage(s),
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Color(0xFF4E342E),
              ),
            ),
            const SizedBox(height: 12),

            // Per-person highlights
            ...s.highlights.take(5).map((h) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('\u2B50 ',
                          style: TextStyle(fontSize: 14)), // ⭐
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF4E342E),
                                height: 1.3),
                            children: [
                              TextSpan(
                                  text: h.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              TextSpan(
                                  text:
                                      ' logged ${h.totalEntries} entries — including ${h.topTypeCount} ${h.topTypeLabel}.'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                )),

            // Reactions shoutout
            if (s.totalReactions > 0) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.favorite,
                      size: 14, color: Color(0xFFE91E63)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Your team shared ${s.totalReactions} reaction${s.totalReactions == 1 ? '' : 's'} this week \u2014 supporting each other!',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF8D6E63)),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 10),

            // Closing cheer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Text('\uD83D\uDCAA', style: TextStyle(fontSize: 16)), // 💪
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Every log matters. Every handoff counts. Thank you for showing up.',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Color(0xFF5D4037),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _buildTeamMessage(_WeeklySummary s) {
    final parts = <String>[];
    parts.add(
        'This week your care team logged ${s.totalEntries} action${s.totalEntries == 1 ? '' : 's'}');
    if (s.activeDays > 1) {
      parts.add('across ${s.activeDays} days');
    }
    if (s.caregiverCount > 1) {
      parts.add('with ${s.caregiverCount} caregivers active');
    }
    return '${parts.join(' ')}. Incredible work!';
  }
}

// ── Data classes ──────────────────────────────────────────────────

class _WeeklySummary {
  final int totalEntries;
  final int activeDays;
  final int caregiverCount;
  final List<_PersonHighlight> highlights;
  final int totalReactions;
  final String weekLabel;

  const _WeeklySummary({
    required this.totalEntries,
    required this.activeDays,
    required this.caregiverCount,
    required this.highlights,
    required this.totalReactions,
    required this.weekLabel,
  });
}

class _PersonHighlight {
  final String name;
  final int totalEntries;
  final EntryType topType;
  final int topTypeCount;
  final String topTypeLabel;

  const _PersonHighlight({
    required this.name,
    required this.totalEntries,
    required this.topType,
    required this.topTypeCount,
    required this.topTypeLabel,
  });
}
