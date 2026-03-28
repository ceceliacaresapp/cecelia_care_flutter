// lib/screens/dashboard_screen.dart
//
// The home dashboard — first tab the user lands on.
// Shows: elder greeting card, today's entry summary by type,
// badges earned, and quick-action shortcuts to log common entries.
//
// Quick log buttons open the same modal bottom sheets used by the Care/
// Timeline screens. Each form is wrapped in a ChangeNotifierProvider.value
// that injects the scoped JournalServiceProvider so saves work identically
// to logging from any other screen.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:cecelia_care_flutter/models/elder_profile.dart';
import 'package:cecelia_care_flutter/models/entry_types.dart';
import 'package:cecelia_care_flutter/models/journal_entry.dart';
import 'package:cecelia_care_flutter/providers/active_elder_provider.dart';
import 'package:cecelia_care_flutter/providers/badge_provider.dart';
import 'package:cecelia_care_flutter/providers/journal_service_provider.dart';
import 'package:cecelia_care_flutter/providers/medication_definitions_provider.dart';
import 'package:cecelia_care_flutter/providers/user_profile_provider.dart';
import 'package:cecelia_care_flutter/screens/forms/mood_form.dart';
import 'package:cecelia_care_flutter/screens/forms/sleep_form.dart';
import 'package:cecelia_care_flutter/screens/forms/meal_form.dart';
import 'package:cecelia_care_flutter/screens/forms/activity_form.dart';
import 'package:cecelia_care_flutter/screens/forms/vital_form.dart';
import 'package:cecelia_care_flutter/screens/forms/pain_form.dart';
import 'package:cecelia_care_flutter/screens/forms/med_form.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';

// ---------------------------------------------------------------------------
// Helper — opens a form as a modal bottom sheet, identical to how the Care
// and Timeline screens open forms. No dialog to dismiss from the dashboard,
// so we don't call Navigator.pop() before showing the sheet.
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
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: Container(
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
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(sheetContext).size.height * 0.92,
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
              Flexible(child: form),
            ],
          ),
        ),
      );
    },
  );
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

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

    final currentUserId =
        FirebaseAuth.instance.currentUser?.uid ?? '';

    final elderDisplayName =
        (activeElder.preferredName?.isNotEmpty == true)
            ? activeElder.preferredName!
            : activeElder.profileName;

    final greeting = _buildGreeting(
        userProfile?.displayName ?? 'Caregiver', elderDisplayName);

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay =
        DateTime(now.year, now.month, now.day, 23, 59, 59);
    final currentDateStr = DateFormat('yyyy-MM-dd').format(now);

    return RefreshIndicator(
      onRefresh: () async {},
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        children: [
          // ── Greeting card ───────────────────────────────────────
          _GreetingCard(
            greeting: greeting,
            elderName: elderDisplayName,
            elderInitial: activeElder.profileName[0].toUpperCase(),
          ),

          const SizedBox(height: 20),

          // ── Today's activity ────────────────────────────────────
          const _SectionLabel(label: "Today's care log"),
          const SizedBox(height: 10),
          StreamBuilder<List<JournalEntry>>(
            stream: context
                .read<JournalServiceProvider>()
                .getJournalEntriesStream(
                  elderId: activeElder.id,
                  currentUserId: currentUserId,
                  startDate: startOfDay,
                  endDate: endOfDay,
                ),
            builder: (context, snapshot) {
              if (snapshot.connectionState ==
                      ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const _TodayLoadingCard();
              }
              final entries = snapshot.data ?? [];
              return _TodaySummaryGrid(entries: entries);
            },
          ),

          const SizedBox(height: 20),

          // ── Badges ──────────────────────────────────────────────
          const _SectionLabel(label: 'Achievements'),
          const SizedBox(height: 10),
          const _BadgesRow(),

          const SizedBox(height: 20),

          // ── Quick log ───────────────────────────────────────────
          const _SectionLabel(label: 'Quick log'),
          const SizedBox(height: 10),
          _QuickActionsGrid(
            activeElder: activeElder,
            currentDateStr: currentDateStr,
          ),
        ],
      ),
    );
  }

  String _buildGreeting(String userName, String elderName) {
    final hour = DateTime.now().hour;
    final String timeGreeting;
    if (hour < 12) {
      timeGreeting = 'Good morning';
    } else if (hour < 17) {
      timeGreeting = 'Good afternoon';
    } else {
      timeGreeting = 'Good evening';
    }
    return '$timeGreeting, $userName';
  }
}

