// lib/screens/dashboard_screen.dart
//
// The home dashboard — first tab the user lands on.

import 'package:cecelia_care_flutter/utils/page_transitions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:cecelia_care_flutter/models/elder_profile.dart';
import 'package:cecelia_care_flutter/models/entry_types.dart';
import 'package:cecelia_care_flutter/models/wandering_assessment.dart';
import 'package:cecelia_care_flutter/models/fall_risk_assessment.dart';
import 'package:cecelia_care_flutter/models/journal_entry.dart';
import 'package:cecelia_care_flutter/providers/active_elder_provider.dart';
import 'package:cecelia_care_flutter/providers/journal_service_provider.dart';
import 'package:cecelia_care_flutter/providers/medication_definitions_provider.dart';
import 'package:cecelia_care_flutter/models/medication_definition.dart';
import 'package:cecelia_care_flutter/screens/forms/mood_form.dart';
import 'package:cecelia_care_flutter/screens/forms/sleep_form.dart';
import 'package:cecelia_care_flutter/screens/forms/meal_form.dart';
import 'package:cecelia_care_flutter/screens/forms/activity_form.dart';
import 'package:cecelia_care_flutter/screens/forms/vital_form.dart';
import 'package:cecelia_care_flutter/screens/forms/pain_form.dart';
import 'package:cecelia_care_flutter/screens/forms/med_form.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cecelia_care_flutter/widgets/dashboard/badges_row.dart';
import 'package:cecelia_care_flutter/widgets/dashboard/journal_preview_card.dart';
import 'package:cecelia_care_flutter/widgets/dashboard/message_composer_sheet.dart';
import 'package:cecelia_care_flutter/services/firestore_service.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';
import 'package:cecelia_care_flutter/utils/entry_type_helpers.dart';
import 'package:cecelia_care_flutter/utils/haptic_utils.dart';
import 'package:cecelia_care_flutter/widgets/stream_error_card.dart';
import 'package:cecelia_care_flutter/widgets/wellness_summary_card.dart';
import 'package:cecelia_care_flutter/providers/wellness_provider.dart';
import 'package:cecelia_care_flutter/providers/gamification_provider.dart';
import 'package:cecelia_care_flutter/screens/wellness_checkin_screen.dart';
import 'package:cecelia_care_flutter/screens/settings/dashboard_settings_screen.dart';
import 'package:cecelia_care_flutter/widgets/symptom_insights_card.dart';
import 'package:cecelia_care_flutter/widgets/med_schedule_timeline.dart';
import 'package:cecelia_care_flutter/widgets/orientation_board_card.dart';
import 'package:cecelia_care_flutter/widgets/task_summary_card.dart';
import 'package:cecelia_care_flutter/widgets/time_since_card.dart';
import 'package:cecelia_care_flutter/widgets/compact_grid_tile.dart';
import 'package:cecelia_care_flutter/widgets/correlation_insights_card.dart';
import 'package:cecelia_care_flutter/widgets/duty_timer_card.dart';
import 'package:cecelia_care_flutter/widgets/skeleton_loaders.dart';
import 'package:cecelia_care_flutter/widgets/staggered_fade_in.dart';
import 'package:cecelia_care_flutter/widgets/weekly_team_summary_card.dart';
import 'package:cecelia_care_flutter/widgets/weight_trend_card.dart';
import 'package:cecelia_care_flutter/widgets/empty_state_widget.dart';
import 'package:cecelia_care_flutter/widgets/adherence_summary_card.dart';
import 'package:cecelia_care_flutter/widgets/hydration_progress_card.dart';
import 'package:cecelia_care_flutter/screens/weight_trend_screen.dart';
import 'package:cecelia_care_flutter/screens/medication_adherence_screen.dart';
import 'package:cecelia_care_flutter/screens/forms/hydration_form.dart';
import 'package:cecelia_care_flutter/models/user_profile.dart';
import 'package:cecelia_care_flutter/widgets/cached_avatar.dart';
import 'package:cecelia_care_flutter/screens/badges_screen.dart';

// ---------------------------------------------------------------------------
// Helper — opens a form as a modal bottom sheet.
// ---------------------------------------------------------------------------
void _openFormSheet(BuildContext context, Widget form) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(sheetContext).scaffoldBackgroundColor,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 20,
                  offset: const Offset(0, -4)),
            ],
          ),
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(sheetContext).size.height * 0.92),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppTheme.textLight,
                    borderRadius: BorderRadius.circular(2)),
              ),
              Flexible(child: form),
            ],
          ),
        ),
      );
    },
  );
}

// ---------------------------------------------------------------------------
// Opens the message composer as a modal bottom sheet.
// Mirrors the inline composer from TimelineScreen but works from the dashboard.
// ---------------------------------------------------------------------------
void _openMessageSheet(
  BuildContext context, {
  required ElderProfile activeElder,
}) {
  final firestoreService = context.read<FirestoreService>();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => MessageComposerSheet(
      activeElder: activeElder,
      firestoreService: firestoreService,
    ),
  );
}

/// Strips email addresses from display names — shows the local part
/// (before @) instead of the full address. Matches the timeline fix.
String _sanitizeDisplayName(String? raw) {
  if (raw == null || raw.isEmpty) return 'Unknown';
  if (raw.contains('@')) return raw.split('@')[0];
  return raw;
}

