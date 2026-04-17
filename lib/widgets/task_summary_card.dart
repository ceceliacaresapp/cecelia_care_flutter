// lib/widgets/task_summary_card.dart
//
// Compact dashboard card showing the current user's open/accepted tasks for
// the active care recipient. Tap to open the Task Delegation Hub.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:cecelia_care_flutter/models/care_task.dart';
import 'package:cecelia_care_flutter/providers/active_elder_provider.dart';
import 'package:cecelia_care_flutter/screens/task_delegation_screen.dart';
import 'package:cecelia_care_flutter/services/firestore_service.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';

class TaskSummaryCard extends StatefulWidget {
  const TaskSummaryCard({super.key});

  @override
  State<TaskSummaryCard> createState() => _TaskSummaryCardState();
}

class _TaskSummaryCardState extends State<TaskSummaryCard> {
  Stream<List<Map<String, dynamic>>>? _stream;
  String? _streamElderId;
  String? _streamUid;

  @override
  Widget build(BuildContext context) {
    final elder = context.watch<ActiveElderProvider>().activeElder;
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (elder == null || uid.isEmpty) return const SizedBox.shrink();

    // Cache the stream and only rebuild it when the elder or user changes,
    // not on every parent rebuild. Constructing the stream inline (the
    // previous behavior) leaked a fresh Firestore listener every rebuild.
    if (_stream == null || _streamElderId != elder.id || _streamUid != uid) {
      _stream = context
          .read<FirestoreService>()
          .getMyTasksStream(elder.id, uid);
      _streamElderId = elder.id;
      _streamUid = uid;
    }

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _stream,
      builder: (context, snap) {
        final raw = snap.data ?? const [];
        final tasks = raw
            .map((d) =>
                CareTask.fromFirestore(elder.id, d['id'] as String, d))
            .toList();
        final overdue = tasks.where((t) => t.isOverdue).length;
        final next = tasks.firstWhere(
          (t) => t.dueDate != null,
          orElse: () => tasks.isNotEmpty
              ? tasks.first
              : CareTask(
                  elderId: elder.id,
                  title: '',
                  category: 'other',
                  createdBy: '',
                  createdByName: '',
                  status: 'open',
                ),
        );

        final hasTasks = tasks.isNotEmpty;
        final accent = overdue > 0
            ? AppTheme.dangerColor
            : AppTheme.tileBlueDark;

        return GestureDetector(
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const TaskDelegationScreen())),
          child: Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
              side: BorderSide(
                  color: accent.withValues(alpha: 0.3), width: 1),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppTheme.radiusS),
                    ),
                    child: Icon(Icons.task_alt_outlined,
                        color: accent, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasTasks
                              ? 'You have ${tasks.length} pending task${tasks.length == 1 ? '' : 's'}'
                              : 'All caught up!',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: accent,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          hasTasks
                              ? (next.title.isEmpty
                                  ? 'Tap to view'
                                  : 'Next: ${next.title}${next.dueDate != null ? " · ${DateFormat('MMM d').format(next.dueDate!)}" : ""}')
                              : 'No tasks assigned to you for ${elder.profileName}.',
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (overdue > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.dangerColor,
                        borderRadius: BorderRadius.circular(AppTheme.radiusS),
                      ),
                      child: Text('$overdue overdue',
                          style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                    ),
                  const Icon(Icons.chevron_right,
                      color: AppTheme.textLight),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