// ---------------------------------------------------------------------------
// Quick actions grid — opens real form sheets
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
              activeElder: activeElder,
            ),
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
              activeElder: activeElder,
            ),
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
              activeElder: activeElder,
            ),
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
              activeElder: activeElder,
            ),
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
              activeElder: activeElder,
            ),
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
              activeElder: activeElder,
            ),
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
              activeElder: activeElder,
            ),
          ),
        ),
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
// Greeting card
// ---------------------------------------------------------------------------

class _GreetingCard extends StatelessWidget {
  const _GreetingCard({
    required this.greeting,
    required this.elderName,
    required this.elderInitial,
  });

  final String greeting;
  final String elderName;
  final String elderInitial;

  @override
  Widget build(BuildContext context) {
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
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Caring for $elderName today',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  DateFormat('EEEE, MMMM d').format(DateTime.now()),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: Text(
              elderInitial,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
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
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
            ),
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
      itemBuilder: (context, i) {
        final type = items[i].key;
        final count = items[i].value;
        return _EntryTypeChip(type: type, count: count);
      },
    );
  }
}

class _EntryTypeChip extends StatelessWidget {
  const _EntryTypeChip({required this.type, required this.count});
  final EntryType type;
  final int count;

  @override
  Widget build(BuildContext context) {
    final color = _colorForType(type);
    final icon = _iconForType(type);

    return Container(
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
          Text(
            '$count',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            _labelForType(type),
            style: const TextStyle(
              fontSize: 10,
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Color _colorForType(EntryType t) {
    switch (t) {
      case EntryType.mood:
        return const Color(0xFFE91E63);
      case EntryType.medication:
        return const Color(0xFF1E88E5);
      case EntryType.sleep:
        return const Color(0xFF5C6BC0);
      case EntryType.meal:
        return const Color(0xFF43A047);
      case EntryType.pain:
        return const Color(0xFFE53935);
      case EntryType.activity:
        return const Color(0xFF00897B);
      case EntryType.vital:
        return const Color(0xFFF57C00);
      case EntryType.expense:
        return const Color(0xFF8E24AA);
      case EntryType.message:
        return const Color(0xFF546E7A);
      default:
        return AppTheme.textSecondary;
    }
  }

  IconData _iconForType(EntryType t) {
    switch (t) {
      case EntryType.mood:
        return Icons.sentiment_satisfied_outlined;
      case EntryType.medication:
        return Icons.medication_outlined;
      case EntryType.sleep:
        return Icons.bedtime_outlined;
      case EntryType.meal:
        return Icons.restaurant_outlined;
      case EntryType.pain:
        return Icons.healing_outlined;
      case EntryType.activity:
        return Icons.directions_walk_outlined;
      case EntryType.vital:
        return Icons.monitor_heart_outlined;
      case EntryType.expense:
        return Icons.receipt_long_outlined;
      case EntryType.message:
        return Icons.chat_bubble_outline;
      default:
        return Icons.note_outlined;
    }
  }

  String _labelForType(EntryType t) {
    switch (t) {
      case EntryType.mood:
        return 'Mood';
      case EntryType.medication:
        return 'Meds';
      case EntryType.sleep:
        return 'Sleep';
      case EntryType.meal:
        return 'Meals';
      case EntryType.pain:
        return 'Pain';
      case EntryType.activity:
        return 'Activity';
      case EntryType.vital:
        return 'Vitals';
      case EntryType.expense:
        return 'Expenses';
      case EntryType.message:
        return 'Messages';
      default:
        return t.name;
    }
  }
}

class _TodayLoadingCard extends StatelessWidget {
  const _TodayLoadingCard();
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: AppTheme.backgroundGray,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(child: CircularProgressIndicator()),
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
    final unlocked =
        badges.values.where((b) => b.unlocked == true).toList();
    final locked =
        badges.values.where((b) => b.unlocked != true).toList();
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
          return Tooltip(
            message: badge.description,
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
                      : Colors.transparent,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isUnlocked
                        ? Icons.emoji_events
                        : Icons.lock_outline,
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
