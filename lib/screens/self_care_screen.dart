// lib/screens/self_care_screen.dart
//
// Redesigned Self Care tab — the caregiver's wellbeing hub.
//
// Layout (top to bottom):
//   1. Daily check-in CTA (if not done today) or today's summary
//   2. Burnout score card with dimension breakdown
//   3. Streak + level widget
//   4. Weekly challenge card
//   5. Relief tools (breathing, SOS, journal, gratitude/affirmations)
//   6. Tiered badge showcase
//   7. Daily mood (existing emoji picker + history strip)
//   8. Break reminders (existing hydrate/stretch/walk)
//
// No Scaffold — _TabScaffold in HomeScreen provides the AppBar.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:cecelia_care_flutter/providers/wellness_provider.dart';
import 'package:cecelia_care_flutter/providers/gamification_provider.dart';
import 'package:cecelia_care_flutter/providers/badge_provider.dart';
import 'package:cecelia_care_flutter/providers/self_care_provider.dart';
import 'package:cecelia_care_flutter/models/self_care_reminder.dart';
import 'package:cecelia_care_flutter/models/badge.dart' as app_badge;
import 'package:cecelia_care_flutter/services/notification_service.dart';
import 'package:cecelia_care_flutter/l10n/app_localizations.dart';
import 'package:cecelia_care_flutter/utils/app_styles.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';

// Screens
import 'package:cecelia_care_flutter/screens/wellness_checkin_screen.dart';
import 'package:cecelia_care_flutter/screens/breathing_exercise_screen.dart';
import 'package:cecelia_care_flutter/screens/sos_screen.dart';
import 'package:cecelia_care_flutter/screens/affirmations_screen.dart';
import 'package:cecelia_care_flutter/screens/caregiver_journal/caregiver_journal_screen.dart';

// Widgets
import 'package:cecelia_care_flutter/widgets/burnout_score_card.dart';
import 'package:cecelia_care_flutter/widgets/streak_widget.dart';
import 'package:cecelia_care_flutter/widgets/weekly_challenge_card.dart';

// Self-care accent — purple, matching the nav tab.
const _kSelfCareColor = Color(0xFF8E24AA);

class SelfCareScreen extends StatefulWidget {
  const SelfCareScreen({super.key});
  @override
  State<SelfCareScreen> createState() => _SelfCareScreenState();
}

class _SelfCareScreenState extends State<SelfCareScreen> {
  final _noteCtrl = TextEditingController();
  String? _lastKnownTodayNote;
  bool _isInit = false;