// ---------------------------------------------------------------------------
// Shows a bottom sheet listing individual entries for a given EntryType.
// Launched when the user taps a summary chip on the dashboard.
// ---------------------------------------------------------------------------
void _showEntriesSheet(
  BuildContext context, {
  required EntryType type,
  required List<JournalEntry> entries,
  required Color color,
  required IconData icon,
  required String label,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(sheetContext).size.height * 0.65,
        ),
        decoration: BoxDecoration(
          color: Theme.of(sheetContext).scaffoldBackgroundColor,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),

            // Header row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "Today's $label",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${entries.length} ${entries.length == 1 ? 'entry' : 'entries'}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),

            // Entry list
            Flexible(
              child: entries.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(
                        'No entries found.',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      itemCount: entries.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final entry = entries[i];
                        final time = DateFormat('h:mm a')
                            .format(entry.entryTimestamp.toDate());
                        final loggedBy =
                            _sanitizeDisplayName(entry.loggedByDisplayName);
                        final summary = _entrySummary(entry);

                        return Padding(
                          padding:
                              const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              // Time column
                              SizedBox(
                                width: 64,
                                child: Text(
                                  time,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: color,
                                  ),
                                ),
                              ),
                              // Details column
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    if (summary.isNotEmpty)
                                      Text(
                                        summary,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppTheme.textPrimary,
                                          height: 1.3,
                                        ),
                                        maxLines: 3,
                                        overflow:
                                            TextOverflow.ellipsis,
                                      ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Logged by $loggedBy',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color:
                                            AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      );
    },
  );
}

