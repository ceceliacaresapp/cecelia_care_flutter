// lib/screens/medications/taper_schedule_list_screen.dart
//
// Lists every taper schedule (active, draft, completed, cancelled) for
// the currently-active elder. Tapping a card opens
// TaperScheduleEditorScreen for view/edit; the FAB creates a new one.
//
// Surfaces active tapers at the top with today's dose visible without
// drilling in — the single most important glanceable datum for a
// caregiver picking up a shift.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:cecelia_care_flutter/models/caregiver_role.dart';
import 'package:cecelia_care_flutter/models/taper_schedule.dart';
import 'package:cecelia_care_flutter/providers/active_elder_provider.dart';
import 'package:cecelia_care_flutter/services/firestore_service.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';
import 'package:cecelia_care_flutter/utils/haptic_utils.dart';
import 'package:cecelia_care_flutter/utils/page_transitions.dart';

import 'taper_schedule_editor_screen.dart';

const Color _kAccent = AppTheme.tileOrange;
const Color _kAccentDeep = AppTheme.tileOrangeDeep;

class TaperScheduleListScreen extends StatelessWidget {
  const TaperScheduleListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final elderProv = context.watch<ActiveElderProvider>();
    final elder = elderProv.activeElder;
    final canEdit = elderProv.currentUserRole.canLog;

    if (elder == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Tapering Schedules'),
          backgroundColor: _kAccent,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('No care recipient selected.',
              style: TextStyle(color: AppTheme.textSecondary)),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tapering Schedules'),
        backgroundColor: _kAccent,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: canEdit
          ? FloatingActionButton.extended(
              backgroundColor: _kAccentDeep,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('New taper'),
              onPressed: () {
                HapticUtils.tap();
                Navigator.push(
                  context,
                  FadeSlideRoute(
                      page: const TaperScheduleEditorScreen()),
                );
              },
            )
          : null,
      body: StreamBuilder<List<TaperSchedule>>(
        stream: context
            .read<FirestoreService>()
            .taperSchedulesStream(elder.id),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting &&
              !snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final tapers = snap.data ?? const <TaperSchedule>[];
          if (tapers.isEmpty) {
            return _EmptyState(canEdit: canEdit);
          }

          // Group: active/draft first (most important), then completed,
          // then cancelled.
          final active = <TaperSchedule>[];
          final completed = <TaperSchedule>[];
          final cancelled = <TaperSchedule>[];
          for (final t in tapers) {
            switch (t.status) {
              case TaperStatus.active:
              case TaperStatus.draft:
                active.add(t);
                break;
              case TaperStatus.completed:
                completed.add(t);
                break;
              case TaperStatus.cancelled:
                cancelled.add(t);
                break;
            }
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              _SafetyBanner(),
              const SizedBox(height: 14),
              if (active.isNotEmpty) ...[
                _SectionHeader('Active & drafts'),
                const SizedBox(height: 6),
                for (final t in active) _TaperCard(taper: t),
              ],
              if (completed.isNotEmpty) ...[
                const SizedBox(height: 14),
                _SectionHeader('Completed'),
                const SizedBox(height: 6),
                for (final t in completed)
                  _TaperCard(taper: t, dimmed: true),
              ],
              if (cancelled.isNotEmpty) ...[
                const SizedBox(height: 14),
                _SectionHeader('Cancelled'),
                const SizedBox(height: 6),
                for (final t in cancelled)
                  _TaperCard(taper: t, dimmed: true),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.canEdit});
  final bool canEdit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Icon(Icons.stacked_line_chart_outlined,
              size: 48, color: _kAccent.withValues(alpha: 0.55)),
          const SizedBox(height: 14),
          Text(
            'No tapering schedules yet.',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _kAccentDeep,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Some medications — corticosteroids, benzodiazepines, opioids, '
            'antidepressants — must be stepped down gradually. An abrupt '
            'stop can cause withdrawal, flare-ups, or serious harm.',
            style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
                height: 1.4),
          ),
          const SizedBox(height: 14),
          const Text(
            'When a doctor writes a taper plan, transcribe it here. The app '
            'will remind you of each day\'s dose so you never lose the thread.',
            style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
                height: 1.4),
          ),
          if (canEdit) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  HapticUtils.tap();
                  Navigator.push(
                    context,
                    FadeSlideRoute(
                        page: const TaperScheduleEditorScreen()),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Create first taper'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusM)),
                  backgroundColor: _kAccentDeep,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SafetyBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kAccent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(color: _kAccent.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 18, color: _kAccentDeep),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Tapering schedules here are a record-keeping and reminder '
              'tool — not medical advice. Always follow the plan your '
              'prescriber has given you.',
              style: TextStyle(
                fontSize: 12,
                color: _kAccentDeep,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }
}

class _TaperCard extends StatelessWidget {
  const _TaperCard({required this.taper, this.dimmed = false});
  final TaperSchedule taper;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final todayStep = taper.todaysStep;
    final isInWindow = taper.isTodayInWindow;
    final opacity = dimmed ? 0.7 : 1.0;

    return Opacity(
      opacity: opacity,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          onTap: () {
            HapticUtils.tap();
            Navigator.push(
              context,
              FadeSlideRoute(
                page: TaperScheduleEditorScreen(existingTaperId: taper.id),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: _statusColor(taper.status)
                            .withValues(alpha: 0.12),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusS),
                      ),
                      child: Icon(
                        Icons.trending_down,
                        size: 20,
                        color: _statusColor(taper.status),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            taper.medName.isEmpty
                                ? '(Unnamed taper)'
                                : taper.medName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            taper.summary,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _StatusPill(status: taper.status),
                  ],
                ),
                if (taper.reminderEnabled) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.alarm_outlined,
                          size: 13, color: AppTheme.textSecondary),
                      const SizedBox(width: 5),
                      Text(
                        'Daily reminder at ${taper.reminderTime}',
                        style: const TextStyle(
                            fontSize: 11, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ],
                if (isInWindow && todayStep != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: _kAccent.withValues(alpha: 0.10),
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusS),
                      border: Border.all(
                          color: _kAccent.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.today_outlined,
                            size: 16, color: _kAccentDeep),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Today: ${todayStep.doseDisplay} — ${todayStep.frequency}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _kAccentDeep,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (taper.totalDays > 0) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: taper.progress,
                      minHeight: 6,
                      backgroundColor: AppTheme.backgroundGray,
                      valueColor: AlwaysStoppedAnimation(
                          _statusColor(taper.status)),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Day ${taper.completedDays.clamp(0, taper.totalDays)} of '
                    '${taper.totalDays}',
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.textSecondary),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final TaperStatus status;

  @override
  Widget build(BuildContext context) {
    final c = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
      ),
      child: Text(
        status.label.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: c,
        ),
      ),
    );
  }
}

Color _statusColor(TaperStatus status) {
  switch (status) {
    case TaperStatus.active:
      return AppTheme.statusGreen;
    case TaperStatus.draft:
      return AppTheme.tileIndigo;
    case TaperStatus.completed:
      return AppTheme.textSecondary;
    case TaperStatus.cancelled:
      return AppTheme.dangerColor;
  }
}
