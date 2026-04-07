// lib/widgets/dashboard/journal_preview_card.dart
//
// Compact dashboard card showing the most recent caregiverJournalEntry
// for the current user, with a button to open the full journal screen.
// Extracted from dashboard_screen.dart so the screen file stays small.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:cecelia_care_flutter/screens/caregiver_journal/caregiver_journal_screen.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';

class JournalPreviewCard extends StatelessWidget {
  const JournalPreviewCard({super.key, required this.currentUserId});
  final String currentUserId;

  static const _kColor = AppTheme.tilePurple;

  @override
  Widget build(BuildContext context) {
    if (currentUserId.isEmpty) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('caregiverJournalEntries')
          .where('userId', isEqualTo: currentUserId)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint(
              'Dashboard journal preview stream error: ${snapshot.error}');
          return const SizedBox.shrink();
        }
        final hasEntry =
            snapshot.hasData && snapshot.data!.docs.isNotEmpty;
        final doc = hasEntry ? snapshot.data!.docs.first : null;
        final note = hasEntry
            ? (doc!.data() as Map<String, dynamic>)['note'] as String? ?? ''
            : '';
        final ts = hasEntry
            ? (doc!.data() as Map<String, dynamic>)['createdAt']
                as Timestamp?
            : null;
        final dateStr =
            ts != null ? DateFormat('MMM d').format(ts.toDate()) : '';

        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const CareGiverJournalScreen()),
          ),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _kColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kColor.withValues(alpha: 0.2)),
              boxShadow: [
                BoxShadow(
                  color: _kColor.withValues(alpha: 0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _kColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.menu_book_outlined,
                      color: _kColor, size: 18),
                ),
                const SizedBox(width: 12),
                // Content
                Expanded(
                  child: hasEntry
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  dateStr,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: _kColor.withValues(alpha: 0.8),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  'View all →',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: _kColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              note,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.textPrimary,
                                height: 1.4,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: Text(
                                'No entries yet — tap to write your first journal entry.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.add_circle_outline,
                                color: _kColor, size: 20),
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
