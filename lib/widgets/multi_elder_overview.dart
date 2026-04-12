// lib/widgets/multi_elder_overview.dart
//
// "All Elders" dashboard content — shows one status card per elder with
// last activity, today's entry count, and a tap-to-switch action.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:cecelia_care_flutter/models/elder_profile.dart';
import 'package:cecelia_care_flutter/models/journal_entry.dart';
import 'package:cecelia_care_flutter/providers/active_elder_provider.dart';
import 'package:cecelia_care_flutter/services/firestore_service.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';

class MultiElderOverview extends StatelessWidget {
  const MultiElderOverview({
    super.key,
    required this.elders,
    required this.currentUserId,
  });

  final List<ElderProfile> elders;
  final String currentUserId;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        // Summary banner
        _SummaryBanner(
          elders: elders,
          currentUserId: currentUserId,
          startOfDay: startOfDay,
          endOfDay: endOfDay,
        ),
        const SizedBox(height: 16),
        Text('CARE RECIPIENTS (${elders.length})',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
              color: AppTheme.textSecondary,
            )),
        const SizedBox(height: 10),
        ...elders.map((elder) => _ElderStatusCard(
              elder: elder,
              currentUserId: currentUserId,
              startOfDay: startOfDay,
              endOfDay: endOfDay,
            )),
      ],
    );
  }
}

// ── Summary banner ────────────────────────────────────────────────

class _SummaryBanner extends StatelessWidget {
  const _SummaryBanner({
    required this.elders,
    required this.currentUserId,
    required this.startOfDay,
    required this.endOfDay,
  });

  final List<ElderProfile> elders;
  final String currentUserId;
  final DateTime startOfDay;
  final DateTime endOfDay;

  @override
  Widget build(BuildContext context) {
    final elderIds = elders.map((e) => e.id).toList();
    final firestoreService = context.read<FirestoreService>();

    return StreamBuilder<List<JournalEntry>>(
      stream: firestoreService.getJournalEntriesStreamForElders(
        elderIds: elderIds,
        currentUserId: currentUserId,
        startDate: startOfDay,
        endDate: endOfDay,
      ),
      builder: (context, snapshot) {
        final todayCount = snapshot.data?.length ?? 0;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: AppTheme.primaryColor.withValues(alpha: 0.15)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatColumn(
                  value: '${elders.length}',
                  label: 'Recipients',
                  icon: Icons.people_outline),
              Container(width: 1, height: 36, color: Colors.grey.shade300),
              _StatColumn(
                  value: '$todayCount',
                  label: 'Entries today',
                  icon: Icons.edit_note_outlined),
            ],
          ),
        );
      },
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({
    required this.value,
    required this.label,
    required this.icon,
  });
  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryColor),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label,
            style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
      ],
    );
  }
}

// ── Elder status card ─────────────────────────────────────────────

class _ElderStatusCard extends StatelessWidget {
  const _ElderStatusCard({
    required this.elder,
    required this.currentUserId,
    required this.startOfDay,
    required this.endOfDay,
  });

  final ElderProfile elder;
  final String currentUserId;
  final DateTime startOfDay;
  final DateTime endOfDay;

  @override
  Widget build(BuildContext context) {
    final firestoreService = context.read<FirestoreService>();
    final displayName = elder.preferredName?.isNotEmpty == true
        ? elder.preferredName!
        : elder.profileName;
    final initial =
        displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 1,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            context.read<ActiveElderProvider>().setActive(elder);
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 24,
                  backgroundColor:
                      AppTheme.primaryColor.withValues(alpha: 0.12),
                  backgroundImage: elder.photoUrl != null &&
                          elder.photoUrl!.isNotEmpty
                      ? NetworkImage(elder.photoUrl!)
                      : null,
                  child: elder.photoUrl == null || elder.photoUrl!.isEmpty
                      ? Text(initial,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ))
                      : null,
                ),
                const SizedBox(width: 14),
                // Name + status
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(displayName,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      // Last activity + today count
                      StreamBuilder<List<JournalEntry>>(
                        stream: firestoreService.getJournalEntriesStreamForElders(
                          elderIds: [elder.id],
                          currentUserId: currentUserId,
                          startDate: startOfDay,
                          endDate: endOfDay,
                        ),
                        builder: (context, snap) {
                          final entries = snap.data ?? [];
                          final count = entries.length;

                          // Last activity timestamp
                          String activityLabel = 'No activity today';
                          Color activityColor = AppTheme.statusRed;
                          if (entries.isNotEmpty) {
                            final latest =
                                entries.first.entryTimestamp.toDate();
                            final diff =
                                DateTime.now().difference(latest);
                            if (diff.inMinutes < 60) {
                              activityLabel =
                                  'Active ${diff.inMinutes}m ago';
                              activityColor = AppTheme.statusGreen;
                            } else if (diff.inHours < 12) {
                              activityLabel =
                                  'Active ${diff.inHours}h ago';
                              activityColor = AppTheme.tileOrange;
                            } else {
                              activityLabel = DateFormat('h:mm a')
                                  .format(latest);
                              activityColor = AppTheme.statusRed;
                            }
                          }

                          return Row(
                            children: [
                              // Activity dot
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: activityColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(activityLabel,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: activityColor)),
                              const Spacer(),
                              if (count > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor
                                        .withValues(alpha: 0.1),
                                    borderRadius:
                                        BorderRadius.circular(10),
                                  ),
                                  child: Text('$count today',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.primaryColor,
                                      )),
                                ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right,
                    size: 18, color: AppTheme.textLight),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