  final Map<String, int> _stableReminderIds = {
    "hydrate": 1001,
    "stretch": 1002,
    "walk": 1003,
  };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      final scProv = context.read<SelfCareProvider>();
      Future.wait([scProv.load(), scProv.loadHistory()]).catchError((error) {
        debugPrint("Error during initial data load in SelfCareScreen: $error");
        return <void>[];
      });
      _isInit = true;
    }

    // Check for level-up celebration
    _checkLevelUp();
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  void _checkLevelUp() {
    final gam = context.read<GamificationProvider>();
    if (gam.levelUpPending) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        gam.clearLevelUp();
        _showLevelUpDialog(gam.level, gam.levelTitle);
      });
    }
  }

  void _showLevelUpDialog(int level, String title) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFC107).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.star, size: 48, color: Color(0xFFFFC107)),
            ),
            const SizedBox(height: 16),
            const Text(
              'Level up!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFFFFC107),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'You reached level $level',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: _kSelfCareColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Keep taking care of yourself and your loved one!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kSelfCareColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: const Text('Awesome!',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scProv = context.watch<SelfCareProvider>();
    final wellProv = context.watch<WellnessProvider>();
    final gamProv = context.watch<GamificationProvider>();
    final badgeProv = context.watch<BadgeProvider>();
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    // Keep mood note in sync
    if (scProv.todayNote != _lastKnownTodayNote) {
      _noteCtrl.text = scProv.todayNote ?? "";
      _lastKnownTodayNote = scProv.todayNote;
    }

    // Loading state
    if (scProv.isLoading &&
        scProv.todayMood == null &&
        scProv.reminders.isEmpty &&
        wellProv.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Error state
    if (scProv.errorInfo != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            "Error: ${scProv.errorInfo!.details}",
            style: TextStyle(color: theme.colorScheme.error),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // Tiered badges for the showcase
    final tieredBadges = badgeProv.tieredBadges.values.toList()
      ..sort((a, b) {
        // Earned badges first, then by tier level descending
        final aEarned = a.isEarned ? 1 : 0;
        final bEarned = b.isEarned ? 1 : 0;
        if (aEarned != bEarned) return bEarned - aEarned;
        return b.tier.index - a.tier.index;
      });

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ══════════════════════════════════════════════════════════
          // 1. DAILY CHECK-IN CTA
          // ══════════════════════════════════════════════════════════
          if (!wellProv.hasCheckedInToday)
            _CheckinCta(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const WellnessCheckinScreen()),
              ),
            )
          else
            _CheckinDoneBadge(checkin: wellProv.todayCheckin!),

          const SizedBox(height: 14),

          // ══════════════════════════════════════════════════════════
          // 2. BURNOUT SCORE CARD
          // ══════════════════════════════════════════════════════════
          if (wellProv.recentCheckins.isNotEmpty) ...[
            _SectionLabel(label: 'Your wellbeing'),
            const SizedBox(height: 8),
            BurnoutScoreCard(
              burnoutStatus: wellProv.burnoutStatus,
              dimensionAverages: wellProv.dimensionAverages,
              moodTrend: wellProv.moodTrend,
              onTapRelief: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const BreathingExerciseScreen()),
              ),
              onTapSos: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SosScreen()),
              ),
            ),
            const SizedBox(height: 14),
          ],

          // ══════════════════════════════════════════════════════════
          // 3. STREAK + LEVEL
          // ══════════════════════════════════════════════════════════
          _SectionLabel(label: 'Your progress'),
          const SizedBox(height: 8),
          StreakWidget(
            currentStreak: gamProv.currentStreak,
            longestStreak: gamProv.longestStreak,
            streakFreezeAvailable:
                !(gamProv.points?.streakFreezeUsed ?? false),
            level: gamProv.level,
            levelTitle: gamProv.levelTitle,
            totalPoints: gamProv.totalPoints,
            levelProgress: gamProv.levelProgress,
          ),

          const SizedBox(height: 14),

          // ══════════════════════════════════════════════════════════
          // 4. WEEKLY CHALLENGE
          // ══════════════════════════════════════════════════════════
          _SectionLabel(label: 'Weekly challenge'),
          const SizedBox(height: 8),
          WeeklyChallengeCard(challenge: gamProv.currentChallenge),

          const SizedBox(height: 14),

          // ══════════════════════════════════════════════════════════
          // 5. RELIEF TOOLS
          // ══════════════════════════════════════════════════════════
          _SectionLabel(label: 'Relief tools'),
          const SizedBox(height: 8),
          _ReliefToolsGrid(
            onBreathing: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => const BreathingExerciseScreen()),
            ),
            onSos: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SosScreen()),
            ),
            onJournal: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => const CareGiverJournalScreen()),
            ),
          ),

          const SizedBox(height: 14),

          // ══════════════════════════════════════════════════════════
          // 6. BADGE TIERS
          // ══════════════════════════════════════════════════════════
          if (tieredBadges.isNotEmpty) ...[
            _SectionLabel(label: 'Achievements'),
            const SizedBox(height: 8),
            SizedBox(
              height: 110,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: tieredBadges.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, i) =>
                    _TieredBadgeChip(badge: tieredBadges[i]),
              ),
            ),
            const SizedBox(height: 14),
          ],

          // ══════════════════════════════════════════════════════════
          // 7. DAILY MOOD (existing — emoji picker + history)
          // ══════════════════════════════════════════════════════════
          _SectionLabel(label: l10n.dailyMood),
          const SizedBox(height: 8),
          _SelfCareCard(
            color: const Color(0xFFE91E63),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: ["🙂", "😐", "😔", "😡", "😍"].map((emoji) {
                    final isSelected = scProv.todayMood == emoji;
                    return GestureDetector(
                      onTap: () => scProv.saveMood(emoji, _noteCtrl.text),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFE91E63).withOpacity(0.15)
                              : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: Text(emoji,
                            style:
                                TextStyle(fontSize: isSelected ? 36 : 30)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _noteCtrl,
                  decoration: InputDecoration(
                    labelText: l10n.optionalNote,
                    filled: true,
                    fillColor: const Color(0xFFE91E63).withOpacity(0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                          color: const Color(0xFFE91E63).withOpacity(0.3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                          color: const Color(0xFFE91E63).withOpacity(0.3)),
                    ),
                  ),
                  onSubmitted: (text) =>
                      scProv.saveMood(scProv.todayMood ?? "🙂", text),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Mood history strip
          if (scProv.history.isNotEmpty) ...[
            _SectionLabel(label: "Mood history"),
            const SizedBox(height: 8),
            SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount:
                    scProv.history.length > 7 ? 7 : scProv.history.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (ctx, i) {
                  final reversed = scProv.history.reversed.toList();
                  if (i >= reversed.length) return const SizedBox.shrink();
                  final entry = reversed[i];
                  final isStreakDay = i < scProv.currentStreak;
                  final dateLabel = DateFormat("MMM d",
                          Localizations.localeOf(context).languageCode)
                      .format(entry.date);
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: isStreakDay
                            ? _kSelfCareColor.withOpacity(0.15)
                            : AppTheme.backgroundGray,
                        child: Text(entry.emoji,
                            style: const TextStyle(fontSize: 20)),
                      ),
                      const SizedBox(height: 4),
                      Text(dateLabel,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: AppTheme.textSecondary)),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
          ],

          // ══════════════════════════════════════════════════════════
          // 8. BREAK REMINDERS (existing)
          // ══════════════════════════════════════════════════════════
          _SectionLabel(label: l10n.breakReminders),
          const SizedBox(height: 8),
          _SelfCareCard(
            color: const Color(0xFF00897B),
            child: Column(
              children: [
                _ReminderRow(
                  context: context,
                  provider: scProv,
                  id: "hydrate",
                  label: l10n.hydrate,
                  icon: Icons.water_drop_outlined,
                  stableIds: _stableReminderIds,
                  l10n: l10n,
                ),
                const Divider(height: 1),
                _ReminderRow(
                  context: context,
                  provider: scProv,
                  id: "stretch",
                  label: l10n.stretch,
                  icon: Icons.self_improvement_outlined,
                  stableIds: _stableReminderIds,
                  l10n: l10n,
                ),
                const Divider(height: 1),
                _ReminderRow(
                  context: context,
                  provider: scProv,
                  id: "walk",
                  label: l10n.walk,
                  icon: Icons.directions_walk_outlined,
                  stableIds: _stableReminderIds,
                  l10n: l10n,
                ),
              ],
            ),
          ),

          const SizedBox(height: AppStyles.spacingL),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Check-in CTA — shown when the user hasn't checked in today
// ---------------------------------------------------------------------------
class _CheckinCta extends StatelessWidget {
  const _CheckinCta({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_kSelfCareColor, _kSelfCareColor.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _kSelfCareColor.withOpacity(0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.favorite, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'How are you today?',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Quick 30-second check-in  •  +10 pts',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                size: 16, color: Colors.white.withOpacity(0.7)),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Check-in done badge — shown after today's check-in is complete
// ---------------------------------------------------------------------------
class _CheckinDoneBadge extends StatelessWidget {
  const _CheckinDoneBadge({required this.checkin});
  final dynamic checkin; // WellnessCheckin

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF43A047).withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: const Color(0xFF43A047).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle,
              color: Color(0xFF43A047), size: 20),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              "Today's check-in complete",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF43A047),
              ),
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => const WellnessCheckinScreen()),
            ),
            child: Text(
              'Edit',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF43A047).withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Relief tools grid — 2x2 grid of action cards
// ---------------------------------------------------------------------------
class _ReliefToolsGrid extends StatelessWidget {
  const _ReliefToolsGrid({
    required this.onBreathing,
    required this.onSos,
    required this.onJournal,
  });

  final VoidCallback onBreathing;
  final VoidCallback onSos;
  final VoidCallback onJournal;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.6,
      children: [
        _ReliefTile(
          icon: Icons.air_outlined,
          label: 'Breathing',
          subtitle: '+10 pts',
          color: const Color(0xFF5C6BC0),
          onTap: onBreathing,
        ),
        _ReliefTile(
          icon: Icons.spa_outlined,
          label: 'SOS mode',
          subtitle: 'Crisis toolkit',
          color: const Color(0xFFE53935),
          onTap: onSos,
        ),
        _ReliefTile(
          icon: Icons.menu_book_outlined,
          label: 'Journal',
          subtitle: '+15 pts',
          color: _kSelfCareColor,
          onTap: onJournal,
        ),
        _ReliefTile(
          icon: Icons.format_quote_outlined,
          label: 'Affirmations',
          subtitle: 'Daily encouragement',
          color: const Color(0xFF00897B),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
                builder: (_) => const AffirmationsScreen()),
          ),
        ),
      ],
    );
  }
}

