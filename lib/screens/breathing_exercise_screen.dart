// lib/screens/breathing_exercise_screen.dart
//
// Guided breathing exercise with an animated expanding/contracting circle.
//
// Three presets:
//   • Box Breathing   — 4s inhale, 4s hold, 4s exhale, 4s hold
//   • 4-7-8 Breathing — 4s inhale, 7s hold, 8s exhale
//   • Calm Breath     — 5s inhale, 5s exhale
//
// Awards points via GamificationProvider on completion of a full cycle.
// Can be launched from Self Care tab, burnout nudge, or SOS screen.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:cecelia_care_flutter/providers/gamification_provider.dart';
import 'package:cecelia_care_flutter/providers/badge_provider.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';

// ---------------------------------------------------------------------------
// Breathing pattern definitions
// ---------------------------------------------------------------------------
class _BreathPhase {
  final String label;
  final int seconds;
  final bool isExpand; // true = circle grows, false = shrinks, null = hold

  const _BreathPhase(this.label, this.seconds, this.isExpand);
}

class _BreathPattern {
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final List<_BreathPhase> phases;

  const _BreathPattern({
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.phases,
  });

  int get totalSeconds => phases.fold(0, (sum, p) => sum + p.seconds);
}

const _patterns = [
  _BreathPattern(
    name: 'Box breathing',
    description: 'Equal timing. Great for focus and calm.',
    icon: Icons.crop_square_outlined,
    color: AppTheme.tileIndigo,
    phases: [
      _BreathPhase('Breathe in', 4, true),
      _BreathPhase('Hold', 4, false),
      _BreathPhase('Breathe out', 4, false),
      _BreathPhase('Hold', 4, false),
    ],
  ),
  _BreathPattern(
    name: '4-7-8 breathing',
    description: 'Long exhale. Reduces anxiety and aids sleep.',
    icon: Icons.nights_stay_outlined,
    color: AppTheme.tileBlue,
    phases: [
      _BreathPhase('Breathe in', 4, true),
      _BreathPhase('Hold', 7, false),
      _BreathPhase('Breathe out', 8, false),
    ],
  ),
  _BreathPattern(
    name: 'Calm breath',
    description: 'Simple and gentle. Good for beginners.',
    icon: Icons.spa_outlined,
    color: AppTheme.tileTeal,
    phases: [
      _BreathPhase('Breathe in', 5, true),
      _BreathPhase('Breathe out', 5, false),
    ],
  ),
];

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------
class BreathingExerciseScreen extends StatefulWidget {
  /// Optional: pre-select a pattern index (0=Box, 1=4-7-8, 2=Calm).
  final int initialPatternIndex;

  const BreathingExerciseScreen({
    super.key,
    this.initialPatternIndex = 0,
  });

  @override
  State<BreathingExerciseScreen> createState() =>
      _BreathingExerciseScreenState();
}