/// Produces a short human-readable summary line for a journal entry.
String _entrySummary(JournalEntry entry) {
  // The entry's `text` field is the most universal summary.
  // If it's empty, fall back to a type-specific one-liner from `data`.
  if (entry.text != null && entry.text!.trim().isNotEmpty) {
    return entry.text!.trim();
  }
  switch (entry.type) {
    case EntryType.mood:
      return entry.data?['mood'] ?? 'Mood logged';
    case EntryType.medication:
      return entry.data?['medicationName'] ?? 'Medication logged';
    case EntryType.sleep:
      final hrs = entry.data?['hours'];
      return hrs != null ? '$hrs hours of sleep' : 'Sleep logged';
    case EntryType.meal:
      return entry.data?['mealType'] ?? 'Meal logged';
    case EntryType.pain:
      final level = entry.data?['level'];
      return level != null ? 'Pain level $level/10' : 'Pain logged';
    case EntryType.activity:
      return entry.data?['activityType'] ?? 'Activity logged';
    case EntryType.vital:
      return entry.data?['vitalType'] ?? 'Vital logged';
    case EntryType.expense:
      final amt = entry.data?['amount'];
      return amt != null ? 'Expense: \$$amt' : 'Expense logged';
    case EntryType.message:
      return 'Message';
    case EntryType.handoff:
      final shift = entry.data?['shift'] as String?;
      return (shift != null && shift.isNotEmpty)
          ? '$shift shift handoff'
          : 'Shift handoff';
    case EntryType.incontinence:
      final iType = entry.data?['incontinenceType'] as String? ?? '';
      final severity = entry.data?['severity'] as String? ?? '';
      return iType.isNotEmpty
          ? '${iType[0].toUpperCase()}${iType.substring(1)} \u00B7 $severity'
          : 'Incontinence logged';
    case EntryType.nightWaking:
      final cause = entry.data?['cause'] as String? ?? '';
      final duration = entry.data?['duration'] as String? ?? '';
      return cause.isNotEmpty ? '$cause \u00B7 $duration' : 'Night waking logged';
    case EntryType.hydration:
      final vol = entry.data?['volume']?.toString() ?? '';
      final hUnit = entry.data?['unit'] as String? ?? 'oz';
      final fType = entry.data?['fluidType'] as String? ?? '';
      return fType.isNotEmpty ? '$fType \u00B7 $vol $hUnit' : '$vol $hUnit fluid';
    case EntryType.custom:
      return entry.data?['customTypeName'] as String? ?? 'Custom entry';
    default:
      return 'Entry logged';
  }
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Map<String, dynamic>>? _sectionConfig;

  // Cached alert streams. Constructed once per elder so the conditional
  // alert StreamBuilders don't tear down and recreate Firestore listeners
  // on every parent rebuild (which happens on any provider notification).
  String? _cachedAlertElderId;
  Stream<QuerySnapshot<Map<String, dynamic>>>? _wanderingAlertStream;
  Stream<QuerySnapshot<Map<String, dynamic>>>? _fallRiskAlertStream;
  Stream<QuerySnapshot<Map<String, dynamic>>>? _turningLogsAlertStream;

  // Cached "today's care log" stream — same reasoning as the alerts.
  String? _cachedCareLogKey; // elderId|userId|yyyy-MM-dd
  Stream<List<JournalEntry>>? _careLogStream;

  Stream<List<JournalEntry>> _ensureCareLogStream({
    required String elderId,
    required String currentUserId,
    required DateTime startOfDay,
    required DateTime endOfDay,
  }) {
    final key =
        '$elderId|$currentUserId|${startOfDay.year}-${startOfDay.month}-${startOfDay.day}';
    if (_careLogStream != null && _cachedCareLogKey == key) {
      return _careLogStream!;
    }
    _cachedCareLogKey = key;
    _careLogStream = context
        .read<JournalServiceProvider>()
        .getJournalEntriesStream(
          elderId: elderId,
          currentUserId: currentUserId,
          startDate: startOfDay,
          endDate: endOfDay,
        );
    return _careLogStream!;
  }

  void _ensureAlertStreams(String elderId) {
    if (_cachedAlertElderId == elderId &&
        _wanderingAlertStream != null &&
        _fallRiskAlertStream != null &&
        _turningLogsAlertStream != null) {
      return;
    }
    _cachedAlertElderId = elderId;
    final elderRef = FirebaseFirestore.instance
        .collection('elderProfiles')
        .doc(elderId);
    _wanderingAlertStream = elderRef
        .collection('wanderingAssessments')
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots();
    _fallRiskAlertStream = elderRef
        .collection('fallRiskAssessments')
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots();
    _turningLogsAlertStream = elderRef
        .collection('turningLogs')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots();
  }

  @override
  void initState() {
    super.initState();
    _loadSectionConfig();
  }

  Future<void> _loadSectionConfig() async {
    final config = await loadDashboardSections();
    if (mounted) setState(() => _sectionConfig = config);
  }

  /// Builds the ordered list of section widgets based on saved config.
  List<Widget> _buildDynamicSections({
    required BuildContext context,
    required ElderProfile activeElder,
    required bool isMultiView,
    required List<ElderProfile> allElders,
    required String currentUserId,
    required String currentDateStr,
    required DateTime startOfDay,
    required DateTime endOfDay,
  }) {
    final firestoreService = context.read<FirestoreService>();
    final sectionBuilders = <String, List<Widget> Function()>{
      'orientationBoard': () => [
        const SizedBox(height: 4),
        const OrientationBoardCard(),
      ],
      'careTeam': () {
        if (isMultiView) return <Widget>[];
        return <Widget>[
          const SizedBox(height: 12),
          _CareTeamRow(elderId: activeElder.id),
        ];
      },
      'weeklyTeamSummary': () => [
        const SizedBox(height: 12),
        const WeeklyTeamSummaryCard(),
      ],
      'wellness': () => [
        Builder(builder: (ctx) {
          final wellProv = ctx.watch<WellnessProvider>();
          final gamProv = ctx.watch<GamificationProvider>();
          if (wellProv.recentCheckins.isEmpty && gamProv.totalPoints == 0) {
            return const SizedBox.shrink();
          }
          final dailyScores = wellProv.recentCheckins.reversed
              .map((c) => c.wellbeingScore)
              .toList();
          return WellnessSummaryCard(
            wellbeingScore: wellProv.wellbeingScore,
            burnoutRiskLevel: wellProv.burnoutStatus.level.name,
            dailyScores: dailyScores,
            dimensionAverages: wellProv.dimensionAverages,
            currentStreak: gamProv.currentStreak,
            level: gamProv.level,
            levelTitle: gamProv.levelTitle,
            hasCheckedInToday: wellProv.hasCheckedInToday,
            onTap: () => Navigator.of(ctx).push(
              FadeSlideRoute(page: const WellnessCheckinScreen()),
            ),
          );
        }),
      ],
      'quickMeds': () {
        // Pinned meds are provider-coupled to the active elder.
        // In multi-view, hide — the provider only has one elder's data.
        if (isMultiView) return <Widget>[];
        return [
          Builder(builder: (ctx) {
            final pinned = ctx.select<MedicationDefinitionsProvider, List>((p) => p.pinnedMeds);
            if (pinned.isEmpty) return const SizedBox.shrink();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                const _SectionLabel(label: 'Quick meds'),
                const SizedBox(height: 10),
                SizedBox(
                  height: 72,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: pinned.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, i) => _PinnedMedCard(
                      med: pinned[i],
                      activeElder: activeElder,
                      currentDateStr: currentDateStr,
                    ),
                  ),
                ),
              ],
            );
          }),
        ];
      },
      'careLog': () {
        if (isMultiView) {
          // Single merged stream for all care recipients (whereIn query).
          final elderIds = allElders.map((e) => e.id).toList();
          return <Widget>[
            const SizedBox(height: 20),
            const _SectionLabel(label: "Today's care log"),
            const SizedBox(height: 10),
            StreamBuilder<List<JournalEntry>>(
              stream: firestoreService.getJournalEntriesStreamForElders(
                elderIds: elderIds,
                currentUserId: currentUserId,
                startDate: startOfDay,
                endDate: endOfDay,
              ),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return StreamErrorCard(
                    message: "Couldn't load today's care log",
                    error: snapshot.error,
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const SkeletonDashboardSection();
                }
                final entries = snapshot.data ?? [];
                // Group entries by care recipient and render per-recipient grids.
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final elder in allElders) ...[
                      _ElderSubheader(
                        elder: elder,
                        index: allElders.indexOf(elder),
                      ),
                      _TodaySummaryGrid(
                        entries: entries
                            .where((e) => e.elderId == elder.id)
                            .toList(),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ],
                );
              },
            ),
          ];
        }
        return <Widget>[
          const SizedBox(height: 20),
          const _SectionLabel(label: "Today's care log"),
          const SizedBox(height: 10),
          StreamBuilder<List<JournalEntry>>(
            stream: _ensureCareLogStream(
              elderId: activeElder.id,
              currentUserId: currentUserId,
              startOfDay: startOfDay,
              endOfDay: endOfDay,
            ),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return StreamErrorCard(
                  message: "Couldn't load today's care log",
                  error: snapshot.error,
                );
              }
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const SkeletonDashboardSection();
              }
              return _TodaySummaryGrid(entries: snapshot.data ?? []);
            },
          ),
        ];
      },
      'achievements': () => [
        const SizedBox(height: 20),
        _SectionLabel(
          label: 'Achievements',
          onTap: () => Navigator.push(context,
              FadeSlideRoute(page: const BadgesScreen())),
        ),
        const SizedBox(height: 10),
        const BadgesRow(),
      ],
      'journal': () => [
        const SizedBox(height: 20),
        const _SectionLabel(label: 'My Journal'),
        const SizedBox(height: 10),
        JournalPreviewCard(currentUserId: currentUserId),
      ],
      'taskSummary': () {
        if (isMultiView) return <Widget>[];
        return <Widget>[
          const SizedBox(height: 20),
          const _SectionLabel(label: 'Tasks'),
          const SizedBox(height: 10),
          const TaskSummaryCard(),
        ];
      },
      'quickLog': () {
        if (!context.select<ActiveElderProvider, bool>((p) => p.canLog)) return <Widget>[];
        if (isMultiView) {
          // Multi-view: render one quick-log row per elder, mirroring the
          // careLog section so caregivers managing multiple recipients can
          // log to any of them without leaving the dashboard.
          return <Widget>[
            const SizedBox(height: 20),
            const _SectionLabel(label: 'Quick log'),
            const SizedBox(height: 10),
            for (final elder in allElders) ...[
              _ElderSubheader(
                elder: elder,
                index: allElders.indexOf(elder),
              ),
              _QuickActionsGrid(
                activeElder: elder,
                currentDateStr: currentDateStr,
              ),
              const SizedBox(height: 8),
            ],
          ];
        }
        return <Widget>[
          const SizedBox(height: 20),
          const _SectionLabel(label: 'Quick log'),
          const SizedBox(height: 10),
          _QuickActionsGrid(
            activeElder: activeElder,
            currentDateStr: currentDateStr,
          ),
        ];
      },
      'insights': () {
        if (isMultiView) return <Widget>[];
        return <Widget>[
          const SizedBox(height: 20),
          const _SectionLabel(label: 'Symptom insights'),
          const SizedBox(height: 10),
          const SymptomInsightsCard(),
        ];
      },
      'medSchedule': () {
        if (isMultiView) return <Widget>[];
        return <Widget>[
          Builder(builder: (ctx) {
            final meds = ctx.select<MedicationDefinitionsProvider, List>((p) => p.medDefinitions);
            if (meds.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                const SizedBox(height: 20),
                _SectionLabel(label: 'Med schedule'),
                const SizedBox(height: 10),
                MedScheduleTimeline(),
              ],
            );
          }),
        ];
      },
      'dutyTimer': () => [
        const SizedBox(height: 20),
        const _SectionLabel(label: 'Duty timer'),
        const SizedBox(height: 10),
        const DutyTimerCard(),
      ],
      'timeSince': () {
        if (isMultiView) return <Widget>[];
        return <Widget>[
          const SizedBox(height: 20),
          const _SectionLabel(label: 'Time since last'),
          const SizedBox(height: 10),
          const TimeSinceCard(),
        ];
      },
      'correlationInsights': () {
        if (isMultiView) return <Widget>[];
        return <Widget>[
          const SizedBox(height: 20),
          const _SectionLabel(label: 'Insights'),
          const SizedBox(height: 10),
          const CorrelationInsightsCard(),
        ];
      },
      'weightTrend': () {
        if (isMultiView) return <Widget>[];
        return <Widget>[
          const SizedBox(height: 20),
          _SectionLabel(
            label: 'Weight trend',
            onTap: () => Navigator.push(context,
                FadeSlideRoute(page: const WeightTrendScreen())),
          ),
          const SizedBox(height: 10),
          const WeightTrendCard(),
        ];
      },
      'adherenceSummary': () {
        if (isMultiView) return <Widget>[];
        return <Widget>[
          const SizedBox(height: 20),
          _SectionLabel(
            label: 'Med adherence',
            onTap: () => Navigator.push(context,
                FadeSlideRoute(page: const MedicationAdherenceScreen())),
          ),
          const SizedBox(height: 10),
          const AdherenceSummaryCard(),
        ];
      },
      'hydrationProgress': () {
        if (isMultiView) return <Widget>[];
        return <Widget>[
          const SizedBox(height: 20),
          _SectionLabel(
            label: 'Hydration',
            onTap: () {
              showModalBottomSheet(
                context: context,
                useRootNavigator: true,
                isScrollControlled: true,
                useSafeArea: true,
                backgroundColor: Colors.transparent,
                builder: (sheetCtx) => Padding(
                  padding: EdgeInsets.only(
                      bottom: MediaQuery.of(sheetCtx).viewInsets.bottom),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(sheetCtx).scaffoldBackgroundColor,
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20)),
                    ),
                    child: HydrationForm(
                      onClose: () {},
                      currentDate: currentDateStr,
                      activeElder: activeElder,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          const HydrationProgressCard(),
        ];
      },
    };

    // Use saved order, or defaults if not loaded yet.
    final order = _sectionConfig ?? kDefaultSections;
    final widgets = <Widget>[];
    int sectionIdx = 0;

    // Track which sections were hidden because they aren't compatible
    // with multi-elder view (e.g. WeightTrendCard, AdherenceSummaryCard,
    // SymptomInsightsCard — all coupled to a single ActiveElderProvider).
    // We use this list to render a "switch to single elder view" hint at
    // the bottom so users understand the dashboard isn't broken.
    final hiddenInMultiView = <String>[];

    for (final section in order) {
      final key = section['key'] as String;
      final visible = section['visible'] as bool? ?? true;
      if (!visible) continue;

      final builder = sectionBuilders[key];
      if (builder == null) continue;
      final result = builder();
      if (result.isEmpty && isMultiView && _isMultiViewIncompatible(key)) {
        hiddenInMultiView.add(_friendlySectionLabel(key));
      } else if (result.isNotEmpty) {
        widgets.add(StaggeredFadeIn(
          index: sectionIdx++,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: result,
          ),
        ));
      }
    }

    if (isMultiView && hiddenInMultiView.isNotEmpty) {
      widgets.add(_MultiViewHiddenHint(hiddenLabels: hiddenInMultiView));
    }

    return widgets;
  }

  /// Sections that are hidden in multi-view because their underlying
  /// widget is hard-wired to the active elder via a provider. Listing
  /// them in a friendly hint helps users understand why the dashboard
  /// looks shorter when multiple elders are selected.
  static const Set<String> _multiViewIncompatibleSections = {
    'pinnedMeds',
    'taskSummary',
    'insights',
    'medSchedule',
    'weightTrend',
    'adherenceSummary',
    'hydrationProgress',
  };

  bool _isMultiViewIncompatible(String key) =>
      _multiViewIncompatibleSections.contains(key);

  String _friendlySectionLabel(String key) {
    // Look up the saved config for the human label, fall back to the
    // hard-coded one used during dashboard reset.
    final fromConfig = _sectionConfig?.firstWhere(
      (s) => s['key'] == key,
      orElse: () => const <String, dynamic>{},
    );
    final label = fromConfig?['label'] as String?;
    if (label != null && label.isNotEmpty) return label;
    return key;
  }

  @override
  Widget build(BuildContext context) {
    final elderProv = context.watch<ActiveElderProvider>();
    final activeElder = elderProv.activeElder;
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    final isMultiView = elderProv.isMultiView;
    final allElders = elderProv.allElders;

    // In multi-view use the first elder as fallback for methods that need one.
    final effectiveElder = isMultiView
        ? (activeElder ?? allElders.firstOrNull)
        : activeElder;

    if (effectiveElder == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'No care recipient selected.\nGo to Settings to set one up.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ),
      );
    }
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final currentDateStr = DateFormat('yyyy-MM-dd').format(now);

    return RefreshIndicator(
      onRefresh: () async {
        await _loadSectionConfig();
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        children: [
          // Customize dashboard link
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () async {
                await Navigator.push(
                  context,
                  FadeSlideRoute(page: const DashboardSettingsScreen()),
                );
                // Reload config when returning from settings
                _loadSectionConfig();
              },
              icon: const Icon(Icons.tune_outlined, size: 14),
              label: const Text('Customize'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.textSecondary,
                textStyle: const TextStyle(fontSize: 11),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),

          // Wandering risk alert (conditional — only shows for High/Critical)
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: (() {
              _ensureAlertStreams(effectiveElder.id);
              return _wanderingAlertStream;
            })(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                debugPrint(
                    'Dashboard wanderingAlert stream error: ${snapshot.error}');
                return const SizedBox.shrink();
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const SizedBox.shrink();
              }
              final data = snapshot.data!.docs.first.data();
              final assessment = WanderingAssessment.fromFirestore(
                  snapshot.data!.docs.first.id, data);
              if (assessment.rawRiskScore < 6) return const SizedBox.shrink();

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: assessment.riskColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  border: Border.all(
                      color: assessment.riskColor.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_outlined,
                        color: assessment.riskColor),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Wandering Risk: ${assessment.riskLevel}',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: assessment.riskColor)),
                          Text(assessment.riskSummary,
                              style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // Fall risk alert (conditional — only shows for High/Very High)
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _fallRiskAlertStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                debugPrint(
                    'Dashboard fallRiskAlert stream error: ${snapshot.error}');
                return const SizedBox.shrink();
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const SizedBox.shrink();
              }
              final data = snapshot.data!.docs.first.data();
              final assessment = FallRiskAssessment.fromFirestore(
                  snapshot.data!.docs.first.id, data);
              if (assessment.rawRiskScore < 8) return const SizedBox.shrink();

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: assessment.riskColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  border: Border.all(
                      color: assessment.riskColor.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.elderly_outlined,
                        color: assessment.riskColor),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Fall Risk: ${assessment.riskLevel}',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: assessment.riskColor)),
                          Text(assessment.riskSummary,
                              style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // Time since last turn alert (3h+ = overdue)
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _turningLogsAlertStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                debugPrint(
                    'Dashboard turningLogs stream error: ${snapshot.error}');
                return const SizedBox.shrink();
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const SizedBox.shrink();
              }
              final data = snapshot.data!.docs.first.data();
              final ts = data['timestamp'] as Timestamp?;
              if (ts == null) return const SizedBox.shrink();
              final elapsed = DateTime.now().difference(ts.toDate());
              if (elapsed.inHours < 3) return const SizedBox.shrink();

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.statusAmber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  border: Border.all(
                      color: AppTheme.statusAmber.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.rotate_left,
                        color: elapsed.inHours >= 4
                            ? AppTheme.statusRed
                            : AppTheme.statusAmber),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Last repositioned ${elapsed.inHours}h ${elapsed.inMinutes % 60}m ago',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: elapsed.inHours >= 4
                              ? AppTheme.statusRed
                              : AppTheme.statusAmber,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // Dynamic sections
          ..._buildDynamicSections(
            context: context,
            activeElder: effectiveElder,
            isMultiView: isMultiView,
            allElders: allElders,
            currentUserId: currentUserId,
            currentDateStr: currentDateStr,
            startOfDay: startOfDay,
            endOfDay: endOfDay,
          ),
        ],
      ),
    );
  }

}

