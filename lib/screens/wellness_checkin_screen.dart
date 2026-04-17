// lib/screens/wellness_checkin_screen.dart
//
// The ~30-second daily wellness check-in.
//
// Five dimensions, each scored 1–5 via a tappable row of labeled circles.
// On save: writes to WellnessProvider, awards points + streak via
// GamificationProvider, triggers badge tier check, and pops.
//
// Launched from the Self Care tab or from a push notification nudge.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:cecelia_care_flutter/providers/wellness_provider.dart';
import 'package:cecelia_care_flutter/providers/gamification_provider.dart';
import 'package:cecelia_care_flutter/providers/badge_provider.dart';
import 'package:cecelia_care_flutter/models/wellness_checkin.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';
import 'package:cecelia_care_flutter/utils/haptic_utils.dart';
import 'package:cecelia_care_flutter/widgets/confetti_overlay.dart';

// Accent — purple, matching the Self Care tab.
const _kAccent = AppTheme.tilePurple;

class WellnessCheckinScreen extends StatefulWidget {
  const WellnessCheckinScreen({super.key});

  @override
  State<WellnessCheckinScreen> createState() => _WellnessCheckinScreenState();
}

class _WellnessCheckinScreenState extends State<WellnessCheckinScreen> {
  int _mood = 3;
  int _sleep = 3;
  int _exercise = 3;
  int _social = 3;
  int _meTime = 3;
  final _noteCtrl = TextEditingController();

  bool _isSaving = false;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill from today's existing check-in if editing.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final existing = context.read<WellnessProvider>().todayCheckin;
      if (existing != null && mounted) {
        setState(() {
          _mood = existing.mood;
          _sleep = existing.sleepQuality;
          _exercise = existing.exercise;
          _social = existing.socialConnection;
          _meTime = existing.meTime;
          _noteCtrl.text = existing.note ?? '';
        });
      }
    });
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final wellness = context.read<WellnessProvider>();
      final gamification = context.read<GamificationProvider>();
      final badges = context.read<BadgeProvider>();

      // 1. Save the check-in
      await wellness.saveCheckin(
        mood: _mood,
        sleepQuality: _sleep,
        exercise: _exercise,
        socialConnection: _social,
        meTime: _meTime,
        note: _noteCtrl.text.trim().isNotEmpty ? _noteCtrl.text.trim() : null,
      );

      // 2. Award points + update streak
      await gamification.onCheckinCompleted();

      // 3. Check badge tier progress
      await badges.checkTierProgress(
        streakDays: gamification.longestStreak,
        moodDays: gamification.lifetimeCheckins,
        journalCount: gamification.lifetimeJournals,
        breathingCount: gamification.lifetimeBreathingSessions,
        careLogCount: gamification.lifetimeCareLogs,
        challengeCount: gamification.lifetimeChallengesCompleted,
        totalPoints: gamification.totalPoints,
      );

      // 4. Haptic feedback
      // Celebration for streak milestones (7, 14, 30, 60, 90, 365…)
      final streak = gamification.currentStreak;
      if (streak == 7 || streak == 14 || streak == 30 ||
          streak == 60 || streak == 90 || streak == 365) {
        HapticUtils.celebration();
        if (mounted) ConfettiOverlay.trigger(context);
      } else {
        HapticUtils.success();
      }

      if (mounted) {
        setState(() => _saved = true);
        // Brief pause to show the success state, then pop.
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) Navigator.of(context).pop(true);
      }
    } catch (e) {
      debugPrint('WellnessCheckinScreen._save error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not save check-in: $e'),
            backgroundColor: AppTheme.dangerColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily check-in'),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryColor,
                AppTheme.primaryColor.withValues(alpha: 0.82),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      body: _saved
          ? _SuccessView()
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Text(
                    'How are you doing today?',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: _kAccent,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Takes about 30 seconds. Your answers help detect burnout early.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 28),

                  // Dimension sliders
                  _DimensionRow(
                    icon: Icons.sentiment_satisfied_outlined,
                    label: 'Mood',
                    value: _mood,
                    labels: WellnessCheckin.moodLabels,
                    color: AppTheme.tilePinkBright,
                    onChanged: (v) => setState(() => _mood = v),
                  ),
                  const SizedBox(height: 20),

                  _DimensionRow(
                    icon: Icons.bedtime_outlined,
                    label: 'Sleep quality',
                    value: _sleep,
                    labels: WellnessCheckin.sleepLabels,
                    color: AppTheme.tileIndigo,
                    onChanged: (v) => setState(() => _sleep = v),
                  ),
                  const SizedBox(height: 20),

                  _DimensionRow(
                    icon: Icons.directions_walk_outlined,
                    label: 'Exercise',
                    value: _exercise,
                    labels: WellnessCheckin.exerciseLabels,
                    color: AppTheme.tileTeal,
                    onChanged: (v) => setState(() => _exercise = v),
                  ),
                  const SizedBox(height: 20),

                  _DimensionRow(
                    icon: Icons.people_outline,
                    label: 'Social connection',
                    value: _social,
                    labels: WellnessCheckin.socialLabels,
                    color: AppTheme.tileBlue,
                    onChanged: (v) => setState(() => _social = v),
                  ),
                  const SizedBox(height: 20),

                  _DimensionRow(
                    icon: Icons.spa_outlined,
                    label: 'Me-time',
                    value: _meTime,
                    labels: WellnessCheckin.meTimeLabels,
                    color: _kAccent,
                    onChanged: (v) => setState(() => _meTime = v),
                  ),

                  const SizedBox(height: 24),

                  // Optional note
                  TextField(
                    controller: _noteCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Anything else on your mind? (optional)',
                      hintText: 'A quick note about your day...',
                      filled: true,
                      fillColor: _kAccent.withValues(alpha: 0.04),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                        borderSide:
                            BorderSide(color: _kAccent.withValues(alpha: 0.2)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                        borderSide:
                            BorderSide(color: _kAccent.withValues(alpha: 0.2)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                        borderSide: const BorderSide(color: _kAccent),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Save button
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusM),
                        ),
                        elevation: 2,
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle_outline, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Save check-in',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  '+10 pts',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
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
// Dimension row — icon + label + 5 tappable circles
// ---------------------------------------------------------------------------
class _DimensionRow extends StatelessWidget {
  const _DimensionRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.labels,
    required this.color,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final int value; // 1–5
  final List<String> labels;
  final Color color;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label row
        Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            const Spacer(),
            Text(
              labels[value.clamp(1, 5) - 1],
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Score circles
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(5, (i) {
            final score = i + 1;
            final isSelected = score == value;
            final isBelow = score <= value;

            return GestureDetector(
              onTap: () => onChanged(score),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: isSelected
                      ? color
                      : isBelow
                          ? color.withValues(alpha: 0.15)
                          : color.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? color
                        : isBelow
                            ? color.withValues(alpha: 0.3)
                            : color.withValues(alpha: 0.15),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    '$score',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? Colors.white : color,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),

        // Min/max labels
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                labels.first,
                style: TextStyle(
                  fontSize: 10,
                  color: color.withValues(alpha: 0.5),
                ),
              ),
              Text(
                labels.last,
                style: TextStyle(
                  fontSize: 10,
                  color: color.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Success view — shown briefly after saving
// ---------------------------------------------------------------------------
class _SuccessView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.statusGreen.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              size: 56,
              color: AppTheme.statusGreen,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Check-in saved!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.statusGreen,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '+10 points earned',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