class _ReliefTile extends StatelessWidget {
  const _ReliefTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const Spacer(),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: color.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tiered badge chip — shows tier color, progress bar, label
// ---------------------------------------------------------------------------
class _TieredBadgeChip extends StatelessWidget {
  const _TieredBadgeChip({required this.badge});
  final app_badge.Badge badge;

  @override
  Widget build(BuildContext context) {
    final style = badge.tierStyle;
    final isEarned = badge.isEarned;

    return Tooltip(
      message: '${badge.description}\n${badge.progressLabel}',
      child: Container(
        width: 90,
        decoration: BoxDecoration(
          color: isEarned ? style.backgroundColor : AppTheme.backgroundGray,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isEarned ? style.color : Colors.transparent,
            width: isEarned ? 1.5 : 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isEarned ? Icons.emoji_events : Icons.lock_outline,
              size: 26,
              color: isEarned ? style.color : AppTheme.textLight,
            ),
            const SizedBox(height: 4),
            if (isEarned)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: style.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  style.label,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: style.color,
                  ),
                ),
              ),
            const SizedBox(height: 3),
            Text(
              badge.label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: isEarned ? FontWeight.w600 : FontWeight.normal,
                color: isEarned ? style.textColor : AppTheme.textLight,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            // Mini progress bar
            if (badge.thresholds != null)
              Container(
                height: 3,
                decoration: BoxDecoration(
                  color: (isEarned ? style.color : AppTheme.textLight)
                      .withOpacity(0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: badge.progressToNextTier,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isEarned ? style.color : AppTheme.textLight,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Reused private widgets from the original self_care_screen
// ---------------------------------------------------------------------------

// Soft card container with left accent strip
class _SelfCareCard extends StatelessWidget {
  const _SelfCareCard({required this.child, required this.color});
  final Widget child;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: color),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: child,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Reminder row — replaces SwitchListTile with colored icon
class _ReminderRow extends StatelessWidget {
  const _ReminderRow({
    required this.context,
    required this.provider,
    required this.id,
    required this.label,
    required this.icon,
    required this.stableIds,
    required this.l10n,
  });

  final BuildContext context;
  final SelfCareProvider provider;
  final String id;
  final String label;
  final IconData icon;
  final Map<String, int> stableIds;
  final AppLocalizations l10n;

  static const _color = Color(0xFF00897B);

  @override
  Widget build(BuildContext ctx) {
    final rem = provider.reminders[id];
    final isOn = rem?.timeOfDay != null;
    final theme = Theme.of(ctx);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: _color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.bodyLarge),
                if (isOn)
                  Text(rem!.timeOfDay!,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: _color))
                else
                  Text(l10n.off,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: AppTheme.textSecondary)),
              ],
            ),
          ),
          Switch(
            value: isOn,
            activeColor: _color,
            onChanged: (on) async {
              if (!on) {
                await provider.saveReminder(
                    SelfCareReminder(id: id, timeOfDay: null));
                await NotificationService.instance
                    .cancel(stableIds[id] ?? id.hashCode);
              } else {
                final pickedTime = await showTimePicker(
                    context: context, initialTime: TimeOfDay.now());
                if (pickedTime != null) {
                  await provider.saveReminder(SelfCareReminder(
                      id: id, timeOfDay: pickedTime.format(context)));
                  await NotificationService.instance
                      .scheduleDailyRepeatingNotification(
                    notificationId: stableIds[id] ?? id.hashCode,
                    time: pickedTime,
                    channelId: "self_care",
                    title: l10n.selfCareReminderTitle,
                    body: "$label time!",
                    payload: '{"type":"$id","reminderType":"self_care"}',
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
}

// Section label — matches dashboard style
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