// ---------------------------------------------------------------------------
// Quick actions grid
// ---------------------------------------------------------------------------

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid({
    required this.activeElder,
    required this.currentDateStr,
  });

  final ElderProfile activeElder;
  final String currentDateStr;

  @override
  Widget build(BuildContext context) {
    final journalService = context.read<JournalServiceProvider>();

    final actions = [
      _QuickAction(
        label: 'Mood',
        icon: Icons.sentiment_satisfied_outlined,
        color: AppTheme.tilePinkBright,
        onTap: () => _openFormSheet(
          context,
          ChangeNotifierProvider.value(
            value: journalService,
            child: MoodForm(
                onClose: () {},
                currentDate: currentDateStr,
                activeElder: activeElder),
          ),
        ),
      ),
      _QuickAction(
        label: 'Medication',
        icon: Icons.medication_outlined,
        color: AppTheme.tileBlue,
        onTap: () => _openFormSheet(
          context,
          MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: journalService),
              ChangeNotifierProvider(
                create: (_) => MedicationDefinitionsProvider()
                  ..updateForElder(activeElder),
              ),
            ],
            child: MedForm(
                onClose: () {},
                currentDate: currentDateStr,
                activeElder: activeElder),
          ),
        ),
      ),
      _QuickAction(
        label: 'Vitals',
        icon: Icons.monitor_heart_outlined,
        color: AppTheme.tileOrange,
        onTap: () => _openFormSheet(
          context,
          ChangeNotifierProvider.value(
            value: journalService,
            child: VitalForm(
                onClose: () {},
                currentDate: currentDateStr,
                activeElder: activeElder),
          ),
        ),
      ),
      _QuickAction(
        label: 'Sleep',
        icon: Icons.bedtime_outlined,
        color: AppTheme.tileIndigo,
        onTap: () => _openFormSheet(
          context,
          ChangeNotifierProvider.value(
            value: journalService,
            child: SleepForm(
                onClose: () {},
                currentDate: currentDateStr,
                activeElder: activeElder),
          ),
        ),
      ),
      _QuickAction(
        label: 'Meal',
        icon: Icons.restaurant_outlined,
        color: AppTheme.statusGreen,
        onTap: () => _openFormSheet(
          context,
          ChangeNotifierProvider.value(
            value: journalService,
            child: MealForm(
                onClose: () {},
                currentDate: currentDateStr,
                activeElder: activeElder),
          ),
        ),
      ),
      _QuickAction(
        label: 'Activity',
        icon: Icons.directions_walk_outlined,
        color: AppTheme.tileTeal,
        onTap: () => _openFormSheet(
          context,
          ChangeNotifierProvider.value(
            value: journalService,
            child: ActivityForm(
                onClose: () {},
                currentDate: currentDateStr,
                activeElder: activeElder),
          ),
        ),
      ),
      _QuickAction(
        label: 'Pain',
        icon: Icons.healing_outlined,
        color: AppTheme.statusRed,
        onTap: () => _openFormSheet(
          context,
          ChangeNotifierProvider.value(
            value: journalService,
            child: PainForm(
                onClose: () {},
                currentDate: currentDateStr,
                activeElder: activeElder),
          ),
        ),
      ),
      // NEW: Message tile — opens inline message composer sheet
      _QuickAction(
        label: 'Message',
        icon: Icons.chat_bubble_outline,
        color: AppTheme.tileBlueGrey,
        onTap: () => _openMessageSheet(context, activeElder: activeElder),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.25,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: actions.length,
      itemBuilder: (context, i) {
        final action = actions[i];
        return TapScaleWrapper(
          onTap: action.onTap,
          child: Container(
            decoration: BoxDecoration(
              color: action.color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
              border: Border.all(color: action.color.withValues(alpha: 0.2)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(action.icon, color: action.color, size: 26),
                const SizedBox(height: 6),
                Text(
                  action.label,
                  style: TextStyle(
                    fontSize: 12,
                    color: action.color,
                    fontWeight: FontWeight.w500,
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

class _QuickAction {
  const _QuickAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
}

// ---------------------------------------------------------------------------
// Message composer sheet
//
// Mirrors TimelineScreen's inline message composer. Lets the caregiver
// send a public (visible to all) or private (specific caregivers) message
// directly from the dashboard. The message lands on the timeline exactly as
// if it were posted from there.
// ---------------------------------------------------------------------------

// MessageComposerSheet extracted to
// lib/widgets/dashboard/message_composer_sheet.dart

// ---------------------------------------------------------------------------
// Today's log summary grid
// ---------------------------------------------------------------------------

class _TodaySummaryGrid extends StatelessWidget {
  const _TodaySummaryGrid({required this.entries});
  final List<JournalEntry> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.edit_note_outlined,
        title: 'No entries logged today yet',
        subtitle: 'Tap a quick log button below to get started.',
        compact: true,
      );
    }

    final counts = <EntryType, int>{};
    for (final e in entries) {
      counts[e.type] = (counts[e.type] ?? 0) + 1;
    }

    final items = counts.entries
        .where((e) => e.key != EntryType.unknown)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.1,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) => _EntryTypeChip(
        type: items[i].key,
        count: items[i].value,
        entries: entries.where((e) => e.type == items[i].key).toList(),
      ),
    );
  }
}

class _EntryTypeChip extends StatelessWidget {
  const _EntryTypeChip({
    required this.type,
    required this.count,
    required this.entries,
  });
  final EntryType type;
  final int count;
  final List<JournalEntry> entries;

  @override
  Widget build(BuildContext context) {
    final color = entryTypeColor(type);
    final icon = entryTypeIcon(type);
    final label = entryTypeShortLabel(type);

    return GestureDetector(
      onTap: () => _showEntriesSheet(
        context,
        type: type,
        entries: entries,
        color: color,
        icon: icon,
        label: label,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text('$count',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            Text(label,
                style: const TextStyle(
                    fontSize: 10, color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

}


// ---------------------------------------------------------------------------
// Journal preview card — shows the most recent caregiverJournalEntry for
// the current user, with a button to open the full journal screen.
// ---------------------------------------------------------------------------

// _TodayLoadingCard removed — replaced by SkeletonDashboardSection

// ---------------------------------------------------------------------------
// Badge info dialog — shown when tapping any badge (locked or unlocked)
// ---------------------------------------------------------------------------

// _BadgesRow, showBadgeInfoDialog, and _TierRow extracted to
// lib/widgets/dashboard/badges_row.dart

// ---------------------------------------------------------------------------
// Pinned medication card — compact one-tap "Taken" quick logger
// ---------------------------------------------------------------------------

class _PinnedMedCard extends StatefulWidget {
  const _PinnedMedCard({
    required this.med,
    required this.activeElder,
    required this.currentDateStr,
  });

  final MedicationDefinition med;
  final ElderProfile activeElder;
  final String currentDateStr;

  @override
  State<_PinnedMedCard> createState() => _PinnedMedCardState();
}

class _PinnedMedCardState extends State<_PinnedMedCard> {
  bool _logging = false;
  bool _justLogged = false;

  static const _kColor = AppTheme.tileBlue;

  Future<void> _logTaken() async {
    if (_logging || _justLogged) return;
    setState(() => _logging = true);

    try {
      final journalService = context.read<JournalServiceProvider>();
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final payload = <String, dynamic>{
        'elderId': widget.activeElder.id,
        'name': widget.med.name,
        'dose': widget.med.dose ?? '',
        'taken': true,
        'time': DateFormat('HH:mm').format(DateTime.now()),
        'date': widget.currentDateStr,
        'loggedByUserId': user.uid,
        'loggedBy': user.displayName ?? user.email ?? 'Unknown',
        'updatedAt': FieldValue.serverTimestamp(),
        'isPublic': true,
        'visibleToUserIds': <String>[],
      };

      await journalService.addJournalEntry(
          'medication', payload, user.uid);

      // Decrement pill count if tracking is set up
      if (widget.med.id != null) {
        final medProv = context.read<MedicationDefinitionsProvider>();
        final elderName =
            widget.activeElder.preferredName?.isNotEmpty == true
                ? widget.activeElder.preferredName!
                : widget.activeElder.profileName;
        await medProv.decrementPillCount(
          medDefId: widget.med.id!,
          medName: widget.med.name,
          elderName: elderName,
        );
      }

      if (mounted) {
        HapticUtils.success();
        setState(() {
          _justLogged = true;
          _logging = false;
        });
        // Reset the checkmark after 2 seconds
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) setState(() => _justLogged = false);
        });
      }
    } catch (e) {
      debugPrint('_PinnedMedCard._logTaken error: $e');
      if (mounted) {
        setState(() => _logging = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not log ${widget.med.name}: $e'),
            backgroundColor: AppTheme.dangerColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _logTaken,
      child: Container(
        width: 140,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: _justLogged
              ? AppTheme.statusGreen.withValues(alpha: 0.08)
              : _kColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          border: Border.all(
            color: _justLogged
                ? AppTheme.statusGreen.withValues(alpha: 0.3)
                : _kColor.withValues(alpha: 0.25),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(
                  _justLogged ? Icons.check_circle : Icons.medication_outlined,
                  size: 16,
                  color: _justLogged ? AppTheme.statusGreen : _kColor,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    widget.med.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _justLogged
                          ? AppTheme.statusGreen
                          : _kColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            if (widget.med.dose != null && widget.med.dose!.isNotEmpty)
              Text(
                widget.med.dose!,
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            else
              Text(
                _justLogged ? 'Logged!' : 'Tap to log',
                style: TextStyle(
                  fontSize: 11,
                  color: _justLogged
                      ? AppTheme.statusGreen
                      : AppTheme.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            if (_logging)
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 1.5),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section label
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Multi-view "hidden sections" hint
// ---------------------------------------------------------------------------

/// Compact info card shown at the bottom of the dashboard in multi-view
/// mode that lists which sections are hidden because they only work for
/// a single active elder. Without this, multi-view looks like the
/// dashboard is broken — sections silently vanish with no explanation.
class _MultiViewHiddenHint extends StatelessWidget {
  const _MultiViewHiddenHint({required this.hiddenLabels});

  final List<String> hiddenLabels;

  @override
  Widget build(BuildContext context) {
    if (hiddenLabels.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          border: Border.all(
              color: AppTheme.primaryColor.withValues(alpha: 0.2)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline,
                color: AppTheme.primaryColor, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'More on the single-recipient dashboard',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${hiddenLabels.join(', ')} '
                    '${hiddenLabels.length == 1 ? 'is' : 'are'} hidden in '
                    'multi-recipient view because the data is specific to one '
                    'care recipient. Switch to single-recipient view to see '
                    'them.',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                      height: 1.4,
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
}

/// Small colored header showing an elder's name — used in multi-view to
/// separate per-elder data within a shared section.
class _ElderSubheader extends StatelessWidget {
  const _ElderSubheader({required this.elder, required this.index});
  final ElderProfile elder;
  final int index;

  static const List<Color> _palette = [
    AppTheme.tileBlue, AppTheme.statusRed, AppTheme.statusGreen,
    AppTheme.tileOrange, AppTheme.tilePurple, AppTheme.tileTeal,
  ];

  @override
  Widget build(BuildContext context) {
    final color = _palette[index % _palette.length];
    final name = elder.preferredName?.isNotEmpty == true
        ? elder.preferredName!
        : elder.profileName;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 4),
      child: Row(
        children: [
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              )),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, this.onTap});
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
        color: AppTheme.textSecondary,
      ),
    );
    if (onTap == null) return text;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          text,
          const SizedBox(width: 4),
          Icon(Icons.chevron_right,
              size: 14, color: AppTheme.textSecondary),
          const Spacer(),
          Text(
            'View',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Care Team activity row — avatar circles with green/grey dot for
// recently-active status. Tapping opens a detail bottom sheet.
// ---------------------------------------------------------------------------

class _CareTeamRow extends StatefulWidget {
  const _CareTeamRow({required this.elderId});
  final String elderId;

  @override
  State<_CareTeamRow> createState() => _CareTeamRowState();
}

class _CareTeamRowState extends State<_CareTeamRow> {
  List<UserProfile>? _users;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void didUpdateWidget(covariant _CareTeamRow old) {
    super.didUpdateWidget(old);
    if (old.elderId != widget.elderId) _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final users = await context
          .read<FirestoreService>()
          .getAssociatedUsersForElder(widget.elderId);
      if (mounted) setState(() { _users = users; _loading = false; });
    } catch (e) {
      debugPrint('_CareTeamRow fetch error: $e');
      if (mounted) setState(() { _users = []; _loading = false; });
    }
  }

  bool _isActive(UserProfile u) {
    if (u.lastActiveAt == null) return false;
    return DateTime.now().difference(u.lastActiveAt!.toDate()).inHours < 24;
  }

  void _showDetail() {
    final users = _users;
    if (users == null || users.isEmpty) return;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Care Team',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 14),
              ...users.map((u) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        _AvatarWithDot(
                          imageUrl: u.avatarUrl,
                          name: u.displayName,
                          isActive: _isActive(u),
                          radius: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(u.displayName,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600)),
                              if (u.lastActiveLabel.isNotEmpty)
                                Text(u.lastActiveLabel,
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: _isActive(u)
                                            ? AppTheme.statusGreen
                                            : AppTheme.textSecondary)),
                            ],
                          ),
                        ),
                        if (u.email.isNotEmpty)
                          Text(u.email,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textLight)),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(height: 40);
    }
    final users = _users;
    if (users == null || users.length < 2) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: _showDetail,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          border: Border.all(
              color: AppTheme.primaryColor.withValues(alpha: 0.12)),
        ),
        child: Row(
          children: [
            // Overlapping avatars
            SizedBox(
              width: 24.0 + (users.length - 1) * 18.0,
              height: 28,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  for (int i = 0; i < users.length && i < 5; i++)
                    Positioned(
                      left: i * 18.0,
                      child: _AvatarWithDot(
                        imageUrl: users[i].avatarUrl,
                        name: users[i].displayName,
                        isActive: _isActive(users[i]),
                        radius: 14,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Care Team',
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600)),
                  Text(
                    '${users.where(_isActive).length} of ${users.length} active today',
                    style: TextStyle(
                        fontSize: 11, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                size: 18, color: AppTheme.textLight),
          ],
        ),
      ),
    );
  }
}

class _AvatarWithDot extends StatelessWidget {
  const _AvatarWithDot({
    required this.imageUrl,
    required this.name,
    required this.isActive,
    this.radius = 14,
  });

  final String? imageUrl;
  final String name;
  final bool isActive;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CachedAvatar(
          imageUrl: imageUrl,
          radius: radius,
          fallbackChild: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: TextStyle(
                fontSize: radius * 0.7,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary),
          ),
        ),
        Positioned(
          right: -1,
          bottom: -1,
          child: Container(
            width: radius * 0.55,
            height: radius * 0.55,
            decoration: BoxDecoration(
              color: isActive ? AppTheme.statusGreen : AppTheme.textLight,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
