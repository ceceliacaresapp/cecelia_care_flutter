// lib/screens/dashboard_screen.dart
//
// The home dashboard — first tab the user lands on.

import 'package:flutter/material.dart' hide Badge;
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cecelia_care_flutter/models/elder_profile.dart';
import 'package:cecelia_care_flutter/models/entry_types.dart';
import 'package:cecelia_care_flutter/models/journal_entry.dart';
import 'package:cecelia_care_flutter/models/user_profile.dart';
import 'package:cecelia_care_flutter/providers/active_elder_provider.dart';
import 'package:cecelia_care_flutter/providers/badge_provider.dart';
import 'package:cecelia_care_flutter/models/badge.dart';
import 'package:cecelia_care_flutter/providers/journal_service_provider.dart';
import 'package:cecelia_care_flutter/providers/medication_definitions_provider.dart';
import 'package:cecelia_care_flutter/models/medication_definition.dart';
import 'package:cecelia_care_flutter/providers/user_profile_provider.dart';
import 'package:cecelia_care_flutter/screens/forms/mood_form.dart';
import 'package:cecelia_care_flutter/screens/forms/sleep_form.dart';
import 'package:cecelia_care_flutter/screens/forms/meal_form.dart';
import 'package:cecelia_care_flutter/screens/forms/activity_form.dart';
import 'package:cecelia_care_flutter/screens/forms/vital_form.dart';
import 'package:cecelia_care_flutter/screens/forms/pain_form.dart';
import 'package:cecelia_care_flutter/screens/forms/med_form.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cecelia_care_flutter/screens/caregiver_journal/caregiver_journal_screen.dart';
import 'package:cecelia_care_flutter/services/firestore_service.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';
import 'package:cecelia_care_flutter/utils/haptic_utils.dart';
import 'package:cecelia_care_flutter/widgets/confetti_overlay.dart';
import 'package:cecelia_care_flutter/widgets/user_selector_widget.dart';
import 'package:cecelia_care_flutter/widgets/wellness_summary_card.dart';
import 'package:cecelia_care_flutter/providers/wellness_provider.dart';
import 'package:cecelia_care_flutter/providers/gamification_provider.dart';
import 'package:cecelia_care_flutter/screens/wellness_checkin_screen.dart';
import 'package:cecelia_care_flutter/screens/settings/dashboard_settings_screen.dart';
import 'package:cecelia_care_flutter/widgets/symptom_insights_card.dart';
import 'package:cecelia_care_flutter/widgets/med_schedule_timeline.dart';

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
                  color: Colors.black.withOpacity(0.12),
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
    builder: (sheetContext) => _MessageComposerSheet(
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
              color: Colors.black.withOpacity(0.12),
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
                      color: color.withOpacity(0.1),
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

  @override
  void initState() {
    super.initState();
    _loadSectionConfig();
  }

  Future<void> _loadSectionConfig() async {
    final config = await loadDashboardSections();
    if (mounted) setState(() => _sectionConfig = config);
  }

  /// Returns true if a section key is visible in the current config.
  bool _isVisible(String key) {
    if (_sectionConfig == null) return true; // show all while loading
    return _sectionConfig!.any((s) => s['key'] == key && s['visible'] == true);
  }

  /// Builds the ordered list of section widgets based on saved config.
  List<Widget> _buildDynamicSections({
    required BuildContext context,
    required ElderProfile activeElder,
    required String currentUserId,
    required String currentDateStr,
    required DateTime startOfDay,
    required DateTime endOfDay,
  }) {
    final sectionBuilders = <String, List<Widget> Function()>{
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
              MaterialPageRoute(
                  builder: (_) => const WellnessCheckinScreen()),
            ),
          );
        }),
      ],
      'quickMeds': () => [
        Builder(builder: (ctx) {
          final medProv = ctx.watch<MedicationDefinitionsProvider>();
          final pinned = medProv.pinnedMeds;
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
      ],
      'careLog': () => [
        const SizedBox(height: 20),
        const _SectionLabel(label: "Today's care log"),
        const SizedBox(height: 10),
        StreamBuilder<List<JournalEntry>>(
          stream: context.read<JournalServiceProvider>().getJournalEntriesStream(
                elderId: activeElder.id,
                currentUserId: currentUserId,
                startDate: startOfDay,
                endDate: endOfDay,
              ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const _TodayLoadingCard();
            }
            return _TodaySummaryGrid(entries: snapshot.data ?? []);
          },
        ),
      ],
      'achievements': () => [
        const SizedBox(height: 20),
        const _SectionLabel(label: 'Achievements'),
        const SizedBox(height: 10),
        const _BadgesRow(),
      ],
      'journal': () => [
        const SizedBox(height: 20),
        const _SectionLabel(label: 'My Journal'),
        const SizedBox(height: 10),
        _JournalPreviewCard(currentUserId: currentUserId),
      ],
      'quickLog': () {
        if (!context.watch<ActiveElderProvider>().canLog) return <Widget>[];
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
      'insights': () => [
        const SizedBox(height: 20),
        const _SectionLabel(label: 'Symptom insights'),
        const SizedBox(height: 10),
        const SymptomInsightsCard(),
      ],
      'medSchedule': () => [
        Builder(builder: (ctx) {
          final medProv = ctx.watch<MedicationDefinitionsProvider>();
          if (medProv.medDefinitions.isEmpty) return const SizedBox.shrink();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              SizedBox(height: 20),
              _SectionLabel(label: 'Med schedule'),
              SizedBox(height: 10),
              MedScheduleTimeline(),
            ],
          );
        }),
      ],
    };

    // Use saved order, or defaults if not loaded yet.
    final order = _sectionConfig ?? kDefaultSections;
    final widgets = <Widget>[];

    for (final section in order) {
      final key = section['key'] as String;
      final visible = section['visible'] as bool? ?? true;
      if (!visible) continue;

      final builder = sectionBuilders[key];
      if (builder != null) widgets.addAll(builder());
    }

    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    final activeElder = context.watch<ActiveElderProvider>().activeElder;
    final userProfile = context.watch<UserProfileProvider>().userProfile;

    if (activeElder == null) {
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

    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final elderDisplayName = (activeElder.preferredName?.isNotEmpty == true)
        ? activeElder.preferredName!
        : activeElder.profileName;
    final greeting = _buildGreeting(
        userProfile?.displayName ?? 'Caregiver', elderDisplayName);

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
          _GreetingCard(
            greeting: greeting,
            elderName: elderDisplayName,
            userInitial: (userProfile?.displayName.isNotEmpty == true)
                ? userProfile!.displayName[0].toUpperCase()
                : 'C',
            userPhotoUrl: userProfile?.avatarUrl,
          ),

          // Customize dashboard link
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const DashboardSettingsScreen()),
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

          // Dynamic sections
          ..._buildDynamicSections(
            context: context,
            activeElder: activeElder,
            currentUserId: currentUserId,
            currentDateStr: currentDateStr,
            startOfDay: startOfDay,
            endOfDay: endOfDay,
          ),
        ],
      ),
    );
  }

  String _buildGreeting(String userName, String elderName) {
    final hour = DateTime.now().hour;
    final String t = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';
    return '$t, $userName';
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
        color: const Color(0xFFE91E63),
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
        color: const Color(0xFF1E88E5),
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
        color: const Color(0xFFF57C00),
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
        color: const Color(0xFF5C6BC0),
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
        color: const Color(0xFF43A047),
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
        color: const Color(0xFF00897B),
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
        color: const Color(0xFFE53935),
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
        color: const Color(0xFF546E7A),
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
        return GestureDetector(
          onTap: action.onTap,
          child: Container(
            decoration: BoxDecoration(
              color: action.color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: action.color.withOpacity(0.2)),
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

class _MessageComposerSheet extends StatefulWidget {
  const _MessageComposerSheet({
    required this.activeElder,
    required this.firestoreService,
  });

  final ElderProfile activeElder;
  final FirestoreService firestoreService;

  @override
  State<_MessageComposerSheet> createState() =>
      _MessageComposerSheetState();
}

class _MessageComposerSheetState extends State<_MessageComposerSheet> {
  static const _kColor = Color(0xFF546E7A);

  final TextEditingController _ctrl = TextEditingController();
  bool _isPublic = true;
  List<String> _selectedUserIds = [];
  List<UserProfile> _associatedUsers = [];
  bool _isLoadingUsers = false;
  bool _isPosting = false;

  @override
  void initState() {
    super.initState();
    _fetchAssociatedUsers();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _fetchAssociatedUsers() async {
    if (widget.activeElder.id.isEmpty) return;
    setState(() => _isLoadingUsers = true);
    try {
      final users = await widget.firestoreService
          .getAssociatedUsersForElder(widget.activeElder.id);
      if (mounted) setState(() => _associatedUsers = users);
    } catch (e) {
      debugPrint('_MessageComposerSheet: error fetching users: $e');
    } finally {
      if (mounted) setState(() => _isLoadingUsers = false);
    }
  }

  Future<void> _post() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isPosting = true);
    try {
      List<String> visibleToUserIds = [];
      if (_isPublic) {
        visibleToUserIds.add('all');
      } else {
        visibleToUserIds.addAll(_selectedUserIds);
        if (!visibleToUserIds.contains(user.uid)) {
          visibleToUserIds.add(user.uid);
        }
      }

      await widget.firestoreService.addJournalEntry(
        elderId: widget.activeElder.id,
        type: EntryType.message,
        creatorId: user.uid,
        text: text,
        visibleToUserIds: visibleToUserIds,
        isPublic: _isPublic,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Message posted to timeline.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('_MessageComposerSheet._post error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not post message: ${e.toString()}'),
            backgroundColor: AppTheme.dangerColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final elderName = (widget.activeElder.preferredName?.isNotEmpty == true)
        ? widget.activeElder.preferredName!
        : widget.activeElder.profileName;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _kColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.chat_bubble_outline,
                    color: _kColor, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                'New message for $elderName\'s timeline',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Audience selector
          UserSelectorWidget(
            allUsers: _associatedUsers,
            isLoadingUsers: _isLoadingUsers,
            initialSelectedUserIds: _selectedUserIds,
            initialIsPublic: _isPublic,
            onSelectionChanged: (ids, isPublic) {
              setState(() {
                _selectedUserIds = ids;
                _isPublic = isPublic;
              });
            },
          ),

          const SizedBox(height: 12),

          // Audience hint
          Text(
            _isPublic
                ? 'Posting to all caregivers'
                : 'Private — visible only to selected people',
            style: theme.textTheme.bodySmall?.copyWith(
              fontStyle: FontStyle.italic,
              color: _isPublic ? AppTheme.textSecondary : _kColor,
            ),
          ),

          const SizedBox(height: 12),

          // Text field
          TextField(
            controller: _ctrl,
            maxLines: 4,
            autofocus: true,
            decoration: InputDecoration(
              hintText:
                  'Write a message for $elderName\'s timeline...',
              filled: true,
              fillColor: _kColor.withOpacity(0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    BorderSide(color: _kColor.withOpacity(0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    BorderSide(color: _kColor.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _kColor),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Action row
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed:
                    _isPosting ? null : () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _isPosting ? null : _post,
                icon: _isPosting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white))
                    : const Icon(Icons.send_outlined, size: 16),
                label: const Text('Post'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Greeting card
// ---------------------------------------------------------------------------

class _GreetingCard extends StatelessWidget {
  const _GreetingCard({
    required this.greeting,
    required this.elderName,
    required this.userInitial,
    this.userPhotoUrl,
  });

  final String greeting;
  final String elderName;
  final String userInitial;
  final String? userPhotoUrl;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = userPhotoUrl != null && userPhotoUrl!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withOpacity(0.75),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  'Caring for $elderName today',
                  style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.85)),
                ),
                const SizedBox(height: 8),
                Text(
                  DateFormat('EEEE, MMMM d').format(DateTime.now()),
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.7)),
                ),
              ],
            ),
          ),
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white.withOpacity(0.2),
            backgroundImage:
                hasPhoto ? NetworkImage(userPhotoUrl!) : null,
            child: hasPhoto
                ? null
                : Text(
                    userInitial,
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Today's log summary grid
// ---------------------------------------------------------------------------

class _TodaySummaryGrid extends StatelessWidget {
  const _TodaySummaryGrid({required this.entries});
  final List<JournalEntry> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.backgroundGray,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            'No entries logged today yet.\nTap a quick log button below to get started.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
        ),
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
    final color = _colorForType(type);
    final icon = _iconForType(type);
    final label = _labelForType(type);

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
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.25)),
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

  Color _colorForType(EntryType t) {
    switch (t) {
      case EntryType.mood: return const Color(0xFFE91E63);
      case EntryType.medication: return const Color(0xFF1E88E5);
      case EntryType.sleep: return const Color(0xFF5C6BC0);
      case EntryType.meal: return const Color(0xFF43A047);
      case EntryType.pain: return const Color(0xFFE53935);
      case EntryType.activity: return const Color(0xFF00897B);
      case EntryType.vital: return const Color(0xFFF57C00);
      case EntryType.expense: return const Color(0xFF8E24AA);
      case EntryType.message: return const Color(0xFF546E7A);
      case EntryType.handoff: return const Color(0xFF00897B);
      case EntryType.custom: return const Color(0xFF546E7A);
      default: return AppTheme.textSecondary;
    }
  }

  IconData _iconForType(EntryType t) {
    switch (t) {
      case EntryType.mood: return Icons.sentiment_satisfied_outlined;
      case EntryType.medication: return Icons.medication_outlined;
      case EntryType.sleep: return Icons.bedtime_outlined;
      case EntryType.meal: return Icons.restaurant_outlined;
      case EntryType.pain: return Icons.healing_outlined;
      case EntryType.activity: return Icons.directions_walk_outlined;
      case EntryType.vital: return Icons.monitor_heart_outlined;
      case EntryType.expense: return Icons.receipt_long_outlined;
      case EntryType.message: return Icons.chat_bubble_outline;
      case EntryType.handoff: return Icons.swap_horiz_outlined;
      case EntryType.custom: return Icons.extension_outlined;
      default: return Icons.note_outlined;
    }
  }

  String _labelForType(EntryType t) {
    switch (t) {
      case EntryType.mood: return 'Mood';
      case EntryType.medication: return 'Meds';
      case EntryType.sleep: return 'Sleep';
      case EntryType.meal: return 'Meals';
      case EntryType.pain: return 'Pain';
      case EntryType.activity: return 'Activity';
      case EntryType.vital: return 'Vitals';
      case EntryType.expense: return 'Expenses';
      case EntryType.message: return 'Messages';
      case EntryType.handoff: return 'Handoff';
      case EntryType.custom: return 'Custom';
      default: return t.name;
    }
  }
}


// ---------------------------------------------------------------------------
// Journal preview card — shows the most recent caregiverJournalEntry for
// the current user, with a button to open the full journal screen.
// ---------------------------------------------------------------------------

class _JournalPreviewCard extends StatelessWidget {
  const _JournalPreviewCard({required this.currentUserId});
  final String currentUserId;

  static const _kColor = Color(0xFF8E24AA);

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
        final hasEntry =
            snapshot.hasData && snapshot.data!.docs.isNotEmpty;
        final doc =
            hasEntry ? snapshot.data!.docs.first : null;
        final note = hasEntry
            ? (doc!.data() as Map<String, dynamic>)['note'] as String? ?? ''
            : '';
        final ts = hasEntry
            ? (doc!.data() as Map<String, dynamic>)['createdAt']
                as Timestamp?
            : null;
        final dateStr = ts != null
            ? DateFormat('MMM d').format(ts.toDate())
            : '';

        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const CareGiverJournalScreen()),
          ),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _kColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kColor.withOpacity(0.2)),
              boxShadow: [
                BoxShadow(
                  color: _kColor.withOpacity(0.06),
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
                    color: _kColor.withOpacity(0.1),
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
                                    color: _kColor.withOpacity(0.8),
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

class _TodayLoadingCard extends StatelessWidget {
  const _TodayLoadingCard();
  @override
  Widget build(BuildContext context) => Container(
        height: 80,
        decoration: BoxDecoration(
            color: AppTheme.backgroundGray,
            borderRadius: BorderRadius.circular(12)),
        child: const Center(child: CircularProgressIndicator()),
      );
}

// ---------------------------------------------------------------------------
// Badge info dialog — shown when tapping any badge (locked or unlocked)
// ---------------------------------------------------------------------------

void _showBadgeInfoDialog(BuildContext context, Badge badge) {
  final isEarned = badge.tier != BadgeTier.none || badge.unlocked == true;
  final tierColor = badge.tierStyle.color;
  final thresholds = badge.thresholds;

  if (isEarned) {
    HapticUtils.celebration();
    ConfettiOverlay.trigger(context);
  }

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(
            isEarned ? Icons.emoji_events : Icons.lock_outline,
            color: isEarned ? tierColor : AppTheme.textLight,
            size: 28,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              badge.label,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isEarned ? tierColor : AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description
          Text(
            badge.description,
            style: const TextStyle(fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 16),

          // Current tier
          if (isEarned) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: tierColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: tierColor.withOpacity(0.3)),
              ),
              child: Text(
                'Current tier: ${badge.tierStyle.label}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: tierColor,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Progress
          if (badge.progressLabel.isNotEmpty)
            Text(
              badge.progressLabel,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          if (badge.progressLabel.isNotEmpty)
            const SizedBox(height: 12),

          // Tier thresholds
          if (thresholds != null) ...[
            const Text(
              'TIER REQUIREMENTS',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            _TierRow(label: 'Bronze', count: thresholds.bronze,
                reached: badge.progressCount >= thresholds.bronze),
            _TierRow(label: 'Silver', count: thresholds.silver,
                reached: badge.progressCount >= thresholds.silver),
            _TierRow(label: 'Gold', count: thresholds.gold,
                reached: badge.progressCount >= thresholds.gold),
            _TierRow(label: 'Diamond', count: thresholds.diamond,
                reached: badge.progressCount >= thresholds.diamond),
          ],

          const SizedBox(height: 16),

          // Why gamification matters
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF8E24AA).withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 14,
                    color: Color(0xFF8E24AA)),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Achievements reward you for taking care of yourself '
                    'while caring for others. Small consistent actions '
                    'reduce burnout and build resilience.',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF8E24AA),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

class _TierRow extends StatelessWidget {
  const _TierRow({
    required this.label,
    required this.count,
    required this.reached,
  });
  final String label;
  final int count;
  final bool reached;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            reached ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 14,
            color: reached ? const Color(0xFF43A047) : AppTheme.textLight,
          ),
          const SizedBox(width: 6),
          Text(
            '$label: $count',
            style: TextStyle(
              fontSize: 12,
              color: reached ? AppTheme.textPrimary : AppTheme.textSecondary,
              fontWeight: reached ? FontWeight.w600 : FontWeight.normal,
              decoration: reached ? TextDecoration.lineThrough : null,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Badges row
// ---------------------------------------------------------------------------

class _BadgesRow extends StatelessWidget {
  const _BadgesRow();

  @override
  Widget build(BuildContext context) {
    final badges = context.watch<BadgeProvider>().badges;
    final unlocked = badges.values.where((b) => b.unlocked == true).toList();
    final locked = badges.values.where((b) => b.unlocked != true).toList();
    final all = [...unlocked, ...locked];
    if (all.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 88,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: all.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final badge = all[i];
          final isUnlocked = badge.unlocked == true;
          return GestureDetector(
            onTap: () => _showBadgeInfoDialog(context, badge),
            child: Container(
              width: 72,
              decoration: BoxDecoration(
                color: isUnlocked
                    ? const Color(0xFFFFF8E1)
                    : AppTheme.backgroundGray,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: isUnlocked
                        ? const Color(0xFFFFC107)
                        : Colors.transparent),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isUnlocked ? Icons.emoji_events : Icons.lock_outline,
                    size: 28,
                    color: isUnlocked
                        ? const Color(0xFFFFC107)
                        : AppTheme.textLight,
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      badge.label,
                      style: TextStyle(
                        fontSize: 9,
                        color: isUnlocked
                            ? const Color(0xFF8D6E00)
                            : AppTheme.textLight,
                        fontWeight: isUnlocked
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

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

  static const _kColor = Color(0xFF1E88E5);

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
              ? const Color(0xFF43A047).withOpacity(0.08)
              : _kColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _justLogged
                ? const Color(0xFF43A047).withOpacity(0.3)
                : _kColor.withOpacity(0.25),
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
                  color: _justLogged ? const Color(0xFF43A047) : _kColor,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    widget.med.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _justLogged
                          ? const Color(0xFF43A047)
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
                      ? const Color(0xFF43A047)
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
        color: AppTheme.textSecondary,
      ),
    );
  }
}