class _BreathingExerciseScreenState extends State<BreathingExerciseScreen>
    with SingleTickerProviderStateMixin {
  late int _patternIndex;
  _BreathPattern get _pattern => _patterns[_patternIndex];

  // Exercise state
  bool _isRunning = false;
  bool _isComplete = false;
  int _currentPhaseIndex = 0;
  int _phaseSecondsRemaining = 0;
  int _cyclesCompleted = 0;
  static const int _targetCycles = 3;
  Timer? _timer;

  // Animation
  late AnimationController _animCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _patternIndex = widget.initialPatternIndex.clamp(0, _patterns.length - 1);
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _scaleAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animCtrl.dispose();
    super.dispose();
  }

  void _selectPattern(int index) {
    if (_isRunning) return;
    setState(() {
      _patternIndex = index;
      _reset();
    });
  }

  void _start() {
    setState(() {
      _isRunning = true;
      _isComplete = false;
      _cyclesCompleted = 0;
      _currentPhaseIndex = 0;
    });
    _startPhase();
  }

  void _stop() {
    _timer?.cancel();
    _animCtrl.stop();
    setState(() => _isRunning = false);
  }

  void _reset() {
    _timer?.cancel();
    _animCtrl.stop();
    _animCtrl.value = 0;
    setState(() {
      _isRunning = false;
      _isComplete = false;
      _cyclesCompleted = 0;
      _currentPhaseIndex = 0;
      _phaseSecondsRemaining = 0;
    });
  }

  void _startPhase() {
    if (!_isRunning || !mounted) return;

    final phase = _pattern.phases[_currentPhaseIndex];
    setState(() => _phaseSecondsRemaining = phase.seconds);

    // Animate the circle
    _animCtrl.duration = Duration(seconds: phase.seconds);
    if (phase.isExpand) {
      _animCtrl.forward(from: _animCtrl.value);
    } else {
      // For exhale/hold, reverse or hold position
      if (phase.label.contains('out')) {
        _animCtrl.reverse(from: _animCtrl.value);
      }
      // For hold, keep current position (do nothing with animation)
    }

    // Haptic feedback at phase transition
    HapticFeedback.lightImpact();

    // Countdown timer
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _phaseSecondsRemaining--);

      if (_phaseSecondsRemaining <= 0) {
        timer.cancel();
        _advancePhase();
      }
    });
  }

  void _advancePhase() {
    if (!_isRunning || !mounted) return;

    final nextIndex = _currentPhaseIndex + 1;
    if (nextIndex >= _pattern.phases.length) {
      // Completed one cycle
      _cyclesCompleted++;
      if (_cyclesCompleted >= _targetCycles) {
        _onExerciseComplete();
        return;
      }
      // Start next cycle
      setState(() => _currentPhaseIndex = 0);
      _startPhase();
    } else {
      setState(() => _currentPhaseIndex = nextIndex);
      _startPhase();
    }
  }

  Future<void> _onExerciseComplete() async {
    _timer?.cancel();
    _animCtrl.stop();

    setState(() {
      _isRunning = false;
      _isComplete = true;
    });

    HapticFeedback.mediumImpact();

    // Award points
    try {
      final gam = context.read<GamificationProvider>();
      await gam.onBreathingCompleted();

      final badges = context.read<BadgeProvider>();
      await badges.checkTierProgress(
        breathingCount: gam.lifetimeBreathingSessions,
        streakDays: gam.longestStreak,
        journalCount: gam.lifetimeJournals,
        careLogCount: gam.lifetimeCareLogs,
        challengeCount: gam.lifetimeChallengesCompleted,
        totalPoints: gam.totalPoints,
        moodDays: gam.lifetimeCheckins,
      );
    } catch (e) {
      debugPrint('BreathingExerciseScreen: error awarding points: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Breathing exercise'),
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
      body: Column(
        children: [
          // ── Pattern selector ─────────────────────────────────────
          if (!_isRunning && !_isComplete)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: List.generate(_patterns.length, (i) {
                  final p = _patterns[i];
                  final selected = i == _patternIndex;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => _selectPattern(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: EdgeInsets.only(
                            left: i == 0 ? 0 : 4,
                            right: i == _patterns.length - 1 ? 0 : 4),
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 8),
                        decoration: BoxDecoration(
                          color: selected
                              ? p.color.withValues(alpha: 0.12)
                              : AppTheme.backgroundGray,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected
                                ? p.color
                                : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(p.icon, color: p.color, size: 22),
                            const SizedBox(height: 4),
                            Text(
                              p.name,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: p.color,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),

          // ── Description ──────────────────────────────────────────
          if (!_isRunning && !_isComplete)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Text(
                _pattern.description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ),

          // ── Animated circle area ─────────────────────────────────
          Expanded(
            child: Center(
              child: _isComplete
                  ? _CompletionView(
                      color: _pattern.color,
                      onReset: _reset,
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Phase label
                        if (_isRunning) ...[
                          Text(
                            _pattern.phases[_currentPhaseIndex].label,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: _pattern.color,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$_phaseSecondsRemaining',
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w300,
                              color: _pattern.color.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Breathing circle
                        AnimatedBuilder(
                          animation: _scaleAnim,
                          builder: (context, child) {
                            final scale =
                                _isRunning ? _scaleAnim.value : 0.5;
                            return Container(
                              width: 180 * scale + 40,
                              height: 180 * scale + 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color:
                                    _pattern.color.withValues(alpha: 0.12),
                                border: Border.all(
                                  color:
                                      _pattern.color.withValues(alpha: 0.3),
                                  width: 3,
                                ),
                              ),
                              child: Center(
                                child: Container(
                                  width: 120 * scale + 20,
                                  height: 120 * scale + 20,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _pattern.color
                                        .withValues(alpha: 0.2),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                        if (_isRunning) ...[
                          const SizedBox(height: 20),
                          Text(
                            'Cycle ${_cyclesCompleted + 1} of $_targetCycles',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
          ),

          // ── Start / Stop buttons ─────────────────────────────────
          if (!_isComplete)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              child: Row(
                children: [
                  if (_isRunning) ...[
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: OutlinedButton(
                          onPressed: _stop,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.dangerColor,
                            side: const BorderSide(
                                color: AppTheme.dangerColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text('Stop',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ),
                  ] else ...[
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _start,
                          icon: const Icon(Icons.play_arrow, size: 22),
                          label: const Text('Begin',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _pattern.color,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Completion view — shown after all cycles are done
// ---------------------------------------------------------------------------
class _CompletionView extends StatelessWidget {
  const _CompletionView({required this.color, required this.onReset});
  final Color color;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.statusGreen.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle,
            size: 64,
            color: AppTheme.statusGreen,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Great job!',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppTheme.statusGreen,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Exercise complete. +10 points earned.',
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Take a moment to notice how you feel.',
          style: TextStyle(
            fontSize: 13,
            color: AppTheme.textSecondary,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 28),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton(
              onPressed: onReset,
              style: OutlinedButton.styleFrom(
                foregroundColor: color,
                side: BorderSide(color: color),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text('Do another'),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text('Done'),
            ),
          ],
        ),
      ],
    );
  }
}
